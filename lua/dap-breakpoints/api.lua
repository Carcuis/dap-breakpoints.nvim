local M = {}

local breakpoint = require("dap-breakpoints.breakpoint")
local config = require("dap-breakpoints.config")
local util = require("dap-breakpoints.util")
local virtual_text = require("dap-breakpoints.virtual-text")

function M.go_to_previous()
  M.go_to_next({ reverse = true })
end

---@param opt { reverse: boolean }|nil
function M.go_to_next(opt)
  local buffer_breakpoints = breakpoint.get_buffer_breakpoints()
  if #buffer_breakpoints == 0 then
    util.echo_message("No breakpoints in current buffer.", vim.log.levels.WARN)
    return
  end

  local count = #buffer_breakpoints
  local num
  local next

  local reverse = opt and opt.reverse
  if reverse then
    num = count
    next = buffer_breakpoints[count]
  else
    num = 1
    next = buffer_breakpoints[1]
  end

  local _position = vim.fn.getcurpos()
  local _line = _position[2]
  local _column = _position[3]

  for _num, _breakpoint in ipairs(buffer_breakpoints) do
    if reverse then
      if _breakpoint.line < _line then
        next = _breakpoint
        num = _num
      else
        break
      end
    else
      if _breakpoint.line > _line then
        next = _breakpoint
        num = _num
        break
      end
    end
  end

  util.echo_message("Breakpoint " .. num .." of " .. count, vim.log.levels.INFO)

  if next.line == _line then
    return
  end

  vim.fn.cursor({ next.line, _column })

  if config.breakpoint.auto_reveal_popup and not breakpoint.is_normal_breakpoint(next) then
    vim.schedule(function()
      M.popup_reveal()
    end)
  end
end

function M.popup_reveal()
  local _breakpoint = breakpoint.get_breakpoint()
  if _breakpoint == nil then
    util.echo_message("No breakpoints on current line.", vim.log.levels.WARN)
    return
  end

  if breakpoint.is_normal_breakpoint(_breakpoint) then
    util.echo_message("No extra properties.", vim.log.levels.WARN)
    return
  end

  if breakpoint.is_conditional_breakpoint(_breakpoint) then
    util.show_popup({
      title = "Breakpoint Condition:",
      message = _breakpoint["condition"],
      syntax = vim.bo.filetype,
    })
  elseif breakpoint.is_hit_condition_breakpoint(_breakpoint) then
    util.show_popup({
      title = "Breakpoint Hit Condition:",
      message = _breakpoint["hitCondition"],
      syntax = vim.bo.filetype,
    })
  else
    util.show_popup({
      title = "Log point message:",
      message = "\"" .. _breakpoint["logMessage"] .. "\"",
      syntax = "lua",
    })
  end
end

function M.edit_property()
  local _breakpoint = breakpoint.get_breakpoint()
  if _breakpoint == nil then
    util.echo_message("No breakpoints on current line.", vim.log.levels.WARN)
    return
  end

  if breakpoint.is_normal_breakpoint(_breakpoint) then
    util.echo_message("No extra properties to edit.", vim.log.levels.WARN)
    return
  end

  local filetype = vim.bo.filetype
  if breakpoint.is_conditional_breakpoint(_breakpoint) then
    vim.ui.input({ prompt = "Edit breakpoint condition: ", default = _breakpoint.condition }, function(input)
      -- breakpoint.set_breakpoint(input and input or _breakpoint.condition, nil, nil)
      M.set_breakpoint({ condition = input and input or _breakpoint.condition })
    end)
  elseif breakpoint.is_hit_condition_breakpoint(_breakpoint) then
    vim.ui.input({ prompt = "Edit hit condition: ", default = _breakpoint.hitCondition }, function(input)
      M.set_breakpoint({ hit_condition = input and input or _breakpoint.hitCondition })
    end)
  else
    vim.ui.input({ prompt = "Edit log point message: ", default = _breakpoint.logMessage }, function(input)
      M.set_breakpoint({ log_message = input and input or _breakpoint.logMessage })
    end)
  end

  if not breakpoint.is_log_point(_breakpoint) then
    util.set_input_ui_filetype(filetype)
  end
end

function M.disable_virtual_text()
  virtual_text.clear_all_virtual_text()
  if config.virtual_text.current_line_only then
    virtual_text.unset_current_line_only_autocmd()
  elseif virtual_text.get_user_layout().layout_type ~= "eol" then
      virtual_text.unset_decoration_provider()
  end
  virtual_text.enabled = false
end

function M.enable_virtual_text()
  if virtual_text.enabled then
    virtual_text.clear_all_virtual_text()
  end

  if config.virtual_text.current_line_only then
    virtual_text.enable_virtual_text_on_line()
    virtual_text.set_current_line_only_autocmd()
  else
    virtual_text.enable_virtual_text_in_all_buffers()

    if virtual_text.get_user_layout().layout_type ~= "eol" then
      virtual_text.set_decoration_provider()
    end
  end

  virtual_text.enabled = true
end

function M.toggle_virtual_text()
  if virtual_text.enabled then
    M.disable_virtual_text()
  else
    M.enable_virtual_text()
  end
end

---@param opt { notify: boolean }|nil
function M.load_breakpoints(opt)
  breakpoint.load()

  if virtual_text.enabled then
    if config.virtual_text.current_line_only then
      virtual_text.enable_virtual_text_on_line()
    else
      virtual_text.enable_virtual_text_in_all_buffers()
    end
  end

  if opt and opt.notify then
    local total_count = breakpoint.get_total_breakpoints_count()
    local loaded_buf_count = vim.tbl_count(breakpoint.get_all_breakpoints())
    local message = "Loaded "..total_count.." breakpoints in "..loaded_buf_count.." buffers."
    util.notify(message)
  end
end

---@param opt { notify: boolean }|nil
function M.save_breakpoints(opt)
  breakpoint.save()

  if opt and opt.notify then
    local total_count = breakpoint.get_total_breakpoints_count()
    local saved_buf_count = vim.tbl_count(breakpoint.get_all_breakpoints())
    local message = "Saved "..total_count.." breakpoints in "..saved_buf_count.." buffers."
    util.notify(message)
  end
end

---@param opt BreakpointProperty|nil
function M.set_breakpoint(opt)
  if opt then
    for _, prop in ipairs({ "condition", "hit_condition", "log_message" }) do
      if opt[prop] == "" then
        opt[prop] = nil
      end
    end
  end

  breakpoint.set_breakpoint(opt)

  if virtual_text.enabled then
    virtual_text.enable_virtual_text_on_line()
  end
end

function M.toggle_breakpoint()
  if breakpoint.get_breakpoint() then
    breakpoint.toggle_breakpoint()

    if virtual_text.enabled then
      virtual_text.clear_virtual_text_on_line()
    end
  else
    M.set_breakpoint()
  end
end

function M.set_conditional_breakpoint()
  local filetype = vim.bo.filetype
  vim.ui.input({ prompt = "Conditional point expression: " }, function(input)
    M.set_breakpoint({ condition = input })
  end)
  util.set_input_ui_filetype(filetype)
end

function M.set_hit_condition_breakpoint()
  local filetype = vim.bo.filetype
  vim.ui.input({ prompt = "Hit condition count: " }, function(input)
    M.set_breakpoint({ hit_condition = input })
  end)
  util.set_input_ui_filetype(filetype)
end

function M.set_log_point()
  vim.ui.input({ prompt = "Log point message: " }, function(input)
    M.set_breakpoint({ log_message = input })
  end)
end

function M.clear_all_breakpoints()
  local and_save = config.breakpoint.auto_save and " and save" or ""
  local total_count = breakpoint.get_total_breakpoints_count()

  if total_count == 0 then
    util.echo_message("No breakpoints to clear.", vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = "Clear all ("..total_count..") breakpoints"..and_save.."? [y/N] " }, function(input)
    if input and string.match(string.lower(input), '^ye?s?$') then
      if virtual_text.enabled then
        virtual_text.clear_all_virtual_text()
      end
      breakpoint.clear_all_breakpoints()
    end
  end)
end

return M

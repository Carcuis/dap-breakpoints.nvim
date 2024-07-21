local M = {}

local breakpoint = require("dap-breakpoints.breakpoint")
local config = require("dap-breakpoints.config")
local util = require("dap-breakpoints.util")
local virtual_text = require("dap-breakpoints.virtual-text")

function M.go_to_previous()
  M.go_to_next({ reverse = true })
end

function M.go_to_next(opt)
  local buffer_breakpoints = breakpoint.get_buffer_breakpoints()
  if buffer_breakpoints == nil then
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

  if config.reveal.auto_popup and not breakpoint.is_normal_breakpoint(next) then
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
  for bufnr, _ in pairs(breakpoint.get_all_breakpoints()) do
    vim.api.nvim_buf_clear_namespace(bufnr, virtual_text.get_ns_id(), 0, -1)
  end

  virtual_text.enabled = false
end

-- TODO: enable for all buffers
function M.enable_virtual_text()
  local buffer_breakpoints = breakpoint.get_buffer_breakpoints()
  if buffer_breakpoints == nil then
    return
  end

  for _, _breakpoint in ipairs(buffer_breakpoints) do
    virtual_text.enable_virtual_text_on_breakpoint(_breakpoint)
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

function M.set_breakpoint(opt)
  for _, prop in ipairs({"condition", "hit_condition", "log_message"}) do
    if opt[prop] == "" then
      opt[prop] = nil
    end
  end

  breakpoint.set_breakpoint(opt)

  if virtual_text.enabled then
    virtual_text.enable_virtual_text_on_breakpoint(opt)
  end

  if type(config.on_set_breakpoint) == "function" then
    config.on_set_breakpoint(opt.condition, opt.hit_condition, opt.log_message)
  end
end

return M

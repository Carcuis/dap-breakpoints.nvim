local breakpoint = require("dap-breakpoints.breakpoint")
local config = require("dap-breakpoints.config")
local util = require("dap-breakpoints.util")
local virtual_text = require("dap-breakpoints.virtual-text")

---@class DapBpApi
local M = {}

function M.go_to_previous()
  M.go_to_next({ reverse = true })
end

---@param opt { reverse: boolean }?
function M.go_to_next(opt)
  local buffer_breakpoints = breakpoint.get_in_buffer()
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

  for i, bp in ipairs(buffer_breakpoints) do
    if reverse then
      if bp.line < _line then
        next = bp
        num = i
      else
        break
      end
    else
      if bp.line > _line then
        next = bp
        num = i
        break
      end
    end
  end

  util.echo_message("Breakpoint " .. num .. " of " .. count, vim.log.levels.INFO)

  if next.line == _line then
    return
  end

  vim.fn.cursor({ next.line, _column })

  if config.auto_reveal_popup and not breakpoint.is_normal(next) then
    vim.schedule(M.popup_reveal)
  end
end

function M.popup_reveal()
  local bp = breakpoint.get()
  if not bp then
    util.echo_message("No breakpoints on current line.", vim.log.levels.WARN)
    return
  end

  local has_condition = breakpoint.has_condition(bp)
  local has_hit_condition = breakpoint.has_hit_condition(bp)
  local has_log_message = breakpoint.has_log_message(bp)

  local prop_count = (has_condition and 1 or 0) + (has_hit_condition and 1 or 0) + (has_log_message and 1 or 0)

  if prop_count == 0 then
    util.echo_message("No extra properties.", vim.log.levels.WARN)
    return
  end

  if prop_count == 1 then
    if has_condition then
      util.show_popup({
        title = "Breakpoint Condition",
        message = bp.condition,
        syntax = vim.bo.filetype,
      })
    elseif has_hit_condition then
      util.show_popup({
        title = "Breakpoint Hit Condition",
        message = bp.hitCondition,
        syntax = vim.bo.filetype,
      })
    else
      util.show_popup({
        title = "Log Point Message",
        message = '"' .. bp.logMessage .. '"',
        syntax = "lua",
      })
    end
    return
  end

  local props = {}
  if has_condition then
    table.insert(props, { title = "[Condition]", message = bp.condition, syntax = vim.bo.filetype })
  end
  if has_hit_condition then
    table.insert(props, { title = "[HitCondition]", message = bp.hitCondition, syntax = vim.bo.filetype })
  end
  if has_log_message then
    table.insert(props, { title = "[LogMessage]", message = '"' .. bp.logMessage .. '"', syntax = "lua" })
  end

  local lines = {}
  for _, prop in ipairs(props) do
    table.insert(lines, prop.title)
    table.insert(lines, prop.message)
    table.insert(lines, "")
  end
  util.show_popup({
    title = "Breakpoint Properties",
    message = table.concat(lines, "\n"),
    syntax = vim.bo.filetype,
  })
end

---@param bp DapBp.Breakpoint
function M.edit_condition(bp)
  local filetype = vim.bo.filetype
  vim.ui.input({ prompt = "Edit condition", default = bp.condition }, function(input)
    local opt = {
      condition = input or bp.condition,
      hitCondition = bp.hitCondition,
      logMessage = bp.logMessage,
    }
    M._set_breakpoint(opt)
  end)
  util.set_input_ui_filetype(filetype)
end

---@param bp DapBp.Breakpoint
function M.edit_hit_condition(bp)
  local filetype = vim.bo.filetype
  vim.ui.input({ prompt = "Edit hit condition", default = bp.hitCondition }, function(input)
    local opt = {
      condition = bp.condition,
      hitCondition = input or bp.hitCondition,
      logMessage = bp.logMessage,
    }
    M._set_breakpoint(opt)
  end)
  util.set_input_ui_filetype(filetype)
end

---@param bp DapBp.Breakpoint
function M.edit_log_message(bp)
  vim.ui.input({ prompt = "Edit log message", default = bp.logMessage }, function(input)
    local opt = {
      condition = bp.condition,
      hitCondition = bp.hitCondition,
      logMessage = input or bp.logMessage,
    }
    M._set_breakpoint(opt)
  end)
end

---@param bp DapBp.Breakpoint
function M.edit_line_number(bp)
  local current_line = bp.line
  vim.ui.input({ prompt = "Move breakpoint to line", default = tostring(current_line) }, function(input)
    if not input or input == "" then
      return
    end
    M.move_breakpoint(input)
  end)
end

---@param opt { all: boolean }?
function M.edit_property(opt)
  local edit_all_properties = opt and opt.all
  local bp = breakpoint.get()

  if not bp then
    M.set_breakpoint()
    return
  end

  local has_condition = breakpoint.has_condition(bp)
  local has_hit_condition = breakpoint.has_hit_condition(bp)
  local has_log_message = breakpoint.has_log_message(bp)

  local prop_count = (has_condition and 1 or 0) + (has_hit_condition and 1 or 0) + (has_log_message and 1 or 0)

  if not edit_all_properties and prop_count <= 1 then
    if has_condition then
      M.edit_condition(bp)
    elseif has_hit_condition then
      M.edit_hit_condition(bp)
    elseif has_log_message then
      M.edit_log_message(bp)
    else
      M.edit_line_number(bp)
    end
    return
  end

  local items = {
    { "Edit Line Number", function()
      M.edit_line_number(bp)
    end },
  }
  if edit_all_properties or has_condition then
    table.insert(items, { "Edit Condition", function()
      M.edit_condition(bp)
    end })
  end
  if edit_all_properties or has_hit_condition then
    table.insert(items, { "Edit Hit Condition", function()
      M.edit_hit_condition(bp)
    end })
  end
  if edit_all_properties or has_log_message then
    table.insert(items, { "Edit Log Message", function()
      M.edit_log_message(bp)
    end })
  end

  vim.ui.select(items, {
    prompt = "Select property to edit",
    format_item = function(item)
      return item[1]
    end,
  }, function(choice)
    if choice then
      choice[2]()
    end
  end)
end

---@param new_line integer|string
---@param force boolean? replace existing breakpoint
function M.move_breakpoint(new_line, force)
  local current_line = vim.fn.line(".")
  local bp = breakpoint.get()

  if not bp then
    util.echo_message("No breakpoint found at line " .. current_line, vim.log.levels.WARN)
    return
  end

  local n = tonumber(new_line)
  if not n or n < 1 or n ~= math.floor(n) then
    util.echo_message("Invalid line number: " .. new_line, vim.log.levels.WARN)
    return
  end
  if current_line == n then
    return
  end

  if not force and breakpoint.get({ line = n }) then
    util.confirm("Breakpoint already exists at line " .. n .. ". Overwrite? [y/N] ", function()
      M.move_breakpoint(new_line, true)
    end)
    return
  end

  local opt = {
    condition = bp.condition,
    hitCondition = bp.hitCondition,
    logMessage = bp.logMessage,
  }

  M.toggle_breakpoint()
  vim.fn.cursor({ n, 1 })
  M._set_breakpoint(opt)
end

function M.disable_virtual_text()
  virtual_text.clear_all()
  if config.virtual_text.current_line_only then
    virtual_text.unset_current_line_only_autocmd()
  elseif virtual_text.get_user_layout().layout_type ~= "eol" then
    virtual_text.unset_decoration_provider()
  end
  virtual_text.enabled = false
end

function M.enable_virtual_text()
  if virtual_text.enabled then
    virtual_text.clear_all()
  end

  if config.virtual_text.current_line_only then
    virtual_text.enable_on_line()
    virtual_text.set_current_line_only_autocmd()
  else
    virtual_text.enable_in_all_buffers()

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

---@param opt { notify: boolean }?
function M.load_breakpoints(opt)
  breakpoint.load()

  if virtual_text.enabled then
    if config.virtual_text.current_line_only then
      virtual_text.enable_on_line()
    else
      virtual_text.enable_in_all_buffers()
    end
  end

  if opt and opt.notify then
    local total_count = breakpoint.get_total_count()
    local loaded_buf_count = vim.tbl_count(breakpoint.get_all())
    local message = "Loaded " .. total_count .. " breakpoints in " .. loaded_buf_count .. " buffers."
    util.notify(message)
  end
end

---@param opt { notify: boolean }?
function M.save_breakpoints(opt)
  breakpoint.save()

  if opt and opt.notify then
    local total_count = breakpoint.get_total_count()
    local saved_buf_count = vim.tbl_count(breakpoint.get_all())
    local message = "Saved " .. total_count .. " breakpoints in " .. saved_buf_count .. " buffers."
    util.notify(message)
  end
end

---@param opt DapBp.BreakpointProperty?
function M._set_breakpoint(opt)
  if opt then
    for _, prop in ipairs({ "condition", "hitCondition", "logMessage" }) do
      if opt[prop] == "" then
        opt[prop] = nil
      end
    end
  end

  breakpoint.set(opt)

  if virtual_text.enabled then
    virtual_text.enable_on_line()
  end
end

function M.set_breakpoint()
  local items = {
    { "Line Breakpoint", M._set_breakpoint },
    { "Conditional Breakpoint", M.set_conditional_breakpoint },
    { "Log Point", M.set_log_point },
    { "Hit Condition Breakpoint", M.set_hit_condition_breakpoint },
  }

  vim.ui.select(items, {
    prompt = "Select breakpoint type",
    format_item = function(item)
      return item[1]
    end,
  }, function(choice)
    if choice then
      choice[2]()
    end
  end)
end

function M.toggle_breakpoint()
  if breakpoint.get() then
    breakpoint.toggle()

    if virtual_text.enabled then
      virtual_text.clear_on_line()
    end
  else
    M._set_breakpoint()
  end
end

function M.set_conditional_breakpoint()
  local filetype = vim.bo.filetype
  vim.ui.input({ prompt = "Conditional point expression" }, function(input)
    M._set_breakpoint({ condition = input })
  end)
  util.set_input_ui_filetype(filetype)
end

function M.set_hit_condition_breakpoint()
  local filetype = vim.bo.filetype
  vim.ui.input({ prompt = "Hit condition count" }, function(input)
    M._set_breakpoint({ hitCondition = input })
  end)
  util.set_input_ui_filetype(filetype)
end

function M.set_log_point()
  vim.ui.input({ prompt = "Log point message" }, function(input)
    M._set_breakpoint({ logMessage = input })
  end)
end

function M.clear_all_breakpoints()
  local and_save = config.auto_save and " and save" or ""
  local total_count = breakpoint.get_total_count()

  if total_count == 0 then
    util.echo_message("No breakpoints to clear.", vim.log.levels.WARN)
    return
  end

  util.confirm("Clear all (" .. total_count .. ") breakpoints" .. and_save .. "? [y/N] ", function()
    if virtual_text.enabled then
      virtual_text.clear_all()
    end
    breakpoint.clear_all()
  end)
end

return M

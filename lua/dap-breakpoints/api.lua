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

  local target
  local original_position = vim.fn.getcurpos()
  local start_line = original_position[2]
  local start_column = original_position[3]

  -- NOTE: assumes breakpoints are in order by line number
  if opt and opt.reverse then
    for _, line_breakpoint in ipairs(buffer_breakpoints) do
      if line_breakpoint.line < start_line then
        target = line_breakpoint
      end
    end
    if target == nil then
      target = buffer_breakpoints[#buffer_breakpoints]
    end
  else
    for _, value in ipairs(buffer_breakpoints) do
      if value.line > start_line then
        target = value
        break
      end
    end
    if target == nil then
      target = buffer_breakpoints[1]
    end
  end

  if target.line == start_line then
    util.echo_message("Already at only breakpoint.", vim.log.levels.WARN)
    return
  end

  vim.fn.cursor({ target.line, start_column })

  if config.reveal.auto_popup and not breakpoint.is_normal_breakpoint(target) then
    vim.schedule(function()
      M.popup_reveal()
    end)
  end
end

function M.popup_reveal()
  local line_breakpoint = breakpoint.get_line_breakpoint()
  if line_breakpoint == nil then
    util.echo_message("No breakpoints on current line.", vim.log.levels.WARN)
    return
  end

  local property = ""
  if line_breakpoint.logMessage ~= nil then
    property = "logMessage"
  elseif line_breakpoint.condition ~= nil then
    property = "condition"
  elseif line_breakpoint.hitCondition ~= nil then
    property = "hitCondition"
  else
    util.echo_message("No extra properties of this breakpoint.", vim.log.levels.WARN)
    return
  end

  local message = line_breakpoint[property]
  if message == nil then
    util.echo_message("Breakpoint does not have a " .. property .. " attribute.", vim.log.levels.WARN)
    return
  end

  if property == "condition" then
    local title = "Breakpoint Condition:"
    util.show_popup({
      title = title,
      message = message,
      syntax = vim.bo.filetype,
    })
  elseif property == "hitCondition" then
    local title = "Breakpoint Hit Count Condition:"
    util.show_popup({
      title = title,
      message = message,
      syntax = vim.bo.filetype,
    })
  else
    local title = "Log point message:"
    util.show_popup({
      title = title,
      message = "\"" .. message .. "\"",
      syntax = "lua",
    })
  end
end

function M.update_property()
  local target = breakpoint.get_line_breakpoint()
  if target == nil then
    util.echo_message("No breakpoints on current line.", vim.log.levels.WARN)
    return
  end

  local targetProperty
  if breakpoint.is_log_point(target) then
    targetProperty = "logMessage"
  elseif breakpoint.is_conditional_breakpoint(target) then
    targetProperty = "condition"
  elseif breakpoint.is_hit_condition_breakpoint(target) then
    targetProperty = "hitCondition"
  else
    util.echo_message("Unable to update property of a normal breakpoint.", vim.log.levels.WARN)
    return
  end

  local filetype = vim.bo.filetype
  if targetProperty == "condition" then
    vim.ui.input({ prompt = "Edit breakpoint condition: ", default = target.condition }, function(input)
      breakpoint.custom_set_breakpoint(input and input or target.condition, nil, nil)
    end)
  elseif targetProperty == "hitCondition" then
    vim.ui.input({ prompt = "Edit hit count condition: ", default = target.hitCondition }, function(input)
      breakpoint.custom_set_breakpoint(nil, input and input or target.hitCondition, nil)
    end)
  else
    vim.ui.input({ prompt = "Edit log point message: ", default = target.logMessage }, function(input)
      breakpoint.custom_set_breakpoint(nil, nil, input and input or target.logMessage)
    end)
  end

  if targetProperty ~= "logMessage" then
    util.set_input_ui_filetype(filetype)
  end
end

function M.disable_virtual_text_in_buffer(_bufnr)
  virtual_text.disable_virtual_text_in_buffer(_bufnr)
end

function M.enable_virtual_text_in_buffer(_bufnr)
  local bufnr = _bufnr or vim.fn.bufnr()

  local buffer_breakpoints = breakpoint.get_buffer_breakpoints(bufnr)
  if buffer_breakpoints == nil then
    return
  end

  for _, line_breakpoint in ipairs(buffer_breakpoints) do
    virtual_text.enable_virtual_text_on_line(line_breakpoint.line, bufnr)
  end
end

function M.update_virtual_text_in_buffer(_bufnr)
  local bufnr = _bufnr or vim.fn.bufnr()

  M.disable_virtual_text_in_buffer(bufnr)
  M.enable_virtual_text_in_buffer(bufnr)
end

return M

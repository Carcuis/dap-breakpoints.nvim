local M = {}

local breakpoint = require("dap-breakpoints.breakpoint")
local config = require("dap-breakpoints.config")
local util = require("dap-breakpoints.util")

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

  if config.reveal.auto_popup and breakpoint.is_special_breakpoint(target) then
    vim.schedule(function()
      breakpoint.popup_reveal()
    end)
  end
end

function M.popup_reveal()
  breakpoint.popup_reveal()
end

function M.update_property()
  local target = breakpoint.get_line_breakpoint()
  if target == nil then
    util.echo_message("No breakpoints on current line.", vim.log.levels.WARN)
    return
  end

  local targetProperty
  if target.logMessage ~= nil then
    targetProperty = "logMessage"
  elseif target.condition ~= nil then
    targetProperty = "condition"
  elseif target.hitCondition ~= nil then
    targetProperty = "hitCondition"
  else
    util.echo_message("Ignoring since this is not a special breakpoint.", vim.log.levels.WARN)
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
  util.set_input_ui_filetype(filetype)
end

return M

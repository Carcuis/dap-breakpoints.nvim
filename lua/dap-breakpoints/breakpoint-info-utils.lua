local M = {}

local config = require("dap-breakpoints.config")
local noti_utils = require("dap-breakpoints.noti-utils")
local breakpoint_utils = require("dap-breakpoints.breakpoint-utils")

function M.custom_set_breakpoint(condition, hit_condition, log_message)
  local dap = require("dap")
  dap.set_breakpoint(condition, hit_condition, log_message)
  if config.on_set_breakpoint ~= nil then
    config.on_set_breakpoint(condition, hit_condition, log_message)
  end
end

function M.update_breakpoint_on_current_line()
  local target = breakpoint_utils.get_breakpoints_on_current_line()
  if target == nil then
    noti_utils.echo_message("No breakpoints on current line.", vim.log.levels.WARN)
    return
  else
    target = target[1]
  end

  local targetProperty
  if target.logMessage ~= nil then
    targetProperty = "logMessage"
  elseif target.condition ~= nil then
    targetProperty = "condition"
  elseif target.hitCondition ~= nil then
    targetProperty = "hitCondition"
  else
    noti_utils.echo_message("Ignoring since this is not a special breakpoint.", vim.log.levels.WARN)
    return
  end

  if targetProperty == "condition" then
    vim.ui.input({ prompt = "Breakpoint condition: ", default = target.condition }, function(input)
      M.custom_set_breakpoint(input, nil, nil)
    end)
  elseif targetProperty == "hitCondition" then
    vim.ui.input({ prompt = "Hit condition: ", default = target.hitCondition }, function(input)
      M.custom_set_breakpoint(nil, input, nil)
    end)
  else
    vim.ui.input({ prompt = "Log point message: ", default = target.logMessage }, function(input)
      M.custom_set_breakpoint(nil, nil, input)
    end)
  end
end

function M.show_breakpoint_property(target, property, silent)
  if target == nil then
    if not silent then
      noti_utils.echo_message("Invalid breakpoint was provided.", vim.log.levels.ERROR)
    end
    return
  end
  local finalProperty = property

  if property == nil then
    if target.logMessage ~= nil then
      finalProperty = "logMessage"
    elseif target.condition ~= nil then
      finalProperty = "condition"
    elseif target.hitCondition ~= nil then
      finalProperty = "hitCondition"
    else
      if not silent then
        noti_utils.echo_message("No extra information to pull from this breakpoint.", vim.log.levels.WARN)
      end
      return
    end
  end

  local message = target[finalProperty]
  if message == nil then
    noti_utils.echo_message("Breakpoint does not have a " .. finalProperty .. " attribute.", vim.log.levels.WARN)
    return
  end

  if finalProperty == "condition" then
    local title = "DAP - Conditional Breakpoint"
    noti_utils.show_popup({
      title = title,
      message = message,
      syntax = vim.bo.filetype,
    })
  elseif finalProperty == "hitCondition" then
    local title = "DAP - Hit Conditional Breakpoint"
    noti_utils.show_popup({
      title = title,
      message = message,
      syntax = vim.bo.filetype,
    })
  else
    local title = "DAP - Logpoint"
    noti_utils.show_popup({
      title = title,
      message = "Outputs: '" .. message .. "'.",
      syntax = "lua",
    })
  end
end

function M.show_breakpoint_info_on_current_line()
  local target = breakpoint_utils.get_breakpoints_on_current_line()
  if target ~= nil then
    M.show_breakpoint_property(target[1])
  else
    noti_utils.echo_message("No breakpoints on current line.", vim.log.levels.WARN)
  end
end

function M.go_to_next_breakpoint(go_to_prev)
  local breakpoints_map = breakpoint_utils.get_breakpoints_in_buffer()
  if breakpoints_map == nil then
    noti_utils.echo_message("There are no breakpoints in this file.", vim.log.levels.WARN)
    return
  end

  local target
  local original_position = vim.fn.getcurpos()
  local start_line = original_position[2]
  local start_column = original_position[3]

  -- NOTE: assumes breakpoints are in order by line number
  if go_to_prev then
    for _, value in ipairs(breakpoints_map) do
      if value.line < start_line then
        target = value
      end
    end
    if target == nil then
      target = breakpoints_map[#breakpoints_map]
    end
  else
    for _, value in ipairs(breakpoints_map) do
      if value.line > start_line then
        target = value
        break
      end
    end
    if target == nil then
      target = breakpoints_map[1]
    end
  end

  if target.line == start_line then
    noti_utils.echo_message("Already at only breakpoint.", vim.log.levels.WARN)
    return
  end

  vim.fn.cursor({ target.line, start_column })

  -- FIX: Doesn't seem to be working properly
  if breakpoint_utils.is_special_breakpoint(target) then
    vim.schedule(function()
      M.show_breakpoint_property(target)
    end)
  end
end

return M

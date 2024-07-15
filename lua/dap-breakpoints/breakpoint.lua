local M = {}

local nvim_dap_breakpoints = require("dap.breakpoints")
local config = require("dap-breakpoints.config")
local util = require("dap-breakpoints.util")

function M.get_breakpoints_in_buffer(_bufnr)
  local bufnr = _bufnr or vim.fn.bufnr()

  local breakpoints_map = nvim_dap_breakpoints.get()[bufnr]
  if breakpoints_map == nil or #breakpoints_map == 0 then
    return nil
  end

  return breakpoints_map
end

function M.get_breakpoints_on_line(_line, _bufnr)
  local bufnr = _bufnr or vim.fn.bufnr()
  local line = _line or vim.fn.line(".")

  local breakpoints_map = M.get_breakpoints_in_buffer(bufnr)
  if breakpoints_map == nil then
    return nil
  end

  local target = {}
  for _, value in ipairs(breakpoints_map) do
    if value.line == line then
      target[#target + 1] = value
      -- NOTE: Breaking since only one breakpoint can currently be placed on a line
      break
    end
  end

  if #target == 0 then
    return nil
  else
    return target
  end
end

function M.get_breakpoints_on_current_line()
  local current_line = vim.fn.line(".")
  return M.get_breakpoints_on_line(current_line)
end

function M.is_special_breakpoint(target)
  if target.logMessage ~= nil or target.condition ~= nil or target.hitCondition ~= nil then
    return true
  else
    return false
  end
end

function M.custom_set_breakpoint(condition, hit_condition, log_message)
  local dap = require("dap")
  dap.set_breakpoint(condition, hit_condition, log_message)
  if config.on_set_breakpoint ~= nil then
    config.on_set_breakpoint(condition, hit_condition, log_message)
  end
end

function M.update_breakpoint_on_current_line()
  local target = M.get_breakpoints_on_current_line()
  if target == nil then
    util.echo_message("No breakpoints on current line.", vim.log.levels.WARN)
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
    util.echo_message("Ignoring since this is not a special breakpoint.", vim.log.levels.WARN)
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
      util.echo_message("Invalid breakpoint was provided.", vim.log.levels.ERROR)
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
        util.echo_message("No extra information to pull from this breakpoint.", vim.log.levels.WARN)
      end
      return
    end
  end

  local message = target[finalProperty]
  if message == nil then
    util.echo_message("Breakpoint does not have a " .. finalProperty .. " attribute.", vim.log.levels.WARN)
    return
  end

  if finalProperty == "condition" then
    local title = "DAP - Conditional Breakpoint"
    util.show_popup({
      title = title,
      message = message,
      syntax = vim.bo.filetype,
    })
  elseif finalProperty == "hitCondition" then
    local title = "DAP - Hit Conditional Breakpoint"
    util.show_popup({
      title = title,
      message = message,
      syntax = vim.bo.filetype,
    })
  else
    local title = "DAP - Logpoint"
    util.show_popup({
      title = title,
      message = "\"" .. message .. "\"",
      syntax = vim.bo.filetype,
    })
  end
end

function M.show_breakpoint_info_on_current_line()
  local target = M.get_breakpoints_on_current_line()
  if target ~= nil then
    M.show_breakpoint_property(target[1])
  else
    util.echo_message("No breakpoints on current line.", vim.log.levels.WARN)
  end
end

function M.go_to_next_breakpoint(go_to_prev)
  local breakpoints_map = M.get_breakpoints_in_buffer()
  if breakpoints_map == nil then
    util.echo_message("There are no breakpoints in this file.", vim.log.levels.WARN)
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
    util.echo_message("Already at only breakpoint.", vim.log.levels.WARN)
    return
  end

  vim.fn.cursor({ target.line, start_column })

  -- FIX: Doesn't seem to be working properly
  if M.is_special_breakpoint(target) then
    vim.schedule(function()
      M.show_breakpoint_property(target)
    end)
  end
end

return M

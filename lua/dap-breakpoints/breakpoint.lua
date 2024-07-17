local M = {}

local nvim_dap_breakpoints = require("dap.breakpoints")
local config = require("dap-breakpoints.config")
local util = require("dap-breakpoints.util")

function M.get_buffer_breakpoints(_bufnr)
  local bufnr = _bufnr or vim.fn.bufnr()

  local buffer_breakpoints = nvim_dap_breakpoints.get()[bufnr]
  if buffer_breakpoints == nil or #buffer_breakpoints == 0 then
    return nil
  end

  return buffer_breakpoints
end

function M.get_line_breakpoint(_line, _bufnr)
  local bufnr = _bufnr or vim.fn.bufnr()
  local line = _line or vim.fn.line(".")

  local buffer_breakpoints = M.get_buffer_breakpoints(bufnr)
  if buffer_breakpoints == nil then
    return nil
  end

  for _, line_breakpoint in ipairs(buffer_breakpoints) do
    if line_breakpoint.line == line then
      return line_breakpoint
    end
  end

  return nil
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

function M.popup_reveal()
  local line_breakpoint = M.get_line_breakpoint()
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
    util.echo_message("No extra information to pull from this breakpoint.", vim.log.levels.WARN)
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

return M

local M = {}

local nvim_dap = require("dap")
local nvim_dap_breakpoints = require("dap.breakpoints")
local config = require("dap-breakpoints.config")

function M.get_all_breakpoints()
  return nvim_dap_breakpoints.get()
end

function M.get_buffer_breakpoints(_bufnr)
  local bufnr = _bufnr or vim.fn.bufnr()

  local buffer_breakpoints = M.get_all_breakpoints()[bufnr]
  if buffer_breakpoints == nil or #buffer_breakpoints == 0 then
    return nil
  end

  return buffer_breakpoints
end

function M.get_breakpoint(opt)
  local bufnr = vim.fn.bufnr()
  local line = vim.fn.line(".")

  if opt then
    bufnr = opt.bufnr or bufnr
    line = opt.line or line
  end

  local buffer_breakpoints = M.get_buffer_breakpoints(bufnr)
  if buffer_breakpoints == nil then
    return nil
  end

  for _, _breakpoint in ipairs(buffer_breakpoints) do
    if _breakpoint.line == line then
      return _breakpoint
    end
  end

  return nil
end

function M.get_total_breakpoints_count()
  local breakpoints = M.get_all_breakpoints()
  local total = 0

  for _, buffer_breakpoints in pairs(breakpoints) do
    total = total + #buffer_breakpoints
  end

  return total
end

function M.is_log_point(target)
  return target.logMessage ~= nil
end

function M.is_conditional_breakpoint(target)
  return target.condition ~= nil
end

function M.is_hit_condition_breakpoint(target)
  return target.hitCondition ~= nil
end

function M.is_normal_breakpoint(target)
  return target.logMessage == nil and target.condition == nil and target.hitCondition == nil
end

function M.custom_set_breakpoint(condition, hit_condition, log_message)
  nvim_dap.set_breakpoint(condition, hit_condition, log_message)
  if type(config.on_set_breakpoint) == "function" then
    config.on_set_breakpoint(condition, hit_condition, log_message)
  end
end

return M

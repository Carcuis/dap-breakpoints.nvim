local M = {}

local nvim_dap = require("dap")
local nvim_dap_breakpoints = require("dap.breakpoints")
local persistent_breakpoints = require("persistent-breakpoints.api")

local config = require("dap-breakpoints.config")

function M.get_all_breakpoints()
  return nvim_dap_breakpoints.get()
end

function M.get_buffer_breakpoints(_bufnr)
  local bufnr = _bufnr or vim.fn.bufnr()

  local buffer_breakpoints = M.get_all_breakpoints()[bufnr]
  if buffer_breakpoints == nil or #buffer_breakpoints == 0 then
    return {}
  end

  return buffer_breakpoints
end

function M.get_breakpoint(opt)
  local bufnr = opt and opt.bufnr or vim.fn.bufnr()
  local line = opt and opt.line or vim.fn.line(".")

  local buffer_breakpoints = M.get_buffer_breakpoints(bufnr)
  if #buffer_breakpoints == 0 then
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

function M.load_breakpoints()
  persistent_breakpoints.load_breakpoints()
end

function M.save_breakpoints()
  persistent_breakpoints.breakpoints_changed_in_current_buffer()
end

function M.auto_save()
  if config.breakpoint.auto_save then
    M.save_breakpoints()
  end
end

function M.set_breakpoint(opt)
  if opt then
    nvim_dap.set_breakpoint(opt.condition, opt.hit_condition, opt.log_message)
  else
    nvim_dap.set_breakpoint()
  end
  M.auto_save()
end

function M.toggle_breakpoint()
  nvim_dap.toggle_breakpoint()
  M.auto_save()
end

function M.clear_all_breakpoints()
  nvim_dap.clear_breakpoints()
  M.auto_save()
end

return M

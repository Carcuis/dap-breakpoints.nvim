local nvim_dap = require("dap")
local nvim_dap_breakpoints = require("dap.breakpoints")
local persistent_breakpoints = require("persistent-breakpoints.api")

local config = require("dap-breakpoints.config")

---@class DapBpBreakpoint
local M = {}

---@class DapBp.BreakpointProperty
---@field condition string?
---@field hitCondition string?
---@field logMessage string?

---@class DapBp.Breakpoint: DapBp.BreakpointProperty
---@field line integer

---@class DapBp.Location
---@field bufnr integer?
---@field line integer

---Get breakpoints in all buffers
---@return table<integer, DapBp.Breakpoint[]>
function M.get_all()
  return nvim_dap_breakpoints.get()
end

---Get breakpoints in buffer
---@param bufnr integer?
---@return DapBp.Breakpoint[]
function M.get_in_buffer(bufnr)
  bufnr = bufnr or vim.fn.bufnr()

  local buffer_breakpoints = M.get_all()[bufnr]
  if not buffer_breakpoints or #buffer_breakpoints == 0 then
    return {}
  end

  return buffer_breakpoints
end

---Get breakpoint at line
---@param opt DapBp.Location?
---@return DapBp.Breakpoint?
function M.get(opt)
  local bufnr = opt and opt.bufnr or vim.fn.bufnr()
  local line = opt and opt.line or vim.fn.line(".")

  local buffer_breakpoints = M.get_in_buffer(bufnr)
  if #buffer_breakpoints == 0 then
    return nil
  end

  for _, bp in ipairs(buffer_breakpoints) do
    if bp.line == line then
      return bp
    end
  end

  return nil
end

---@return integer
function M.get_total_count()
  local breakpoints = M.get_all()
  local total = 0

  for _, buffer_breakpoints in pairs(breakpoints) do
    total = total + #buffer_breakpoints
  end

  return total
end

---@param bp DapBp.Breakpoint
---@return boolean
function M.has_log_message(bp)
  return bp.logMessage ~= nil
end

---@param bp DapBp.Breakpoint
---@return boolean
function M.has_condition(bp)
  return bp.condition ~= nil
end

---@param bp DapBp.Breakpoint
---@return boolean
function M.has_hit_condition(bp)
  return bp.hitCondition ~= nil
end

---@param bp DapBp.Breakpoint
---@return boolean
function M.is_normal(bp)
  return bp.logMessage == nil and bp.condition == nil and bp.hitCondition == nil
end

function M.load()
  persistent_breakpoints.reload_breakpoints()
end

function M.save()
  persistent_breakpoints.breakpoints_changed_in_current_buffer()
end

function M.auto_save()
  if config.auto_save then
    M.save()
  end
end

---@param opt DapBp.BreakpointProperty?
function M.set(opt)
  if opt then
    nvim_dap.set_breakpoint(opt.condition, opt.hitCondition, opt.logMessage)
  else
    nvim_dap.set_breakpoint()
  end
  M.auto_save()
end

function M.toggle()
  nvim_dap.toggle_breakpoint()
  M.auto_save()
end

function M.clear_all()
  nvim_dap.clear_breakpoints()
  M.auto_save()
end

return M

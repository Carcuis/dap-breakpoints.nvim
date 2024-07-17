local M = {}

local nvim_dap_breakpoints = require("dap.breakpoints")
local config = require("dap-breakpoints.config")

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

return M

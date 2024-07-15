local M = {}

local breakpoints_util = require("dap.breakpoints")

function M.get_breakpoints_in_buffer(_bufnr)
  local bufnr = _bufnr or vim.fn.bufnr()

  local breakpoints_map = breakpoints_util.get()[bufnr]
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
      -- NOTE: Breaking since only one breakpoint can currently be placed on a
      -- line
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

return M

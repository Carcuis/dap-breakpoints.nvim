local nvim_dap = require("dap")

---@class DapBpSession
local M = {
  ---@type DapBp.ExceptionFilter[]
  exception_filters = nil,
  session_type = "",
}

---@class DapBp.ExceptionFilter
---@field filter string
---@field label string
---@field description string
---@field default boolean
---@field activated boolean

---@param session dap.Session DAP session
function M.init_exception_filters(session)
  if not session or not session.capabilities or not session.capabilities.exceptionBreakpointFilters then
    M.exception_filters = nil
    return
  end

  local filters = session.capabilities.exceptionBreakpointFilters
  if not filters or #filters == 0 then
    return
  end

  M.session_type = session.config.type
  ---@type string[]|string
  local default_exception_breakpoints = nvim_dap.defaults[M.session_type].exception_breakpoints

  M.exception_filters = {}
  for _, filter in ipairs(filters) do
    local activated = false
    if type(default_exception_breakpoints) == "string" then
      activated = filter.default
    else
      activated = vim.tbl_contains(default_exception_breakpoints, filter.filter)
    end
    table.insert(M.exception_filters, {
      filter = filter.filter,
      label = filter.label,
      description = filter.description,
      default = filter.default,
      activated = activated,
    })
  end
end

---@return string[]
function M.get_activated_filters()
  if not M.exception_filters then
    return {}
  end

  local activated = {}
  for _, filter in ipairs(M.exception_filters) do
    if filter.activated then
      table.insert(activated, filter.filter)
    end
  end
  return activated
end

---@return boolean
function M.has_exception_filters()
  return M.exception_filters ~= nil and #M.exception_filters > 0
end

---@param filters string[]
function M.set_exception_breakpoints(filters)
  if not M.exception_filters then
    return
  end

  for _, filter in ipairs(M.exception_filters) do
    filter.activated = vim.tbl_contains(filters, filter.filter)
  end

  ---@diagnostic disable-next-line
  nvim_dap.defaults[M.session_type].exception_breakpoints = filters
  if not nvim_dap.session() then
    return
  end
  nvim_dap.set_exception_breakpoints(filters)
end

return M

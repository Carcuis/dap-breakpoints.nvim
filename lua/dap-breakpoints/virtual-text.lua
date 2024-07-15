local M = {}

local config = require("dap-breakpoints.config")
local breakpoint_util = require("dap-breakpoints.breakpoint-utils")

local virtual_text_list = {}

local break_point_types = {
  REGULAR         = 0,
  LOG_POINT       = 1,
  CONDITIONAL     = 2,
  HIT_CONDITIONAL = 3,
}
local virtual_text_highlight_list = {
  [break_point_types.REGULAR]         = "DapBreakpointVirtualText",
  [break_point_types.LOG_POINT]       = "DapLogPointVirtualText",
  [break_point_types.CONDITIONAL]     = "DapConditionPointVirtualText",
  [break_point_types.HIT_CONDITIONAL] = "DapHitConditionPointVirtualText",
}

function M.get_breakpoint_type(target)
  if target.logMessage ~= nil then
    return break_point_types.LOG_POINT
  elseif target.condition ~= nil then
    return break_point_types.CONDITIONAL
  elseif target.hitCondition ~= nil then
    return break_point_types.HIT_CONDITIONAL
  else
    return break_point_types.REGULAR
  end
end

function M.clear_virt_text_on_line(_line, _bufnr)
  local bufnr = _bufnr or vim.fn.bufnr()
  local line = _line or vim.fn.line(".")

  local virt_text_ns = vim.api.nvim_create_namespace(config.virt_text_opts.namespace)
  local extmarks = vim.api.nvim_buf_get_extmarks(
    bufnr,
    virt_text_ns,
    { line - 1, 0 },
    { line - 1, -1 },
    { details = true }
  )

  for _, extmark in ipairs(extmarks) do
    local mark_line = extmark[2]
    vim.api.nvim_buf_clear_namespace(bufnr, virt_text_ns, mark_line, mark_line + 1)
    virtual_text_list[bufnr][line] = nil
  end
end

function M.clear_virt_text_in_buffer(_bufnr)
  local bufnr = _bufnr or vim.fn.bufnr()
  local saved_virt_text_lines = virtual_text_list[bufnr]
  if saved_virt_text_lines ~= nil then
    for line, _ in pairs(saved_virt_text_lines) do
      M.clear_virt_text_on_line(line)
    end
  end
end

function M.create_virt_text_chunks_by_breakpoints(breakpoints)
  local special_breakpoints = {}
  for _, breakpoint in ipairs(breakpoints) do
    if breakpoint_util.is_special_breakpoint(breakpoint) then
      special_breakpoints[#special_breakpoints + 1] = breakpoint
    end
  end

  if #special_breakpoints == 0 then
    return nil
  end

  local prefix = config.virt_text_opts.prefix
  local suffix = config.virt_text_opts.suffix
  local spacing = config.virt_text_opts.spacing

  -- Create a little more space between virtual text and contents
  local virt_texts = { { string.rep(" ", spacing) } }

  for i = 1, #special_breakpoints do
    local resolved_prefix = prefix
    if type(prefix) == "function" then
      resolved_prefix = prefix(special_breakpoints[i]) or ""
    end
    table.insert(
      virt_texts,
      { resolved_prefix, virtual_text_highlight_list[M.get_breakpoint_type(special_breakpoints[i])] }
    )
  end

  local last_special_breakpoint = special_breakpoints[#special_breakpoints]
  local message = ""
  local last_breakpoint_type = M.get_breakpoint_type(last_special_breakpoint)
  if last_breakpoint_type == break_point_types.CONDITIONAL then
    message = last_special_breakpoint.condition
  elseif last_breakpoint_type == break_point_types.LOG_POINT then
    message = last_special_breakpoint.logMessage
  elseif last_breakpoint_type == break_point_types.HIT_CONDITIONAL then
    message = last_special_breakpoint.hitCondition
  end

  if type(suffix) == "function" then
    suffix = suffix(last_special_breakpoint) or ""
  end

  table.insert(virt_texts, {
    string.format("%s%s", message:gsub("\r", ""):gsub("\n", "  "), suffix),
    virtual_text_highlight_list[last_breakpoint_type],
  })

  return virt_texts
end

function M.show_line_breakpoint_info_in_virt_text(_line, _bufnr)
  local bufnr = _bufnr or vim.fn.bufnr()
  local line = _line or vim.fn.line(".")

  local virt_text_ns = vim.api.nvim_create_namespace(config.virt_text_opts.namespace)
  local breakpoints = breakpoint_util.get_breakpoints_on_line(line, bufnr)
  local virt_text = M.create_virt_text_chunks_by_breakpoints(breakpoints)

  local cached_buffer_info = virtual_text_list[bufnr] or {}
  if vim.fn.bufloaded(bufnr) ~= 0 then
    local success, id = pcall(vim.api.nvim_buf_set_extmark, bufnr, virt_text_ns, line - 1, 0, {
      hl_mode = "combine",
      id = cached_buffer_info[line],
      virt_text = virt_text,
    })
    if success then
      virtual_text_list[bufnr] = vim.tbl_deep_extend("force", cached_buffer_info, { [line] = id })
    end
  end
end

function M.show_buffer_breakpoint_info_in_virt_text(_bufnr)
  local bufnr = _bufnr or vim.fn.bufnr()

  local breakpoints = breakpoint_util.get_breakpoints_in_buffer(bufnr)
  if breakpoints == nil then
    return
  end

  for _, breakpoint in ipairs(breakpoints) do
    M.show_line_breakpoint_info_in_virt_text(breakpoint.line, bufnr)
  end
end

function M.reload_buffer_virt_text(_bufnr)
  local bufnr = _bufnr or vim.fn.bufnr()

  M.clear_virt_text_in_buffer(bufnr)
  M.show_buffer_breakpoint_info_in_virt_text(bufnr)
end

return M

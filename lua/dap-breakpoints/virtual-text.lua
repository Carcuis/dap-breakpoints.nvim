local M = {}

local config = require("dap-breakpoints.config")
local breakpoint = require("dap-breakpoints.breakpoint")

local namespace = "dap-breakpoints"
local ns_id = vim.api.nvim_create_namespace(namespace)
local virtual_text_ids_list = {}

function M.get_virtual_text_hl_group(_breakpoint)
  if breakpoint.is_log_point(_breakpoint) then
    return "DapLogPointVirtualText"
  elseif breakpoint.is_conditional_breakpoint(_breakpoint) then
    return "DapConditionalPointVirtualText"
  elseif breakpoint.is_hit_condition_breakpoint(_breakpoint) then
    return "DapHitConditionPointVirtualText"
  else
    return "DapBreakpointVirtualText"
  end
end

function M.clear_virtual_text_on_line(_line)
  local bufnr = vim.fn.bufnr()
  local line = _line or vim.fn.line(".")

  local extmarks = vim.api.nvim_buf_get_extmarks(
    bufnr,
    ns_id,
    { line - 1, 0 },
    { line - 1, -1 },
    { details = true }
  )

  for _, extmark in ipairs(extmarks) do
    local mark_line = extmark[2]
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, mark_line, mark_line + 1)
    virtual_text_ids_list[bufnr][line] = nil
  end
end

function M.generate_virtual_text_by_breakpoint(target)
  local special_breakpoints = {}
  if not breakpoint.is_normal_breakpoint(target) then
    special_breakpoints[#special_breakpoints + 1] = target
  end

  if #special_breakpoints == 0 then
    return nil
  end

  local prefix = config.virtual_text.prefix
  local suffix = config.virtual_text.suffix
  local spacing = config.virtual_text.spacing

  -- Create a little more space between virtual text and contents
  local virtual_texts = { { string.rep(" ", spacing) } }

  for i = 1, #special_breakpoints do
    local resolved_prefix = prefix
    if type(prefix) == "function" then
      resolved_prefix = prefix(special_breakpoints[i]) or ""
    end
    table.insert(
      virtual_texts,
      { resolved_prefix, M.get_virtual_text_hl_group(special_breakpoints[i]) }
    )
  end

  local last_special_breakpoint = special_breakpoints[#special_breakpoints]
  local message = ""
  if breakpoint.is_log_point(last_special_breakpoint) then
    message = last_special_breakpoint.logMessage
  elseif breakpoint.is_conditional_breakpoint(last_special_breakpoint) then
    message = last_special_breakpoint.condition
  elseif breakpoint.is_hit_condition_breakpoint(last_special_breakpoint) then
    message = last_special_breakpoint.hitCondition
  end

  if type(suffix) == "function" then
    suffix = suffix(last_special_breakpoint) or ""
  end

  table.insert(virtual_texts, {
    string.format("%s%s", message:gsub("\r", ""):gsub("\n", "  "), suffix),
    M.get_virtual_text_hl_group(last_special_breakpoint),
  })

  return virtual_texts
end

function M.enable_virtual_text_on_line(_line)
  local line = _line or vim.fn.line(".")
  local bufnr = vim.fn.bufnr()

  local line_breakpoint = breakpoint.get_line_breakpoint(line)
  local virtual_text = M.generate_virtual_text_by_breakpoint(line_breakpoint)

  local virtual_text_id_in_buffer = virtual_text_ids_list[bufnr] or {}
  if vim.fn.bufloaded(bufnr) ~= 0 then
    local success, id = pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, line - 1, 0, {
      hl_mode = "combine",
      id = virtual_text_id_in_buffer[line],
      virt_text = virtual_text,
    })
    if success then
      virtual_text_ids_list[bufnr] = vim.tbl_deep_extend("force", virtual_text_id_in_buffer, { [line] = id })
    end
  end
end

function M.disable_virtual_text()
  local bufnr = vim.fn.bufnr()
  local virtual_text_ids_in_buffer = virtual_text_ids_list[bufnr]
  if virtual_text_ids_in_buffer ~= nil then
    for line, _ in pairs(virtual_text_ids_in_buffer) do
      M.clear_virtual_text_on_line(line)
    end
  end
end

return M

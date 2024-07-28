local M = {
  enabled = false
}

local breakpoint = require("dap-breakpoints.breakpoint")
local config = require("dap-breakpoints.config")

local namespace = "dap-breakpoints"
local ns_id = vim.api.nvim_create_namespace(namespace)

function M.get_ns_id()
  return ns_id
end

function M.get_virtual_text_hl_group(target)
  if breakpoint.is_log_point(target) then
    return "DapLogPointVirt"
  elseif breakpoint.is_conditional_breakpoint(target) then
    return "DapConditionalPointVirt"
  elseif breakpoint.is_hit_condition_breakpoint(target) then
    return "DapHitConditionPointVirt"
  else
    return "DapBreakpointVirt"
  end
end

function M.clear_virtual_text_on_line(opt)
  local bufnr = opt and opt.bufnr or vim.fn.bufnr()
  local line = opt and opt.line or vim.fn.line(".")

  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, line - 1, line)
end

function M.clear_virtual_text_in_buffer(_bufnr)
  local bufnr = _bufnr or vim.fn.bufnr()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

function M.clear_all_virtual_text()
  for bufnr, _ in pairs(breakpoint.get_all_breakpoints()) do
    M.clear_virtual_text_in_buffer(bufnr)
  end
end

function M.generate_virtual_text_by_breakpoint(target)
  local normal = breakpoint.is_normal_breakpoint(target)
  local log_point = breakpoint.is_log_point(target)
  local conditional = breakpoint.is_conditional_breakpoint(target)
  local hit_condition = breakpoint.is_hit_condition_breakpoint(target)

  local prefix_map = {
    [normal] = config.virtual_text.prefix.normal,
    [log_point] = config.virtual_text.prefix.log_point,
    [conditional] = config.virtual_text.prefix.conditional,
    [hit_condition] = config.virtual_text.prefix.hit_condition
  }

  local message_map = {
    [normal] = "",
    [log_point] = target.logMessage,
    [conditional] = target.condition,
    [hit_condition] = target.hitCondition
  }

  local spacing = config.virtual_text.spacing
  local prefix = ""
  local message = ""

  if type(config.virtual_text.custom_text_handler) == "function" then
    message = config.virtual_text.custom_text_handler(target) or message
  else
    prefix = prefix_map[true] or prefix
    message = message_map[true] or message
  end

  if prefix == "" and message == "" then
    return {}
  end

  local virt_text = {
    { string.rep(" ", spacing) },
    { prefix, M.get_virtual_text_hl_group(target) .. "Prefix" },
    { string.format("%s", message:gsub("\r", ""):gsub("\n", "  ")), M.get_virtual_text_hl_group(target) }
  }

  return virt_text
end

function M.enable_virtual_text_on_line(opt)
  local bufnr = opt and opt.bufnr or vim.fn.bufnr()
  local line = opt and opt.line or vim.fn.line(".")

  if vim.fn.bufloaded(bufnr) == 0 then
    return
  end

  M.clear_virtual_text_on_line({ bufnr = bufnr, line = line })

  local virt_text = M.generate_virtual_text_by_breakpoint(breakpoint.get_breakpoint({ bufnr = bufnr, line = line }))
  vim.api.nvim_buf_set_extmark(
    bufnr,
    ns_id,
    line - 1,
    0,
    {
      hl_mode = "combine",
      virt_text = virt_text,
      undo_restore = false,
      invalidate = true,
    }
  )
end

function M.enable_virtual_text_in_buffer(bufnr)
  for _, _breakpoint in ipairs( breakpoint.get_buffer_breakpoints(bufnr)) do
    M.enable_virtual_text_on_line({
      bufnr = bufnr,
      line = _breakpoint.line
    })
  end
end

return M

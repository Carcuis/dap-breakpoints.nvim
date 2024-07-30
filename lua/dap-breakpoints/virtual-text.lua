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

---@alias LayoutType "eol"|"right_align"|"overlay"

---@return { layout_type: LayoutType, layout_col: integer }
function M.get_user_layout()
  local user_layout = config.virtual_text.layout.position
  local layout_type = "eol"
  local layout_col = 0

  if user_layout == "right_align" then
    layout_type = "right_align"
  elseif type(user_layout) == "number" and user_layout == math.floor(user_layout) then
    if user_layout > 0 then
      layout_type = "overlay"
      layout_col = user_layout
    end
  end
  return { layout_type = layout_type, layout_col = layout_col }
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

  local layout_type = M.get_user_layout().layout_type
  local spaces = 0

  if layout_type == "eol" then
    spaces = math.max(config.virtual_text.layout.spaces - 1, 0)
  else
    spaces = 0
  end

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

  if layout_type == "right_align" then
    message = message .. " "
  end

  local hl_group = M.get_virtual_text_hl_group(target)

  local virt_text = {
    { string.rep(" ", spaces) },
    { prefix, hl_group .. "Prefix" },
    { string.format(message), hl_group }
  }

  return virt_text
end

function M.enable_virtual_text_on_line(opt)
  local bufnr = opt and opt.bufnr or vim.fn.bufnr()
  local line = opt and opt.line or vim.fn.line(".")

  if vim.fn.bufloaded(bufnr) == 0 then
    return
  end

  local target = breakpoint.get_breakpoint({ bufnr = bufnr, line = line })
  if target == nil then
    return
  end

  M.clear_virtual_text_on_line({ bufnr = bufnr, line = line })

  local virt_text = M.generate_virtual_text_by_breakpoint(target)

  local user_layout = M.get_user_layout()
  ---@type LayoutType
  local virt_text_pos = user_layout.layout_type
  ---@type integer|nil
  local virt_text_win_col = nil

  local line_len = vim.fn.virtcol({ line, '$' }) - 1
  local leftcol = vim.fn.winsaveview().leftcol

  if virt_text_pos == "right_align" then
    local virt_text_str = {}
    for _, data in ipairs(virt_text) do
      virt_text_str[#virt_text_str + 1] = data[1]
    end
    local virt_text_length = vim.api.nvim_strwidth(table.concat(virt_text_str))

    local winid = vim.api.nvim_get_current_win()
    local wininfo = vim.fn.getwininfo(winid)[1]
    local textoff = wininfo and wininfo.textoff or 0
    local win_width = vim.api.nvim_win_get_width(0) - textoff

    if virt_text_length > (win_width - line_len + leftcol) then
      virt_text_pos = "eol"
    end
  elseif virt_text_pos == "overlay" then
    if user_layout.layout_col <= line_len then
      virt_text_pos = "eol"
    else
      virt_text_win_col = math.max(user_layout.layout_col - leftcol - 1, 0)
    end
  end

  vim.api.nvim_buf_set_extmark(
    bufnr,
    ns_id,
    line - 1,
    0,
    {
      hl_mode = "combine",
      virt_text = virt_text,
      virt_text_hide = true,
      virt_text_pos = virt_text_pos,
      virt_text_win_col = virt_text_win_col,
      priority = config.virtual_text.priority,
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

--- Set decoration provider for virtual text if user layout type is "overlay" or "right_align".
---
--- This can fix the issue of virtual text covering code when the code length exceeds
--- the user-defined column position, especially for inlay hints updates.
function M.set_decoration_provider()
  if M.get_user_layout().layout_type == "eol" then
    return
  end

  vim.api.nvim_set_decoration_provider(ns_id, {
    on_start = function(_, tick)
      if tick % 10 ~= 0 then
        return
      end
      M.enable_virtual_text_in_buffer()
    end
  })
end

function M.unset_decoration_provider()
  if M.get_user_layout().layout_type == "eol" then
    return
  end

  vim.api.nvim_set_decoration_provider(ns_id, {})
end

return M

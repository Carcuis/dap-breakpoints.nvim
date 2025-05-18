local breakpoint = require("dap-breakpoints.breakpoint")
local config = require("dap-breakpoints.config")

---@class DapBpVirtText
local M = {
  enabled = false,
  ns_id = vim.api.nvim_create_namespace("dap-breakpoints"),
}

---@alias DapBpVirtText.LayoutType "eol"|"right_align"|"overlay"
---@alias DapBpVirtText.HlGroup
---| '"DapBreakpointVirt"'
---| '"DapLogPointVirt"'
---| '"DapConditionalPointVirt"'
---| '"DapHitConditionPointVirt"'

---@class DapBp.VirtualText
---@field [1] string text
---@field [2] DapBpVirtText.HlGroup? highlight group

---@param opt DapBp.Location?
function M.clear_on_line(opt)
  local bufnr = opt and opt.bufnr or vim.fn.bufnr()
  local line = opt and opt.line or vim.fn.line(".")

  vim.api.nvim_buf_clear_namespace(bufnr, M.ns_id, line - 1, line)
end

---@param bufnr integer?
function M.clear_in_buffer(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  vim.api.nvim_buf_clear_namespace(bufnr, M.ns_id, 0, -1)
end

function M.clear_all()
  for bufnr, _ in pairs(breakpoint.get_all()) do
    M.clear_in_buffer(bufnr)
  end
end

---@return { layout_type: DapBpVirtText.LayoutType, layout_col: integer }
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

---Generate virtual text. A list of `[text, highlight]` tuples, each representing a text chunk
---@param bp DapBp.Breakpoint
---@return DapBp.VirtualText[]
function M.generate_by_breakpoint(bp)
  local layout_type = M.get_user_layout().layout_type
  local spaces = 0

  if layout_type == "eol" then
    spaces = math.max(config.virtual_text.layout.spaces - 1, 0)
  else
    spaces = 0
  end

  local virt_text_map = {}

  if breakpoint.has_log_message(bp) then
    virt_text_map.l = {
      prefix = config.virtual_text.prefix.log_point,
      text = bp.logMessage,
      hl = "DapLogPointVirt",
    }
  end

  if breakpoint.has_condition(bp) then
    virt_text_map.c = {
      prefix = config.virtual_text.prefix.conditional,
      text = bp.condition,
      hl = "DapConditionalPointVirt",
    }
  end

  if breakpoint.has_hit_condition(bp) then
    virt_text_map.h = {
      prefix = config.virtual_text.prefix.hit_condition,
      text = bp.hitCondition,
      hl = "DapHitConditionPointVirt",
    }
  end

  local parts = {}
  local order = config.virtual_text.order or "chl"

  for i = 1, #order do
    local part = virt_text_map[order:sub(i, i):lower()]
    if part then
      table.insert(parts, part)
    end
  end

  if breakpoint.is_normal(bp) and config.virtual_text.prefix.normal ~= "" then
    table.insert(parts, {
      prefix = config.virtual_text.prefix.normal,
      text = "",
      hl = "DapBreakpointVirt",
    })
  end

  if type(config.virtual_text.custom_text_handler) == "function" then
    local custom_message = config.virtual_text.custom_text_handler(bp)
    if custom_message then
      parts = { {
        prefix = "",
        text = custom_message,
        hl = "DapBreakpointVirt",
      } }
    end
  end

  if #parts == 0 then
    return {}
  end

  ---@type DapBp.VirtualText[]
  local virt_text = {
    { string.rep(" ", spaces) }
  }

  local preset = config.virtual_text.preset or "default"

  if preset == "default" or preset == "messages_only" then
    for i, part in ipairs(parts) do
      if preset == "default" then
        table.insert(virt_text, { part.prefix, part.hl .. "Prefix" })
      end
      table.insert(virt_text, { part.text, part.hl })

      if i < #parts then
        table.insert(virt_text, { " " })
      end
    end
  elseif preset == "separate" or preset == "icons_only" then
    for _, part in ipairs(parts) do
      table.insert(virt_text, { part.prefix, part.hl .. "Prefix" })
    end

    if preset == "separate" then
      for _, part in ipairs(parts) do
        if part.text and part.text ~= "" then
          table.insert(virt_text, { " " .. part.text, part.hl })
        end
      end
    end
  end

  if layout_type == "right_align" and #virt_text > 0 then
    virt_text[#virt_text][1] = virt_text[#virt_text][1] .. " "
  end

  return virt_text
end

---@param opt DapBp.Location?
function M.enable_on_line(opt)
  local bufnr = opt and opt.bufnr or vim.fn.bufnr()
  local line = opt and opt.line or vim.fn.line(".")

  if vim.fn.bufloaded(bufnr) == 0 then
    return
  end

  local bp = breakpoint.get({ bufnr = bufnr, line = line })
  if not bp then
    return
  end

  M.clear_on_line({ bufnr = bufnr, line = line })

  local virt_text = M.generate_by_breakpoint(bp)

  local user_layout = M.get_user_layout()
  local virt_text_pos = user_layout.layout_type ---@type DapBpVirtText.LayoutType
  local virt_text_win_col = nil ---@type integer?

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
    M.ns_id,
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

---@param bufnr integer?
function M.enable_in_buffer(bufnr)
  bufnr = bufnr or vim.fn.bufnr()

  for _, bp in ipairs(breakpoint.get_in_buffer(bufnr)) do
    M.enable_on_line({
      bufnr = bufnr,
      line = bp.line
    })
  end
end

function M.enable_in_all_buffers()
  for bufnr, buffer_breakpoints in pairs(breakpoint.get_all()) do
    for _, bp in ipairs(buffer_breakpoints) do
      M.enable_on_line({
        bufnr = bufnr,
        line = bp.line
      })
    end
  end
end

---Set decoration provider for virtual text if user layout type is "overlay" or "right_align".
---This can fix the issue of virtual text covering code when the code length
---exceeds the user-defined column position, especially for inlay hints updates.
function M.set_decoration_provider()
  vim.api.nvim_set_decoration_provider(M.ns_id, {
    on_start = function(_, tick)
      if tick % 10 ~= 0 then
        return
      end
      M.enable_in_buffer()
    end
  })
end

function M.unset_decoration_provider()
  vim.api.nvim_set_decoration_provider(M.ns_id, {})
end

function M.set_current_line_only_autocmd()
  local group = vim.api.nvim_create_augroup("dap-breakpoints-virt-text", { clear = true })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group,
    callback = function()
      M.clear_all()
      M.enable_on_line()
    end
  })
end

function M.unset_current_line_only_autocmd()
  vim.api.nvim_del_augroup_by_name("dap-breakpoints-virt-text")
end

return M

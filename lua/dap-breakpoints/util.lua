local M = {}

local message_highlight_map = {
  [vim.log.levels.INFO] = "MsgArea",
  [vim.log.levels.WARN] = "WarningMsg",
  [vim.log.levels.ERROR] = "ErrorMsg",
}

function M.echo_message(message, level)
  vim.api.nvim_echo({{ message, message_highlight_map[level] or "MsgArea" }}, false, {})
end

function M.show_popup(opts)
  local width = 9
  if string.len(opts.message) > width then
    width = string.len(opts.message)
  end
  if string.len(opts.title) > width then
    width = string.len(opts.title)
  end
  local default_opts = {
    border = "single",
    title_pos = "left",
    width = width + 1,
  }
  local final_opts = vim.tbl_deep_extend("force", default_opts, opts)
  local bufnr, _ = vim.lsp.util.open_floating_preview({ opts.message }, opts.syntax, final_opts)
  vim.bo[bufnr].filetype = opts.syntax
end

function M.set_input_ui_filetype(filetype)
  vim.schedule(function()
    for _, win_id in ipairs(vim.api.nvim_list_wins()) do
      local bufnr = vim.api.nvim_win_get_buf(win_id)
      if vim.bo[bufnr].filetype == "DressingInput" then
        vim.bo[bufnr].filetype = filetype
        break
      end
    end
  end)
end

return M

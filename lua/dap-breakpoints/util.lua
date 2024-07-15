local M = {}

function M.echo_message(message, log_level)
  local log_hl = {
    [vim.log.levels.ERROR] = "ErrorMsg",
    [vim.log.levels.WARN] = "WarningMsg",
  }
  local default_log_hl = "None"
  local final_log_hl = log_level == nil and default_log_hl or log_hl[log_level]

  vim.cmd("echohl " .. final_log_hl .. " | echo '" .. message .. "' | echohl " .. default_log_hl)
  vim.defer_fn(function()
    vim.cmd('echon ""')
  end, 2000)
end

function M.show_popup(opts)
  local width = 9
  if string.len(opts.message) > width then
    width = string.len(opts.message)
  end
  if string.len(opts.title) > width then
    width = string.len(opts.title)
  end
  local DEFAULT_OPTS = {
    border = "single",
    title_pos = "left",
    width = width + 1,
  }
  local final_opts = vim.tbl_deep_extend("force", DEFAULT_OPTS, opts)
  vim.lsp.util.open_floating_preview({ opts.message }, opts.syntax, final_opts)
end

return M

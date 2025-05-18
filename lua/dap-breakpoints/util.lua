---@class DapBpUtil
local M = {}

---@class DapBpUtil.PopupContent
---@field message string
---@field title string
---@field syntax string

---@param message string
---@param level integer
function M.echo_message(message, level)
  local message_highlight_map = {
    [vim.log.levels.INFO] = "MsgArea",
    [vim.log.levels.WARN] = "WarningMsg",
    [vim.log.levels.ERROR] = "ErrorMsg",
  }
  local highlight = message_highlight_map[level] or "MsgArea"
  vim.api.nvim_echo({ { message, highlight } }, false, {})
end

---@param message string
---@param level integer?
function M.notify(message, level)
  level = level or vim.log.levels.INFO
  vim.notify(message, level, { title = "dap-breakpoints" })
end

---@param content DapBpUtil.PopupContent
function M.show_popup(content)
  local width = 9
  for line in content.message:gmatch("([^\n]*)\n?") do
    if #line > width then
      width = #line
    end
  end
  if string.len(content.title) > width then
    width = string.len(content.title)
  end
  local opts = {
    border = "single",
    title = content.title,
    title_pos = "left",
    width = width + 1,
  }
  local bufnr, _ = vim.lsp.util.open_floating_preview({ content.message }, content.syntax, opts)
  vim.bo[bufnr].filetype = content.syntax
end

---@param filetype string
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

---@param prompt string
---@param cb function
function M.confirm(prompt, cb)
  vim.ui.input({ prompt = prompt }, function(input)
    if input and input:lower():match("^ye?s?$") then
      cb()
    end
  end)
end

return M

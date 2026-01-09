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

---@param plugin string
---@return boolean
function M.has_plugin(plugin)
  return pcall(require, plugin)
end

---@param filters DapBp.ExceptionFilter[]
---@param cb fun(selected: string[])
function M.show_exception_picker(filters, cb)
  if M.has_plugin("snacks") then
    M._snacks_multi_select(filters, cb)
    return
  end

  if M.has_plugin("telescope") then
    M._telescope_multi_select(filters, cb)
    return
  end

  M._input_multi_select(filters, cb)
end

---@param filters DapBp.ExceptionFilter[]
---@param cb fun(selected: string[])
function M._telescope_multi_select(filters, cb)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  local results = {}
  local filter_map = {}
  for _, filter in ipairs(filters) do
    local display = (filter.activated and "●" or "○") .. " " .. filter.label
    table.insert(results, display)
    filter_map[display] = filter
  end

  local title = "Exception Filters <tab>: Select <cr>: Confirm"

  pickers.new({}, {
    prompt_title = title,
    results_title = "",
    finder = finders.new_table {
      results = results,
    },
    previewer = previewers.new_buffer_previewer({
      define_preview = function(self, entry)
        local item = filter_map[entry[1]]
        local lines = {
          (item.activated and " ● Activated\t[" or " ○ Deactivated\t[") .. item.filter .. "]",
          item.description and "" or nil,
          item.description and " " .. item.description or nil,
        }
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      end,
    }),
    layout_strategy = "vertical",
    layout_config = {
      width = 70,
      height = 13,
      preview_height = 3,
      preview_cutoff = 0,
      mirror = true,
    },
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()
        actions.close(prompt_bufnr)

        local selected_filters = {}
        for _, entry in ipairs(selections) do
          local item = filter_map[entry[1]]
          table.insert(selected_filters, item.filter)
        end

        cb(selected_filters)
      end)
      return true
    end,
  }):find()
end

---@param filters DapBp.ExceptionFilter[]
---@param cb fun(selected: string[])
function M._snacks_multi_select(filters, cb)
  local Snacks = require("snacks")
  local picker_items = {}
  for _, filter in ipairs(filters) do
    table.insert(picker_items, {
      text = (filter.activated and "●" or "○") .. " " .. filter.label,
      label = filter.label,
      filter = filter.filter,
      activated = filter.activated,
      description = filter.description,
    })
  end

  local title = "Exception Filters <tab>: Select <cr>: Confirm"

  Snacks.picker.pick({
    title = title,
    items = picker_items,
    format = "text",
    preview = function(ctx)
      local item = ctx.item
      local lines = {
        (item.activated and " ● Activated\t[" or " ○ Deactivated\t[") .. item.filter .. "]",
        item.description and "\n " .. item.description or nil,
      }
      ctx.preview:set_lines(lines)
    end,
    layout = {
      layout = {
        box = "vertical",
        width = 0.3,
        min_width = 80,
        height = 0.2,
        min_height = 12,
        {
          box = "vertical",
          border = true,
          title = "{title}",
          { win = "input", height = 1, border = "bottom" },
          { win = "list", border = "none" },
        },
        {
          win = "preview",
          border = true,
          height = 3,
          wo = {
            number = false,
            relativenumber = false,
            signcolumn = "no",
          },
        },
      },
    },
    confirm = function(picker)
      local selected = picker:selected()
      picker:close()

      local selected_filters = {}
      for _, item in ipairs(selected) do
        table.insert(selected_filters, item.filter)
      end

      cb(selected_filters)
    end,
  })
end

---@param filters DapBp.ExceptionFilter[]
---@param cb fun(selected: string[])
function M._input_multi_select(filters, cb)
  local options = {}

  local status_icons = {}
  for _, filter in ipairs(filters) do
    table.insert(options, filter.filter)
    table.insert(status_icons, filter.activated and "●" or "○")
  end

  local prompt = "Enter exception filters (comma-separated): Current: " .. table.concat(status_icons, " ")
  local default = table.concat(options, ", ")

  vim.ui.input({
    prompt = prompt,
    default = default,
  }, function(input)
    if not input then
      return
    end

    local selected_filters = {}
    for filter in input:gmatch("[^,%s]+") do
      local valid = false
      for _, _filter in ipairs(filters) do
        if _filter.filter == filter then
          valid = true
          break
        end
      end
      if valid then
        table.insert(selected_filters, filter)
      end
    end

    cb(selected_filters)
  end)
end

return M

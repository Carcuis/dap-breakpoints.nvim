local M = {}

local api = require("dap-breakpoints.api")
local config = require("dap-breakpoints.config")

local function setup_commands()
  local commands = {
    { name = "DapBpNext", api = api.go_to_next },
    { name = "DapBpPrev", api = api.go_to_previous },
    { name = "DapBpReveal", api = api.popup_reveal },
    { name = "DapBpLoad", api = api.load_breakpoints },
    { name = "DapBpSave", api = api.save_breakpoints },
    { name = "DapBpEdit", api = api.edit_property },
    { name = "DapBpToggle", api = api.toggle_breakpoint },
    { name = "DapBpSetConditionalPoint", api = api.set_conditional_breakpoint },
    { name = "DapBpSetHitConditionPoint", api = api.set_hit_condition_breakpoint },
    { name = "DapBpSetLogPoint", api = api.set_log_point },
    { name = "DapBpClearAll", api = api.clear_all_breakpoints },
    { name = "DapBpVirtEnable", api = api.enable_virtual_text },
    { name = "DapBpVirtDisable", api = api.disable_virtual_text },
    { name = "DapBpVirtToggle", api = api.toggle_virtual_text },
  }

  for _, command in ipairs(commands) do
    vim.api.nvim_create_user_command(command.name, command.api, {})
  end
end

local function setup_highlight_groups()
  local highlights = {
    { group = 'DapBreakpointVirt', default = 'NonText' },
    { group = 'DapLogPointVirt', default = 'DapBreakpointVirt' },
    { group = 'DapConditionalPointVirt', default = 'DapBreakpointVirt' },
    { group = 'DapHitConditionPointVirt', default = 'DapBreakpointVirt' },
    { group = 'DapBreakpointVirtPrefix', default = 'DapBreakpointVirt' },
    { group = 'DapLogPointVirtPrefix', default = 'DapBreakpointVirtPrefix' },
    { group = 'DapConditionalPointVirtPrefix', default = 'DapBreakpointVirtPrefix' },
    { group = 'DapHitConditionPointVirtPrefix', default = 'DapBreakpointVirtPrefix' },
  }

  for _, highlight in ipairs(highlights) do
    vim.api.nvim_set_hl(0, highlight.group, { link = highlight.default, default = true })
  end
end

local function setup_autocmds()
  local group = vim.api.nvim_create_augroup("dap-breakpoints", { clear = true })

  if config.breakpoint.auto_load then
    vim.api.nvim_create_autocmd({ "BufReadPost" }, { group = group, callback = api.load_breakpoints })
  end

  if config.breakpoint.auto_save then
    vim.api.nvim_create_autocmd({ "BufWritePost", "QuitPre" }, { group = group, callback = api.save_breakpoints })
  end
end

local function setup_virtual_text()
  if config.virtual_text.enabled then
    api.enable_virtual_text()
  end
end

function M.setup(opt)
  for key, val in pairs(vim.tbl_deep_extend("force", config, opt or {})) do
    config[key] = val
  end

  setup_commands()
  setup_highlight_groups()
  setup_autocmds()
  setup_virtual_text()
end

return M

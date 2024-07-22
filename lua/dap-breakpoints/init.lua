local M = {}

local api = require("dap-breakpoints.api")
local config = require("dap-breakpoints.config")

local setup_commands = function()
  vim.api.nvim_create_user_command("DapBpNext", function()
    api.go_to_next()
  end, {})

  vim.api.nvim_create_user_command("DapBpPrev", function()
    api.go_to_previous()
  end, {})

  vim.api.nvim_create_user_command("DapBpReveal", function()
    api.popup_reveal()
  end, {})

  vim.api.nvim_create_user_command("DapBpLoad", function()
    api.load_breakpoints()
  end, {})

  vim.api.nvim_create_user_command("DapBpSave", function()
    api.save_breakpoints()
  end, {})

  vim.api.nvim_create_user_command("DapBpEdit", function()
    api.edit_property()
  end, {})

  vim.api.nvim_create_user_command("DapBpToggle", function()
    api.toggle_breakpoint()
  end, {})

  vim.api.nvim_create_user_command("DapBpSetConditionalPoint", function()
    api.set_conditional_breakpoint()
  end, {})

  vim.api.nvim_create_user_command("DapBpSetHitConditionPoint", function()
    api.set_hit_condition_breakpoint()
  end, {})

  vim.api.nvim_create_user_command("DapBpSetLogPoint", function()
    api.set_log_point()
  end, {})

  vim.api.nvim_create_user_command("DapBpClearAll", function()
    api.clear_all_breakpoints()
  end, {})

  vim.api.nvim_create_user_command("DapBpVirtEnable", function()
    api.enable_virtual_text()
  end, {})

  vim.api.nvim_create_user_command("DapBpVirtDisable", function()
    api.disable_virtual_text()
  end, {})

  vim.api.nvim_create_user_command("DapBpVirtToggle", function()
    api.toggle_virtual_text()
  end, {})
end

local setup_highlight_groups = function()
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

M.setup = function(opt)
  for key, val in pairs(vim.tbl_extend("force", config, opt or {})) do
    config[key] = val
  end

  setup_commands()
  setup_highlight_groups()

  if config.breakpoint.auto_load then
    -- TODO: add autogroup
    vim.api.nvim_create_autocmd({ "BufReadPost" }, { callback = function()
      api.load_breakpoints()
    end})
  end
end

return M

local M = {}

local api = require("dap-breakpoints.api")
local virtual_text = require("dap-breakpoints.virtual-text")
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
  vim.api.nvim_create_user_command("DapBpUpdate", function()
    api.update_property()
  end, {})

  vim.api.nvim_create_user_command("DapBpClearVirtText", function()
    virtual_text.clear_virtual_text_in_buffer()
  end, {})

  vim.api.nvim_create_user_command("DapBpShowVirtText", function()
    virtual_text.show_virtual_text_in_buffer()
  end, {})

  vim.api.nvim_create_user_command("DapBpReloadVirtText", function()
    virtual_text.reload_virtual_text_in_buffer()
  end, {})
end

M.setup = function(user_config)
  local final_cfg = vim.tbl_extend("force", config, user_config or {})
  for key, val in pairs(final_cfg) do
    config[key] = val
  end

  setup_commands()
end

return M

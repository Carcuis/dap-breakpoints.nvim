local M = {}

local breakpoint = require("dap-breakpoints.breakpoint")
local virtual_text = require("dap-breakpoints.virtual-text")
local config = require("dap-breakpoints.config")

local setup_commands = function()
  vim.api.nvim_create_user_command("DapBpNext", function()
    breakpoint.go_to_next_breakpoint()
  end, {})
  vim.api.nvim_create_user_command("DapBpPrev", function()
    breakpoint.go_to_next_breakpoint(true)
  end, {})
  vim.api.nvim_create_user_command("DapBpReveal", function()
    breakpoint.show_breakpoint_info_on_current_line()
  end, {})
  vim.api.nvim_create_user_command("DapBpUpdate", function()
    breakpoint.update_breakpoint_on_current_line()
  end, {})

  vim.api.nvim_create_user_command("DapBpClearVirtText", function()
    virtual_text.clear_virt_text_in_buffer()
  end, {})

  vim.api.nvim_create_user_command("DapBpShowVirtText", function()
    virtual_text.show_buffer_breakpoint_info_in_virt_text()
  end, {})

  vim.api.nvim_create_user_command("DapBpReloadVirtText", function()
    virtual_text.reload_buffer_virt_text()
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

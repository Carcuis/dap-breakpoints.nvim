local M = {}

local breakpoint_info_utils = require("dap-breakpoints.breakpoint-info-utils")
local virt_text_util = require("dap-breakpoints.virtual-text")
local config = require("dap-breakpoints.config")

local setup_commands = function()
  vim.api.nvim_create_user_command("DapInfoNextBp", function()
    breakpoint_info_utils.go_to_next_breakpoint()
  end, {})
  vim.api.nvim_create_user_command("DapInfoPrevBp", function()
    breakpoint_info_utils.go_to_next_breakpoint(true)
  end, {})
  vim.api.nvim_create_user_command("DapInfoRevealBp", function()
    breakpoint_info_utils.show_breakpoint_info_on_current_line()
  end, {})
  vim.api.nvim_create_user_command("DapInfoUpdateBp", function()
    breakpoint_info_utils.update_breakpoint_on_current_line()
  end, {})

  vim.api.nvim_create_user_command("DapInfoClearVirtText", function()
    virt_text_util.clear_virt_text_in_buffer()
  end, {})

  vim.api.nvim_create_user_command("DapInfoShowVirtText", function()
    virt_text_util.show_buffer_breakpoint_info_in_virt_text()
  end, {})

  vim.api.nvim_create_user_command("DapInfoReloadVirtText", function()
    virt_text_util.reload_buffer_virt_text()
  end, {})
end

M.setup = function(_config)
  local final_cfg = vim.tbl_extend("force", config, _config or {})
  for key, val in pairs(final_cfg) do
    config[key] = val
  end

  setup_commands()
end

return M

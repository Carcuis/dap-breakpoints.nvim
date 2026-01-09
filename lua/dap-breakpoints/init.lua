local api = require("dap-breakpoints.api")
local config = require("dap-breakpoints.config")
local session = require("dap-breakpoints.session")

local nvim_dap = require("dap")

---@class DapBp
local M = {}

---@class DapBpCommand
---@field [1] string command
---@field [2] function api

function M.setup_commands()
  ---@type DapBpCommand[]
  local commands = {
    { "DapBpNext", api.go_to_next },
    { "DapBpPrev", api.go_to_previous },
    { "DapBpReveal", api.popup_reveal },
    { "DapBpLoad", function() api.load_breakpoints({ notify = "always" }) end },
    { "DapBpSave", function() api.save_breakpoints({ notify = "always" }) end },
    { "DapBpEdit", api.edit_property },
    { "DapBpEditAll", function() api.edit_property({ all = true }) end },
    { "DapBpToggle", api.toggle_breakpoint },
    { "DapBpSet", api.set_breakpoint },
    { "DapBpSetConditionalPoint", api.set_conditional_breakpoint },
    { "DapBpSetHitConditionPoint", api.set_hit_condition_breakpoint },
    { "DapBpSetLogPoint", api.set_log_point },
    { "DapBpClearAll", api.clear_all_breakpoints },
    { "DapBpVirtEnable", api.enable_virtual_text },
    { "DapBpVirtDisable", api.disable_virtual_text },
    { "DapBpVirtToggle", api.toggle_virtual_text },
    { "DapBpEditException", api.edit_exception_filters },
  }

  for _, command in ipairs(commands) do
    vim.api.nvim_create_user_command(command[1], command[2], {})
  end
end

function M.setup_highlight_groups()
  local highlights = {
    { 'DapBreakpointVirt', 'NonText' },
    { 'DapLogPointVirt', 'DapBreakpointVirt' },
    { 'DapConditionalPointVirt', 'DapBreakpointVirt' },
    { 'DapHitConditionPointVirt', 'DapBreakpointVirt' },
    { 'DapBreakpointVirtPrefix', 'DapBreakpointVirt' },
    { 'DapLogPointVirtPrefix', 'DapBreakpointVirtPrefix' },
    { 'DapConditionalPointVirtPrefix', 'DapBreakpointVirtPrefix' },
    { 'DapHitConditionPointVirtPrefix', 'DapBreakpointVirtPrefix' },
  }

  for _, highlight in ipairs(highlights) do
    vim.api.nvim_set_hl(0, highlight[1], { link = highlight[2], default = true })
  end
end

function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup("dap-breakpoints", { clear = true })

  if config.auto_load then
    vim.api.nvim_create_autocmd({ "BufReadPost" }, { group = group, callback = api.load_breakpoints })
  end

  if config.auto_save then
    vim.api.nvim_create_autocmd({ "BufWritePost", "QuitPre" }, { group = group, callback = api.save_breakpoints })
  end
end

function M.setup_virtual_text()
  if config.virtual_text.enabled then
    api.enable_virtual_text()
  end
end

function M.setup_dap_listeners()
  nvim_dap.listeners.after.configurationDone.dapbp_exception = function(dap_session, _)
    session.init_exception_filters(dap_session)
  end

  nvim_dap.listeners.after.launch.dapbp_exception = function(_, _)
    local filters = session.get_activated_filters()
    if #filters > 0 then
      nvim_dap.set_exception_breakpoints(filters)
    end
  end
end

---@param opt DapBpConfig?
function M.setup(opt)
  for key, val in pairs(vim.tbl_deep_extend("force", config, opt or {})) do
    config[key] = val
  end

  M.setup_commands()
  M.setup_highlight_groups()
  M.setup_autocmds()
  M.setup_virtual_text()
  M.setup_dap_listeners()
end

return M

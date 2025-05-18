---@class DapBpConfig
local M = {
  auto_load = true,         -- auto load breakpoints on 'BufReadPost'
  auto_save = true,         -- auto save breakpoints when make changes to breakpoints
  auto_reveal_popup = true, -- auto show pop up property when navigate to next/prev breakpoint
  virtual_text = {
    enabled = true,
    priority = 10,
    current_line_only = false,
    preset = "default", ---@type "default" | "separate" | "icons_only" | "messages_only"
    order = "chl", ---@type string order of conditional, hit_condition, log_point, omit a char to hide that type
    layout = {
      position = 121, ---@type "eol" | "right_align" | integer
      spaces = 4, -- spaces between code and virtual text, only for position = "eol"
    },
    prefix = {
      normal = "",
      log_point = "󰰍 ",
      conditional = "󰯲 ",
      hit_condition = "󰰁 ",
    },
    custom_text_handler = nil, ---@type nil | fun(bp: DapBp.Breakpoint): string
  },
}

return M

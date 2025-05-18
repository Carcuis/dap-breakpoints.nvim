# dap-breakpoints.nvim

`dap-breakpoints.nvim` is a Lua plugin for Neovim that helps manage breakpoints,
create advanced breakpoints using vim.ui.input, and display breakpoint
properties as virtual text with [nvim-dap](https://github.com/mfussenegger/nvim-dap).

<!-- panvimdoc-ignore-start -->

![image](https://github.com/user-attachments/assets/be734cc3-10f3-4efb-89ed-5c7147640914)

- [Requirements](#requirements)
- [Setup](#setup)
- [Configuation](#configuation)
- [Commands](#commands)
- [Keymaps](#keymaps)
- [Highlight Groups](#highlight-groups)
- [Reference](#reference)

<!-- panvimdoc-ignore-end -->

## Requirements

- Neovim >= 0.10
- [nvim-dap](https://github.com/mfussenegger/nvim-dap)
- [persistent-breakpoints.nvim](https://github.com/Weissle/persistent-breakpoints.nvim)
- [dressing.nvim](https://github.com/stevearc/dressing.nvim) (optional)
- [nvim-notify](https://github.com/rcarriga/nvim-notify) (optional)

## Setup

```lua
require("persistent-breakpoints").setup()
require("dap-breakpoints").setup()
```

## Configuation

```lua
-- default config
require('dap-breakpoints').setup{
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
```

## Commands

`:DapBpToggle`

Toggle breakpoint at current line.

`:DapBpNext`

Go to the next breakpoint in buffer.

`:DapBpPrev`

Go to the previous breakpoint in buffer.

`:DapBpReveal`

Reveal popup info about current breakpoint's properties.

`:DapBpLoad`

Load saved breakpoints in current opened buffers by using persistent-breakpoints.nvim.
Set `auto_load` to `true` to load breakpoints automatically on `BufReadPost`.

`:DapBpSave`

Save all breakpoints in buffers using persistent-breakpoints.nvim.
Set `auto_save` to `true` to save breakpoints automatically on changes.

`:DapBpEdit`

Edit log point message or breakpoint condition for current breakpoint.

`:DapBpEditAll`

Edit or add all available properties of the current breakpoint.

`:DapBpSet`

Set all kinds of breakpoint at current line using vim.ui.select.

`:DapBpSetLogPoint`

Set log point at current line using vim.ui.input.

`:DapBpSetConditionalPoint`

Set conditional breakpoint at current line using vim.ui.input.

`:DapBpSetHitConditionPoint`

Set hit condition breakpoint at current line using vim.ui.input.

`:DapBpClearAll`

Clear all breakpoints in buffers.

`:DapBpVirtEnable`

Show virtual text information about breakpoints.

`:DapBpVirtDisable`

Clear virtual text information about breakpoints.

`:DapBpVirtToggle`

Toggle virtual text information about breakpoints.

## Keymaps

```lua
-- add below to your neovim configuration
local dapbp_api = require("dap-breakpoints.api")
local dapbp_keymaps = {
  { "<leader>b", dapbp_api.toggle_breakpoint, desc = "Toggle Breakpoint" },
  { "<leader>dts", dapbp_api.set_breakpoint, desc = "Set Breakpoint" },
  { "<leader>dtc", dapbp_api.set_conditional_breakpoint, desc = "Set Conditional Breakpoint" },
  { "<leader>dth", dapbp_api.set_hit_condition_breakpoint, desc = "Set Hit Condition Breakpoint" },
  { "<leader>dtl", dapbp_api.set_log_point, desc = "Set Log Point" },
  { "<leader>dtL", function() dapbp_api.load_breakpoints({ notify = true }) end, desc = "Load Breakpoints" },
  { "<leader>dtS", function() dapbp_api.save_breakpoints({ notify = true }) end, desc = "Save Breakpoints" },
  { "<leader>dte", dapbp_api.edit_property, desc = "Edit Breakpoint Property" },
  { "<leader>dtE", function() dapbp_api.edit_property({ all = true }) end, desc = "Edit All Breakpoint Properties" },
  { "<leader>dtv", dapbp_api.toggle_virtual_text, desc = "Toggle Breakpoint Virtual Text" },
  { "<leader>dtC", dapbp_api.clear_all_breakpoints, desc = "Clear All Breakpoints" },
  { "[b", dapbp_api.go_to_previous, desc = "Go to Previous Breakpoint" },
  { "]b", dapbp_api.go_to_next, desc = "Go to Next Breakpoint" },
  { "<M-b>", dapbp_api.popup_reveal, desc = "Reveal Breakpoint" },
}
for _, keymap in ipairs(dapbp_keymaps) do
  vim.keymap.set("n", keymap[1], keymap[2], { desc = keymap.desc })
end
```

## Highlight Groups

- `DapBreakpointVirt`
- `DapBreakpointVirtPrefix`
- `DapLogPointVirt`
- `DapLogPointVirtPrefix`
- `DapConditionalPointVirt`
- `DapConditionalPointVirtPrefix`
- `DapHitConditionPointVirt`
- `DapHitConditionPointVirtPrefix`

## Reference

- [dap-info](https://github.com/jonathan-elize/dap-info.nvim)

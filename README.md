# dap-breakpoints.nvim

`dap-breakpoints.nvim` is a lua plugin for Neovim to help manage breakpoints,
create advanced breakpoints using `vim.ui.input`, and display breakpoint
properties virtual text with [nvim-dap](https://github.com/mfussenegger/nvim-dap).

- [Requirements](#requirements)
- [Setup](#setup)
- [Configuation](#configuation)
- [Commands](#commands)
- [Keymaps](#keymaps)
- [Highlight Groups](#highlight-groups)
- [Reference](#reference)

## Requirements

- Neovim >= 0.10
- [nvim-dap](https://github.com/mfussenegger/nvim-dap)
- [persistent-breakpoints.nvim](https://github.com/Weissle/persistent-breakpoints.nvim)
- [dressing.nvim](https://github.com/stevearc/dressing.nvim) (optional)

## Setup

```lua
require("persistent-breakpoints").setup()
require("dap-breakpoints").setup()
```

## Configuation

```lua
-- default config
require('dap-breakpoints').setup{
  breakpoint = {
    auto_load = true,         -- auto load breakpoints on 'BufReadPost'
    auto_save = true,         -- auto save breakpoints when make changes to breakpoints
    auto_reveal_popup = true, -- auto show pop up property when navigate to next/prev breakpoint
  },
  virtual_text = {
    enable = true,
    priority = 10,
    current_line_only = false,
    aligned = false,
    spacing = 4,
    prefix = {
      normal = "",
      log_point = "󰰍 ",
      conditional = "󰯲 ",
      hit_condition = "󰰁 ",
    },
    custom_text_handler = nil, -- function(target)
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

Load breakpoints using persistent-breakpoints.nvim.

`:DapBpSave`

Save breakpoints using persistent-breakpoints.nvim.

`:DapBpEdit`

Edit log point message or breakpoint condition for current breakpoint.

`:DapBpSetLogPoint`

Set log point at current line using vim.ui.input.

`:DapBpSetConditionalPoint`

Set conditional breakpoint at current line using vim.ui.input.

`:DapBpSetHitConditionPoint`

Set hit condition breakpoint at current line using vim.ui.input.

`:DapBpVirtEnable`

Show virtual text information about breakpoints.

`:DapBpVirtDisable`

Clear virtual text information about breakpoints.

`:DapBpVirtToggle`

Toggle virtual text information about breakpoints.

`:DapBpClearAll`

Clear all breakpoints.

## Keymaps

```lua
-- add below to your neovim configuration
local dapbp_api = require("dap-breakpoints.api")
local dapbp_keymaps = {
    { key = "<leader>b", api = dapbp_api.toggle_breakpoint, desc = "Toggle Breakpoint" },
    { key = "<leader>dtc", api = dapbp_api.set_conditional_breakpoint, desc = "Set Conditional Breakpoint" },
    { key = "<leader>dth", api = dapbp_api.set_hit_condition_breakpoint, desc = "Set Hit Condition Breakpoint" },
    { key = "<leader>dtl", api = dapbp_api.set_log_point, desc = "Set Log Point" },
    { key = "<leader>dtL", api = dapbp_api.load_breakpoints, desc = "Load Breakpoints" },
    { key = "<leader>dts", api = dapbp_api.save_breakpoints, desc = "Save Breakpoints" },
    { key = "<leader>dte", api = dapbp_api.edit_property, desc = "Edit Breakpoint Property" },
    { key = "<leader>dtv", api = dapbp_api.toggle_virtual_text, desc = "Toggle Breakpoint Virtual Text" },
    { key = "<leader>dtC", api = dapbp_api.clear_all_breakpoints, desc = "Clear All Breakpoints" },
    { key = "[b", api = dapbp_api.go_to_previous, desc = "Go to Previous Breakpoint" },
    { key = "]b", api = dapbp_api.go_to_next, desc = "Go to Next Breakpoint" },
    { key = "<M-b>", api = dapbp_api.popup_reveal, desc = "Reveal Breakpoint" },
}
for _, keymap in ipairs(dapbp_keymaps) do
    vim.keymap.set("n", keymap.key, keymap.api, { desc = keymap.desc })
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

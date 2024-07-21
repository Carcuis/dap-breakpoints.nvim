# dap-breakpoints.nvim

`dap-breakpoints.nvim` is a lua plugin for Neovim to help manage breakpoints and display virtual texts with [nvim-dap](https://github.com/mfussenegger/nvim-dap)

## Requirements

- Neovim 0.10+
- [nvim-dap](https://github.com/mfussenegger/nvim-dap)
- [persistent-breakpoints.nvim](https://github.com/Weissle/persistent-breakpoints.nvim)

## Configuation

```lua
require('dap-breakpoints').setup{
  reveal = {
    auto_popup = true,        -- auto show pop up property when navigate to next/prev breakpoint
    conditional = true,       -- enable for conditional breakpoints
    hit_condition = true,     -- enable for hit conditional breakpoints
    log_point = true,         -- enable for log points
  },
  virtual_text = {
    enable = true,
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
  on_set_breakpoint = nil,
}
```

## Usage

### :DapBpNext

Go to the next breakpoint in file.

### :DapBpPrev

Go to the previous breakpoint in file.

### :DapBpReveal

Reveal popup info about current breakpoint.

### :DapBpEdit

Edit log point message or breakpoint condition for current breakpoint.

### :DapBpVirtEnable

Show virtual text information about breakpoints.

### :DapBpVirtDisable

Clear virtual text information about breakpoints.

### :DapBpVirtToggle

Toggle virtual text information about breakpoints.

## Highlight Groups

- `DapBreakpointVirt`
- `DapBreakpointVirtPrefix`
- `DapLogPointVirt`
- `DapLogPointVirtPrefix`
- `DapConditionalPointVirt`
- `DapConditionalPointVirtPrefix`
- `DapHitConditionPointVirt`
- `DapHitConditionPointVirtPrefix`

## References

- [dap-info](https://github.com/jonathan-elize/dap-info.nvim)

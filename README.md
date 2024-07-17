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
    hit_conditional = true,   -- enable for hit conditional breakpoints
    log_point = true,         -- enable for log points
  },
  virtual_text = {
    enable = true,
    current_line_only = false,
    aligned = false,
    prefix = "󰻂 ",
    suffix = "",
    spacing = 4,
  },
  on_set_breakpoint = nil,
}
```

## Usage

### :DapBpNext

Goes to the next breakpoint in file and tries to reveal info about it if possible

### :DapBpPrev

Goes to the previous breakpoint in file and tries to reveal info about it if possible

### :DapBpReveal

Tries to reveal info about the breakpoint on the current line if possible

### :DapBpUpdate

Tries to allow you to update a log point message or breakpoint condition for a breakpoint on the line you are currently on.

### :DapBpClearVirtText

Clears virtual text revealing information about breakpoints within current buffer.

### :DapBpShowVirtText

Shows virtual text revealing information about breakpoints within current buffer.

### :DapBpReloadVirtText

Reloads virtual text revealing information about breakpoints within current buffer. (Essentially the same as running `DapBpClearVirtText` and `DapBpShowVirtText` one after another)

## Highlight Groups

- `DapBreakpointVirtualText`
- `DapLogPointVirtualText`
- `DapConditionalPointVirtualText`
- `DapHitConditionalPointVirtualText`

## References

- [dap-info](https://github.com/jonathan-elize/dap-info.nvim)


# dap-breakpoints.nvim

`dap-breakpoints.nvim` is a lua plugin for Neovim to help manage and display breakpoints info using [nvim-dap](https://github.com/mfussenegger/nvim-dap)

## Dependencies

- [nvim-dap](https://github.com/mfussenegger/nvim-dap)
- [persistent-breakpoints.nvim](https://github.com/Weissle/persistent-breakpoints.nvim)

## Configuation

```lua
require('dap-breakpoints').setup{
  virt_text = {
    prefix = "󰻂 ",
    suffix = "",
    spacing = 4,
  },
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
- `DapConditionPointVirtualText`
- `DapHitConditionPointVirtualText`

## References

- [dap-info](https://github.com/jonathan-elize/dap-info.nvim)


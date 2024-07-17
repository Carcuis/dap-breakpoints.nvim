local config = {}

config = {
  reveal = {
    auto_popup = true,        -- auto show pop up property when navigate to next/prev breakpoint
    normal = false,           -- for normal breakpoints
    conditional = true,       -- for conditional breakpoints
    hit_conditional = true,   -- for hit conditional breakpoints
    log_point = true,         -- for log points
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

return config

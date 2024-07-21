local config = {}

config = {
  reveal = {
    auto_popup = true,        -- auto show pop up property when navigate to next/prev breakpoint
    conditional = true,       -- enable for conditional breakpoints
    hit_condition = true,     -- enable for hit conditional breakpoints
    log_point = true,         -- enable for log points
  },
  virtual_text = {
    enabled = true,
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

return config

local config = {}

config = {
  breakpoint = {
    auto_load = true,         -- auto load breakpoints on 'BufReadPost'
    auto_save = true,         -- auto save breakpoints when make changes to breakpoints
    auto_reveal_popup = true, -- auto show pop up property when navigate to next/prev breakpoint
  },
  virtual_text = {
    enabled = true,
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

return config

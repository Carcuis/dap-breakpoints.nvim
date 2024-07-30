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
    layout = {
      position = 121,         ---@type "eol"|"right_align"|integer
                              -- can be "eol", "right_align", or a fixed number (>= 1) for starting column
      spaces = 4,             -- spaces between code and virtual text, only for position = "eol"
                              -- their is at least one space between code and virtual text in neovim
    },
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

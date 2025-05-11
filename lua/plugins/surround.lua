
return {
  "echasnovski/mini.surround",
  config = function()
    require("mini.surround").setup({
      mappings = {
        add = "gsa",          -- Add surrounding in Normal and Visual modes (now with 'g')
        delete = "gsd",       -- Delete surrounding (now with 'g')
        find = "gsf",         -- Find surrounding (to the right) (now with 'g')
        find_left = "gsF",    -- Find surrounding (to the left) (now with 'g')
        highlight = "gsh",    -- Highlight surrounding (now with 'g')
        replace = "gsr",      -- Replace surrounding (now with 'g')
        update_n_lines = "gsn",  -- Update `n_lines` (now with 'g')
      },
    })
  end,
}

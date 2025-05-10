return {
  "echasnovski/mini.move",
  opts = {
    mappings = {
      -- Directional movement for selected text or lines
      left  = "<M-h>",
      right = "<M-l>",
      down  = "<M-j>",
      up    = "<M-k>",

      -- Move selection line in visual mode
      line_left  = "<M-h>",
      line_right = "<M-l>",
      line_down  = "<M-j>",
      line_up    = "<M-k>",
    },
 options = {
    -- Automatically reindent selection during linewise vertical move
    reindent_linewise = true,
  },
  },
}

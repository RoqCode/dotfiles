return {
  -- Catppuccin (nur installieren, nicht aktivieren)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      transparent_background = false,
      integrations = {
        bufferline = true,
      },
    },
  },

  -- Rose Pine
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
  },

  -- LazyVim Default-Config
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine-main",
    },
  },
}

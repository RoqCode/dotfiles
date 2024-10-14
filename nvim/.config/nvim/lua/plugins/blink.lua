return {
  {
    "hrsh7th/nvim-cmp",
    enabled = false,
  },
  {
    "hrsh7th/cmp-buffer",
    enabled = false,
  },
  {
    "hrsh7th/cmp-path",
    enabled = false,
  },
  {
    "hrsh7th/cmp-nvim-lsp",
    enabled = false,
  },

  --

  {
    "saghen/blink.cmp",

    lazy = false, -- lazy loading handled internally
    dependencies = "rafamadriz/friendly-snippets",

    version = "v0.*",
    opts = {
      highlight = {
        use_nvim_cmp_as_default = true,
      },
      windows = {
        autocomplete = {
          border = "single",
          draw = "reversed",
        },
        documentation = {
          border = "single",
        },
        signature_help = {
          border = "single",
        },
      },
      nerd_font_variant = "normal",

      accept = { auto_brackets = { enabled = true } },
    },
  },
}

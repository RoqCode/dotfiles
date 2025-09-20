return {
  {
    "stevearc/aerial.nvim",
    opts = function(_, opts)
      opts = opts or {}

      local with_var = {
        "Class",
        "Constructor",
        "Enum",
        "Field",
        "Function",
        "Interface",
        "Method",
        "Module",
        "Namespace",
        "Property",
        "Struct",
        "Trait",
        "Variable",
      }

      opts.filter_kind = opts.filter_kind or {}
      opts.filter_kind.typescript = with_var
      opts.filter_kind.typescriptreact = with_var
      opts.filter_kind.javascript = with_var
      opts.filter_kind.vue = with_var

      opts.backends = { "lsp", "treesitter", "markdown", "man" }

      opts.layout = vim.tbl_deep_extend("force", opts.layout or {}, {
        default_direction = "right", -- Sidebar rechts
        width = 40, -- feste Breite in Spalten
        min_width = 30, -- minimale Breite
        max_width = 80, -- maximale Breite (optional)
        resize_to_content = false, -- nicht automatisch schrumpfen
      })

      opts.autojump = true -- Cursor springt beim Navigieren in Aerial
      opts.highlight_on_hover = true -- markiert kurz die Zielzeile im Code

      return opts
    end,
  },
}

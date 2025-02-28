return {
  "m4xshen/hardtime.nvim",
  dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
  event = "VeryLazy",
  opts = {
    restriction_mode = "block", -- Von "block" auf "hint" ändern, damit nur Hinweise gegeben werden
    hint = true, -- Aktiviert die Hinweise
    notification = true, -- Zeigt die Tipps als Benachrichtigung an
    disabled_keys = {
      ["<Left>"] = {},
      ["<Right>"] = {},
      ["<Up>"] = {},
      ["<Down>"] = {},
    },
    max_count = 5, -- De facto unlimitiert, verhindert das Blockieren
  },
}

return {
  "m4xshen/hardtime.nvim",
  dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
  event = "VeryLazy",
  opts = {
    restriction_mode = "hint", -- Von "block" auf "hint" ändern, damit nur Hinweise gegeben werden
    hint = true, -- Aktiviert die Hinweise
    notification = true, -- Zeigt die Tipps als Benachrichtigung an
    disabled_keys = {
      ["<Left>"] = {},
      ["<Right>"] = {},
    },
    max_count = 999, -- De facto unlimitiert, verhindert das Blockieren
  },
}

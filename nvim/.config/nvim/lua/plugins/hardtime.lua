return {
  "m4xshen/hardtime.nvim",
  dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
  event = "VeryLazy",
  opts = { restriction_mode = "block", disabled_keys = {
    ["<Left>"] = {},
    ["<Right>"] = {},
  } },
}

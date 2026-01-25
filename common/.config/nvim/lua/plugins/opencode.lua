return {
  "NickvanDyke/opencode.nvim",
  dependencies = {
    {
      "folke/snacks.nvim",
      opts = { input = {}, picker = {}, terminal = {} },
    },
  },
  config = function()
    vim.g.opencode_opts = {
      provider = {
        enabled = false,
      },
    }

    vim.o.autoread = true

    local opencode = require("opencode")
    vim.keymap.set({ "n", "x" }, "<leader>aa", function()
      opencode.ask("@this: ", { submit = true })
    end, { desc = "Ask opencode" })
    vim.keymap.set({ "n", "x" }, "<leader>as", function()
      opencode.select()
    end, { desc = "Select opencode action" })
  end,
}

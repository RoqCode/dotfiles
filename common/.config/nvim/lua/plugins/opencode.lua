return {
  "NickvanDyke/opencode.nvim",
  dependencies = {
    {
      "folke/snacks.nvim",
      opts = { input = {}, picker = {}, terminal = {} },
    },
  },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {}

    vim.o.autoread = true

    -- Auto-save buffer before any prompt so opencode reads the latest from disk
    local prompt_api = require("opencode.api.prompt")
    local original_prompt = prompt_api.prompt
    prompt_api.prompt = function(prompt, opts)
      vim.cmd("silent! write")
      return original_prompt(prompt, opts)
    end

    local opencode = require("opencode")
    vim.keymap.set({ "n", "x" }, "<leader>aa", function()
      opencode.ask("@this: ", { submit = true })
    end, { desc = "Ask opencode" })
    vim.keymap.set({ "n", "x" }, "<leader>as", function()
      opencode.select()
    end, { desc = "Select opencode action" })
  end,
}

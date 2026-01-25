return {
  "zbirenbaum/copilot.lua",
  keys = {
    {
      "<leader>at",
      function()
        local cmd = require("copilot.command")
        if vim.g._copilot_disabled then
          cmd.enable()
          vim.g._copilot_disabled = false
          vim.notify("Copilot enabled")
        else
          cmd.disable()
          vim.g._copilot_disabled = true
          vim.notify("Copilot disabled")
        end
      end,
      desc = "Toggle Copilot",
    },
  },
}

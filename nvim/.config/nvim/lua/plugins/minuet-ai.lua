-- ~/.config/nvim/lua/plugins/ai.lua
return {
  -- 1) Das Minuet-Plugin (AI-Provider)
  {
    "milanglacier/minuet-ai.nvim",
    event = "InsertEnter", -- sorgt dafür, dass Minuet geladen wird, sobald du tippst
    priority = 1000, -- hoch, damit es auf jeden Fall vor blink.cmp geladen wird
    config = function()
      require("minuet").setup({
        provider = "openai",
        provider_options = {
          openai = {
            model = "gpt-4.1-mini",
            stream = true,
            api_key = function()
              return os.getenv("OPENAI_API_KEY")
            end,
          },
        },
      })
    end,
  },

  -- 2) blink.cmp, hier nur erweitern, nicht komplett ersetzen
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    dependencies = { "milanglacier/minuet-ai.nvim" },
    opts = function(_, opts)
      -- a) Provider-Tabelle erweitern (merge!)
      opts.sources = opts.sources or {}
      opts.sources.providers = vim.tbl_extend("force", opts.sources.providers or {}, {
        minuet = {
          name = "minuet",
          module = "minuet.blink",
          async = true,
          timeout_ms = 3000,
          score_offset = 50,
        },
      })

      -- b) In default-Quelle einfügen, falls noch nicht da
      opts.sources.default = opts.sources.default or { "lsp", "path", "buffer", "snippets" }
      if not vim.tbl_contains(opts.sources.default, "minuet") then
        table.insert(opts.sources.default, "minuet")
      end

      -- c) Keymap ergänzen
      opts.keymap = opts.keymap or {}
      opts.keymap["<A-y>"] = require("minuet").make_blink_map()

      -- d) Trigger-Option setzen (prefetch ausschalten)
      opts.completion = opts.completion or {}
      opts.completion.trigger = vim.tbl_extend("force", opts.completion.trigger or {}, { prefetch_on_insert = false })
    end,
  },
}

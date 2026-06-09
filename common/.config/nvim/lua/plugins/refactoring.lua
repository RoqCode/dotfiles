return {
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "lewis6991/async.nvim",
    },
    opts = function(_, opts)
      opts.debug = opts.debug or {}
      opts.debug.print_var = opts.debug.print_var or {}
      opts.debug.print_var.code_generation = opts.debug.print_var.code_generation or {}
      opts.debug.print_var.code_generation.print_var = opts.debug.print_var.code_generation.print_var or {}

      local function debug_print_var(opts)
        return ('console.log("[NUXT_DEBUG] %s", %s);'):format(
          opts.identifier_str:gsub('"', '\\"'),
          opts.identifier
        )
      end

      for _, ft in ipairs({
        "javascript",
        "javascriptreact",
        "js",
        "typescript",
        "typescriptreact",
        "ts",
        "vue",
      }) do
        opts.debug.print_var.code_generation.print_var[ft] = debug_print_var
      end
    end,
  },
}

return {
  {
    "ThePrimeagen/refactoring.nvim",
    opts = function(_, opts)
      opts.print_var_statements = opts.print_var_statements or {}
      opts.printf_statements = opts.printf_statements or {}

      local debug_print_var = { 'console.log("[NUXT_DEBUG] %s", %s);' }
      local debug_printf = { 'console.log("[NUXT_DEBUG] %s");' }

      for _, ft in ipairs({
        "javascript",
        "javascriptreact",
        "js",
        "typescript",
        "typescriptreact",
        "ts",
        "vue",
      }) do
        opts.print_var_statements[ft] = debug_print_var
        opts.printf_statements[ft] = debug_printf
      end
    end,
  },
}

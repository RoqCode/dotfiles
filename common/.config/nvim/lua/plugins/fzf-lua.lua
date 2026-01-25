return {
  {
    "ibhagwan/fzf-lua",
    keys = {
      -- Überschreibt LazyVims Default für <leader>ss
      {
        "<leader>ss",
        function()
          require("fzf-lua").lsp_document_symbols({
            regex_filter = nil,
            symbols = {
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
            },
          })
        end,
        desc = "Goto Symbol",
      },
    },
  },
}

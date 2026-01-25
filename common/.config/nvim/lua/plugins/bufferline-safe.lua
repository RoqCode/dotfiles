-- lua/plugins/bufferline-safe.lua
return {
  "akinsho/bufferline.nvim",
  opts = function(_, opts)
    local theme = vim.g.colors_name or ""
    if not theme:find("catppuccin") then
      return opts
    end

    local ok, integration = pcall(require, "catppuccin.groups.integrations.bufferline")
    if not ok or type(integration) ~= "table" then
      return opts
    end

    -- catppuccin API-Drift abfangen:
    local f = integration.get or integration.get_highlights or integration.get_bufferline or integration.highlights -- falls als Feld vorkompiliert

    if type(f) == "function" then
      opts.highlights = f()
    elseif type(f) == "table" then
      opts.highlights = f
    end

    return opts
  end,
}

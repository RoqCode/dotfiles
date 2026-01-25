-- lua/plugins/catppuccin-bufferline-compat.lua
return {
  "catppuccin/nvim",
  priority = 1000, -- sehr früh laden
  init = function()
    local k = "catppuccin.groups.integrations.bufferline"
    local orig_require = require
    package.preload[k] = package.preload[k]
      or function()
        local ok, real = pcall(orig_require, k)
        local M = {}
        if ok and type(real) == "table" then
          local has_get = type(real.get) == "function"
          local has_get_theme = type(real.get_theme) == "function"

          if has_get or has_get_theme then
            local fn = real.get or real.get_theme
            M.get = fn
            M.get_theme = fn
            return setmetatable(M, { __index = real })
          end

          if type(real.highlights) == "table" then
            M.get = function()
              return real.highlights
            end
            M.get_theme = M.get
            return setmetatable(M, { __index = real })
          end
        end

        -- Fallback: leere Highlights, damit Bufferline nicht crasht
        M.get = function()
          return {}
        end
        M.get_theme = M.get
        return M
      end
  end,
}

-- lua/plugins/catppuccin-bufferline-shim.lua
return {
  "catppuccin/nvim",
  priority = 1, -- sehr früh laden
  init = function()
    local k = "catppuccin.groups.integrations.bufferline"
    -- Nur überschreiben, falls das Modul später noch nicht verfügbar ist:
    local orig_require = require
    package.preload[k] = package.preload[k]
      or function()
        -- Versuche zuerst das echte Modul zu laden (falls Catppuccin es bereits stellt)
        local ok, real = pcall(orig_require, k)
        local M = {}

        if ok and type(real) == "table" then
          -- Kandidaten in abnehmender Wahrscheinlichkeit prüfen:
          local candidates = {
            "get", -- alte API (LazyVim-Doku nutzt noch das)
            "get_highlights", -- möglicher neuer Name
            "get_bufferline", -- möglicher neuer Name
          }

          local f
          for _, name in ipairs(candidates) do
            if type(real[name]) == "function" then
              f = real[name]
              break
            end
          end

          if not f and type(real.highlights) == "table" then
            -- falls die Integration jetzt eine fertige Tabelle exportiert
            M.get = function()
              return real.highlights
            end
            return setmetatable(M, { __index = real })
          end

          if f then
            M.get = f
            return setmetatable(M, { __index = real })
          end

          -- Keine passende API gefunden → weicher Fallback
          M.get = function()
            return {}
          end
          return setmetatable(M, { __index = real })
        end

        -- Reales Modul existiert (noch) nicht → No-op Fallback
        M.get = function()
          return {}
        end
        return M
      end
  end,
}

return {
  "NickvanDyke/opencode.nvim",
  dependencies = {
    {
      "folke/snacks.nvim",
      opts = { input = {}, picker = {}, terminal = {} },
    },
  },
  config = function()
    local function opencode_port()
      local project_dir = vim.fn.getcwd()
      local root_result = vim.system({ "git", "-C", project_dir, "rev-parse", "--show-toplevel" }, { text = true }):wait()
      if root_result.code == 0 then
        project_dir = vim.trim(root_result.stdout)
      end

      local result = vim.system({ "cksum" }, { stdin = project_dir, text = true }):wait()
      local hash = result.stdout and result.stdout:match("^(%d+)")
      if hash then
        return 20000 + (tonumber(hash) % 10000)
      end
    end

    local function opencode_url(callback)
      local port = opencode_port()
      callback(port and ("http://localhost:" .. port) or nil)
    end

    local function opencode_command()
      local port = opencode_port()
      return port and ("opencode --port " .. port) or "opencode --port"
    end

    ---@type opencode.Opts
    vim.g.opencode_opts = {
      server = {
        url = opencode_url,
        start = function()
          require("opencode.terminal").open(opencode_command(), {
            split = "right",
            width = math.floor(vim.o.columns * 0.35),
          })
        end,
        toggle = function()
          require("opencode.terminal").toggle(opencode_command(), {
            split = "right",
            width = math.floor(vim.o.columns * 0.35),
          })
        end,
      },
    }

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

-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local function branch_scope(branch)
  if not branch or branch == "" then
    return ""
  end

  local ticket = branch:match("^[^/]+/([A-Za-z][A-Za-z0-9]+%-%d+)")
  if ticket then
    return string.upper(ticket)
  end

  local upper = string.upper(branch)
  if upper:match("^NOTICKET%-") or upper:match("^NOTICKET$") or upper:match("/NOTICKET%-") or upper:match("/NOTICKET$") then
    return "NOTICKET"
  end
  if upper:match("^HOTFIX%-") or upper:match("^HOTFIX$") or upper:match("/HOTFIX%-") or upper:match("/HOTFIX$") then
    return "HOTFIX"
  end
  if upper:match("^BUGFIX%-") or upper:match("^BUGFIX$") or upper:match("/BUGFIX%-") or upper:match("/BUGFIX$") then
    return "BUGFIX"
  end

  return branch
end

local day_ping_group = vim.api.nvim_create_augroup("DayCliPing", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
  group = day_ping_group,
  callback = function()
    if vim.fn.executable("day") ~= 1 then
      return
    end

    local file = vim.fn.expand("%:.")
    if file == "" then
      return
    end

    local buf = vim.api.nvim_get_current_buf()
    local buftype = vim.bo[buf].buftype
    if buftype ~= "" then
      return
    end

    local buf_name = vim.api.nvim_buf_get_name(buf)
    local file_dir = vim.fn.fnamemodify(buf_name, ":p:h")
    if file_dir == "" then
      local uv = vim.uv or vim.loop
      file_dir = uv.cwd()
    end

    local in_worktree = vim.fn.system({ "git", "-C", file_dir, "rev-parse", "--is-inside-work-tree" })
    if vim.v.shell_error ~= 0 or (in_worktree or ""):gsub("\n", "") ~= "true" then
      return
    end

    local branch = vim.fn.system({ "git", "-C", file_dir, "symbolic-ref", "--quiet", "--short", "HEAD" })
    branch = (branch or ""):gsub("\n", "")
    local scope = branch_scope(branch)

    local cmd = { "day", "ping", "--silent", "--source", "nvim", "entered nvim: " .. file }
    if scope ~= "" then
      table.insert(cmd, "--scope")
      table.insert(cmd, scope)
    end

    vim.fn.jobstart(cmd, { detach = true })
  end,
})

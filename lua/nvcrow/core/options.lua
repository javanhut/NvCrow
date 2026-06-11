-- Sensible defaults. Override anything via the `options` table in crow.lua.

local M = {}

function M.setup()
  -- Leader must be set before lazy.nvim loads.
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "

  local o = vim.opt

  o.number = true
  o.relativenumber = false
  o.cursorline = true
  o.fillchars = { eob = " " } -- no ~ markers past end of buffer
  o.signcolumn = "yes"
  o.termguicolors = true
  o.scrolloff = 8
  o.splitright = true
  o.splitbelow = true
  o.wrap = false

  o.ignorecase = true
  o.smartcase = true
  o.inccommand = "split"

  o.tabstop = 2
  o.shiftwidth = 2
  o.expandtab = true
  o.smartindent = true

  o.undofile = true
  o.swapfile = false
  o.updatetime = 250
  o.timeoutlen = 400
  o.mouse = "a"
  o.confirm = true

  -- Sync with system clipboard (after startup, so it doesn't slow launch).
  vim.schedule(function()
    vim.opt.clipboard = "unnamedplus"
  end)

  vim.diagnostic.config({
    virtual_text = true,
    severity_sort = true,
    float = { border = "rounded" },
  })
end

return M

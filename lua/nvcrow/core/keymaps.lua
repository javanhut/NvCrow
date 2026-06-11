-- Core keymaps. LSP keymaps live in core/autocmds.lua (on LspAttach).

local M = {}

function M.setup()
  local map = vim.keymap.set

  -- Clear search highlight
  map("n", "<Esc>", "<cmd>nohlsearch<cr>")

  -- Save
  map({ "n", "i" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

  -- Window navigation
  map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
  map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
  map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
  map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

  -- Buffers
  map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
  map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
  map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

  -- Move selected lines
  map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
  map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

  -- Keep cursor centered when jumping
  map("n", "<C-d>", "<C-d>zz")
  map("n", "<C-u>", "<C-u>zz")
  map("n", "n", "nzzzv")
  map("n", "N", "Nzzzv")

  -- Stay in visual mode when indenting
  map("v", "<", "<gv")
  map("v", ">", ">gv")

  -- Diagnostics
  map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Line diagnostics" })

  -- The Crow picker
  map("n", "<leader>cc", "<cmd>Crow<cr>", { desc = "Crow — add things" })
  map("n", "<leader>ct", "<cmd>Crow theme<cr>", { desc = "Pick theme (live preview)" })
end

return M

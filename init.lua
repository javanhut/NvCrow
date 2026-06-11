-- NvCrow — Neovim config that barely requires a thought.
-- You never need to edit this file. Your spec lives in crow.lua.

if vim.fn.has("nvim-0.11") == 0 then
  vim.api.nvim_echo({ { "NvCrow requires Neovim 0.11 or newer.\n", "ErrorMsg" } }, true, {})
  return
end

require("nvcrow").setup()

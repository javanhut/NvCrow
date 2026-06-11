-- Resolved state, populated by nvcrow.resolver at startup.
-- Base plugin configs read from here so they never need editing.

return {
  plugins = {},          -- full lazy.nvim spec list
  lsp = {},              -- server name -> config table for vim.lsp.config()
  lsp_servers = {},      -- list of server names for mason-lspconfig
  mason_tools = {},      -- extra mason package names (formatters, linters)
  treesitter = {},       -- parser names
  formatters_by_ft = {}, -- conform.nvim formatters_by_ft
  colorscheme = "default",
}

-- Resolved state, populated by nvcrow.resolver at startup.
-- Base plugin configs read from here so they never need editing.

return {
  plugins = {},          -- full lazy.nvim spec list
  lsp = {},              -- server name -> config table for vim.lsp.config()
  lsp_servers = {},      -- list of server names for mason-lspconfig
  lsp_custom = {},       -- custom servers on PATH (native lsp/<name>.lua config),
                         -- enabled directly via vim.lsp.enable — NOT mason packages
  mason_tools = {},      -- extra mason package names (formatters, linters)
  treesitter = {},       -- parser names
  formatters_by_ft = {}, -- conform.nvim formatters_by_ft
  colorscheme = "default",
}

-- crow.lua — your NvCrow spec. This is the only file you edit.
--
--   Add a name, restart Neovim, done. Or use the commands:
--     :Crow add rust        :Crow remove rust
--     :Crow list            :Crow sync

return {
  theme = "tokyonight",

  langs = {
    "lua",
    "rust",
    "python",
    "oxigen",
  },

  plugins = {
    "telescope",
    "nvim-tree",
    "dashboard",
    "command-bar",
  },

  options = {},
}

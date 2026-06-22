-- Resolver: user spec + recipes -> populated nvcrow.state.
-- This is where "rust" becomes an LSP server, formatter, parsers,
-- and plugins without the user thinking about any of it.

local M = {}

local function add_unique(list, value)
  for _, v in ipairs(list) do
    if v == value then return end
  end
  table.insert(list, value)
end

function M.resolve(spec)
  local recipes = require("nvcrow.recipes")
  local state = require("nvcrow.state")

  state.plugins = {}
  state.lsp = {}
  state.lsp_servers = {}
  state.lsp_custom = {}
  state.mason_tools = {}
  -- Parsers everyone hits regardless of langs: shell scripts, docs,
  -- config files. Keeps highlighting solid out of the box.
  state.treesitter = {
    "vim", "vimdoc", "query", "regex",
    "bash", "markdown", "markdown_inline",
    "json", "yaml", "toml", "gitcommit", "diff",
  }
  state.formatters_by_ft = {}

  -- Theme
  local theme = recipes.themes[spec.theme or "catppuccin"]
  if not theme then
    vim.notify(
      ("NvCrow: unknown theme %q — falling back to catppuccin.\nAvailable: %s")
        :format(spec.theme, table.concat(recipes.names(recipes.themes), ", ")),
      vim.log.levels.WARN
    )
    theme = recipes.themes.catppuccin
  end
  state.colorscheme = theme.colorscheme
  table.insert(state.plugins, {
    theme.repo,
    name = theme.name,
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme(theme.colorscheme)
    end,
  })

  -- Keep the other themes installed (but not loaded) so the theme
  -- picker can live-preview and switch without a restart.
  for _, other in pairs(recipes.themes) do
    if other.repo ~= theme.repo then
      table.insert(state.plugins, { other.repo, name = other.name, lazy = true })
    end
  end

  -- Languages
  for _, name in ipairs(spec.langs or {}) do
    local canonical = recipes.lang_name(name)
    local recipe = canonical and recipes.langs[canonical]
    if not recipe then
      vim.notify(("NvCrow: unknown language %q in crow.lua — skipping."):format(name), vim.log.levels.WARN)
    else
      for server, cfg in pairs(recipe.lsp or {}) do
        state.lsp[server] = cfg
        add_unique(state.lsp_servers, server)
      end
      -- Custom servers: a binary already on PATH, configured by a native
      -- lsp/<name>.lua on the runtimepath. Not a mason/lspconfig package, so it
      -- is enabled directly (see core/plugins.lua) and kept out of
      -- mason-lspconfig's ensure_installed.
      for _, server in ipairs(recipe.lsp_custom or {}) do
        add_unique(state.lsp_custom, server)
      end
      for ft, formatters in pairs(recipe.formatters or {}) do
        state.formatters_by_ft[ft] = formatters
      end
      for _, tool in ipairs(recipe.mason or {}) do
        add_unique(state.mason_tools, tool)
      end
      for _, parser in ipairs(recipe.treesitter or {}) do
        add_unique(state.treesitter, parser)
      end
      for _, plugin in ipairs(recipe.plugins or {}) do
        table.insert(state.plugins, plugin)
      end
    end
  end

  -- Plugins: recipe names, raw "user/repo" strings, or raw lazy specs.
  for _, entry in ipairs(spec.plugins or {}) do
    if type(entry) == "table" then
      table.insert(state.plugins, entry) -- passthrough lazy spec
    elseif recipes.plugins[entry] then
      for _, plugin in ipairs(recipes.plugins[entry]) do
        table.insert(state.plugins, plugin)
      end
    elseif entry:find("/") then
      table.insert(state.plugins, { entry })
    else
      vim.notify(("NvCrow: unknown plugin %q in crow.lua — skipping."):format(entry), vim.log.levels.WARN)
    end
  end

  -- Base plugins last; they read state in their config functions.
  for _, plugin in ipairs(require("nvcrow.core.plugins")) do
    table.insert(state.plugins, plugin)
  end

  return spec
end

return M

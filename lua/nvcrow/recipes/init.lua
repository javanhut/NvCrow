-- Recipe registry lookup helpers.

local M = {}

M.langs = require("nvcrow.recipes.langs")
M.plugins = require("nvcrow.recipes.plugins")
M.themes = require("nvcrow.recipes.themes")

-- Map of alias -> canonical lang name, built once.
local lang_aliases = {}
for name, recipe in pairs(M.langs) do
  for _, alias in ipairs(recipe.aliases or {}) do
    lang_aliases[alias] = name
  end
end

-- Resolve a lang name or alias to its canonical name, or nil.
function M.lang_name(name)
  if M.langs[name] then return name end
  return lang_aliases[name]
end

-- Classify an arbitrary name. Returns kind ("lang"|"plugin"|"theme"|"repo")
-- and the canonical name, or nil plus fuzzy suggestions.
function M.classify(name)
  local lang = M.lang_name(name)
  if lang then return "lang", lang end
  if M.plugins[name] then return "plugin", name end
  if M.themes[name] then return "theme", name end
  if name:find("/") then return "repo", name end

  local candidates = {}
  for k in pairs(M.langs) do table.insert(candidates, k) end
  for k in pairs(M.plugins) do table.insert(candidates, k) end
  for k in pairs(M.themes) do table.insert(candidates, k) end
  local suggestions = vim.fn.matchfuzzy(candidates, name)
  return nil, suggestions
end

-- Sorted name lists, for :Crow list and completion.
function M.names(registry)
  local out = {}
  for k in pairs(registry) do table.insert(out, k) end
  table.sort(out)
  return out
end

return M

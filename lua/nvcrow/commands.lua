-- :Crow add/remove/list/sync — the day-to-day interface.
-- Commands edit crow.lua (the source of truth) and then sync.

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "NvCrow" })
end

local function contains(list, value)
  for _, v in ipairs(list) do
    if v == value then return true end
  end
  return false
end

local function remove_value(list, value)
  for i, v in ipairs(list) do
    if v == value then
      table.remove(list, i)
      return true
    end
  end
  return false
end

-- Offer a restart to activate spec changes (on launch everything
-- missing installs itself). Shared with the :Crow GUI.
function M.post_change(summary)
  if vim.fn.exists(":restart") == 2 then
    local choice = vim.fn.confirm(summary .. "\nRestart Neovim now to finish setup?", "&Yes\n&No", 1)
    if choice == 1 then
      vim.cmd("restart")
      return
    end
  end
  notify(summary .. "\nRestart Neovim to finish setup — everything installs automatically on launch.")
end

local function add(names)
  local recipes = require("nvcrow.recipes")
  local spec_mod = require("nvcrow.spec")
  local spec = spec_mod.load()

  local added = {}
  for _, name in ipairs(names) do
    local kind, resolved = recipes.classify(name)
    if kind == "lang" then
      if not contains(spec.langs, resolved) then
        table.insert(spec.langs, resolved)
        table.insert(added, resolved .. " (language)")
      else
        notify(("%q is already in your spec."):format(resolved), vim.log.levels.WARN)
      end
    elseif kind == "plugin" or kind == "repo" then
      if not contains(spec.plugins, resolved) then
        table.insert(spec.plugins, resolved)
        table.insert(added, resolved .. " (plugin)")
      else
        notify(("%q is already in your spec."):format(resolved), vim.log.levels.WARN)
      end
    elseif kind == "theme" then
      spec.theme = resolved
      table.insert(added, resolved .. " (theme)")
    else
      local hint = #resolved > 0
          and ("Did you mean: %s?"):format(table.concat(vim.list_slice(resolved, 1, 3), ", "))
        or "Run :Crow list to see what's available, or use a full \"user/repo\"."
      notify(("Unknown name %q. %s"):format(name, hint), vim.log.levels.ERROR)
    end
  end

  if #added == 0 then return end

  local ok, err = spec_mod.save(spec)
  if not ok then
    notify(err, vim.log.levels.ERROR)
    return
  end
  M.post_change("Added: " .. table.concat(added, ", "))
end

local function remove(names)
  local recipes = require("nvcrow.recipes")
  local spec_mod = require("nvcrow.spec")
  local spec = spec_mod.load()

  local removed = {}
  for _, name in ipairs(names) do
    local canonical = recipes.lang_name(name) or name
    if remove_value(spec.langs, canonical) or remove_value(spec.plugins, canonical) then
      table.insert(removed, canonical)
    else
      notify(("%q is not in your spec."):format(name), vim.log.levels.WARN)
    end
  end

  if #removed == 0 then return end

  local ok, err = spec_mod.save(spec)
  if not ok then
    notify(err, vim.log.levels.ERROR)
    return
  end
  M.post_change("Removed: " .. table.concat(removed, ", ") .. "\n(Run :Lazy clean after restart to delete unused plugins.)")
end

local function list()
  local recipes = require("nvcrow.recipes")
  local spec = require("nvcrow.spec").load()

  local function line(items)
    return #items > 0 and table.concat(items, ", ") or "(none)"
  end

  local plugins = {}
  for _, p in ipairs(spec.plugins) do
    table.insert(plugins, type(p) == "table" and (p[1] or "custom spec") or p)
  end

  local msg = table.concat({
    "Your spec (crow.lua):",
    "  theme:   " .. spec.theme,
    "  langs:   " .. line(spec.langs),
    "  plugins: " .. line(plugins),
    "",
    "Available languages: " .. table.concat(recipes.names(recipes.langs), ", "),
    "Available plugins:   " .. table.concat(recipes.names(recipes.plugins), ", "),
    "Available themes:    " .. table.concat(recipes.names(recipes.themes), ", "),
    "",
    "Anything else? :Crow add user/repo works for any GitHub plugin.",
  }, "\n")
  vim.notify(msg, vim.log.levels.INFO, { title = "NvCrow" })
end

local function sync()
  require("lazy").sync({ wait = false })
  notify("Syncing plugins. LSP servers and tools install automatically on restart.")
end

local subcommands = { "add", "remove", "list", "sync", "ui" }

local function complete(arglead, cmdline)
  local recipes = require("nvcrow.recipes")
  local args = vim.split(cmdline, "%s+", { trimempty = true })
  local sub = args[2]

  local candidates
  if not sub or (#args == 2 and cmdline:sub(-1) ~= " ") then
    candidates = subcommands
  elseif sub == "add" then
    candidates = {}
    vim.list_extend(candidates, recipes.names(recipes.langs))
    vim.list_extend(candidates, recipes.names(recipes.plugins))
    vim.list_extend(candidates, recipes.names(recipes.themes))
  elseif sub == "remove" then
    local spec = require("nvcrow.spec").load()
    candidates = {}
    vim.list_extend(candidates, spec.langs)
    for _, p in ipairs(spec.plugins) do
      if type(p) == "string" then table.insert(candidates, p) end
    end
  else
    candidates = {}
  end

  return vim.tbl_filter(function(c)
    return vim.startswith(c, arglead)
  end, candidates)
end

function M.setup()
  vim.api.nvim_create_user_command("Crow", function(opts)
    local args = opts.fargs
    local sub = table.remove(args, 1)
    if sub == nil or sub == "ui" then
      require("nvcrow.ui").open()
    elseif sub == "add" and #args > 0 then
      add(args)
    elseif sub == "remove" and #args > 0 then
      remove(args)
    elseif sub == "list" then
      list()
    elseif sub == "sync" then
      sync()
    else
      notify("Usage: :Crow [ui] | add <name...> | remove <name...> | list | sync", vim.log.levels.WARN)
    end
  end, {
    nargs = "*",
    complete = complete,
    desc = "NvCrow: manage languages, plugins, and themes (no args: GUI)",
  })

  vim.api.nvim_create_user_command("CrowSync", sync, { desc = "NvCrow: sync plugins and tools" })
end

return M

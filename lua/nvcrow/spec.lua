-- Load and write crow.lua, the user's spec file.

local M = {}

function M.path()
  return vim.fn.stdpath("config") .. "/crow.lua"
end

local default_spec = {
  theme = "catppuccin",
  langs = { "lua" },
  plugins = { "telescope" },
  options = {},
}

function M.load()
  local ok, spec = pcall(dofile, M.path())
  if not ok or type(spec) ~= "table" then
    vim.schedule(function()
      vim.notify(
        "NvCrow: could not read crow.lua (" .. tostring(spec) .. ") — using defaults.",
        vim.log.levels.ERROR
      )
    end)
    return vim.deepcopy(default_spec)
  end
  spec.theme = spec.theme or default_spec.theme
  spec.langs = spec.langs or {}
  spec.plugins = spec.plugins or {}
  spec.options = spec.options or {}
  return spec
end

-- Serialize one plugins-list entry. Strings stay strings; tables are
-- rendered with vim.inspect (only possible when they hold plain data).
local function serialize_entry(entry, indent)
  if type(entry) == "string" then
    return string.format("%q", entry)
  end
  local rendered = vim.inspect(entry, { indent = "  " })
  if rendered:find("<function") or rendered:find("<userdata") then
    return nil
  end
  return (rendered:gsub("\n", "\n" .. indent))
end

-- Rewrite crow.lua in canonical form. Returns false + reason if the
-- spec holds things we can't serialize (e.g. plugin specs with
-- config functions) — in that case the user edits by hand.
function M.save(spec)
  local lines = {
    "-- crow.lua — your NvCrow spec. This is the only file you edit.",
    "--",
    "--   Add a name, restart Neovim, done. Or use the commands:",
    "--     :Crow add rust        :Crow remove rust",
    "--     :Crow list            :Crow sync",
    "",
    "return {",
    ('  theme = %q,'):format(spec.theme),
    "",
    "  langs = {",
  }
  for _, lang in ipairs(spec.langs) do
    table.insert(lines, ('    %q,'):format(lang))
  end
  table.insert(lines, "  },")
  table.insert(lines, "")
  table.insert(lines, "  plugins = {")
  for _, entry in ipairs(spec.plugins) do
    local rendered = serialize_entry(entry, "    ")
    if not rendered then
      return false, "crow.lua contains a plugin spec with a function — edit the file by hand instead."
    end
    table.insert(lines, "    " .. rendered .. ",")
  end
  table.insert(lines, "  },")

  local options = serialize_entry(spec.options or {}, "  ")
  if not options then
    return false, "crow.lua options contain a function — edit the file by hand instead."
  end
  table.insert(lines, "")
  table.insert(lines, "  options = " .. options .. ",")
  table.insert(lines, "}")

  local fd, err = io.open(M.path(), "w")
  if not fd then
    return false, "could not write crow.lua: " .. tostring(err)
  end
  fd:write(table.concat(lines, "\n") .. "\n")
  fd:close()
  return true
end

return M

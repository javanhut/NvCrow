-- :checkhealth nvcrow

local M = {}

function M.check()
  local health = vim.health

  health.start("NvCrow")

  if vim.fn.has("nvim-0.11") == 1 then
    health.ok("Neovim " .. tostring(vim.version()))
  else
    health.error("Neovim 0.11+ required")
  end

  for _, bin in ipairs({ "git", "make", "rg" }) do
    if vim.fn.executable(bin) == 1 then
      health.ok(bin .. " found")
    else
      health.warn(bin .. " not found — some features need it (rg: telescope grep, make: fzf-native)")
    end
  end

  require("nvcrow.deps").setup_path()
  if vim.fn.executable("tree-sitter") == 1 then
    health.ok("tree-sitter CLI found: " .. vim.fn.exepath("tree-sitter"))
  else
    health.warn("tree-sitter CLI not found — NvCrow auto-downloads it on startup; if this persists, check your network")
  end

  if vim.fn.executable("cc") == 1 or vim.fn.executable("gcc") == 1 or vim.fn.executable("clang") == 1 then
    health.ok("C compiler found")
  else
    health.warn("no C compiler — parsers and fzf-native can't build (NvCrow offers to install one on startup)")
  end

  local ok, spec = pcall(dofile, require("nvcrow.spec").path())
  if ok and type(spec) == "table" then
    health.ok("crow.lua parses")
    local recipes = require("nvcrow.recipes")
    for _, name in ipairs(spec.langs or {}) do
      if not recipes.lang_name(name) then
        health.warn(("unknown language %q in crow.lua"):format(name))
      end
    end
    for _, name in ipairs(spec.plugins or {}) do
      if type(name) == "string" and not recipes.plugins[name] and not name:find("/") then
        health.warn(("unknown plugin %q in crow.lua"):format(name))
      end
    end
    if spec.theme and not recipes.themes[spec.theme] then
      health.warn(("unknown theme %q in crow.lua"):format(spec.theme))
    end
  else
    health.error("crow.lua failed to parse: " .. tostring(spec))
  end
end

return M

-- The :Crow GUI: a floating picker over the recipe registry.
-- Enter toggles a language/plugin on or off (themes are pick-one);
-- closing applies everything to crow.lua in one go.

local M = {}

-- Load a theme's plugin (pre-installed but lazy) and apply it now.
-- Returns false when the plugin isn't on disk yet (needs a restart).
function M.apply_theme(name)
  local theme = require("nvcrow.recipes").themes[name]
  if not theme then return false end
  local plugin = theme.name or theme.repo:match("[^/]+$")
  pcall(function()
    require("lazy").load({ plugins = { plugin } })
  end)
  return pcall(vim.cmd.colorscheme, theme.colorscheme)
end

-- Theme picker: moving the cursor live-previews, Enter keeps it
-- (saved to crow.lua, already applied — no restart), q/Esc reverts.
function M.themes()
  local recipes = require("nvcrow.recipes")
  local spec_mod = require("nvcrow.spec")
  local spec = spec_mod.load()
  local names = recipes.names(recipes.themes)
  local original = spec.theme

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local lines, current_row = {}, 1
  for i, name in ipairs(names) do
    lines[i] = ("  %s %s"):format(name == spec.theme and "●" or " ", name)
    if name == spec.theme then current_row = i end
  end
  table.insert(lines, 1, "  move to preview · ⏎ keep · q revert")
  table.insert(lines, 2, "")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local ns = vim.api.nvim_create_namespace("nvcrow_themes")
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, { line_hl_group = "Comment" })

  local width = 38
  local height = #lines
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2) - 1,
    style = "minimal",
    border = "rounded",
    title = " Theme ",
    title_pos = "center",
  })
  vim.wo[win].cursorline = true
  vim.api.nvim_win_set_cursor(win, { current_row + 2, 4 })

  local function hovered()
    return names[vim.api.nvim_win_get_cursor(win)[1] - 2]
  end

  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
      local name = hovered()
      if name and not M.apply_theme(name) then
        vim.notify(name .. " isn't installed yet — restart Neovim first.", vim.log.levels.WARN, { title = "NvCrow" })
      end
    end,
  })

  local function close(keep)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    local name = keep
    if not name then
      M.apply_theme(original)
      return
    end
    spec.theme = name
    local ok, err = spec_mod.save(spec)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR, { title = "NvCrow" })
      return
    end
    vim.notify("Theme: " .. name, vim.log.levels.INFO, { title = "NvCrow" })
  end

  local opts = { buffer = buf, nowait = true }
  vim.keymap.set("n", "<CR>", function() close(hovered()) end, opts)
  vim.keymap.set("n", "q", function() close(nil) end, opts)
  vim.keymap.set("n", "<Esc>", function() close(nil) end, opts)
end

function M.open()
  local recipes = require("nvcrow.recipes")
  local spec_mod = require("nvcrow.spec")
  local spec = spec_mod.load()
  local dirty = false

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local ns = vim.api.nvim_create_namespace("nvcrow_ui")

  local items -- line number -> { kind, name }

  local function build()
    local lines, map = {}, {}
    local function push(text, item)
      table.insert(lines, text)
      map[#lines] = item
    end

    push("  ⏎ toggle    q apply & close")
    push("")
    push("  Languages")
    for _, name in ipairs(recipes.names(recipes.langs)) do
      local on = vim.tbl_contains(spec.langs, name)
      push(("    [%s] %s"):format(on and "✓" or " ", name), { kind = "lang", name = name })
    end
    push("")
    push("  Plugins")
    for _, name in ipairs(recipes.names(recipes.plugins)) do
      local on = vim.tbl_contains(spec.plugins, name)
      push(("    [%s] %s"):format(on and "✓" or " ", name), { kind = "plugin", name = name })
    end
    for _, p in ipairs(spec.plugins) do
      if type(p) == "string" and p:find("/") then
        push(("    [✓] %s"):format(p), { kind = "plugin", name = p })
      end
    end
    push("")
    push("  Theme")
    for _, name in ipairs(recipes.names(recipes.themes)) do
      push(("    (%s) %s"):format(spec.theme == name and "●" or " ", name), { kind = "theme", name = name })
    end
    return lines, map
  end

  local function decorate(lines)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for i, line in ipairs(lines) do
      local hl
      if i == 1 then
        hl = "Comment"
      elseif line == "  Languages" or line == "  Plugins" or line == "  Theme" then
        hl = "Title"
      elseif line:find("✓", 1, true) or line:find("●", 1, true) then
        hl = "String"
      end
      if hl then
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { line_hl_group = hl })
      end
    end
  end

  local function render()
    local lines
    lines, items = build()
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    decorate(lines)
    return #lines
  end

  local total = render()
  local width = 44
  local height = math.min(total, vim.o.lines - 6)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2) - 1,
    style = "minimal",
    border = "rounded",
    title = " 🐦‍⬛ NvCrow ",
    title_pos = "center",
  })
  vim.wo[win].cursorline = true
  vim.api.nvim_win_set_cursor(win, { 4, 4 })

  local function toggle()
    local item = items[vim.api.nvim_win_get_cursor(win)[1]]
    if not item then return end

    if item.kind == "theme" then
      if spec.theme ~= item.name then
        spec.theme = item.name
        dirty = true
        M.apply_theme(item.name) -- instant feedback, no restart needed
      end
    else
      local list = item.kind == "lang" and spec.langs or spec.plugins
      local removed = false
      for i, v in ipairs(list) do
        if v == item.name then
          table.remove(list, i)
          removed = true
          break
        end
      end
      if not removed then
        table.insert(list, item.name)
      end
      dirty = true
    end
    render()
  end

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if not dirty then return end
    local ok, err = spec_mod.save(spec)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR, { title = "NvCrow" })
      return
    end
    require("nvcrow.commands").post_change("crow.lua updated.")
  end

  local opts = { buffer = buf, nowait = true }
  vim.keymap.set("n", "<CR>", toggle, opts)
  vim.keymap.set("n", "<Space>", toggle, opts)
  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)
end

return M

-- The :Crow GUI: a floating picker over the recipe registry.
-- Enter toggles a language/plugin on or off (themes are pick-one);
-- closing applies everything to crow.lua in one go.

local M = {}

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

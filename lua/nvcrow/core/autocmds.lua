local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("nvcrow", { clear = true })

  -- Flash yanked text
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    callback = function()
      vim.hl.on_yank()
    end,
  })

  -- LSP keymaps, attached per-buffer when a server connects
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event)
      local function map(keys, fn, desc)
        vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = desc })
      end

      -- Prefer telescope pickers when available
      local function picker(builtin, fallback)
        return function()
          local ok, t = pcall(require, "telescope.builtin")
          if ok then t[builtin]() else fallback() end
        end
      end

      map("gd", picker("lsp_definitions", vim.lsp.buf.definition), "Goto definition")
      map("gr", picker("lsp_references", vim.lsp.buf.references), "References")
      map("gI", picker("lsp_implementations", vim.lsp.buf.implementation), "Goto implementation")
      map("gD", vim.lsp.buf.declaration, "Goto declaration")
      map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
      map("<leader>ca", vim.lsp.buf.code_action, "Code action")
      map("K", vim.lsp.buf.hover, "Hover docs")
    end,
  })
end

return M

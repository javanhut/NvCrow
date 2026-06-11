-- NvCrow core orchestrator: load the user spec, resolve recipes,
-- boot lazy.nvim with the resolved plugin list.

local M = {}

function M.setup()
  require("nvcrow.core.options").setup()

  -- Expose NvCrow-managed binaries (auto-downloaded tools) to this
  -- session before any plugin needs them.
  require("nvcrow.deps").setup_path()

  local spec = require("nvcrow.spec").load()
  spec = require("nvcrow.resolver").resolve(spec)

  require("nvcrow.bootstrap").ensure_lazy()

  require("lazy").setup(require("nvcrow.state").plugins, {
    install = { colorscheme = { require("nvcrow.state").colorscheme, "habamax" } },
    checker = { enabled = false },
    change_detection = { notify = false },
    ui = { border = "rounded" },
  })

  require("nvcrow.core.keymaps").setup()
  require("nvcrow.core.autocmds").setup()
  require("nvcrow.commands").setup()
  require("nvcrow.ivaldi").setup()

  -- User option overrides win over NvCrow defaults.
  for k, v in pairs(spec.options or {}) do
    vim.opt[k] = v
  end

  -- After the UI settles, offer to install any missing system tools.
  vim.defer_fn(function()
    require("nvcrow.deps").check_system()
  end, 1500)
end

return M

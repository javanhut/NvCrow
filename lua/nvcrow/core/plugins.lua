-- Base plugins every NvCrow install gets: treesitter, LSP stack,
-- completion, formatting, statusline, git signs, which-key.
-- Their configs read resolved data from nvcrow.state.

return {
  -- Auto-detect indentation; no tabs-vs-spaces config ever.
  { "tpope/vim-sleuth" },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      local parsers = require("nvcrow.state").treesitter

      -- Legacy API: checkout is on the frozen `master` branch.
      local has_legacy, legacy = pcall(require, "nvim-treesitter.configs")
      if has_legacy then
        legacy.setup({
          ensure_installed = parsers,
          auto_install = true,
          highlight = { enable = true },
          indent = { enable = true },
        })
        return
      end

      -- Current API: `main` branch rewrite. The tree-sitter CLI is
      -- auto-downloaded if missing, then parsers install.
      local ts = require("nvim-treesitter")
      ts.setup({})
      require("nvcrow.deps").ensure_tree_sitter(function()
        ts.install(parsers)
      end)
      local attempted = {} -- avoid re-installing a parser that failed
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("nvcrow_treesitter", { clear = true }),
        callback = function(ev)
          local function start(buf)
            if pcall(vim.treesitter.start, buf) then
              vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
              return true
            end
          end
          if start(ev.buf) then return end

          -- Parser missing: install it on demand, then attach.
          local lang = vim.treesitter.language.get_lang(ev.match)
          if not lang or attempted[lang] or vim.fn.executable("tree-sitter") == 0 then
            return
          end
          if not vim.tbl_contains(ts.get_available(), lang) then return end
          attempted[lang] = true
          ts.install(lang):await(function()
            vim.schedule(function()
              if vim.api.nvim_buf_is_valid(ev.buf) then
                start(ev.buf)
              end
            end)
          end)
        end,
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", opts = { ui = { border = "rounded" } } },
      "mason-org/mason-lspconfig.nvim",
    },
    lazy = false,
    config = function()
      local state = require("nvcrow.state")

      for server, cfg in pairs(state.lsp) do
        if type(cfg) == "table" and next(cfg) ~= nil then
          vim.lsp.config(server, cfg)
        end
      end

      -- Installs every recipe's LSP server and enables it automatically.
      require("mason-lspconfig").setup({
        ensure_installed = state.lsp_servers,
        automatic_enable = true,
      })

      -- Custom servers (e.g. oxigen-lsp): the binary is already on PATH and its
      -- config comes from a native lsp/<name>.lua on the runtimepath. They are
      -- NOT mason packages, so enable them directly instead of via
      -- mason-lspconfig's automatic_enable.
      for _, server in ipairs(state.lsp_custom or {}) do
        vim.lsp.enable(server)
      end

      -- Install non-LSP tools (formatters, linters) from recipes.
      local ok, registry = pcall(require, "mason-registry")
      if ok then
        registry.refresh(function()
          for _, name in ipairs(state.mason_tools) do
            local found, pkg = pcall(registry.get_package, name)
            if found and not pkg:is_installed() then
              pkg:install()
            end
          end
        end)
      end
    end,
  },

  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true }) end, desc = "Format buffer" },
    },
    config = function()
      require("conform").setup({
        formatters_by_ft = require("nvcrow.state").formatters_by_ft,
        format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
      })
    end,
  },

  {
    "saghen/blink.cmp",
    version = "1.*",
    event = "InsertEnter",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "enter",
        -- Tab walks down the completion list, Shift-Tab walks up;
        -- inside a snippet they jump between placeholders instead.
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
      signature = { enabled = true },
    },
  },

  { "lewis6991/gitsigns.nvim", event = "VeryLazy", opts = {} },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = { theme = "auto", globalstatus = true },
      sections = {
        lualine_b = {
          "branch",
          function() return require("nvcrow.ivaldi").statusline() end,
          "diff",
          "diagnostics",
        },
      },
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>c", group = "code" },
        { "<leader>h", group = "harpoon" },
        { "<leader>x", group = "diagnostics" },
        { "<leader>v", group = "ivaldi" },
      },
    },
  },

  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
}

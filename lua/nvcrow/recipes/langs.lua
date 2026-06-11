-- Language recipes. Each one is a tested bundle:
--   lsp        : server name -> config for vim.lsp.config() ({} = defaults)
--   formatters : conform.nvim formatters_by_ft entries
--   mason      : extra mason packages to auto-install (formatters, linters)
--   treesitter : parser names
--   plugins    : companion lazy.nvim specs
--   aliases    : other names that resolve to this recipe

local R = {}

R.lua = {
  lsp = { lua_ls = {} },
  formatters = { lua = { "stylua" } },
  mason = { "stylua" },
  treesitter = { "lua", "luadoc" },
  plugins = {
    { "folke/lazydev.nvim", ft = "lua", opts = {} },
  },
}

R.rust = {
  lsp = { rust_analyzer = {} },
  formatters = { rust = { "rustfmt" } }, -- ships with rustup
  treesitter = { "rust", "toml" },
  plugins = {
    { "saecki/crates.nvim", event = "BufRead Cargo.toml", opts = {} },
  },
}

R.python = {
  aliases = { "py" },
  lsp = { pyright = {} },
  formatters = { python = { "ruff_format" } },
  mason = { "ruff" },
  treesitter = { "python" },
}

R.go = {
  aliases = { "golang" },
  lsp = { gopls = {} },
  formatters = { go = { "gofumpt" } },
  mason = { "gofumpt" },
  treesitter = { "go", "gomod", "gosum" },
}

R.typescript = {
  aliases = { "ts", "js", "javascript" },
  lsp = { ts_ls = {} },
  formatters = {
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
  },
  mason = { "prettier" },
  treesitter = { "typescript", "tsx", "javascript", "jsdoc" },
}

R.web = {
  aliases = { "html", "css" },
  lsp = { html = {}, cssls = {}, emmet_language_server = {} },
  formatters = { html = { "prettier" }, css = { "prettier" }, scss = { "prettier" } },
  mason = { "prettier" },
  treesitter = { "html", "css", "scss" },
}

R.json = {
  lsp = { jsonls = {} },
  formatters = { json = { "prettier" }, jsonc = { "prettier" } },
  mason = { "prettier" },
  treesitter = { "json", "jsonc" },
}

R.yaml = {
  lsp = { yamlls = {} },
  formatters = { yaml = { "prettier" } },
  mason = { "prettier" },
  treesitter = { "yaml" },
}

R.markdown = {
  aliases = { "md" },
  lsp = { marksman = {} },
  formatters = { markdown = { "prettier" } },
  mason = { "prettier" },
  treesitter = { "markdown", "markdown_inline" },
  plugins = {
    { "MeanderingProgrammer/render-markdown.nvim", ft = "markdown", opts = {} },
  },
}

R.c = {
  aliases = { "cpp", "c++" },
  lsp = { clangd = {} },
  formatters = { c = { "clang_format" }, cpp = { "clang_format" } },
  mason = { "clang-format" },
  treesitter = { "c", "cpp" },
}

R.bash = {
  aliases = { "sh", "shell", "zsh" },
  lsp = { bashls = {} },
  formatters = { sh = { "shfmt" }, bash = { "shfmt" } },
  mason = { "shfmt" },
  treesitter = { "bash" },
}

R.zig = {
  lsp = { zls = {} },
  formatters = { zig = { "zigfmt" } }, -- ships with zig
  treesitter = { "zig" },
}

R.java = {
  lsp = { jdtls = {} },
  treesitter = { "java" },
}

R.php = {
  lsp = { intelephense = {} },
  treesitter = { "php" },
}

R.docker = {
  aliases = { "dockerfile" },
  lsp = { dockerls = {} },
  treesitter = { "dockerfile" },
}

R.terraform = {
  aliases = { "tf" },
  lsp = { terraformls = {} },
  formatters = { terraform = { "terraform_fmt" } },
  treesitter = { "terraform", "hcl" },
}

return R

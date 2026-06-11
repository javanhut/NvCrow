-- Plugin recipes: curated, pre-configured lazy.nvim specs with keymaps
-- already wired. Each entry is a list of specs (some recipes bring friends).

local R = {}

R.telescope = {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    cmd = "Telescope",
    keys = {
      { "<C-f>", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Grep text" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
    },
    config = function()
      require("telescope").setup({})
      pcall(require("telescope").load_extension, "fzf")
    end,
  },
}

R.harpoon = {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Harpoon add file" },
      { "<leader>hh", function() local h = require("harpoon") h.ui:toggle_quick_menu(h:list()) end, desc = "Harpoon menu" },
      { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
      { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
      { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon 3" },
      { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon 4" },
    },
    config = function() require("harpoon"):setup() end,
  },
}

R.oil = {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false, -- so `nvim some-dir/` opens oil
    keys = { { "-", "<cmd>Oil<cr>", desc = "File browser (oil)" } },
    opts = {},
  },
}

R["neo-tree"] = {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "File tree" },
      { "<C-t>", "<cmd>Neotree toggle<cr>", desc = "File tree" },
    },
    opts = {},
  },
}

R["nvim-tree"] = {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "NvimTreeToggle",
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "File tree" },
      { "<C-t>", "<cmd>NvimTreeToggle<cr>", desc = "File tree" },
    },
    opts = {
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        api.config.mappings.default_on_attach(bufnr)
        -- nvim-tree's own <C-t> ("open in new tab") shadows the global
        -- toggle inside the tree — make it close the tree instead.
        vim.keymap.set("n", "<C-t>", api.tree.toggle, { buffer = bufnr, desc = "Close tree" })
      end,
    },
  },
}

R.flash = {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
    },
    opts = {},
  },
}

R.trouble = {
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
    },
    opts = {},
  },
}

R["todo-comments"] = {
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
    opts = {},
  },
}

R.surround = {
  { "kylechui/nvim-surround", event = "VeryLazy", opts = {} },
}

R["zen-mode"] = {
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    keys = { { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen mode" } },
    opts = {},
  },
}

R.lazygit = {
  {
    "kdheepak/lazygit.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "LazyGit",
    keys = { { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" } },
  },
}

R.undotree = {
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = { { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Undo tree" } },
  },
}

R.copilot = {
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    opts = {
      suggestion = { auto_trigger = true, keymap = { accept = "<Tab>" } },
      panel = { enabled = false },
    },
  },
}

R["indent-guides"] = {
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", event = "VeryLazy", opts = {} },
}

R["command-bar"] = {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      cmdline = { view = "cmdline_popup" }, -- floating command bar
      presets = {
        command_palette = true, -- cmdline + completions together up top
        bottom_search = true, -- / search stays put (less jarring)
        long_message_to_split = true,
      },
    },
  },
}

R.dashboard = {
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local dashboard = require("alpha.themes.dashboard")
      dashboard.section.header.val = {
        [[ ██████   █████ █████   █████   █████████  ███████████      ███████    █████   ███   █████]],
        [[░░██████ ░░███ ░░███   ░░███   ███░░░░░███░░███░░░░░███   ███░░░░░███ ░░███   ░███  ░░███ ]],
        [[ ░███░███ ░███  ░███    ░███  ███     ░░░  ░███    ░███  ███     ░░███ ░███   ░███   ░███ ]],
        [[ ░███░░███░███  ░███    ░███ ░███          ░██████████  ░███      ░███ ░███   ░███   ░███ ]],
        [[ ░███ ░░██████  ░░███   ███  ░███          ░███░░░░░███ ░███      ░███ ░░███  █████  ███  ]],
        [[ ░███  ░░█████   ░░░█████░   ░░███     ███ ░███    ░███ ░░███     ███   ░░░█████░█████░   ]],
        [[ █████  ░░█████    ░░███      ░░█████████  █████   █████ ░░░███████░      ░░███ ░░███     ]],
        [[░░░░░    ░░░░░      ░░░        ░░░░░░░░░  ░░░░░   ░░░░░    ░░░░░░░         ░░░   ░░░      ]],
      }
      dashboard.section.buttons.val = {
        dashboard.button("f", "󰈞  Find file", "<cmd>Telescope find_files<cr>"),
        dashboard.button("r", "󰋚  Recent files", "<cmd>Telescope oldfiles<cr>"),
        dashboard.button("g", "󰈬  Grep text", "<cmd>Telescope live_grep<cr>"),
        dashboard.button("e", "  File tree", "<cmd>NvimTreeToggle<cr>"),
        dashboard.button("c", "  Crow — add things", "<cmd>Crow<cr>"),
        dashboard.button("t", "  Pick theme", "<cmd>Crow theme<cr>"),
        dashboard.button("l", "󰒲  Lazy", "<cmd>Lazy<cr>"),
        dashboard.button("q", "  Quit", "<cmd>qa<cr>"),
      }
      dashboard.section.footer.val = "config that barely requires a thought"
      dashboard.section.header.opts.hl = "Title"
      dashboard.section.footer.opts.hl = "Comment"
      require("alpha").setup(dashboard.config)
      -- lazy.nvim loads us during VimEnter, after which alpha's own
      -- VimEnter autocmd can no longer fire — start explicitly.
      -- (start(true) skips itself when a file was opened directly.)
      if vim.v.vim_did_enter == 1 then
        require("alpha").start(true, dashboard.config)
      end
    end,
  },
}

return R

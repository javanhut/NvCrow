# NvCrow 🐦‍⬛

**The easiest way to add plugins and languages to Neovim — config that barely requires a thought.**

You shouldn't have to think in lazy specs, mason registries, lspconfig
boilerplate, or formatter wiring. With NvCrow you say *what* you want;
it knows *how*.

```lua
-- crow.lua — the only file you ever edit
return {
  theme   = "catppuccin",
  langs   = { "lua", "rust", "python" },
  plugins = { "telescope", "harpoon" },
}
```

That's a complete config. Each language name brings its LSP server,
formatter, treesitter parsers, and companion plugins — pre-wired,
compatible, installed automatically on launch.

## Install

Works on **macOS and Linux**. The installer handles system
dependencies itself — package manager detection (brew / apt / dnf /
pacman / zypper / apk), missing tools, even Neovim 0.11+ if your
distro's is too old.

```sh
git clone <this-repo> ~/Development/NvCrow
cd ~/Development/NvCrow && ./install.sh
nvim
```

First launch bootstraps everything: lazy.nvim, plugins, LSP servers,
formatters, parsers, the tree-sitter CLI. Grab a coffee (≈1 min),
restart once, done.

NvCrow also self-heals at runtime: tools with prebuilt binaries (like
the tree-sitter CLI) download automatically into its own bin dir — no
sudo, no package manager. Anything that genuinely needs your package
manager (a C compiler, ripgrep) triggers a one-keypress install offer
inside Neovim.

## Day-to-day

You never *have* to leave Neovim:

```
:Crow                   opens the picker GUI — Enter toggles, q applies
:Crow add rust          adds rust: rust-analyzer, rustfmt, treesitter, crates.nvim
:Crow add tokyonight    switches theme
:Crow add folke/zen-mode.nvim   any GitHub plugin works too
:Crow remove python
:Crow list              shows your spec + everything available
:Crow sync              re-sync plugins in-session
```

The bare `:Crow` (or `<space>cc`) is the easiest way in: a floating
menu of every language, plugin, and theme with what you have checked
off. Toggle things with Enter, hit q, restart — done.

`:Crow add` updates `crow.lua` for you and offers a restart; on launch
anything missing installs itself. Tab-completion works everywhere.

## What's in the box

**Languages** (LSP + formatter + treesitter + extras, autowired):
`lua` `rust` `python` `go` `typescript` `web` `json` `yaml` `markdown`
`c` `bash` `zig` `java` `php` `docker` `terraform`
— aliases work too (`js`, `py`, `cpp`, `sh`, …).

**Plugin recipes** (pre-configured with keymaps):
`telescope` `harpoon` `oil` `neo-tree` `nvim-tree` `flash` `trouble`
`todo-comments` `surround` `zen-mode` `lazygit` `undotree` `copilot`
`indent-guides` `dashboard` (NvCrow splash screen)

**[Ivaldi VCS](https://github.com/javanhut/Ivaldi), built in:** if the `ivaldi` binary is on your system,
NvCrow lights up automatically — current timeline in the statusline,
`:Ivaldi` (no args opens the TUI dashboard in a float), and keymaps
under `<space>v`: status, log, diff, gather current file, seal with a
message prompt, sync, time travel.

**Themes:** `catppuccin` `tokyonight` `gruvbox` `kanagawa` `rose-pine`
`onedark` `nord` `nightfox`

**Always included:** treesitter highlighting, Mason-managed LSPs,
format-on-save (conform.nvim), completion (blink.cmp), gitsigns,
lualine, which-key, autopairs, indent autodetection, sane defaults
(leader = space, system clipboard, undofile, smart search).

## Key habits

| Keys | Action |
|---|---|
| `<space>ff` / `fg` | find files / grep (telescope) |
| `gd` / `gr` / `K` | definition / references / docs |
| `<space>ca` / `rn` | code action / rename |
| `<space>cf` | format buffer (also on save) |
| `<space>e` | file tree (with neo-tree/nvim-tree) |
| `<space>xx` | diagnostics list (with trouble) |
| `<space>cc` | Crow picker GUI |
| `<space>vv` | Ivaldi TUI dashboard |

`<space>` then wait — which-key shows everything.

## Escape hatches

NvCrow stays out of your way when you want control:

- `plugins = { "user/repo" }` — any GitHub plugin, no recipe needed
- `plugins = { { "user/repo", opts = {...} } }` — full raw lazy.nvim
  specs pass straight through
- `options = { relativenumber = false }` — override any vim option
- `:checkhealth nvcrow` — diagnose your spec

## Why not just NvChad / LazyVim?

They're great — but you still end up writing lazy specs, lspconfig
setup, conform tables, and mason lists by hand, and keeping them
compatible. NvCrow's recipe registry does that wiring for you: one
name per thing you want, zero glue code.

# tree.nvim

Minimal file explorer for Neovim. ~800 lines of Lua.

## Install

```lua
-- lazy.nvim
{ "0ax1/tree.nvim" }
```

## Setup

```lua
require("tree").setup({
  width = 30,     -- sidebar width (default 30)
  icons = false,  -- disable devicons, use text arrows (default true)
  git = false,    -- disable git status markers (default true)
})

vim.keymap.set("n", "<c-n>", "<cmd>Tree<cr>")
```

## Keymaps

| Key | Action |
|-----|--------|
| `<CR>` `o` `l` | Open file / toggle directory |
| `h` | Close directory or go to parent |
| `s` | Open in horizontal split |
| `v` | Open in vertical split |
| `a` | Create file or directory (end name with `/`) |
| `d` | Delete (with confirmation) |
| `r` | Rename |
| `y` `x` `p` | Copy / cut / paste |
| `R` | Refresh |
| `<C-]>` | cd into directory |
| `-` | cd up to parent |
| `q` | Close tree |

## Features

- Async git status via `git status --porcelain`
- Filesystem watching via libuv (debounced, per expanded directory)
- Auto-reveal: tree follows the current buffer
- Optional nvim-web-devicons support

## Highlights

All highlight groups can be overridden:

| Group | Default link | Used for |
|-------|-------------|----------|
| `TreeNormal` | `Comment` | All tree text |
| `TreeGitModified` | `WarningMsg` | Modified files |
| `TreeGitAdded` | `DiffAdd` | Added files |
| `TreeGitDeleted` | `DiffDelete` | Deleted files |
| `TreeGitUntracked` | `Comment` | Untracked files |

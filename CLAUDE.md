# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

pj.nvim is a Neovim plugin for fast project discovery and navigation using the [pj](https://github.com/josephschmitt/pj) binary. It provides a pluggable picker architecture supporting multiple UI frameworks (Snacks, Telescope, fzf-lua, television, mini.pick).

## Development Commands

There is no formal test suite or build system. Testing is done manually:

```bash
# Run health check inside Neovim
:checkhealth pj

# Test the plugin
:Pj
:Pj depth=2
:PjCd
```

## Architecture

### Entry Points
- `plugin/pj.lua` - Registers user commands (`:Pj`, `:PjCd`, `:PjCheckUpdates`, etc.) and parses command arguments
- `lua/pj/init.lua` - Main module with `setup()`, `open()`, and `cd()` APIs

### Core Modules
- `lua/pj/config.lua` - Configuration defaults and deep-merge setup
- `lua/pj/binary.lua` - Auto-download, version checking, platform detection for the pj binary
- `lua/pj/finder.lua` - Executes pj binary, parses output (text or JSON mode)
- `lua/pj/session.lua` - Integrates with auto-session or persistence.nvim
- `lua/pj/depth.lua` - State machine for project tree search depth control
- `lua/pj/icons.lua` - Maps project markers to filetypes for icon lookup

### Picker Architecture
All pickers in `lua/pj/pickers/` implement the same interface: an `open(opts)` function that:
1. Fetches projects via `finder.get_projects()`
2. Displays the picker UI
3. Handles actions (open, split, vsplit, tab, depth control)

- `pickers/init.lua` - Registry and selector for configured picker
- `pickers/snacks.lua` - Snacks.nvim (default)
- `pickers/telescope.lua` - Telescope.nvim
- `pickers/fzf_lua.lua` - fzf-lua
- `pickers/tv.lua` - Television binary
- `pickers/mini.lua` - mini.pick

### Data Flow
```
User Command (:Pj)
  → plugin/pj.lua (parse args)
  → lua/pj/init.lua (binary check, async download if needed)
  → lua/pj/pickers/init.lua (select configured picker)
  → Picker implementation (fetch projects via finder, display UI)
  → On selection: session.lua (load session) or direct cd
```

## Key Patterns

- **Module pattern**: All files export `local M = {}; return M`
- **Configuration**: Deep-merged via `vim.tbl_deep_extend("force", defaults, opts)`
- **Async operations**: Use `vim.fn.jobstart()` for non-blocking binary downloads
- **Safe library loading**: Use `pcall()` when checking for optional dependencies
- **Callbacks**: Binary download and updates use callback-based async patterns

## Adding a New Picker

1. Create `lua/pj/pickers/newpicker.lua`
2. Implement `M.open(opts)` function
3. Add to registry in `pickers/init.lua`
4. Add picker-specific config defaults in `config.lua`

## Auto-Downloaded Binary Location

`~/.local/share/nvim/pj-nvim/bin/pj` with metadata stored alongside

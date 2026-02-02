# pj.nvim

![image](https://github.com/user-attachments/assets/7cf1d085-5604-48b6-8e56-33bd0a78dbde)

A Neovim plugin for quickly finding and navigating to projects using [pj](https://github.com/josephschmitt/pj).

## Features

- 🚀 Fast project discovery using the pj binary
- 🎨 Multiple picker UIs: **Snacks**, **Telescope**, **fzf-lua**, **tv (television)**, **mini.pick**
- 🔍 Fuzzy search through your projects
- 📁 Instantly switch to project directories
- 💾 Leverages pj's intelligent caching
- 🎯 Icon support with Nerd Fonts
- ⌨️ Consistent keybindings across all pickers
- 🪟 Split, vsplit, and tab support
- 🗂️ Tab-local directory changing (matches Snacks behavior)
- 💼 Optional session manager integration (auto-session, persistence.nvim)
- 🔧 Extensible architecture for adding more pickers
- 📦 **Automatic pj binary installation** - Downloads the correct binary for your platform
- 🔄 **Automatic updates** - Keeps the pj binary up to date automatically

## Requirements

**Core:**
- Neovim >= 0.9.0
- `curl` - For automatic binary download (optional if pj is installed manually)

**pj Binary:**
The [pj](https://github.com/josephschmitt/pj) binary is **automatically downloaded** on first use. No manual installation required! The plugin detects your platform (macOS, Linux, or Windows) and architecture (Intel or ARM) and downloads the appropriate binary.

**Important:** If you have pj installed globally (in your PATH), it will be used instead of the auto-downloaded version. The plugin prefers system binaries by default (configurable via `prefer_system` option).

If you prefer to install pj manually, see [Manual pj Installation](#manual-pj-installation).

**Picker UI (choose one or more):**
- [Snacks.nvim](https://github.com/folke/snacks.nvim) - For `snacks` picker (default)
- [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - For `telescope` picker
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) - For `fzf_lua` picker
- [television](https://github.com/alexpasmantier/television) - For `tv` picker
- [mini.pick](https://github.com/nvim-mini/mini.pick) or [mini.nvim](https://github.com/nvim-mini/mini.nvim) - For `mini.pick` picker

**Optional:**
- [Nerd Fonts](https://www.nerdfonts.com/) - For icon display
- [auto-session](https://github.com/rmagatti/auto-session) - For session management
- [persistence.nvim](https://github.com/folke/persistence.nvim) - Alternative session manager

## Installation

### With Snacks (default picker)

```lua
-- Using lazy.nvim
{
  "josephschmitt/pj.nvim",
  dependencies = {
    "folke/snacks.nvim",
  },
  cmd = { "Pj", "PjCd" },
  keys = {
    { "<leader>fp", "<cmd>Pj<cr>", desc = "Find Projects" },
  },
  opts = {},
}
```

### With Telescope

```lua
-- Using lazy.nvim
{
  "josephschmitt/pj.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  cmd = { "Pj", "PjCd" },
  keys = {
    { "<leader>fp", "<cmd>Pj<cr>", desc = "Find Projects" },
  },
  opts = {
    picker = { type = "telescope" },
  },
}
```

### With fzf-lua

```lua
-- Using lazy.nvim
{
  "josephschmitt/pj.nvim",
  dependencies = {
    "ibhagwan/fzf-lua",
  },
  cmd = { "Pj", "PjCd" },
  keys = {
    { "<leader>fp", "<cmd>Pj<cr>", desc = "Find Projects" },
  },
  opts = {
    picker = { type = "fzf_lua" },
  },
}
```

### With television

```lua
-- Using lazy.nvim
{
  "josephschmitt/pj.nvim",
  cmd = { "Pj", "PjCd" },
  keys = {
    { "<leader>fp", "<cmd>Pj<cr>", desc = "Find Projects" },
  },
  opts = {
    picker = { type = "tv" },
  },
}
```

**Note:** The `tv` picker requires the [television](https://github.com/alexpasmantier/television) binary to be installed. It does not require tv.nvim.

### With mini.pick

```lua
-- Using lazy.nvim
{
  "josephschmitt/pj.nvim",
  dependencies = {
    "nvim-mini/mini.pick", -- or "nvim-mini/mini.nvim"
  },
  cmd = { "Pj", "PjCd" },
  keys = {
    { "<leader>fp", "<cmd>Pj<cr>", desc = "Find Projects" },
  },
  opts = {
    picker = { type = "mini.pick" },
  },
}
```

### With All Pickers (for flexibility)

```lua
-- Using lazy.nvim
{
  "josephschmitt/pj.nvim",
  dependencies = {
    "folke/snacks.nvim",
    "nvim-telescope/telescope.nvim",
    "ibhagwan/fzf-lua",
    "nvim-mini/mini.pick",
  },
  cmd = { "Pj", "PjCd" },
  keys = {
    { "<leader>fp", "<cmd>Pj<cr>", desc = "Find Projects" },
  },
  opts = {
    -- You can switch between pickers anytime by changing the type
    picker = { type = "snacks" }, -- or "telescope", "fzf_lua", "tv", or "mini.pick"
  },
}
```

## Configuration

### Default Configuration

```lua
require("pj").setup({
  -- pj binary settings
  pj = {
    cmd = "auto",                  -- "auto" (default), "pj", or "/path/to/pj"
    args = {},                     -- Additional arguments to pass to pj
    icons = true,                  -- Use icons in the picker
    cache = true,                  -- Use pj's built-in cache
    -- Auto-download settings (used when cmd = "auto")
    auto = {
      prefer_system = true,        -- Use system binary if available (default: true)
      check_updates = true,        -- Check for newer versions periodically
      auto_update = true,          -- Automatically install updates when found
      update_interval = 7,         -- Days between update checks
      github_repo = "josephschmitt/pj", -- GitHub repo for releases
    },
  },

  -- Picker settings
  picker = {
    type = "snacks",               -- Picker type: "snacks", "telescope", "fzf_lua", "tv", or "mini.pick"

    -- fzf-lua specific settings
    fzf_lua = {
      winopts = {
        height = 0.85,
        width = 0.80,
      },
      preview = {
        enabled = false,           -- Enable preview window
        cmd = "ls -la",            -- Command to show preview
      },
    },

    -- telescope specific settings
    telescope = {
      theme = nil,                 -- "dropdown", "ivy", "cursor", or nil for default
      layout_config = {
        width = 0.8,
        height = 0.9,
      },
      previewer = false,           -- Enable file previewer
    },

    -- tv (television) specific settings
    tv = {
      tv_binary = "tv",            -- Path to tv binary
      preview = {
        enabled = false,           -- Enable preview window
        cmd = "ls -la {}",         -- Preview command (use {} as placeholder)
        size = 50,                 -- Preview window size percentage
      },
    },
  },

  -- Behavior settings
  behavior = {
    cd_on_select = true,           -- Change directory when selecting a project
    cd_scope = "tab",              -- "tab" (tcd) or "global" (cd)
    close_on_select = true,        -- Close picker after selection
    notify_on_error = true,        -- Show error notifications
    session_manager = nil,         -- nil, "auto-session", or "persistence"
  },

  -- Keymaps (within the picker)
  keymaps = {
    open = "<CR>",                 -- Open project
    split = "<C-x>",               -- Open in horizontal split
    vsplit = "<C-v>",              -- Open in vertical split
    tab = "<C-t>",                 -- Open in new tab
    depth_increase = "<C-l>",      -- Increase search depth
    depth_decrease = "<C-h>",      -- Decrease search depth
  },

  -- Depth settings for project tree display
  depth = {
    initial = nil,                 -- Starting depth (nil = use pj's default of 3)
    min = 1,                       -- Minimum depth
    max = 10,                      -- Maximum depth
  },
})
```

### Session Management Integration

pj.nvim can integrate with session manager plugins to automatically restore your workspace when switching projects. This matches the behavior of Snacks' projects picker.

#### With auto-session

```lua
require("pj").setup({
  behavior = {
    session_manager = "auto-session",
    cd_scope = "tab",  -- Recommended with session managers
  },
})
```

#### With persistence.nvim

```lua
require("pj").setup({
  behavior = {
    session_manager = "persistence",
    cd_scope = "tab",
  },
})
```

When a session manager is configured:
- Selecting a project will try to restore its session
- If no session exists, it just changes the directory
- Open buffers are closed/restored based on the session
- Your workspace state (windows, buffers, etc.) is preserved per-project

#### Simple directory change (no sessions)

```lua
require("pj").setup({
  behavior = {
    session_manager = nil,  -- Disable session management
    cd_scope = "global",     -- Use global cd instead of tcd
  },
})
```

This simpler mode just changes the working directory without affecting buffers.

### Picker-Specific Configuration

#### Using Telescope with dropdown theme

```lua
require("pj").setup({
  picker = {
    type = "telescope",
    telescope = {
      theme = "dropdown",
      previewer = true,
      layout_config = {
        width = 0.9,
        height = 0.8,
      },
    },
  },
})
```

#### Using fzf-lua with preview

```lua
require("pj").setup({
  picker = {
    type = "fzf_lua",
    fzf_lua = {
      winopts = {
        height = 0.9,
        width = 0.9,
        preview = {
          layout = "vertical",
          vertical = "up:45%",
        },
      },
      preview = {
        enabled = true,
        cmd = "tree -C -L 2",
      },
    },
  },
})
```

#### Using television with preview

```lua
require("pj").setup({
  picker = {
    type = "tv",
    tv = {
      preview = {
        enabled = true,
        cmd = "tree -C -L 2 {}",
        size = 70,
      },
    },
  },
})
```

#### Using mini.pick with custom window

```lua
require("pj").setup({
  picker = {
    type = "mini.pick",
    mini = {
      window = {
        config = {
          width = 80,
          height = 20,
        },
      },
    },
  },
})
```

#### Custom pj configuration

```lua
require("pj").setup({
  pj = {
    args = { "--path", "~/work", "--path", "~/personal" },
    icons = true,
  },
  picker = {
    type = "telescope", -- Use your preferred picker
  },
})
```

#### Disable automatic directory change

```lua
require("pj").setup({
  behavior = {
    cd_on_select = false,
  },
})
```

#### Use a specific pj binary

```lua
-- Use system pj (must be in PATH)
require("pj").setup({
  pj = { cmd = "pj" },
})

-- Or specify exact path
require("pj").setup({
  pj = { cmd = "/usr/local/bin/pj" },
})
```

#### Disable auto-download (require manual installation)

```lua
require("pj").setup({
  pj = {
    cmd = "pj",  -- Will error if pj is not in PATH
  },
})
```

## Usage

### Commands

- `:Pj` - Open the project picker
- `:Pj depth=N` - Open picker at specific depth (e.g., `:Pj depth=2`)
- `:PjCd` - Open picker (alias for changing directory)
- `:PjCheckUpdates` - Check for pj binary updates
- `:PjUpdate` - Update pj binary to latest version
- `:PjReinstall` - Force reinstall pj binary (for troubleshooting)
- `:PjUninstall` - Remove auto-downloaded pj binary

### Keymaps

The plugin doesn't set any global keymaps by default. Add your own:

```lua
vim.keymap.set("n", "<leader>fp", "<cmd>Pj<cr>", { desc = "Find Projects" })
vim.keymap.set("n", "<leader>fP", "<cmd>PjCd<cr>", { desc = "Change to Project" })
```

### Lua API

```lua
-- Open the picker
require("pj").open()

-- Open with runtime options
require("pj").open({ no_cache = true })

-- Change directory only
require("pj").cd()
```

## How It Works

1. **Project Discovery**: The plugin calls the `pj` binary to discover projects in your configured directories
2. **Caching**: pj uses intelligent caching to make subsequent searches nearly instant
3. **Fuzzy Search**: Snacks.nvim provides a beautiful picker UI with fuzzy search
4. **Navigation**: Selecting a project changes Neovim's working directory to that project

## Health Check

Run `:checkhealth pj` to verify your installation and configuration.

The health check will verify:
- pj binary status (auto-download mode, system binary, or custom path)
- Platform detection and compatibility
- Your configured picker is available (Snacks/Telescope/fzf-lua/tv/mini.pick)
- Configuration is valid
- Projects can be discovered
- Show all available pickers and their status

## Troubleshooting

### Binary Priority

When `pj.cmd = "auto"` (the default), the plugin uses binaries in this order:
1. **System binary** - If pj is found in your PATH (when `prefer_system = true`)
2. **Auto-downloaded binary** - Falls back to cached binary if no system binary found
3. **Auto-download** - Downloads binary on first use if neither exists

This means if you install pj globally later, it will automatically be used instead of the auto-downloaded version.

### "pj binary not found"

By default, pj.nvim automatically downloads the pj binary on first use. If auto-download fails:

1. **Check curl is installed** - Required for downloading
2. **Check your internet connection**
3. **Run `:checkhealth pj`** - Shows detailed status and troubleshooting info

You can also manually trigger a download:
```lua
:lua require('pj.binary').ensure_binary()
```

### Manual pj Installation

If you prefer to install pj manually instead of using auto-download:

```bash
# Using Go
go install github.com/josephschmitt/pj@latest

# Or download from GitHub releases
# https://github.com/josephschmitt/pj/releases
```

Then configure pj.nvim to use the system binary:
```lua
require("pj").setup({
  pj = { cmd = "pj" }  -- Use system binary instead of auto-download
})
```

Or specify a custom path:
```lua
require("pj").setup({
  pj = { cmd = "/path/to/pj" }
})
```

### Picker not found errors

If you get errors about missing picker dependencies:

**For Snacks picker:**
```lua
-- Make sure snacks.nvim is installed
{
  "folke/snacks.nvim",
  -- your snacks config
}
```

**For Telescope picker:**
```lua
-- Make sure telescope is installed
{
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" }
}
```

**For fzf-lua picker:**
```lua
-- Make sure fzf-lua is installed
{
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" } -- optional for icons
}
```

**For tv picker:**
```bash
# Install television binary (choose one method)

# macOS (Homebrew)
brew install television

# Cargo (Rust)
cargo install television

# Or download from: https://github.com/alexpasmantier/television/releases
```

**For mini.pick picker:**
```lua
-- Make sure mini.pick is installed
{
  "nvim-mini/mini.pick",
  -- or use the full mini.nvim if you want other mini modules
  -- "nvim-mini/mini.nvim",
}
```

### Switching between pickers

You can easily switch pickers by changing the configuration:

```lua
require("pj").setup({
  picker = {
    type = "telescope", -- Change to "snacks", "telescope", "fzf_lua", "tv", or "mini.pick"
  },
})
```

### "No projects found"

Check your pj configuration at `~/.config/pj/config.yaml`:

```yaml
search_paths:
  - ~/projects
  - ~/code
  - ~/development

markers:
  - .git
  - go.mod
  - package.json
```

Run `pj` in your terminal to verify it's working correctly.

### Icons not showing

Make sure you have a Nerd Font installed and configured in your terminal.

## Future Enhancements

- [x] Support for Telescope picker
- [x] Support for FZF picker
- [x] Support for television picker
- [x] Automatic pj binary installation
- [x] Automatic pj binary updates
- [ ] Custom project actions
- [ ] Recent projects tracking
- [ ] Project-specific configurations

## Development

### Running Tests

The plugin uses [mini.test](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-test.md) for testing.

```bash
# Install test dependencies
make deps

# Run all tests
make test

# Run a specific test file
make test-file FILE=tests/unit/depth_spec.lua
```

### Test Structure

```
tests/
├── init.lua              # Test runner entry point
├── helpers.lua           # Shared test utilities and mocks
├── minimal_init.lua      # Minimal Neovim config for tests
├── unit/                 # Unit tests
│   ├── config_spec.lua   # Configuration tests
│   ├── depth_spec.lua    # Depth state machine tests
│   ├── finder_spec.lua   # Parser function tests
│   ├── icons_spec.lua    # Icon lookup tests
│   ├── session_spec.lua  # Session/directory switching tests
│   └── utils_spec.lua    # Utility function tests
└── fixtures/             # Test data
    ├── projects.json     # Sample JSON output from pj
    ├── projects.txt      # Sample text output with icons
    └── projects_no_icons.txt
```

### Git Hooks

This project uses [lefthook](https://github.com/evilmartians/lefthook) for pre-push hooks to run tests automatically.

```bash
# Install lefthook (choose one)
brew install lefthook
# or: npm install -g lefthook
# or: go install github.com/evilmartians/lefthook@latest

# Enable hooks for this repo
lefthook install
```

Once installed, tests will run automatically before each `git push`.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

Before submitting, please ensure tests pass:
```bash
make test
```

## License

MIT

## Related Projects

- [pj](https://github.com/josephschmitt/pj) - The underlying project finder
- [Snacks.nvim](https://github.com/folke/snacks.nvim) - The picker UI framework

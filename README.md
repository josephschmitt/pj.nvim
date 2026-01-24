# pj.nvim

A Neovim plugin for quickly finding and navigating to projects using [pj](https://github.com/jschaf/pj).

## Features

- 🚀 Fast project discovery using the pj binary
- 🎨 Multiple picker UIs: **Snacks**, **Telescope**, **fzf-lua**
- 🔍 Fuzzy search through your projects
- 📁 Instantly switch to project directories
- 💾 Leverages pj's intelligent caching
- 🎯 Icon support with Nerd Fonts
- ⌨️ Consistent keybindings across all pickers
- 🪟 Split, vsplit, and tab support
- 🗂️ Tab-local directory changing (matches Snacks behavior)
- 💼 Optional session manager integration (auto-session, persistence.nvim)
- 🔧 Extensible architecture for adding more pickers

## Requirements

**Core:**
- Neovim >= 0.9.0
- [pj](https://github.com/jschaf/pj) - Project finder binary

**Picker UI (choose one or more):**
- [Snacks.nvim](https://github.com/folke/snacks.nvim) - For `snacks` picker (default)
- [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - For `telescope` picker
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) - For `fzf_lua` picker

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

### With All Pickers (for flexibility)

```lua
-- Using lazy.nvim
{
  "josephschmitt/pj.nvim",
  dependencies = {
    "folke/snacks.nvim",
    "nvim-telescope/telescope.nvim",
    "ibhagwan/fzf-lua",
  },
  cmd = { "Pj", "PjCd" },
  keys = {
    { "<leader>fp", "<cmd>Pj<cr>", desc = "Find Projects" },
  },
  opts = {
    -- You can switch between pickers anytime by changing the type
    picker = { type = "snacks" }, -- or "telescope" or "fzf_lua"
  },
}
```

## Configuration

### Default Configuration

```lua
require("pj").setup({
  -- pj binary settings
  pj = {
    cmd = "pj",                    -- Path to pj binary
    args = {},                     -- Additional arguments to pass to pj
    icons = true,                  -- Use icons in the picker
    cache = true,                  -- Use pj's built-in cache
  },

  -- Picker settings
  picker = {
    type = "snacks",               -- Picker type: "snacks", "telescope", or "fzf_lua"
    prompt = "PJ Projects> ",      -- Picker prompt text

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

#### Use a custom pj binary path

```lua
require("pj").setup({
  pj = {
    cmd = "/usr/local/bin/pj",
  },
})
```

## Usage

### Commands

- `:Pj` - Open the project picker
- `:PjCd` - Open picker (alias for changing directory)

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
- pj binary is installed and accessible
- Your configured picker is available (Snacks/Telescope/fzf-lua)
- Configuration is valid
- Projects can be discovered
- Show all available pickers and their status

## Troubleshooting

### "pj binary not found"

Make sure the pj binary is installed and in your PATH:

```bash
# Install pj
go install github.com/jschaf/pj@latest

# Or specify custom path in config
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

### Switching between pickers

You can easily switch pickers by changing the configuration:

```lua
require("pj").setup({
  picker = {
    type = "telescope", -- Change to "snacks", "telescope", or "fzf_lua"
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

- [ ] Support for Telescope picker
- [ ] Support for FZF picker
- [ ] Custom project actions
- [ ] Recent projects tracking
- [ ] Project-specific configurations

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT

## Related Projects

- [pj](https://github.com/jschaf/pj) - The underlying project finder
- [Snacks.nvim](https://github.com/folke/snacks.nvim) - The picker UI framework

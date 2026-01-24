# pj.nvim

A Neovim plugin for quickly finding and navigating to projects using [pj](https://github.com/jschaf/pj).

## Features

- 🚀 Fast project discovery using the pj binary
- 🎨 Beautiful picker UI with Snacks.nvim
- 🔍 Fuzzy search through your projects
- 📁 Instantly switch to project directories
- 💾 Leverages pj's intelligent caching
- 🎯 Icon support with Nerd Fonts
- 🔧 Extensible architecture for future picker support (Telescope, FZF)

## Requirements

- Neovim >= 0.9.0
- [pj](https://github.com/jschaf/pj) - Project finder binary
- [Snacks.nvim](https://github.com/folke/snacks.nvim) - Picker UI
- [Nerd Fonts](https://www.nerdfonts.com/) (optional, for icons)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "yourusername/pj.nvim",
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

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "yourusername/pj.nvim",
  requires = {
    "folke/snacks.nvim",
  },
  config = function()
    require("pj").setup()
  end
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
    type = "snacks",               -- Picker type (currently only "snacks")
    prompt = "Projects> ",         -- Picker prompt text
  },

  -- Behavior settings
  behavior = {
    cd_on_select = true,           -- Change directory when selecting a project
    close_on_select = true,        -- Close picker after selection
    notify_on_error = true,        -- Show error notifications
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

### Custom Configuration Examples

#### Using custom pj configuration

```lua
require("pj").setup({
  pj = {
    args = { "--path", "~/work", "--path", "~/personal" },
    icons = true,
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
- Snacks.nvim is available
- Configuration is valid
- Projects can be discovered

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

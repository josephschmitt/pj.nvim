local M = {}

M.defaults = {
  -- pj binary settings
  pj = {
    cmd = "auto", -- "auto", "pj", or "/path/to/pj"
    args = {},
    icons = true,
    cache = true,
    json = true,
    -- Auto-download settings (used when cmd = "auto")
    auto = {
      prefer_system = true, -- Use system binary if available
      check_updates = true, -- Check for newer versions periodically
      auto_update = true, -- Automatically install updates when found
      update_interval = 7, -- Days between update checks
      github_repo = "josephschmitt/pj", -- GitHub repo for releases
    },
  },

  -- Picker settings
  picker = {
    type = "snacks",

    -- fzf-lua specific settings
    fzf_lua = {
      winopts = {
        height = 0.85,
        width = 0.80,
      },
      preview = {
        enabled = false,
        cmd = "ls -la",
      },
    },

    -- telescope specific settings
    telescope = {
      theme = nil, -- "dropdown", "ivy", "cursor", or nil for default
      layout_config = {
        width = 0.8,
        height = 0.9,
      },
      previewer = false,
    },

    -- tv specific settings
    tv = {
      tv_binary = "tv", -- Path to tv binary
      preview = {
        enabled = false,
        cmd = "ls -la {}", -- Preview command (use {} as placeholder)
        size = 50, -- Preview window size percentage
      },
    },

    -- mini.pick specific settings
    mini = {
      window = {}, -- Window config overrides (passed to MiniPick.start)
      show = nil, -- Custom show function (nil uses built-in pj_show)
    },
  },

  -- Behavior settings
  behavior = {
    cd_on_select = true,
    cd_scope = "tab", -- "global" or "tab" (uses tcd for tab-local, cd for global)
    close_on_select = true,
    notify_on_error = true,
    session_manager = nil, -- nil, "auto-session", or "persistence"
  },

  -- Keymaps
  keymaps = {
    open = "<CR>",
    split = "<C-x>",
    vsplit = "<C-v>",
    tab = "<C-t>",
    depth_increase = "<C-l>", -- Increase depth (show more nested projects)
    depth_decrease = "<C-h>", -- Decrease depth (show fewer nested projects)
  },

  -- Depth settings for project tree display
  depth = {
    initial = nil, -- nil means use pj's default
    min = 1,
    max = 10,
  },
}

M.options = {}

M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})

  -- Initialize depth module with config
  local depth = require("pj.depth")
  depth.setup(M.options)

  return M.options
end

return M

local M = {}

M.defaults = {
  -- pj binary settings
  pj = {
    cmd = "pj",
    args = {},
    icons = true,
    cache = true,
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
  },
}

M.options = {}

M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  return M.options
end

return M

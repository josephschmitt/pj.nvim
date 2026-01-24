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
    prompt = "Projects> ",
  },

  -- Behavior settings
  behavior = {
    cd_on_select = true,
    close_on_select = true,
    notify_on_error = true,
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

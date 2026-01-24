local M = {}

-- Registry of available pickers
M.pickers = {
  snacks = function()
    return require("pj.pickers.snacks")
  end,
  -- Future: telescope, fzf, etc.
}

-- Get the configured picker
M.get = function()
  local config = require("pj.config").options
  local picker_type = config.picker.type

  if not M.pickers[picker_type] then
    vim.notify("Unknown picker type: " .. picker_type, vim.log.levels.ERROR)
    return nil
  end

  return M.pickers[picker_type]()
end

return M

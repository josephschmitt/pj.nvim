local M = {}

M.setup = function(opts)
  require("pj.config").setup(opts)
end

M.open = function(opts)
  opts = opts or {}
  local pickers = require("pj.pickers")
  local picker = pickers.get()

  if not picker then
    return
  end

  picker.open(opts)
end

M.cd = function(opts)
  opts = opts or {}
  opts.cd_only = true
  M.open(opts)
end

return M

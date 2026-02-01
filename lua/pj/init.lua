local M = {}

M.setup = function(opts)
  require("pj.config").setup(opts)

  -- Initialize binary manager if in auto mode
  local config = require("pj.config").options
  if config.pj.cmd == "auto" then
    -- Schedule async binary check/download to avoid blocking startup
    vim.schedule(function()
      local binary = require("pj.binary")
      -- Just check status, don't trigger download yet
      -- Download will happen on first use if needed
      local status = binary.get_status()
      if status.active_binary == "none" and config.behavior.notify_on_error then
        vim.notify(
          "pj binary will be downloaded on first use. Run :checkhealth pj for details.",
          vim.log.levels.INFO
        )
      end
    end)
  end
end

M.open = function(opts)
  opts = opts or {}
  local config = require("pj.config").options
  local finder = require("pj.finder")

  -- In auto mode, ensure binary is available before opening picker
  if config.pj.cmd == "auto" and not finder.check_binary() then
    vim.notify("Downloading pj binary...", vim.log.levels.INFO)
    finder.ensure_binary(function(success, err)
      if success then
        vim.schedule(function()
          M._do_open(opts)
        end)
      else
        vim.schedule(function()
          vim.notify("Failed to get pj binary: " .. (err or "unknown error"), vim.log.levels.ERROR)
        end)
      end
    end)
    return
  end

  M._do_open(opts)
end

M._do_open = function(opts)
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

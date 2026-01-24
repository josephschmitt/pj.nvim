local M = {}

M.check = function()
  local health = vim.health or require("health")
  local config = require("pj.config").options
  local finder = require("pj.finder")

  health.start("pj.nvim")

  -- Check pj binary
  if finder.check_binary() then
    health.ok("pj binary found: " .. config.pj.cmd)

    -- Try to get version
    local version = vim.fn.system(config.pj.cmd .. " --version 2>&1")
    if vim.v.shell_error == 0 then
      health.info("pj version: " .. vim.trim(version))
    end
  else
    health.error("pj binary not found", {
      "Install pj from: https://github.com/jschaf/pj",
      "Or configure custom path in setup(): require('pj').setup({ pj = { cmd = '/path/to/pj' } })",
    })
  end

  -- Check picker availability
  local picker_type = config.picker.type
  if picker_type == "snacks" then
    local ok = pcall(require, "snacks")
    if ok then
      health.ok("Snacks.nvim found")
    else
      health.error("Snacks.nvim not found", {
        "Install folke/snacks.nvim",
        "Add to your plugin manager: 'folke/snacks.nvim'",
      })
    end
  end

  -- Check configuration
  health.start("Configuration")
  health.info("Picker type: " .. picker_type)
  health.info("Icons enabled: " .. tostring(config.pj.icons))
  health.info("Cache enabled: " .. tostring(config.pj.cache))
  health.info("Change directory on select: " .. tostring(config.behavior.cd_on_select))

  -- Check if we can run pj successfully
  health.start("Runtime Check")
  if finder.check_binary() then
    local projects, err = finder.get_projects({ no_cache = true })
    if err then
      health.warn("Failed to get projects: " .. err)
    elseif projects and #projects > 0 then
      health.ok("Successfully found " .. #projects .. " project(s)")
    else
      health.warn("No projects found. Check your pj configuration at ~/.config/pj/config.yaml")
    end
  end
end

return M

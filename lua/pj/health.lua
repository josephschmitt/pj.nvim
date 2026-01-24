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
  health.start("Picker Dependencies")

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
  elseif picker_type == "fzf_lua" then
    local ok = pcall(require, "fzf-lua")
    if ok then
      health.ok("fzf-lua found")
    else
      health.error("fzf-lua not found", {
        "Install ibhagwan/fzf-lua",
        "Add to your plugin manager: 'ibhagwan/fzf-lua'",
      })
    end
  elseif picker_type == "telescope" then
    local ok = pcall(require, "telescope")
    if ok then
      health.ok("Telescope found")
      -- Check for optional telescope extensions
      local entry_display_ok = pcall(require, "telescope.pickers.entry_display")
      if entry_display_ok then
        health.ok("Telescope entry_display available (enhanced UI)")
      else
        health.warn("Telescope entry_display not available (fallback to simple display)")
      end
    else
      health.error("Telescope not found", {
        "Install nvim-telescope/telescope.nvim",
        "Add to your plugin manager: 'nvim-telescope/telescope.nvim'",
      })
    end
  else
    health.error("Unknown picker type: " .. picker_type, {
      "Supported picker types: snacks, fzf_lua, telescope",
      "Change picker.type in your configuration",
    })
  end

  -- Show available pickers
  health.info("Available picker types:")
  local pickers = require("pj.pickers")
  for name, _ in pairs(pickers.pickers) do
    local dep_ok = false
    if name == "snacks" then
      dep_ok = pcall(require, "snacks")
    elseif name == "fzf_lua" then
      dep_ok = pcall(require, "fzf-lua")
    elseif name == "telescope" then
      dep_ok = pcall(require, "telescope")
    end

    local status = dep_ok and "✓" or "✗"
    health.info("  " .. status .. " " .. name)
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

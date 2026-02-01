local M = {}

M.check = function()
  local health = vim.health or require("health")
  local config = require("pj.config").options
  local finder = require("pj.finder")

  health.start("pj.nvim")

  -- Check pj binary
  if config.pj.cmd == "auto" then
    -- Auto mode - show detailed status
    local binary = require("pj.binary")
    local status = binary.get_status()
    local platform_info = binary.get_platform_info()

    health.info("Mode: auto-download")
    health.info("Platform: " .. (platform_info.os or "unknown") .. "_" .. (platform_info.arch or "unknown"))

    if not platform_info.supported then
      health.error("Platform not supported: " .. (platform_info.error or "unknown error"), {
        "Auto-download supports: macOS (Intel/ARM), Linux (x64/ARM), Windows (x64/ARM)",
        "Install pj manually from: https://github.com/josephschmitt/pj",
      })
    elseif status.active_binary == "system" then
      health.ok("Using system pj binary")
      local version = vim.fn.system("pj --version 2>&1")
      if vim.v.shell_error == 0 then
        health.info("pj version: " .. vim.trim(version))
      end
    elseif status.active_binary == "cached" then
      health.ok("Using auto-downloaded pj binary")
      health.info("Binary path: " .. status.cached_path)
      if status.version then
        health.info("pj version: " .. status.version)
      end
      if status.installed_at then
        health.info("Installed: " .. status.installed_at)
      end
    else
      health.warn("pj binary not yet downloaded", {
        "Binary will be downloaded automatically on first use",
        "Or run :lua require('pj.binary').ensure_binary()",
        "Requires curl to be installed",
      })
      if vim.fn.executable("curl") ~= 1 then
        health.error("curl not found (required for auto-download)", {
          "Install curl or set pj.cmd to a specific path",
        })
      end
    end

    -- Show auto-download settings
    local auto_config = config.pj.auto or {}
    health.info("Prefer system binary: " .. tostring(auto_config.prefer_system ~= false))
    health.info("Check for updates: " .. tostring(auto_config.check_updates ~= false))
    health.info("Auto-update: " .. tostring(auto_config.auto_update ~= false))
    health.info("Update interval: " .. tostring(auto_config.update_interval or 7) .. " days")
    if status.last_check then
      health.info("Last update check: " .. status.last_check)
    end
    if status.system_available then
      health.info("System binary available: yes")
    end
    if status.cached_available then
      health.info("Cached binary available: yes")
    end
  elseif finder.check_binary() then
    health.ok("pj binary found: " .. config.pj.cmd)

    -- Try to get version
    local version = vim.fn.system(config.pj.cmd .. " --version 2>&1")
    if vim.v.shell_error == 0 then
      health.info("pj version: " .. vim.trim(version))
    end
  else
    health.error("pj binary not found", {
      "Install pj from: https://github.com/josephschmitt/pj",
      "Or configure custom path in setup(): require('pj').setup({ pj = { cmd = '/path/to/pj' } })",
      "Or use auto-download: require('pj').setup({ pj = { cmd = 'auto' } })",
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
  elseif picker_type == "tv" then
    -- Check for television binary
    local tv_binary = config.picker.tv and config.picker.tv.tv_binary or "tv"
    local tv_found = vim.fn.executable(tv_binary) == 1
    if tv_found then
      health.ok("television binary found: " .. tv_binary)
      -- Try to get version
      local version = vim.fn.system(tv_binary .. " --version 2>&1")
      if vim.v.shell_error == 0 then
        health.info("television version: " .. vim.trim(version))
      end
    else
      health.error("television binary not found", {
        "Install television from: https://github.com/alexpasmantier/television",
        "Or configure custom path in setup(): require('pj').setup({ picker = { tv = { tv_binary = '/path/to/tv' } } })",
      })
    end
  elseif picker_type == "mini" then
    local ok = pcall(require, "mini.pick")
    if ok then
      health.ok("mini.pick found")
    else
      health.error("mini.pick not found", {
        "Install nvim-mini/mini.pick or nvim-mini/mini.nvim",
        "Add to your plugin manager: 'nvim-mini/mini.pick' or 'nvim-mini/mini.nvim'",
      })
    end
  else
    health.error("Unknown picker type: " .. picker_type, {
      "Supported picker types: snacks, fzf_lua, telescope, tv, mini",
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
    elseif name == "tv" then
      local tv_binary = config.picker.tv and config.picker.tv.tv_binary or "tv"
      dep_ok = vim.fn.executable(tv_binary) == 1
    elseif name == "mini" then
      dep_ok = pcall(require, "mini.pick")
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

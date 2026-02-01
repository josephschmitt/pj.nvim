local M = {}

local depth_module = require("pj.depth")

-- Get picker title with depth indicator
local function get_title()
  return string.format("PJ Projects (%s)", depth_module.get_display())
end

-- Custom format function with colored icons
local function pj_format(item, picker)
  local ret = {}
  local data = item.data

  -- Icon with highlight
  if data.icon and data.icon ~= "" then
    local hl = data.icon_hl or "SnacksPickerIcon"
    ret[#ret + 1] = { data.icon, hl, virtual = true }
    ret[#ret + 1] = { " ", virtual = true }
  end

  -- Project name
  ret[#ret + 1] = { data.name, "SnacksPickerFile" }
  ret[#ret + 1] = { " " }

  -- Path (dimmed)
  ret[#ret + 1] = { data.display_path, "SnacksPickerDir" }

  return ret
end

M.open = function(opts)
  opts = opts or {}
  local config = require("pj.config").options
  local finder = require("pj.finder")

  -- If depth is passed in opts, set it in the depth module so title reflects it
  if opts.depth then
    depth_module.set(opts.depth)
  end

  -- Check binary
  if not finder.check_binary() then
    if config.behavior.notify_on_error then
      vim.notify("pj binary not found. Please install it first.", vim.log.levels.ERROR)
    end
    return
  end

  -- Check if Snacks is available
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    if config.behavior.notify_on_error then
      vim.notify("Snacks.nvim not found. Please install folke/snacks.nvim", vim.log.levels.ERROR)
    end
    return
  end

  -- Finder function that fetches projects (called on refresh)
  local function pj_finder()
    local projects, err = finder.get_projects(opts)
    if err then
      if config.behavior.notify_on_error then
        vim.notify(err, vim.log.levels.ERROR)
      end
      return {}
    end
    return projects or {}
  end

  -- Initial check for projects
  local initial_projects = pj_finder()
  if #initial_projects == 0 then
    vim.notify("No projects found", vim.log.levels.WARN)
    return
  end

  -- Build keymaps for depth control from config
  local keymaps = config.keymaps or {}
  local input_keys = {}
  if keymaps.depth_increase then
    input_keys[keymaps.depth_increase] = { "pj_depth_increase", mode = { "i", "n" }, desc = "Increase depth" }
  end
  if keymaps.depth_decrease then
    input_keys[keymaps.depth_decrease] = { "pj_depth_decrease", mode = { "i", "n" }, desc = "Decrease depth" }
  end

  -- Open the picker
  snacks.picker({
    title = get_title(),
    finder = pj_finder,
    format = pj_format,
    actions = {
      pj_depth_increase = function(picker)
        local _, changed = depth_module.increment()
        if changed then
          picker.title = get_title()
          picker:update_titles()
          picker:refresh()
        else
          vim.notify("Already at maximum depth", vim.log.levels.WARN)
        end
      end,
      pj_depth_decrease = function(picker)
        local _, changed = depth_module.decrement()
        if changed then
          picker.title = get_title()
          picker:update_titles()
          picker:refresh()
        else
          vim.notify("Already at minimum depth", vim.log.levels.WARN)
        end
      end,
    },
    win = {
      input = {
        keys = input_keys,
      },
    },
    confirm = function(picker, item)
      if not item then
        return
      end

      -- Close the picker first
      picker:close()

      -- Handle different open modes based on opts
      if opts.split then
        vim.cmd("split")
      elseif opts.vsplit then
        vim.cmd("vsplit")
      elseif opts.tab then
        vim.cmd("tabnew")
      end

      -- Switch to project (handles directory change and session loading)
      local session = require("pj.session")
      session.switch_to_project(item.data.path, item.data.name, config)
    end,
  })
end

return M

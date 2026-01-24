local M = {}

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

  -- Get projects
  local projects, err = finder.get_projects(opts)
  if err then
    if config.behavior.notify_on_error then
      vim.notify(err, vim.log.levels.ERROR)
    end
    return
  end

  if not projects or #projects == 0 then
    vim.notify("No projects found", vim.log.levels.WARN)
    return
  end

  -- Open the picker
  snacks.picker({
    title = "PJ Projects",
    items = projects,
    format = pj_format,
    confirm = function(picker, item)
      if not item then
        return
      end

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

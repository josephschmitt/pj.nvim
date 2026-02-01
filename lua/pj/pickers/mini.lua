local M = {}

local depth_module = require("pj.depth")

-- Get picker name with depth indicator
local function get_name()
  return string.format("PJ Projects (%s)", depth_module.get_display())
end

-- Custom show function with colored icons
-- This displays items in the picker with icons and proper highlighting
local function pj_show(buf_id, items, query)
  if not items or #items == 0 then
    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, {})
    return
  end

  local lines = {}
  local ns_id = vim.api.nvim_create_namespace("pj_mini_pick")

  for _, item in ipairs(items) do
    local data = item.data or {}
    local icon = data.icon or ""
    local name = data.name or ""
    local display_path = data.display_path or ""

    -- Format: "icon name  path"
    local line
    if icon ~= "" then
      line = string.format("%s %s  %s", icon, name, display_path)
    else
      line = string.format("%s  %s", name, display_path)
    end
    table.insert(lines, line)
  end

  vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)

  -- Apply highlighting for icons
  vim.api.nvim_buf_clear_namespace(buf_id, ns_id, 0, -1)
  for i, item in ipairs(items) do
    local data = item.data or {}
    if data.icon and data.icon ~= "" and data.icon_hl then
      -- Highlight the icon (first few characters)
      local icon_len = vim.fn.strwidth(data.icon)
      vim.api.nvim_buf_add_highlight(buf_id, ns_id, data.icon_hl, i - 1, 0, icon_len)
    end

    -- Highlight the name
    local name_start = data.icon and data.icon ~= "" and (vim.fn.strwidth(data.icon) + 1) or 0
    local name = data.name or ""
    local name_end = name_start + vim.fn.strwidth(name)
    vim.api.nvim_buf_add_highlight(buf_id, ns_id, "MiniPickMatchRanges", i - 1, name_start, name_end)

    -- Highlight the path (dimmed)
    local path_start = name_end + 2 -- account for "  " separator
    vim.api.nvim_buf_add_highlight(buf_id, ns_id, "Comment", i - 1, path_start, -1)
  end
end

M.open = function(opts)
  opts = opts or {}
  local config = require("pj.config").options
  local finder = require("pj.finder")

  -- If depth is passed in opts, set it in the depth module so name reflects it
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

  -- Check if mini.pick is available
  local ok, _ = pcall(require, "mini.pick")
  if not ok then
    if config.behavior.notify_on_error then
      vim.notify("mini.pick not found. Please install nvim-mini/mini.pick or mini.nvim", vim.log.levels.ERROR)
    end
    return
  end

  local MiniPick = require("mini.pick")

  -- Function to fetch projects
  local function get_items()
    local projects, err = finder.get_projects(opts)
    if err then
      if config.behavior.notify_on_error then
        vim.notify(err, vim.log.levels.ERROR)
      end
      return {}
    end

    -- Transform items to mini.pick format
    -- Each item needs a 'text' field for matching
    local items = {}
    for _, project in ipairs(projects or {}) do
      table.insert(items, {
        text = project.data.name .. " " .. project.data.path,
        data = project.data,
      })
    end

    return items
  end

  -- Get initial items
  local items = get_items()
  if #items == 0 then
    vim.notify("No projects found", vim.log.levels.WARN)
    return
  end

  -- Helper function to switch to project
  local function switch_to_project(item, window_mode)
    if not item then
      return
    end

    -- Handle different open modes
    if window_mode == "split" then
      vim.cmd("split")
    elseif window_mode == "vsplit" then
      vim.cmd("vsplit")
    elseif window_mode == "tab" then
      vim.cmd("tabnew")
    end

    -- Switch to project (handles directory change and session loading)
    local session = require("pj.session")
    session.switch_to_project(item.data.path, item.data.name, config)
  end

  -- Build keymaps for depth control from config
  local keymaps = config.keymaps or {}

  -- Define custom actions for depth control
  local function depth_increase_action()
    local _, changed = depth_module.increment()
    if changed then
      vim.notify(depth_module.get_display(), vim.log.levels.INFO)
      -- Refresh items with new depth
      local new_items = get_items()
      MiniPick.set_picker_items(new_items)
    else
      vim.notify("Already at maximum depth", vim.log.levels.WARN)
    end
  end

  local function depth_decrease_action()
    local _, changed = depth_module.decrement()
    if changed then
      vim.notify(depth_module.get_display(), vim.log.levels.INFO)
      -- Refresh items with new depth
      local new_items = get_items()
      MiniPick.set_picker_items(new_items)
    else
      vim.notify("Already at minimum depth", vim.log.levels.WARN)
    end
  end

  -- Helper to get current item and execute action
  local function choose_with_mode(mode)
    return function()
      local matches = MiniPick.get_picker_matches()
      local item = matches and matches.current
      if item then
        MiniPick.stop()
        vim.schedule(function()
          switch_to_project(item, mode)
        end)
      end
    end
  end

  -- Build mappings table with char and func for custom actions
  local mappings = {
    -- Depth control
    pj_depth_increase = { char = keymaps.depth_increase or "<C-l>", func = depth_increase_action },
    pj_depth_decrease = { char = keymaps.depth_decrease or "<C-h>", func = depth_decrease_action },
    -- Window modes - use pj's conventions
    pj_choose_split = { char = keymaps.split or "<C-x>", func = choose_with_mode("split") },
    pj_choose_vsplit = { char = keymaps.vsplit or "<C-v>", func = choose_with_mode("vsplit") },
    pj_choose_tab = { char = keymaps.tab or "<C-t>", func = choose_with_mode("tab") },
  }

  -- Get mini.pick specific config
  local mini_config = config.picker.mini or {}

  -- Start the picker
  MiniPick.start({
    source = {
      items = items,
      name = get_name(),
      show = mini_config.show or pj_show,
      choose = function(item)
        switch_to_project(item, nil)
      end,
      choose_marked = function(marked_items)
        -- Open first marked item in current window, rest in splits
        if #marked_items > 0 then
          switch_to_project(marked_items[1], nil)
          for i = 2, #marked_items do
            switch_to_project(marked_items[i], "split")
          end
        end
      end,
    },
    mappings = mappings,
    window = mini_config.window or {},
  })
end

return M

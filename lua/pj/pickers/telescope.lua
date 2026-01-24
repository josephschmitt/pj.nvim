local M = {}

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

  -- Check if telescope is available
  local ok, _ = pcall(require, "telescope")
  if not ok then
    if config.behavior.notify_on_error then
      vim.notify("Telescope not found. Please install nvim-telescope/telescope.nvim", vim.log.levels.ERROR)
    end
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values

  -- Try to use entry_display, but fallback if not available
  local entry_display_ok, entry_display = pcall(require, "telescope.pickers.entry_display")

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

  -- Create entry maker with or without entry_display
  local make_entry
  if entry_display_ok then
    -- Use entry_display for columnar layout
    local displayer = entry_display.create({
      separator = " ",
      items = {
        { width = 2 },  -- icon
        { width = 30 }, -- name
        { remaining = true }, -- path
      },
    })

    make_entry = function(project)
      return {
        value = project,
        display = function(entry)
          -- Use icon_hl if available, otherwise fallback to TelescopeResultsIcon
          local icon_hl = entry.value.data.icon_hl or "TelescopeResultsIcon"
          return displayer({
            { entry.value.data.icon or "", icon_hl },
            { entry.value.data.name, "TelescopeResultsIdentifier" },
            { entry.value.data.display_path, "TelescopeResultsComment" },
          })
        end,
        ordinal = project.data.name .. " " .. project.data.path,
        path = project.data.path, -- For previewer
      }
    end
  else
    -- Simple fallback without entry_display
    make_entry = function(project)
      local display = project.data.icon and
        (project.data.icon .. " " .. project.data.name .. " " .. project.data.display_path) or
        (project.data.name .. " " .. project.data.display_path)

      return {
        value = project,
        display = display,
        ordinal = project.data.name .. " " .. project.data.path,
        path = project.data.path,
      }
    end
  end

  -- Create action handlers
  local function handle_selection(close, mode)
    return function(prompt_bufnr)
      local selection = action_state.get_selected_entry()
      if not selection then return end

      if close then
        actions.close(prompt_bufnr)
      end

      -- Handle window mode
      if mode == "split" then
        vim.cmd("split")
      elseif mode == "vsplit" then
        vim.cmd("vsplit")
      elseif mode == "tab" then
        vim.cmd("tabnew")
      end

      -- Switch to project (handles directory change and session loading)
      local session = require("pj.session")
      session.switch_to_project(selection.value.data.path, selection.value.data.name, config)
    end
  end

  -- Create picker options
  local picker_opts = {
    prompt_title = "PJ Projects",
    finder = finders.new_table({
      results = projects,
      entry_maker = make_entry,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      -- Map actions
      actions.select_default:replace(handle_selection(true, nil))
      map("i", "<C-x>", handle_selection(true, "split"))
      map("i", "<C-v>", handle_selection(true, "vsplit"))
      map("i", "<C-t>", handle_selection(true, "tab"))

      return true
    end,
  }

  -- Get telescope specific config
  local telescope_config = config.picker.telescope or {}

  -- Apply theme if configured
  if telescope_config.theme then
    local themes_ok, themes = pcall(require, "telescope.themes")
    if themes_ok then
      local theme_func = themes["get_" .. telescope_config.theme]
      if theme_func then
        picker_opts = theme_func(picker_opts)
      end
    end
  end

  -- Apply layout config
  if telescope_config.layout_config then
    picker_opts.layout_config = telescope_config.layout_config
  end

  -- Add previewer if enabled
  if telescope_config.previewer then
    picker_opts.previewer = conf.file_previewer(opts)
  end

  -- Create and start picker
  pickers.new(opts, picker_opts):find()
end

return M
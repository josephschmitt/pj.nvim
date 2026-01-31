local M = {}

local depth_module = require("pj.depth")

-- Get prompt with depth indicator
local function get_prompt()
  return string.format("PJ Projects (%s)> ", depth_module.get_display())
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

  -- Check if fzf-lua is available
  local ok, fzf_lua = pcall(require, "fzf-lua")
  if not ok then
    if config.behavior.notify_on_error then
      vim.notify("fzf-lua not found. Please install ibhagwan/fzf-lua", vim.log.levels.ERROR)
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

  -- Helper to get ANSI color from highlight group
  local function get_ansi_color(hl_group)
    if not hl_group then return "" end
    local hl = vim.api.nvim_get_hl(0, { name = hl_group, link = false })
    if hl.fg then
      local fg = hl.fg
      local r = math.floor(fg / 65536)
      local g = math.floor((fg % 65536) / 256)
      local b = fg % 256
      return string.format("\27[38;2;%d;%d;%dm", r, g, b)
    end
    return ""
  end

  local ansi_reset = "\27[0m"

  -- Format entries for display with icon highlighting
  local entries = {}
  for _, project in ipairs(projects) do
    local icon = project.data.icon or ""
    local icon_hl = project.data.icon_hl

    -- Apply ANSI color to icon if we have a highlight group
    local colored_icon = icon
    if icon ~= "" and icon_hl then
      local color = get_ansi_color(icon_hl)
      if color ~= "" then
        colored_icon = color .. icon .. ansi_reset
      end
    end

    -- Format: colored_icon name path|actual_path
    local display = string.format("%s %s %s|%s",
      colored_icon,
      project.data.name,
      project.data.display_path,
      project.data.path)

    table.insert(entries, display)
  end

  -- Create action handlers
  local function handle_selection(selected, opts_inner)
    if not selected or #selected == 0 then return end
    -- Extract path from the encoded entry (after the last |)
    -- Strip ANSI codes first to handle colored icons
    local cleaned = selected[1]:gsub("\27%[[0-9;]*m", "")
    local path = cleaned:match("|(.+)$")
    if not path then
      -- Fallback if delimiter not found
      path = cleaned
    end

    -- Handle window mode
    if opts_inner.split then
      vim.cmd("split")
    elseif opts_inner.vsplit then
      vim.cmd("vsplit")
    elseif opts_inner.tab then
      vim.cmd("tabnew")
    end

    -- Switch to project (handles directory change and session loading)
    local session = require("pj.session")
    local name = vim.fn.fnamemodify(path, ":t")
    session.switch_to_project(path, name, config)
  end

  -- Get fzf-lua specific config
  local fzf_config = config.picker.fzf_lua or {}
  local keymaps = config.keymaps or {}

  -- Helper to convert Neovim key notation to fzf format
  local function nvim_to_fzf_key(key)
    if not key then return nil end
    -- Handle arrow keys
    key = key:gsub("<C%-Up>", "ctrl-up")
    key = key:gsub("<C%-Down>", "ctrl-down")
    key = key:gsub("<C%-Left>", "ctrl-left")
    key = key:gsub("<C%-Right>", "ctrl-right")
    -- Handle regular ctrl keys
    key = key:gsub("<C%-", "ctrl-"):gsub(">", ""):lower()
    return key
  end

  -- Build fzf options with depth keybindings in header
  local depth_keys_info = ""
  if keymaps.depth_increase and keymaps.depth_decrease then
    -- Convert Neovim key notation to fzf-friendly display
    local inc_display = nvim_to_fzf_key(keymaps.depth_increase):gsub("ctrl%-", "C-")
    local dec_display = nvim_to_fzf_key(keymaps.depth_decrease):gsub("ctrl%-", "C-")
    depth_keys_info = string.format(", %s/%s=depth", inc_display, dec_display)
  end

  -- Depth control actions that reload the picker
  local function handle_depth_change(change_fn, fail_msg)
    return function()
      local _, changed = change_fn()
      if changed then
        vim.notify(depth_module.get_display(), vim.log.levels.INFO)
        -- Reopen the picker with new depth
        vim.schedule(function()
          M.open(opts)
        end)
      else
        vim.notify(fail_msg, vim.log.levels.WARN)
      end
    end
  end

  -- Build actions table
  local actions_table = {
    ["default"] = function(selected)
      handle_selection(selected, {})
    end,
    ["ctrl-x"] = function(selected)
      handle_selection(selected, { split = true })
    end,
    ["ctrl-v"] = function(selected)
      handle_selection(selected, { vsplit = true })
    end,
    ["ctrl-t"] = function(selected)
      handle_selection(selected, { tab = true })
    end,
  }

  -- Add depth control actions if keymaps are configured
  if keymaps.depth_increase then
    local fzf_key = nvim_to_fzf_key(keymaps.depth_increase)
    actions_table[fzf_key] = handle_depth_change(
      depth_module.increment,
      "Already at maximum depth"
    )
  end
  if keymaps.depth_decrease then
    local fzf_key = nvim_to_fzf_key(keymaps.depth_decrease)
    actions_table[fzf_key] = handle_depth_change(
      depth_module.decrement,
      "Already at minimum depth"
    )
  end

  -- Configure and open fzf-lua
  fzf_lua.fzf_exec(entries, {
    prompt = get_prompt(),
    winopts = fzf_config.winopts or {
      height = 0.85,
      width = 0.80,
    },
    preview = fzf_config.preview and fzf_config.preview.enabled and {
      cmd = fzf_config.preview.cmd or "ls -la",
      type = "cmd",
    } or nil,
    actions = actions_table,
    fzf_opts = {
      ["--header"] = "Enter=open, C-x=split, C-v=vsplit, C-t=tab" .. depth_keys_info,
      ["--ansi"] = "", -- Enable ANSI color codes
    },
  })
end

return M
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

  -- Format entries for display
  local entries = {}
  for _, project in ipairs(projects) do
    local display = project.data.icon and
      (project.data.icon .. " " .. project.data.name) or
      project.data.name
    -- Store path as hidden data after delimiter
    table.insert(entries, display .. " " .. project.data.display_path .. "|" .. project.data.path)
  end

  -- Create action handlers
  local function handle_selection(selected, opts_inner)
    if not selected or #selected == 0 then return end
    local path = selected[1]:match("|(.+)$")
    if not path then
      -- Fallback if delimiter not found
      path = selected[1]
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

  -- Configure and open fzf-lua
  fzf_lua.fzf_exec(entries, {
    prompt = config.picker.prompt,
    winopts = fzf_config.winopts or {
      height = 0.85,
      width = 0.80,
    },
    preview = fzf_config.preview and fzf_config.preview.enabled and {
      cmd = fzf_config.preview.cmd or "ls -la",
      type = "cmd",
    } or nil,
    actions = {
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
    },
    fzf_opts = {
      ["--header"] = "Enter=open, C-x=split, C-v=vsplit, C-t=tab",
    },
  })
end

return M
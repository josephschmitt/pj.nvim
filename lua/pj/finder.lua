local M = {}

-- Execute pj binary and return projects
M.get_projects = function(opts)
  opts = opts or {}
  local config = require("pj.config").options
  local cmd_args = { config.pj.cmd }

  -- Add default args from config
  for _, arg in ipairs(config.pj.args) do
    table.insert(cmd_args, arg)
  end

  -- Add runtime options
  if opts.no_cache or not config.pj.cache then
    table.insert(cmd_args, "--no-cache")
  end

  if config.pj.icons then
    table.insert(cmd_args, "--icons")
  end

  if config.pj.json then
    table.insert(cmd_args, "--json")
  end

  -- Add depth if specified (runtime or from depth module)
  local depth = opts.depth
  if depth == nil then
    local depth_module = require("pj.depth")
    depth = depth_module.get_current()
  end
  if depth then
    table.insert(cmd_args, "--max-depth")
    table.insert(cmd_args, tostring(depth))
  end

  -- Execute command
  local result
  if config.pj.json then
    -- For JSON output, we need the full string, not lines
    result = vim.fn.system(table.concat(cmd_args, " "))
  else
    result = vim.fn.systemlist(table.concat(cmd_args, " "))
  end

  if vim.v.shell_error ~= 0 then
    local err_msg = type(result) == "table" and table.concat(result, "\n") or result
    return nil, "pj command failed: " .. err_msg
  end

  -- Parse output based on mode
  if config.pj.json then
    return M.parse_json_output(result, config.pj.icons)
  else
    return M.parse_output(result, config.pj.icons)
  end
end

-- Parse pj output into picker items
M.parse_output = function(lines, has_icons)
  local items = {}

  for _, line in ipairs(lines) do
    if line ~= "" then
      local path, icon

      if has_icons then
        -- Extract icon and path (format: "icon path")
        -- Icons are typically 1-2 characters (emoji or nerd font icon)
        local first_space = line:find(" ")
        if first_space then
          icon = line:sub(1, first_space - 1)
          path = vim.trim(line:sub(first_space + 1))
        else
          path = line
        end
      else
        path = line
      end

      -- Expand path to absolute
      path = vim.fn.expand(path)

      table.insert(items, {
        text = vim.fn.fnamemodify(path, ":t"), -- Project name
        file = path, -- Full path
        data = {
          path = path,
          icon = icon,
          name = vim.fn.fnamemodify(path, ":t"),
          display_path = vim.fn.fnamemodify(path, ":~"),
        },
      })
    end
  end

  return items
end

-- Parse JSON output from pj into picker items
M.parse_json_output = function(json_str, has_icons)
  local ok, data = pcall(vim.fn.json_decode, json_str)
  if not ok or not data or not data.projects then
    return nil, "Failed to parse JSON output"
  end

  local items = {}
  local icons_module = require("pj.icons")

  for _, project in ipairs(data.projects) do
    local path = vim.fn.expand(project.path)
    local icon, icon_hl = icons_module.get_icon_hl(project.marker, project.icon)

    table.insert(items, {
      text = project.name,
      file = path,
      data = {
        path = path,
        icon = icon,
        icon_hl = icon_hl,
        marker = project.marker,
        name = project.name,
        display_path = vim.fn.fnamemodify(path, ":~"),
      },
    })
  end

  return items
end

-- Check if pj binary exists
M.check_binary = function()
  local config = require("pj.config").options
  return vim.fn.executable(config.pj.cmd) == 1
end

return M

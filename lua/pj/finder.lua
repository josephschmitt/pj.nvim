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

  -- Execute command
  local result = vim.fn.systemlist(table.concat(cmd_args, " "))

  if vim.v.shell_error ~= 0 then
    return nil, "pj command failed: " .. table.concat(result, "\n")
  end

  return M.parse_output(result, config.pj.icons)
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

-- Check if pj binary exists
M.check_binary = function()
  local config = require("pj.config").options
  return vim.fn.executable(config.pj.cmd) == 1
end

return M

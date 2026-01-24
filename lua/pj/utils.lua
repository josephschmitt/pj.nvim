local M = {}

-- Utility functions for pj.nvim

-- Check if a command/binary exists
M.executable = function(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Safely notify the user
M.notify = function(msg, level)
  level = level or vim.log.levels.INFO
  vim.notify(msg, level)
end

-- Escape special characters for shell command
M.shell_escape = function(str)
  return vim.fn.shellescape(str)
end

-- Get the project name from a path
M.get_project_name = function(path)
  return vim.fn.fnamemodify(path, ":t")
end

-- Get the shortened path (relative to home)
M.get_short_path = function(path)
  return vim.fn.fnamemodify(path, ":~")
end

return M

local M = {}

-- Change directory based on config scope
M.change_directory = function(path, config)
  config = config or require("pj.config").options

  if not config.behavior.cd_on_select then
    return
  end

  local cmd = config.behavior.cd_scope == "tab" and "tcd" or "cd"
  vim.cmd(cmd .. " " .. vim.fn.fnameescape(path))
end

-- Load session if session manager is configured
M.load_session = function(path, config)
  config = config or require("pj.config").options

  if not config.behavior.session_manager then
    return false
  end

  -- Try to load session based on configured manager
  if config.behavior.session_manager == "auto-session" then
    local ok, auto_session = pcall(require, "auto-session")
    if ok and auto_session.RestoreSession then
      -- Change to directory first for auto-session to find the session
      M.change_directory(path, config)
      auto_session.RestoreSession()
      return true
    end
  elseif config.behavior.session_manager == "persistence" then
    local ok, persistence = pcall(require, "persistence")
    if ok and persistence.load then
      M.change_directory(path, config)
      persistence.load()
      return true
    end
  end

  return false
end

-- Main function to switch to a project
M.switch_to_project = function(path, name, config)
  config = config or require("pj.config").options

  -- Try to load session first if configured
  local session_loaded = M.load_session(path, config)

  -- If no session was loaded, just change directory
  if not session_loaded then
    M.change_directory(path, config)
  end

  -- Notify user
  local scope = config.behavior.cd_scope == "tab" and " (tab)" or ""
  vim.notify("Changed to: " .. name .. scope, vim.log.levels.INFO)
end

return M

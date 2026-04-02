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

-- Save current session if session manager supports it
local function save_current_session(config)
  if config.behavior.session_manager == "auto-session" then
    local ok, auto_session = pcall(require, "auto-session")
    if ok and auto_session.SaveSession then
      auto_session.SaveSession()
    end
  elseif config.behavior.session_manager == "persistence" then
    local ok, persistence = pcall(require, "persistence")
    if ok and persistence.save then
      persistence.save()
    end
  end
end

-- Clear all buffers and windows to prepare for a new session
local function clear_buffers()
  -- Delete all buffers to remove old project files from the buffer list
  vim.cmd("silent! %bdelete!")
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
    if ok then
      -- Save the current session before switching away
      save_current_session(config)

      -- Clear existing buffers so old project files don't linger
      clear_buffers()

      -- For tab scope, use global cd for session restore compatibility,
      -- then set tab-local directory afterward
      vim.cmd("cd " .. vim.fn.fnameescape(path))

      -- Restore session for the new directory
      if auto_session.RestoreSession then
        auto_session.RestoreSession()
      end

      -- Set tab-local directory after session restore so it isn't
      -- overwritten by cd commands inside the session file
      if config.behavior.cd_scope == "tab" then
        vim.cmd("tcd " .. vim.fn.fnameescape(path))
      end

      return true
    end
  elseif config.behavior.session_manager == "persistence" then
    local ok, persistence = pcall(require, "persistence")
    if ok and persistence.load then
      save_current_session(config)
      clear_buffers()
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

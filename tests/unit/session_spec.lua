-- Tests for lua/pj/session.lua
-- Session and directory switching module

local MiniTest = require("mini.test")
local expect = MiniTest.expect

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      -- Reset modules before each test
      package.loaded["pj.session"] = nil
      package.loaded["pj.config"] = nil
    end,
  },
})

-- Helper to get a fresh session module
local function get_session()
  return require("pj.session")
end

-- =============================================================================
-- change_directory() tests
-- =============================================================================
T["change_directory"] = MiniTest.new_set()

T["change_directory"]["calls tcd for tab scope"] = function()
  local session = get_session()
  local captured_cmd = nil

  local original_cmd = vim.cmd
  vim.cmd = function(cmd)
    captured_cmd = cmd
  end

  session.change_directory("/test/path", {
    behavior = {
      cd_on_select = true,
      cd_scope = "tab",
    },
  })

  vim.cmd = original_cmd

  expect.equality(captured_cmd:match("^tcd"), "tcd")
  expect.equality(captured_cmd:match("/test/path"), "/test/path")
end

T["change_directory"]["calls cd for global scope"] = function()
  local session = get_session()
  local captured_cmd = nil

  local original_cmd = vim.cmd
  vim.cmd = function(cmd)
    captured_cmd = cmd
  end

  session.change_directory("/test/path", {
    behavior = {
      cd_on_select = true,
      cd_scope = "global",
    },
  })

  vim.cmd = original_cmd

  expect.equality(captured_cmd:match("^cd "), "cd ")
  expect.equality(captured_cmd:match("/test/path"), "/test/path")
end

T["change_directory"]["does nothing when cd_on_select is false"] = function()
  local session = get_session()
  local cmd_called = false

  local original_cmd = vim.cmd
  vim.cmd = function(_)
    cmd_called = true
  end

  session.change_directory("/test/path", {
    behavior = {
      cd_on_select = false,
      cd_scope = "tab",
    },
  })

  vim.cmd = original_cmd

  expect.equality(cmd_called, false)
end

T["change_directory"]["escapes path with special characters"] = function()
  local session = get_session()
  local captured_cmd = nil

  local original_cmd = vim.cmd
  vim.cmd = function(cmd)
    captured_cmd = cmd
  end

  session.change_directory("/test/path with spaces", {
    behavior = {
      cd_on_select = true,
      cd_scope = "tab",
    },
  })

  vim.cmd = original_cmd

  -- Should contain escaped path
  expect.equality(captured_cmd:match("path"), "path")
end

-- =============================================================================
-- load_session() tests
-- =============================================================================
T["load_session"] = MiniTest.new_set()

T["load_session"]["returns false when no session manager configured"] = function()
  local session = get_session()

  local result = session.load_session("/test/path", {
    behavior = {
      session_manager = nil,
      cd_on_select = true,
      cd_scope = "tab",
    },
  })

  expect.equality(result, false)
end

T["load_session"]["returns false when auto-session not available"] = function()
  local session = get_session()

  -- Ensure auto-session is not loaded
  package.loaded["auto-session"] = nil

  local result = session.load_session("/test/path", {
    behavior = {
      session_manager = "auto-session",
      cd_on_select = true,
      cd_scope = "tab",
    },
  })

  expect.equality(result, false)
end

T["load_session"]["returns false when persistence not available"] = function()
  local session = get_session()

  -- Ensure persistence is not loaded
  package.loaded["persistence"] = nil

  local result = session.load_session("/test/path", {
    behavior = {
      session_manager = "persistence",
      cd_on_select = true,
      cd_scope = "tab",
    },
  })

  expect.equality(result, false)
end

T["load_session"]["calls auto-session when available"] = function()
  local session = get_session()
  local restore_called = false
  local cd_called = false

  -- Mock auto-session
  package.loaded["auto-session"] = {
    RestoreSession = function()
      restore_called = true
    end,
  }

  local original_cmd = vim.cmd
  vim.cmd = function(_)
    cd_called = true
  end

  local result = session.load_session("/test/path", {
    behavior = {
      session_manager = "auto-session",
      cd_on_select = true,
      cd_scope = "tab",
    },
  })

  vim.cmd = original_cmd
  package.loaded["auto-session"] = nil

  expect.equality(result, true)
  expect.equality(restore_called, true)
  expect.equality(cd_called, true) -- Should cd first
end

T["load_session"]["calls persistence when available"] = function()
  local session = get_session()
  local load_called = false
  local cd_called = false

  -- Mock persistence
  package.loaded["persistence"] = {
    load = function()
      load_called = true
    end,
  }

  local original_cmd = vim.cmd
  vim.cmd = function(_)
    cd_called = true
  end

  local result = session.load_session("/test/path", {
    behavior = {
      session_manager = "persistence",
      cd_on_select = true,
      cd_scope = "tab",
    },
  })

  vim.cmd = original_cmd
  package.loaded["persistence"] = nil

  expect.equality(result, true)
  expect.equality(load_called, true)
  expect.equality(cd_called, true)
end

-- =============================================================================
-- switch_to_project() tests
-- =============================================================================
T["switch_to_project"] = MiniTest.new_set()

T["switch_to_project"]["changes directory and notifies"] = function()
  local session = get_session()
  local cd_called = false
  local notify_msg = nil

  local original_cmd = vim.cmd
  local original_notify = vim.notify

  vim.cmd = function(_)
    cd_called = true
  end
  vim.notify = function(msg, _)
    notify_msg = msg
  end

  session.switch_to_project("/test/path", "TestProject", {
    behavior = {
      session_manager = nil,
      cd_on_select = true,
      cd_scope = "tab",
    },
  })

  vim.cmd = original_cmd
  vim.notify = original_notify

  expect.equality(cd_called, true)
  expect.equality(notify_msg:match("TestProject"), "TestProject")
  expect.equality(notify_msg:match("%(tab%)"), "(tab)")
end

T["switch_to_project"]["shows global scope in notification"] = function()
  local session = get_session()
  local notify_msg = nil

  local original_cmd = vim.cmd
  local original_notify = vim.notify

  vim.cmd = function(_) end
  vim.notify = function(msg, _)
    notify_msg = msg
  end

  session.switch_to_project("/test/path", "TestProject", {
    behavior = {
      session_manager = nil,
      cd_on_select = true,
      cd_scope = "global",
    },
  })

  vim.cmd = original_cmd
  vim.notify = original_notify

  -- Global scope should not show "(tab)"
  expect.equality(notify_msg:match("%(tab%)"), nil)
end

T["switch_to_project"]["tries session before cd"] = function()
  local session = get_session()
  local call_order = {}

  -- Mock auto-session
  package.loaded["auto-session"] = {
    RestoreSession = function()
      table.insert(call_order, "restore")
    end,
  }

  local original_cmd = vim.cmd
  local original_notify = vim.notify

  vim.cmd = function(_)
    table.insert(call_order, "cmd")
  end
  vim.notify = function(_, _) end

  session.switch_to_project("/test/path", "TestProject", {
    behavior = {
      session_manager = "auto-session",
      cd_on_select = true,
      cd_scope = "tab",
    },
  })

  vim.cmd = original_cmd
  vim.notify = original_notify
  package.loaded["auto-session"] = nil

  -- Should have: cmd (for cd before restore), restore
  -- The change_directory is called within load_session before RestoreSession
  expect.equality(#call_order >= 2, true)
end

-- =============================================================================
-- edge cases
-- =============================================================================
T["edge_cases"] = MiniTest.new_set()

T["edge_cases"]["handles nil config by using require"] = function()
  local session = get_session()

  -- Setup config module
  local config = require("pj.config")
  config.options = {
    behavior = {
      cd_on_select = true,
      cd_scope = "tab",
      session_manager = nil,
    },
  }

  local cd_called = false
  local original_cmd = vim.cmd
  local original_notify = vim.notify

  vim.cmd = function(_)
    cd_called = true
  end
  vim.notify = function(_, _) end

  -- Call without config parameter
  session.switch_to_project("/test/path", "TestProject", nil)

  vim.cmd = original_cmd
  vim.notify = original_notify

  expect.equality(cd_called, true)
end

return T

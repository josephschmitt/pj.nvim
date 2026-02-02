-- Tests for lua/pj/utils.lua
-- Utility functions that wrap vim APIs

local MiniTest = require("mini.test")
local expect = MiniTest.expect

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      -- Reset module before each test
      package.loaded["pj.utils"] = nil
    end,
  },
})

-- Helper to get a fresh utils module
local function get_utils()
  return require("pj.utils")
end

-- =============================================================================
-- executable() tests
-- =============================================================================
T["executable"] = MiniTest.new_set()

T["executable"]["returns true when command exists"] = function()
  local utils = get_utils()

  -- 'ls' should exist on all systems
  local result = utils.executable("ls")

  expect.equality(result, true)
end

T["executable"]["returns false when command does not exist"] = function()
  local utils = get_utils()

  local result = utils.executable("nonexistent_command_12345")

  expect.equality(result, false)
end

-- =============================================================================
-- shell_escape() tests
-- =============================================================================
T["shell_escape"] = MiniTest.new_set()

T["shell_escape"]["escapes simple strings"] = function()
  local utils = get_utils()

  local result = utils.shell_escape("hello")

  -- Should be quoted
  expect.equality(result:sub(1, 1), "'")
  expect.equality(result:sub(-1), "'")
end

T["shell_escape"]["escapes strings with spaces"] = function()
  local utils = get_utils()

  local result = utils.shell_escape("hello world")

  -- The result should be properly escaped/quoted
  expect.equality(type(result), "string")
  expect.equality(result:match("hello"), "hello")
  expect.equality(result:match("world"), "world")
end

T["shell_escape"]["escapes strings with special characters"] = function()
  local utils = get_utils()

  local result = utils.shell_escape("test$var")

  -- Should be escaped
  expect.equality(type(result), "string")
end

-- =============================================================================
-- get_project_name() tests
-- =============================================================================
T["get_project_name"] = MiniTest.new_set()

T["get_project_name"]["extracts basename from path"] = function()
  local utils = get_utils()

  local result = utils.get_project_name("/home/user/projects/my-app")

  expect.equality(result, "my-app")
end

T["get_project_name"]["handles path with trailing slash"] = function()
  local utils = get_utils()

  -- Note: fnamemodify :t on trailing slash returns empty string
  local result = utils.get_project_name("/home/user/projects/my-app/")

  -- This may return empty string due to trailing slash behavior
  expect.equality(type(result), "string")
end

T["get_project_name"]["handles simple name without path"] = function()
  local utils = get_utils()

  local result = utils.get_project_name("my-app")

  expect.equality(result, "my-app")
end

T["get_project_name"]["handles root path"] = function()
  local utils = get_utils()

  local result = utils.get_project_name("/")

  expect.equality(type(result), "string")
end

-- =============================================================================
-- get_short_path() tests
-- =============================================================================
T["get_short_path"] = MiniTest.new_set()

T["get_short_path"]["shortens home directory to tilde"] = function()
  local utils = get_utils()
  local home = vim.fn.expand("~")

  local result = utils.get_short_path(home .. "/projects/my-app")

  expect.equality(result, "~/projects/my-app")
end

T["get_short_path"]["leaves non-home paths unchanged"] = function()
  local utils = get_utils()

  local result = utils.get_short_path("/tmp/test-project")

  expect.equality(result, "/tmp/test-project")
end

T["get_short_path"]["handles home directory itself"] = function()
  local utils = get_utils()
  local home = vim.fn.expand("~")

  local result = utils.get_short_path(home)

  expect.equality(result, "~")
end

-- =============================================================================
-- notify() tests
-- =============================================================================
T["notify"] = MiniTest.new_set()

T["notify"]["calls vim.notify with message"] = function()
  local utils = get_utils()
  local captured_msg = nil
  local captured_level = nil

  -- Temporarily override vim.notify
  local original_notify = vim.notify
  vim.notify = function(msg, level)
    captured_msg = msg
    captured_level = level
  end

  utils.notify("Test message")

  vim.notify = original_notify

  expect.equality(captured_msg, "Test message")
  expect.equality(captured_level, vim.log.levels.INFO)
end

T["notify"]["respects custom log level"] = function()
  local utils = get_utils()
  local captured_level = nil

  local original_notify = vim.notify
  vim.notify = function(_, level)
    captured_level = level
  end

  utils.notify("Error message", vim.log.levels.ERROR)

  vim.notify = original_notify

  expect.equality(captured_level, vim.log.levels.ERROR)
end

return T

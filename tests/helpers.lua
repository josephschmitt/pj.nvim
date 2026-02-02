-- Test helpers and mock utilities
local M = {}

-- Create a mock vim object with commonly used functions
M.mock_vim = function(overrides)
  overrides = overrides or {}

  local mock = {
    fn = {
      expand = function(path)
        -- Simple expand: just replace ~ with /home/user for tests
        if path:sub(1, 1) == "~" then
          return "/home/user" .. path:sub(2)
        end
        return path
      end,
      fnamemodify = function(path, modifier)
        if modifier == ":t" then
          -- Get basename
          return path:match("([^/]+)$") or path
        elseif modifier == ":~" then
          -- Make relative to home
          if path:sub(1, 11) == "/home/user/" then
            return "~/" .. path:sub(12)
          elseif path:sub(1, 10) == "/home/user" then
            return "~"
          end
          return path
        end
        return path
      end,
      shellescape = function(str)
        return "'" .. str:gsub("'", "'\\''") .. "'"
      end,
      fnameescape = function(str)
        return str:gsub(" ", "\\ ")
      end,
      executable = function()
        return 1
      end,
      system = function()
        return ""
      end,
      systemlist = function()
        return {}
      end,
      json_decode = vim.fn.json_decode, -- Use real json_decode
    },
    v = {
      shell_error = 0,
    },
    cmd = function() end,
    notify = function() end,
    log = {
      levels = {
        DEBUG = 0,
        INFO = 1,
        WARN = 2,
        ERROR = 3,
      },
    },
    tbl_deep_extend = vim.tbl_deep_extend,
    trim = vim.trim,
  }

  -- Apply overrides
  for k, v in pairs(overrides) do
    if type(v) == "table" and type(mock[k]) == "table" then
      for k2, v2 in pairs(v) do
        mock[k][k2] = v2
      end
    else
      mock[k] = v
    end
  end

  return mock
end

-- Run a function with a mocked vim global
M.with_mock_vim = function(mock, fn)
  local original_vim = _G.vim
  _G.vim = mock
  local ok, result = pcall(fn)
  _G.vim = original_vim
  if not ok then
    error(result)
  end
  return result
end

-- Load a fixture file
M.fixture = function(name)
  local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
  local fixture_path = plugin_root .. "/tests/fixtures/" .. name
  local file = io.open(fixture_path, "r")
  if not file then
    error("Fixture not found: " .. name)
  end
  local content = file:read("*all")
  file:close()
  return content
end

-- Load fixture as lines
M.fixture_lines = function(name)
  local content = M.fixture(name)
  local lines = {}
  for line in content:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  return lines
end

-- Reset a module by clearing it from package.loaded
M.reset_module = function(name)
  package.loaded[name] = nil
end

-- Reset all pj modules
M.reset_pj_modules = function()
  for name, _ in pairs(package.loaded) do
    if name:match("^pj%.") then
      package.loaded[name] = nil
    end
  end
end

return M

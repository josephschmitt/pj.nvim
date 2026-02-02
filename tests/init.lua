-- Test runner entry point
-- Usage: nvim --headless -u tests/minimal_init.lua -c "luafile tests/init.lua"

local MiniTest = require("mini.test")

-- Setup mini.test first
MiniTest.setup()

-- Get plugin root
local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")

-- Collect all test files
local test_files = vim.fn.glob(plugin_root .. "/tests/unit/*_spec.lua", false, true)

-- Run tests using MiniTest.run with custom find_files
MiniTest.run({
  collect = {
    emulate_busted = false,
    find_files = function()
      return test_files
    end,
  },
  execute = {
    reporter = MiniTest.gen_reporter.stdout({ group_depth = 2 }),
  },
})

-- Exit
vim.cmd("qall!")

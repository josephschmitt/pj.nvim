-- Tests for lua/pj/depth.lua
-- This module is a pure state machine with no external dependencies

local MiniTest = require("mini.test")
local expect = MiniTest.expect

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      -- Reset modules before each test
      package.loaded["pj.depth"] = nil
      package.loaded["pj.config"] = nil
    end,
  },
})

-- Helper to get a fresh depth module
local function get_depth()
  return require("pj.depth")
end

-- Helper to setup config with depth settings
local function setup_config(depth_opts)
  local config = require("pj.config")
  config.options = {
    depth = depth_opts or { initial = nil, min = 1, max = 10 },
  }
  return config
end

-- =============================================================================
-- setup() tests
-- =============================================================================
T["setup"] = MiniTest.new_set()

T["setup"]["initializes with default values when no config provided"] = function()
  local depth = get_depth()
  depth.setup(nil)

  expect.equality(depth.state.current, nil)
  expect.equality(depth.state.min, 1)
  expect.equality(depth.state.max, 10)
end

T["setup"]["initializes with config values"] = function()
  local depth = get_depth()
  depth.setup({
    depth = {
      initial = 5,
      min = 2,
      max = 8,
    },
  })

  expect.equality(depth.state.current, 5)
  expect.equality(depth.state.min, 2)
  expect.equality(depth.state.max, 8)
end

T["setup"]["uses defaults for missing config values"] = function()
  local depth = get_depth()
  depth.setup({
    depth = {
      initial = 3,
      -- min and max not provided
    },
  })

  expect.equality(depth.state.current, 3)
  expect.equality(depth.state.min, 1)
  expect.equality(depth.state.max, 10)
end

-- =============================================================================
-- get_current() tests
-- =============================================================================
T["get_current"] = MiniTest.new_set()

T["get_current"]["returns nil when no depth set"] = function()
  local depth = get_depth()
  depth.state.current = nil

  expect.equality(depth.get_current(), nil)
end

T["get_current"]["returns current depth value"] = function()
  local depth = get_depth()
  depth.state.current = 5

  expect.equality(depth.get_current(), 5)
end

-- =============================================================================
-- set() tests
-- =============================================================================
T["set"] = MiniTest.new_set()

T["set"]["sets depth within bounds"] = function()
  local depth = get_depth()
  depth.state.min = 1
  depth.state.max = 10

  local result = depth.set(5)
  expect.equality(result, 5)
  expect.equality(depth.state.current, 5)
end

T["set"]["clamps to minimum when below min"] = function()
  local depth = get_depth()
  depth.state.min = 3
  depth.state.max = 10

  local result = depth.set(1)
  expect.equality(result, 3)
  expect.equality(depth.state.current, 3)
end

T["set"]["clamps to maximum when above max"] = function()
  local depth = get_depth()
  depth.state.min = 1
  depth.state.max = 5

  local result = depth.set(10)
  expect.equality(result, 5)
  expect.equality(depth.state.current, 5)
end

T["set"]["sets to nil when nil passed"] = function()
  local depth = get_depth()
  depth.state.current = 5

  local result = depth.set(nil)
  expect.equality(result, nil)
  expect.equality(depth.state.current, nil)
end

T["set"]["clamps exactly at boundary values"] = function()
  local depth = get_depth()
  depth.state.min = 2
  depth.state.max = 8

  expect.equality(depth.set(2), 2) -- at min
  expect.equality(depth.set(8), 8) -- at max
end

-- =============================================================================
-- increment() tests
-- =============================================================================
T["increment"] = MiniTest.new_set()

T["increment"]["increases depth by 1 from current value"] = function()
  local depth = get_depth()
  depth.state.current = 3
  depth.state.min = 1
  depth.state.max = 10

  local new, changed = depth.increment()
  expect.equality(new, 4)
  expect.equality(changed, true)
  expect.equality(depth.state.current, 4)
end

T["increment"]["uses pj_default when current is nil"] = function()
  local depth = get_depth()
  depth.state.current = nil
  depth.state.pj_default = 3
  depth.state.min = 1
  depth.state.max = 10

  local new, changed = depth.increment()
  expect.equality(new, 4)
  expect.equality(changed, true)
end

T["increment"]["returns false when at max"] = function()
  local depth = get_depth()
  depth.state.current = 10
  depth.state.max = 10

  local new, changed = depth.increment()
  expect.equality(new, 10)
  expect.equality(changed, false)
  expect.equality(depth.state.current, 10)
end

T["increment"]["allows increment from nil to pj_default+1 when max allows"] = function()
  local depth = get_depth()
  depth.state.current = nil
  depth.state.pj_default = 5
  depth.state.max = 10

  local new, _ = depth.increment()
  expect.equality(new, 6)
end

-- =============================================================================
-- decrement() tests
-- =============================================================================
T["decrement"] = MiniTest.new_set()

T["decrement"]["decreases depth by 1 from current value"] = function()
  local depth = get_depth()
  depth.state.current = 5
  depth.state.min = 1
  depth.state.max = 10

  local new, changed = depth.decrement()
  expect.equality(new, 4)
  expect.equality(changed, true)
  expect.equality(depth.state.current, 4)
end

T["decrement"]["uses pj_default when current is nil"] = function()
  local depth = get_depth()
  depth.state.current = nil
  depth.state.pj_default = 3
  depth.state.min = 1
  depth.state.max = 10

  local new, changed = depth.decrement()
  expect.equality(new, 2)
  expect.equality(changed, true)
end

T["decrement"]["returns false when at min"] = function()
  local depth = get_depth()
  depth.state.current = 1
  depth.state.min = 1

  local new, changed = depth.decrement()
  expect.equality(new, 1)
  expect.equality(changed, false)
  expect.equality(depth.state.current, 1)
end

T["decrement"]["returns false when pj_default equals min"] = function()
  local depth = get_depth()
  depth.state.current = nil
  depth.state.pj_default = 1
  depth.state.min = 1

  local new, changed = depth.decrement()
  expect.equality(new, 1)
  expect.equality(changed, false)
end

-- =============================================================================
-- reset() tests
-- =============================================================================
T["reset"] = MiniTest.new_set()

T["reset"]["resets to initial from config"] = function()
  setup_config({ initial = 5, min = 1, max = 10 })
  local depth = get_depth()
  depth.state.current = 8 -- Set to something else first

  depth.reset()

  expect.equality(depth.state.current, 5)
end

T["reset"]["resets to nil when config has no initial"] = function()
  setup_config({ initial = nil, min = 1, max = 10 })
  local depth = get_depth()
  depth.state.current = 5

  depth.reset()

  expect.equality(depth.state.current, nil)
end

-- =============================================================================
-- get_display() tests
-- =============================================================================
T["get_display"] = MiniTest.new_set()

T["get_display"]["returns formatted string with current depth"] = function()
  local depth = get_depth()
  depth.state.current = 5

  expect.equality(depth.get_display(), "depth: 5")
end

T["get_display"]["returns 'depth: default' when current is nil"] = function()
  local depth = get_depth()
  depth.state.current = nil

  expect.equality(depth.get_display(), "depth: default")
end

-- =============================================================================
-- State machine integration tests
-- =============================================================================
T["state_machine"] = MiniTest.new_set()

T["state_machine"]["can increment then decrement back"] = function()
  local depth = get_depth()
  depth.state.current = 5
  depth.state.min = 1
  depth.state.max = 10

  depth.increment()
  expect.equality(depth.state.current, 6)

  depth.decrement()
  expect.equality(depth.state.current, 5)
end

T["state_machine"]["respects bounds after multiple operations"] = function()
  local depth = get_depth()
  depth.state.current = 8
  depth.state.min = 1
  depth.state.max = 10

  -- Try to increment past max
  depth.increment()
  depth.increment()
  depth.increment()
  depth.increment()

  expect.equality(depth.state.current, 10)

  -- Now decrement past min
  for _ = 1, 15 do
    depth.decrement()
  end

  expect.equality(depth.state.current, 1)
end

return T

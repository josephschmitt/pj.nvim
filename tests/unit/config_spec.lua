-- Tests for lua/pj/config.lua
-- Configuration module with deep merge functionality

local MiniTest = require("mini.test")
local expect = MiniTest.expect

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      -- Reset modules before each test
      package.loaded["pj.config"] = nil
      package.loaded["pj.depth"] = nil
    end,
  },
})

-- Helper to get a fresh config module
local function get_config()
  return require("pj.config")
end

-- =============================================================================
-- defaults tests
-- =============================================================================
T["defaults"] = MiniTest.new_set()

T["defaults"]["has expected top-level keys"] = function()
  local config = get_config()

  expect.no_equality(config.defaults.pj, nil)
  expect.no_equality(config.defaults.picker, nil)
  expect.no_equality(config.defaults.behavior, nil)
  expect.no_equality(config.defaults.keymaps, nil)
  expect.no_equality(config.defaults.depth, nil)
end

T["defaults"]["pj defaults are sensible"] = function()
  local config = get_config()

  expect.equality(config.defaults.pj.cmd, "auto")
  expect.equality(config.defaults.pj.icons, true)
  expect.equality(config.defaults.pj.cache, true)
  expect.equality(config.defaults.pj.json, true)
end

T["defaults"]["picker defaults to snacks"] = function()
  local config = get_config()

  expect.equality(config.defaults.picker.type, "snacks")
end

T["defaults"]["behavior defaults are sensible"] = function()
  local config = get_config()

  expect.equality(config.defaults.behavior.cd_on_select, true)
  expect.equality(config.defaults.behavior.cd_scope, "tab")
  expect.equality(config.defaults.behavior.close_on_select, true)
  expect.equality(config.defaults.behavior.notify_on_error, true)
  expect.equality(config.defaults.behavior.session_manager, nil)
end

T["defaults"]["keymaps have expected bindings"] = function()
  local config = get_config()

  expect.equality(config.defaults.keymaps.open, "<CR>")
  expect.equality(config.defaults.keymaps.split, "<C-x>")
  expect.equality(config.defaults.keymaps.vsplit, "<C-v>")
  expect.equality(config.defaults.keymaps.tab, "<C-t>")
  expect.equality(config.defaults.keymaps.depth_increase, "<C-l>")
  expect.equality(config.defaults.keymaps.depth_decrease, "<C-h>")
end

T["defaults"]["depth defaults allow full range"] = function()
  local config = get_config()

  expect.equality(config.defaults.depth.initial, nil)
  expect.equality(config.defaults.depth.min, 1)
  expect.equality(config.defaults.depth.max, 10)
end

-- =============================================================================
-- setup() tests
-- =============================================================================
T["setup"] = MiniTest.new_set()

T["setup"]["returns merged options"] = function()
  local config = get_config()

  local result = config.setup({})

  expect.no_equality(result, nil)
  expect.equality(type(result), "table")
end

T["setup"]["uses defaults when no options provided"] = function()
  local config = get_config()

  config.setup({})

  expect.equality(config.options.pj.cmd, "auto")
  expect.equality(config.options.picker.type, "snacks")
end

T["setup"]["overrides top-level values"] = function()
  local config = get_config()

  config.setup({
    picker = {
      type = "telescope",
    },
  })

  expect.equality(config.options.picker.type, "telescope")
end

T["setup"]["preserves nested defaults when overriding siblings"] = function()
  local config = get_config()

  config.setup({
    pj = {
      icons = false,
    },
  })

  -- Overridden value
  expect.equality(config.options.pj.icons, false)
  -- Preserved defaults
  expect.equality(config.options.pj.cmd, "auto")
  expect.equality(config.options.pj.cache, true)
  expect.equality(config.options.pj.json, true)
end

T["setup"]["deeply merges nested tables"] = function()
  local config = get_config()

  config.setup({
    picker = {
      telescope = {
        theme = "dropdown",
      },
    },
  })

  -- Overridden value
  expect.equality(config.options.picker.telescope.theme, "dropdown")
  -- Preserved nested defaults
  expect.equality(config.options.picker.telescope.previewer, false)
  expect.equality(config.options.picker.telescope.layout_config.width, 0.8)
end

T["setup"]["adds custom args to pj.args"] = function()
  local config = get_config()

  config.setup({
    pj = {
      args = { "--root", "/custom/path" },
    },
  })

  expect.equality(#config.options.pj.args, 2)
  expect.equality(config.options.pj.args[1], "--root")
  expect.equality(config.options.pj.args[2], "/custom/path")
end

T["setup"]["handles nil options gracefully"] = function()
  local config = get_config()

  config.setup(nil)

  -- Should use defaults
  expect.equality(config.options.pj.cmd, "auto")
end

T["setup"]["initializes depth module"] = function()
  local config = get_config()

  config.setup({
    depth = {
      initial = 5,
      min = 2,
      max = 8,
    },
  })

  local depth = require("pj.depth")
  -- Note: depth.setup is called by config.setup, so state should be set
  expect.equality(depth.state.current, 5)
  expect.equality(depth.state.min, 2)
  expect.equality(depth.state.max, 8)
end

-- =============================================================================
-- options persistence tests
-- =============================================================================
T["options"] = MiniTest.new_set()

T["options"]["starts as empty table"] = function()
  local config = get_config()

  expect.equality(type(config.options), "table")
end

T["options"]["is populated after setup"] = function()
  local config = get_config()

  config.setup({})

  expect.no_equality(config.options.pj, nil)
  expect.no_equality(config.options.picker, nil)
end

-- =============================================================================
-- edge cases
-- =============================================================================
T["edge_cases"] = MiniTest.new_set()

T["edge_cases"]["empty nested tables don't break merge"] = function()
  local config = get_config()

  config.setup({
    pj = {},
    picker = {},
    behavior = {},
  })

  -- All defaults should be preserved
  expect.equality(config.options.pj.cmd, "auto")
  expect.equality(config.options.picker.type, "snacks")
  expect.equality(config.options.behavior.cd_on_select, true)
end

T["edge_cases"]["can set behavior.session_manager"] = function()
  local config = get_config()

  config.setup({
    behavior = {
      session_manager = "auto-session",
    },
  })

  expect.equality(config.options.behavior.session_manager, "auto-session")
end

T["edge_cases"]["can override all keymaps"] = function()
  local config = get_config()

  config.setup({
    keymaps = {
      open = "<C-o>",
      split = "<C-s>",
      vsplit = "<C-v>",
      tab = "<C-n>",
      depth_increase = "<C-k>",
      depth_decrease = "<C-j>",
    },
  })

  expect.equality(config.options.keymaps.open, "<C-o>")
  expect.equality(config.options.keymaps.split, "<C-s>")
  expect.equality(config.options.keymaps.depth_increase, "<C-k>")
  expect.equality(config.options.keymaps.depth_decrease, "<C-j>")
end

return T

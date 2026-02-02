-- Tests for lua/pj/finder.lua
-- Parser functions are pure and easily testable

local MiniTest = require("mini.test")
local expect = MiniTest.expect
local helpers = require("helpers")

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      -- Reset modules before each test
      package.loaded["pj.finder"] = nil
      package.loaded["pj.config"] = nil
      package.loaded["pj.depth"] = nil
      package.loaded["pj.binary"] = nil
      package.loaded["pj.icons"] = nil

      -- Mock nvim-web-devicons to avoid dependency
      package.loaded["nvim-web-devicons"] = {
        get_icon = function(ft, _, opts)
          local mock_icons = {
            rs = { icon = "", hl = "DevIconRust" },
            js = { icon = "", hl = "DevIconJs" },
            go = { icon = "", hl = "DevIconGo" },
            py = { icon = "", hl = "DevIconPy" },
            git = { icon = "", hl = "DevIconGit" },
          }
          local data = mock_icons[ft]
          if data then
            return data.icon, data.hl
          end
          return nil, nil
        end,
      }
    end,
    post_case = function()
      package.loaded["nvim-web-devicons"] = nil
    end,
  },
})

-- Helper to get a fresh finder module
local function get_finder()
  return require("pj.finder")
end

-- =============================================================================
-- parse_output() tests - text format parsing
-- =============================================================================
T["parse_output"] = MiniTest.new_set()

T["parse_output"]["parses lines with icons"] = function()
  local finder = get_finder()
  local lines = {
    "🦀 /home/user/projects/rust-app",
    "📦 /home/user/projects/node-app",
  }

  local items = finder.parse_output(lines, true)

  expect.equality(#items, 2)
  expect.equality(items[1].data.icon, "🦀")
  expect.equality(items[1].data.name, "rust-app")
  expect.equality(items[2].data.icon, "📦")
  expect.equality(items[2].data.name, "node-app")
end

T["parse_output"]["parses lines without icons"] = function()
  local finder = get_finder()
  local lines = {
    "/home/user/projects/rust-app",
    "/home/user/projects/node-app",
  }

  local items = finder.parse_output(lines, false)

  expect.equality(#items, 2)
  expect.equality(items[1].data.icon, nil)
  expect.equality(items[1].data.name, "rust-app")
  expect.equality(items[2].data.icon, nil)
  expect.equality(items[2].data.name, "node-app")
end

T["parse_output"]["skips empty lines"] = function()
  local finder = get_finder()
  local lines = {
    "/home/user/projects/app1",
    "",
    "/home/user/projects/app2",
    "",
  }

  local items = finder.parse_output(lines, false)

  expect.equality(#items, 2)
end

T["parse_output"]["sets text to project name"] = function()
  local finder = get_finder()
  local lines = {
    "/home/user/my-awesome-project",
  }

  local items = finder.parse_output(lines, false)

  expect.equality(items[1].text, "my-awesome-project")
end

T["parse_output"]["sets file to full path"] = function()
  local finder = get_finder()
  local lines = {
    "/home/user/projects/app",
  }

  local items = finder.parse_output(lines, false)

  expect.equality(items[1].file, "/home/user/projects/app")
end

T["parse_output"]["handles paths with spaces"] = function()
  local finder = get_finder()
  local lines = {
    "🦀 /home/user/my project with spaces",
  }

  local items = finder.parse_output(lines, true)

  expect.equality(items[1].data.path, "/home/user/my project with spaces")
  expect.equality(items[1].data.name, "my project with spaces")
end

T["parse_output"]["handles nerd font icons (single char)"] = function()
  local finder = get_finder()
  local lines = {
    " /home/user/projects/rust-app", -- Nerd font icon
  }

  local items = finder.parse_output(lines, true)

  expect.equality(items[1].data.icon, "")
  expect.equality(items[1].data.path, "/home/user/projects/rust-app")
end

T["parse_output"]["returns empty table for empty input"] = function()
  local finder = get_finder()
  local items = finder.parse_output({}, false)

  expect.equality(#items, 0)
end

-- =============================================================================
-- parse_json_output() tests - JSON format parsing
-- =============================================================================
T["parse_json_output"] = MiniTest.new_set()

T["parse_json_output"]["parses valid JSON with projects"] = function()
  local finder = get_finder()
  local json_str = [[{
    "projects": [
      {"path": "/home/user/rust-app", "name": "rust-app", "marker": "Cargo.toml", "icon": "🦀"},
      {"path": "/home/user/node-app", "name": "node-app", "marker": "package.json", "icon": "📦"}
    ]
  }]]

  local items = finder.parse_json_output(json_str, true)

  expect.equality(#items, 2)
  expect.equality(items[1].data.name, "rust-app")
  expect.equality(items[1].data.marker, "Cargo.toml")
  expect.equality(items[2].data.name, "node-app")
  expect.equality(items[2].data.marker, "package.json")
end

T["parse_json_output"]["sets text to project name from JSON"] = function()
  local finder = get_finder()
  local json_str = [[{
    "projects": [
      {"path": "/home/user/my-project", "name": "my-project", "marker": ".git", "icon": ""}
    ]
  }]]

  local items = finder.parse_json_output(json_str, true)

  expect.equality(items[1].text, "my-project")
end

T["parse_json_output"]["sets file to full path from JSON"] = function()
  local finder = get_finder()
  local json_str = [[{
    "projects": [
      {"path": "/home/user/my-project", "name": "my-project", "marker": ".git", "icon": ""}
    ]
  }]]

  local items = finder.parse_json_output(json_str, true)

  expect.equality(items[1].file, "/home/user/my-project")
end

T["parse_json_output"]["returns error for invalid JSON"] = function()
  local finder = get_finder()

  local items, err = finder.parse_json_output("not valid json", true)

  expect.equality(items, nil)
  expect.equality(type(err), "string")
end

T["parse_json_output"]["returns error for JSON without projects key"] = function()
  local finder = get_finder()

  local items, err = finder.parse_json_output('{"data": []}', true)

  expect.equality(items, nil)
  expect.equality(type(err), "string")
end

T["parse_json_output"]["returns error for empty JSON object"] = function()
  local finder = get_finder()

  local items, err = finder.parse_json_output("{}", true)

  expect.equality(items, nil)
end

T["parse_json_output"]["handles empty projects array"] = function()
  local finder = get_finder()
  local json_str = '{"projects": []}'

  local items = finder.parse_json_output(json_str, true)

  expect.equality(#items, 0)
end

T["parse_json_output"]["includes icon_hl from icons module"] = function()
  local finder = get_finder()
  local json_str = [[{
    "projects": [
      {"path": "/home/user/rust-app", "name": "rust-app", "marker": "Cargo.toml", "icon": "🦀"}
    ]
  }]]

  local items = finder.parse_json_output(json_str, true)

  -- With our mock, Cargo.toml maps to "rs" which has DevIconRust
  expect.equality(items[1].data.icon_hl, "DevIconRust")
end

T["parse_json_output"]["handles projects without icon"] = function()
  local finder = get_finder()
  local json_str = [[{
    "projects": [
      {"path": "/home/user/project", "name": "project", "marker": ".git"}
    ]
  }]]

  local items = finder.parse_json_output(json_str, true)

  expect.equality(#items, 1)
  expect.equality(items[1].data.name, "project")
end

-- =============================================================================
-- parse_output() with fixture data
-- =============================================================================
T["parse_output_fixtures"] = MiniTest.new_set()

T["parse_output_fixtures"]["parses fixture file with icons"] = function()
  local finder = get_finder()
  local lines = helpers.fixture_lines("projects.txt")

  local items = finder.parse_output(lines, true)

  expect.equality(#items, 5)
  expect.equality(items[1].data.icon, "🦀")
  expect.equality(items[2].data.icon, "📦")
  expect.equality(items[3].data.icon, "🐹")
end

T["parse_output_fixtures"]["parses fixture file without icons"] = function()
  local finder = get_finder()
  local lines = helpers.fixture_lines("projects_no_icons.txt")

  local items = finder.parse_output(lines, false)

  expect.equality(#items, 5)
  for _, item in ipairs(items) do
    expect.equality(item.data.icon, nil)
  end
end

-- =============================================================================
-- parse_json_output() with fixture data
-- =============================================================================
T["parse_json_output_fixtures"] = MiniTest.new_set()

T["parse_json_output_fixtures"]["parses JSON fixture file"] = function()
  local finder = get_finder()
  local json_str = helpers.fixture("projects.json")

  local items = finder.parse_json_output(json_str, true)

  expect.equality(#items, 5)
  expect.equality(items[1].data.name, "my-rust-app")
  expect.equality(items[1].data.marker, "Cargo.toml")
  expect.equality(items[2].data.name, "node-server")
  expect.equality(items[3].data.name, "go-service")
end

return T

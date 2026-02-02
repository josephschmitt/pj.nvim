-- Tests for lua/pj/icons.lua
-- Icon lookup module with optional nvim-web-devicons dependency

local MiniTest = require("mini.test")
local expect = MiniTest.expect

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      -- Reset the icons module before each test
      package.loaded["pj.icons"] = nil
    end,
  },
})

-- Helper to get a fresh icons module
local function get_icons()
  return require("pj.icons")
end

-- =============================================================================
-- marker_filetypes mapping tests
-- =============================================================================
T["marker_filetypes"] = MiniTest.new_set()

T["marker_filetypes"]["has expected Go mapping"] = function()
  local icons = get_icons()
  expect.equality(icons.marker_filetypes["go.mod"], "go")
end

T["marker_filetypes"]["has expected Rust mapping"] = function()
  local icons = get_icons()
  expect.equality(icons.marker_filetypes["Cargo.toml"], "rs")
end

T["marker_filetypes"]["has expected Node mapping"] = function()
  local icons = get_icons()
  expect.equality(icons.marker_filetypes["package.json"], "js")
end

T["marker_filetypes"]["has expected Python mapping"] = function()
  local icons = get_icons()
  expect.equality(icons.marker_filetypes["pyproject.toml"], "py")
end

T["marker_filetypes"]["has expected Nix mapping"] = function()
  local icons = get_icons()
  expect.equality(icons.marker_filetypes["flake.nix"], "nix")
end

T["marker_filetypes"]["has expected Git mapping"] = function()
  local icons = get_icons()
  expect.equality(icons.marker_filetypes[".git"], "git")
end

T["marker_filetypes"]["has expected Makefile mapping"] = function()
  local icons = get_icons()
  expect.equality(icons.marker_filetypes["Makefile"], "Makefile")
end

-- =============================================================================
-- get_icon_hl() tests without nvim-web-devicons
-- =============================================================================
T["get_icon_hl_no_devicons"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      -- Ensure nvim-web-devicons is not available
      package.loaded["nvim-web-devicons"] = nil
      package.preload["nvim-web-devicons"] = function()
        error("nvim-web-devicons not available")
      end
      package.loaded["pj.icons"] = nil
    end,
    post_case = function()
      -- Clean up the preload
      package.preload["nvim-web-devicons"] = nil
    end,
  },
})

T["get_icon_hl_no_devicons"]["returns empty string and nil without devicons"] = function()
  local icons = get_icons()

  local icon, hl = icons.get_icon_hl("go.mod", nil)

  expect.equality(icon, "")
  expect.equality(hl, nil)
end

T["get_icon_hl_no_devicons"]["returns fallback icon when provided"] = function()
  local icons = get_icons()

  local icon, hl = icons.get_icon_hl("go.mod", "🔷")

  expect.equality(icon, "🔷")
  expect.equality(hl, nil)
end

T["get_icon_hl_no_devicons"]["returns fallback for unknown marker"] = function()
  local icons = get_icons()

  local icon, hl = icons.get_icon_hl("unknown.marker", "❓")

  expect.equality(icon, "❓")
  expect.equality(hl, nil)
end

-- =============================================================================
-- get_icon_hl() tests with mocked nvim-web-devicons
-- =============================================================================
T["get_icon_hl_with_devicons"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      -- Create a mock nvim-web-devicons module
      package.loaded["nvim-web-devicons"] = {
        get_icon = function(ft, _, opts)
          -- Mock implementation
          local mock_icons = {
            go = { icon = "", hl = "DevIconGo" },
            rs = { icon = "", hl = "DevIconRust" },
            js = { icon = "", hl = "DevIconJs" },
            py = { icon = "", hl = "DevIconPy" },
            nix = { icon = "", hl = "DevIconNix" },
            git = { icon = "", hl = "DevIconGit" },
            Makefile = { icon = "", hl = "DevIconMakefile" },
          }
          local data = mock_icons[ft]
          if data then
            return data.icon, data.hl
          end
          return nil, nil
        end,
      }
      package.loaded["pj.icons"] = nil
    end,
    post_case = function()
      package.loaded["nvim-web-devicons"] = nil
    end,
  },
})

T["get_icon_hl_with_devicons"]["returns icon and highlight for known marker"] = function()
  local icons = get_icons()

  local icon, hl = icons.get_icon_hl("go.mod", nil)

  -- Should use fallback (which is nil), getting the devicons icon
  expect.equality(hl, "DevIconGo")
end

T["get_icon_hl_with_devicons"]["prefers fallback icon over devicons icon"] = function()
  local icons = get_icons()

  local icon, hl = icons.get_icon_hl("Cargo.toml", "🦀")

  -- Fallback icon should be preferred
  expect.equality(icon, "🦀")
  expect.equality(hl, "DevIconRust")
end

T["get_icon_hl_with_devicons"]["returns highlight for js/package.json"] = function()
  local icons = get_icons()

  local _, hl = icons.get_icon_hl("package.json", nil)

  expect.equality(hl, "DevIconJs")
end

T["get_icon_hl_with_devicons"]["returns fallback for unmapped marker even with devicons"] = function()
  local icons = get_icons()

  local icon, hl = icons.get_icon_hl("random.file", "🔹")

  -- Unknown marker - should return fallback, no highlight
  expect.equality(icon, "🔹")
  expect.equality(hl, nil)
end

-- =============================================================================
-- edge cases
-- =============================================================================
T["edge_cases"] = MiniTest.new_set()

T["edge_cases"]["handles nil marker gracefully"] = function()
  local icons = get_icons()

  local icon, hl = icons.get_icon_hl(nil, "❓")

  expect.equality(icon, "❓")
  expect.equality(hl, nil)
end

T["edge_cases"]["handles empty string marker"] = function()
  local icons = get_icons()

  local icon, hl = icons.get_icon_hl("", "❓")

  expect.equality(icon, "❓")
  expect.equality(hl, nil)
end

return T

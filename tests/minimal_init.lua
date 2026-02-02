-- Minimal init for test environment
-- This file sets up the minimum required to run tests

-- Get plugin root from this file's location
local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")

-- Set up runtimepath to include the plugin
vim.opt.runtimepath:prepend(plugin_root)

-- Add mini.nvim to runtimepath for mini.test
local mini_nvim_path = plugin_root .. "/test-deps/mini.nvim"
if vim.fn.isdirectory(mini_nvim_path) == 1 then
  vim.opt.runtimepath:prepend(mini_nvim_path)
end

-- Add tests directory to lua path for helpers
package.path = plugin_root .. "/tests/?.lua;" .. package.path

-- Disable swap files and other distractions
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Make sure we can load pj modules
vim.opt.runtimepath:append(plugin_root .. "/lua")

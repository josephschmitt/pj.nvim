-- Only load once
if vim.g.loaded_pj then
  return
end
vim.g.loaded_pj = true

-- Create user commands
vim.api.nvim_create_user_command("Pj", function()
  require("pj").open()
end, {
  desc = "Open project picker",
  nargs = 0,
})

vim.api.nvim_create_user_command("PjCd", function()
  require("pj").cd()
end, {
  desc = "Change to project directory",
  nargs = 0,
})

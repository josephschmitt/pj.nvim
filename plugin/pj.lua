-- Only load once
if vim.g.loaded_pj then
  return
end
vim.g.loaded_pj = true

-- Create user commands only if they don't exist (lazy.nvim might create them)
if vim.fn.exists(":Pj") == 0 then
  vim.api.nvim_create_user_command("Pj", function(opts)
    require("pj").open(opts)
  end, {
    desc = "Open project picker",
  })
end

if vim.fn.exists(":PjCd") == 0 then
  vim.api.nvim_create_user_command("PjCd", function(opts)
    require("pj").cd(opts)
  end, {
    desc = "Change to project directory",
  })
end

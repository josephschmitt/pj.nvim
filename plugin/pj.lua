-- Only load once
if vim.g.loaded_pj then
  return
end
vim.g.loaded_pj = true

-- Parse command arguments (key=value pairs)
local function parse_command_args(fargs)
  local result = {}
  for _, arg in ipairs(fargs) do
    local key, value = arg:match("([^=]+)=(.*)")
    if key then
      key = vim.trim(key)
      value = vim.trim(value)
      -- Convert to appropriate types
      if value == "true" then
        result[key] = true
      elseif value == "false" then
        result[key] = false
      elseif tonumber(value) then
        result[key] = tonumber(value)
      else
        result[key] = value
      end
    end
  end
  return result
end

-- Create user commands only if they don't exist (lazy.nvim might create them)
if vim.fn.exists(":Pj") == 0 then
  vim.api.nvim_create_user_command("Pj", function(opts)
    local pj_opts = parse_command_args(opts.fargs)
    require("pj").open(pj_opts)
  end, {
    nargs = "*",
    desc = "Open project picker (e.g., :Pj depth=2)",
  })
end

if vim.fn.exists(":PjCd") == 0 then
  vim.api.nvim_create_user_command("PjCd", function(opts)
    require("pj").cd(opts)
  end, {
    desc = "Change to project directory",
  })
end

-- Binary management commands (for auto mode)
if vim.fn.exists(":PjCheckUpdates") == 0 then
  vim.api.nvim_create_user_command("PjCheckUpdates", function()
    require("pj.binary").check_for_updates_manual()
  end, {
    desc = "Check for pj binary updates",
  })
end

if vim.fn.exists(":PjUpdate") == 0 then
  vim.api.nvim_create_user_command("PjUpdate", function()
    require("pj.binary").update_with_progress()
  end, {
    desc = "Update pj binary to latest version",
  })
end

if vim.fn.exists(":PjReinstall") == 0 then
  vim.api.nvim_create_user_command("PjReinstall", function()
    require("pj.binary").reinstall()
  end, {
    desc = "Force reinstall pj binary",
  })
end

if vim.fn.exists(":PjUninstall") == 0 then
  vim.api.nvim_create_user_command("PjUninstall", function()
    require("pj.binary").uninstall()
  end, {
    desc = "Remove auto-downloaded pj binary",
  })
end

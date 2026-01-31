local M = {}

M.open = function(opts)
  opts = opts or {}
  local config = require("pj.config").options
  local finder = require("pj.finder")

  -- Check binary
  if not finder.check_binary() then
    if config.behavior.notify_on_error then
      vim.notify("pj binary not found. Please install it first.", vim.log.levels.ERROR)
    end
    return
  end

  -- Get tv config
  local tv_config = config.picker.tv or {}
  local tv_binary = tv_config.tv_binary or "tv"

  -- Check if television binary is available
  if vim.fn.executable(tv_binary) ~= 1 then
    if config.behavior.notify_on_error then
      vim.notify("television binary not found. Please install it from https://github.com/alexpasmantier/television", vim.log.levels.ERROR)
    end
    return
  end

  -- Build pj command
  local pj_cmd = config.pj.cmd
  local args = vim.list_extend({}, config.pj.args or {})

  -- Don't use JSON for tv, we want simple line output
  -- Add flags based on config
  if not config.pj.cache then
    table.insert(args, "--no-cache")
  end
  if config.pj.icons then
    table.insert(args, "--icons")
  end

  -- Add runtime opts
  if opts.no_cache then
    table.insert(args, "--no-cache")
  end

  local full_pj_cmd = pj_cmd
  if #args > 0 then
    full_pj_cmd = full_pj_cmd .. " " .. table.concat(args, " ")
  end

  -- Build television command with custom source
  local tv_cmd_parts = {
    tv_binary,
    "--source-command", vim.fn.shellescape(full_pj_cmd),
  }

  -- Add preview if configured
  if tv_config.preview and tv_config.preview.enabled then
    table.insert(tv_cmd_parts, "--preview-command")
    table.insert(tv_cmd_parts, vim.fn.shellescape(tv_config.preview.cmd or "ls -la {}"))
  end

  -- Add preview size if configured
  if tv_config.preview and tv_config.preview.size then
    table.insert(tv_cmd_parts, "--preview-size")
    table.insert(tv_cmd_parts, tostring(tv_config.preview.size))
  end

  local tv_cmd = table.concat(tv_cmd_parts, " ")

  -- Create a temporary file to capture output
  local tmpfile = vim.fn.tempname()
  local full_cmd = tv_cmd .. " > " .. vim.fn.shellescape(tmpfile)

  -- Save current window
  local original_win = vim.api.nvim_get_current_win()

  -- Create a new terminal buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  -- Open in current window
  vim.api.nvim_set_current_buf(buf)

  -- Start terminal with tv command
  local job_id = vim.fn.termopen(full_cmd, {
    on_exit = function(_, exit_code)
      -- Close the terminal buffer
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end

        -- Return to original window if it's still valid
        if vim.api.nvim_win_is_valid(original_win) then
          vim.api.nvim_set_current_win(original_win)
        end

        -- Handle selection if exit was successful
        if exit_code == 0 then
          -- Read the selected entry from tmpfile
          local f = io.open(tmpfile, "r")
          if f then
            local content = f:read("*all")
            f:close()
            os.remove(tmpfile)

            local selected = vim.trim(content)
            if selected ~= "" then
              -- Parse the selected entry
              -- Format could be: "icon path" or just "path"
              local path = selected
              if config.pj.icons then
                -- Remove icon (first word/characters before space)
                local first_space = selected:find(" ")
                if first_space then
                  path = vim.trim(selected:sub(first_space + 1))
                end
              end

              -- Expand path to absolute
              path = vim.fn.expand(path)

              -- Get the project name from the path
              local name = vim.fn.fnamemodify(path, ":t")

              -- Handle different open modes based on opts
              if opts.split then
                vim.cmd("split")
              elseif opts.vsplit then
                vim.cmd("vsplit")
              elseif opts.tab then
                vim.cmd("tabnew")
              end

              -- Switch to project (handles directory change and session loading)
              local session = require("pj.session")
              session.switch_to_project(path, name, config)
            end
          else
            os.remove(tmpfile)
          end
        elseif exit_code == 130 then
          -- User cancelled (Ctrl-C), just clean up
          os.remove(tmpfile)
        else
          -- Error occurred
          os.remove(tmpfile)
          if config.behavior.notify_on_error then
            vim.notify("Television exited with code: " .. exit_code, vim.log.levels.WARN)
          end
        end
      end)
    end,
  })

  if job_id <= 0 then
    if config.behavior.notify_on_error then
      vim.notify("Failed to start television", vim.log.levels.ERROR)
    end
    -- Clean up tmpfile on failure
    os.remove(tmpfile)
  else
    -- Enter terminal mode
    vim.cmd("startinsert")
  end
end

return M

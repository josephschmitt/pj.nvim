local M = {}

-- Cache directory structure:
-- ~/.local/share/nvim/pj-nvim/
--   ├── bin/
--   │   └── pj (or pj.exe on Windows)
--   └── metadata.json (version info, last check)

local uv = vim.loop or vim.uv

-- Platform detection
local function get_platform()
  local uname = uv.os_uname()
  local sysname = uname.sysname:lower()
  local machine = uname.machine

  -- Normalize OS name
  local os_name
  if sysname:find("darwin") then
    os_name = "darwin"
  elseif sysname:find("linux") then
    os_name = "linux"
  elseif sysname:find("windows") or sysname:find("mingw") or sysname:find("msys") then
    os_name = "windows"
  else
    return nil, nil, "Unsupported operating system: " .. sysname
  end

  -- Normalize architecture
  local arch
  if machine == "x86_64" or machine == "amd64" then
    arch = "amd64"
  elseif machine == "aarch64" or machine == "arm64" then
    arch = "arm64"
  else
    return nil, nil, "Unsupported architecture: " .. machine
  end

  return os_name, arch, nil
end

-- Get paths for binary storage
local function get_paths()
  local data_dir = vim.fn.stdpath("data")
  local base_dir = data_dir .. "/pj-nvim"
  local bin_dir = base_dir .. "/bin"
  local metadata_file = base_dir .. "/metadata.json"

  local os_name = get_platform()
  local binary_name = os_name == "windows" and "pj.exe" or "pj"
  local binary_path = bin_dir .. "/" .. binary_name

  return {
    base_dir = base_dir,
    bin_dir = bin_dir,
    binary_path = binary_path,
    binary_name = binary_name,
    metadata_file = metadata_file,
  }
end

-- Ensure directory exists
local function ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, "p")
  end
end

-- Read metadata file
local function read_metadata()
  local paths = get_paths()
  if vim.fn.filereadable(paths.metadata_file) == 0 then
    return nil
  end

  local content = vim.fn.readfile(paths.metadata_file)
  if #content == 0 then
    return nil
  end

  local ok, data = pcall(vim.fn.json_decode, table.concat(content, "\n"))
  if not ok then
    return nil
  end

  return data
end

-- Write metadata file
local function write_metadata(data)
  local paths = get_paths()
  ensure_dir(paths.base_dir)

  local json = vim.fn.json_encode(data)
  vim.fn.writefile({ json }, paths.metadata_file)
end

-- Check if system binary is available
local function check_system_binary()
  return vim.fn.executable("pj") == 1
end

-- Get the latest release version from GitHub
local function get_latest_version(callback)
  local config = require("pj.config").options
  local repo = config.pj.auto and config.pj.auto.github_repo or "josephschmitt/pj"
  local url = "https://api.github.com/repos/" .. repo .. "/releases/latest"

  -- Use curl to fetch the latest release
  local cmd
  local os_name = get_platform()
  if os_name == "windows" then
    cmd = string.format('curl -sL -H "Accept: application/vnd.github.v3+json" "%s"', url)
  else
    cmd = string.format("curl -sL -H 'Accept: application/vnd.github.v3+json' '%s'", url)
  end

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local json_str = table.concat(data, "")
        local ok, release = pcall(vim.fn.json_decode, json_str)
        if ok and release and release.tag_name then
          -- Remove 'v' prefix if present
          local version = release.tag_name:gsub("^v", "")
          callback(version, nil)
        else
          callback(nil, "Failed to parse GitHub release response")
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 and data[1] ~= "" then
        callback(nil, "Failed to fetch release info: " .. table.concat(data, ""))
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        callback(nil, "Failed to fetch release info (exit code: " .. code .. ")")
      end
    end,
  })
end

-- Build download URL for the binary
local function build_download_url(version)
  local os_name, arch, err = get_platform()
  if err then
    return nil, err
  end

  local config = require("pj.config").options
  local repo = config.pj.auto and config.pj.auto.github_repo or "josephschmitt/pj"

  -- Asset name format: pj_{version}_{os}_{arch}.tar.gz
  local asset_name = string.format("pj_%s_%s_%s.tar.gz", version, os_name, arch)
  local url = string.format("https://github.com/%s/releases/download/v%s/%s", repo, version, asset_name)

  return url, nil
end

-- Download and extract the binary
local function download_binary(version, callback)
  local url, err = build_download_url(version)
  if err then
    callback(false, err)
    return
  end

  local paths = get_paths()
  local os_name = get_platform()

  -- Ensure directories exist
  ensure_dir(paths.base_dir)
  ensure_dir(paths.bin_dir)

  -- Create temp directory for download
  local temp_dir = vim.fn.tempname()
  vim.fn.mkdir(temp_dir, "p")
  local archive_path = temp_dir .. "/pj.tar.gz"

  vim.notify("Downloading pj binary v" .. version .. "...", vim.log.levels.INFO)

  -- Download command
  local download_cmd
  if os_name == "windows" then
    download_cmd = string.format('curl -sL -o "%s" "%s"', archive_path, url)
  else
    download_cmd = string.format("curl -sL -o '%s' '%s'", archive_path, url)
  end

  vim.fn.jobstart(download_cmd, {
    on_exit = function(_, download_code)
      if download_code ~= 0 then
        vim.fn.delete(temp_dir, "rf")
        vim.schedule(function()
          callback(false, "Failed to download binary (exit code: " .. download_code .. ")")
        end)
        return
      end

      vim.schedule(function()
        vim.notify("Extracting pj binary...", vim.log.levels.INFO)
      end)

      -- Extract command
      local extract_cmd
      if os_name == "windows" then
        extract_cmd = string.format('tar -xzf "%s" -C "%s"', archive_path, temp_dir)
      else
        extract_cmd = string.format("tar -xzf '%s' -C '%s'", archive_path, temp_dir)
      end

      vim.fn.jobstart(extract_cmd, {
        on_exit = function(_, extract_code)
          if extract_code ~= 0 then
            vim.fn.delete(temp_dir, "rf")
            vim.schedule(function()
              callback(false, "Failed to extract binary (exit code: " .. extract_code .. ")")
            end)
            return
          end

          -- Move binary to bin directory
          local extracted_binary = temp_dir .. "/" .. paths.binary_name
          if vim.fn.filereadable(extracted_binary) == 0 then
            vim.fn.delete(temp_dir, "rf")
            vim.schedule(function()
              callback(false, "Binary not found in archive")
            end)
            return
          end

          -- Copy binary to final location
          local copy_ok = vim.fn.rename(extracted_binary, paths.binary_path)
          if copy_ok ~= 0 then
            -- Try copy instead of rename (cross-filesystem)
            vim.fn.writefile(vim.fn.readfile(extracted_binary, "b"), paths.binary_path, "b")
          end

          -- Set executable permissions on Unix
          if os_name ~= "windows" then
            vim.fn.system("chmod +x '" .. paths.binary_path .. "'")
          end

          -- Clean up temp directory
          vim.fn.delete(temp_dir, "rf")

          -- Verify the binary works
          local verify_cmd = paths.binary_path .. " --version"
          local verify_result = vim.fn.system(verify_cmd)
          if vim.v.shell_error ~= 0 then
            vim.fn.delete(paths.binary_path)
            vim.schedule(function()
              callback(false, "Downloaded binary failed verification")
            end)
            return
          end

          -- Update metadata
          write_metadata({
            version = version,
            installed_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            last_check = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            platform = os_name .. "_" .. (select(2, get_platform())),
            binary_path = paths.binary_path,
          })

          vim.schedule(function()
            vim.notify("pj binary v" .. version .. " installed successfully!", vim.log.levels.INFO)
            callback(true, nil)
          end)
        end,
      })
    end,
  })
end

-- Get the path to the pj binary (auto-download if needed)
-- This is a synchronous check, async download happens separately
M.get_binary_path = function()
  local config = require("pj.config").options

  -- If not in auto mode, return nil (use config.pj.cmd directly)
  if config.pj.cmd ~= "auto" then
    return nil
  end

  local auto_config = config.pj.auto or {}

  -- Check system binary first if preferred
  if auto_config.prefer_system ~= false and check_system_binary() then
    return "pj"
  end

  -- Check if we have a cached binary
  local paths = get_paths()
  if vim.fn.executable(paths.binary_path) == 1 then
    return paths.binary_path
  end

  return nil
end

-- Ensure binary is available (triggers download if needed)
-- Returns immediately, download happens async
M.ensure_binary = function(callback)
  callback = callback or function() end

  local config = require("pj.config").options

  if config.pj.cmd ~= "auto" then
    callback(true, nil)
    return
  end

  local auto_config = config.pj.auto or {}

  -- Check system binary first if preferred
  if auto_config.prefer_system ~= false and check_system_binary() then
    callback(true, nil)
    return
  end

  -- Check if we have a cached binary
  local paths = get_paths()
  if vim.fn.executable(paths.binary_path) == 1 then
    callback(true, nil)
    return
  end

  -- Need to download - check if curl is available
  if vim.fn.executable("curl") ~= 1 then
    local err = "curl is required for auto-download but not found"
    vim.notify(err, vim.log.levels.ERROR)
    callback(false, err)
    return
  end

  -- Get latest version and download
  get_latest_version(function(version, err)
    if err then
      vim.schedule(function()
        vim.notify("Failed to get pj version: " .. err, vim.log.levels.ERROR)
        callback(false, err)
      end)
      return
    end

    download_binary(version, callback)
  end)
end

-- Check if binary needs update
M.check_for_updates = function(callback)
  callback = callback or function() end

  local config = require("pj.config").options
  if config.pj.cmd ~= "auto" then
    callback(false, nil, nil)
    return
  end

  local auto_config = config.pj.auto or {}
  if not auto_config.check_updates then
    callback(false, nil, nil)
    return
  end

  local metadata = read_metadata()
  if not metadata then
    callback(false, nil, nil)
    return
  end

  -- Check if enough time has passed since last check
  local update_interval = auto_config.update_interval or 7
  if metadata.last_check then
    local last_check = metadata.last_check
    -- Simple date comparison (just check if more than N days)
    local now = os.date("!%Y-%m-%d")
    local last = last_check:sub(1, 10)
    -- This is a rough check - good enough for our purposes
    if now == last then
      callback(false, metadata.version, nil)
      return
    end
  end

  get_latest_version(function(latest_version, err)
    if err then
      callback(false, nil, err)
      return
    end

    -- Update last check time
    metadata.last_check = os.date("!%Y-%m-%dT%H:%M:%SZ")
    write_metadata(metadata)

    local needs_update = latest_version ~= metadata.version
    callback(needs_update, latest_version, nil)
  end)
end

-- Update the binary to a specific version
M.update = function(version, callback)
  callback = callback or function() end

  if not version then
    get_latest_version(function(latest_version, err)
      if err then
        vim.schedule(function()
          vim.notify("Failed to get latest version: " .. err, vim.log.levels.ERROR)
          callback(false, err)
        end)
        return
      end
      download_binary(latest_version, callback)
    end)
  else
    download_binary(version, callback)
  end
end

-- Get status information about the binary
M.get_status = function()
  local config = require("pj.config").options
  local paths = get_paths()
  local metadata = read_metadata()

  local status = {
    mode = config.pj.cmd,
    auto_enabled = config.pj.cmd == "auto",
    system_available = check_system_binary(),
    cached_available = vim.fn.executable(paths.binary_path) == 1,
    cached_path = paths.binary_path,
    version = metadata and metadata.version or nil,
    platform = metadata and metadata.platform or nil,
    installed_at = metadata and metadata.installed_at or nil,
    last_check = metadata and metadata.last_check or nil,
  }

  -- Determine which binary will be used
  if config.pj.cmd == "auto" then
    local auto_config = config.pj.auto or {}
    if auto_config.prefer_system ~= false and status.system_available then
      status.active_binary = "system"
      status.active_path = "pj"
    elseif status.cached_available then
      status.active_binary = "cached"
      status.active_path = paths.binary_path
    else
      status.active_binary = "none"
      status.active_path = nil
    end
  else
    status.active_binary = "configured"
    status.active_path = config.pj.cmd
  end

  return status
end

-- Get platform info
M.get_platform_info = function()
  local os_name, arch, err = get_platform()
  return {
    os = os_name,
    arch = arch,
    error = err,
    supported = err == nil,
  }
end

return M

local M = {}

-- Marker -> filetype for nvim-web-devicons lookup
M.marker_filetypes = {
  ["go.mod"] = "go",
  ["Cargo.toml"] = "rs",
  ["package.json"] = "js",
  ["pyproject.toml"] = "py",
  ["flake.nix"] = "nix",
  [".git"] = "git",
  ["Makefile"] = "Makefile",
}

-- Get icon and highlight group for a marker
function M.get_icon_hl(marker, fallback_icon)
  local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
  if devicons_ok then
    local ft = M.marker_filetypes[marker]
    if ft then
      local icon, hl = devicons.get_icon(ft, nil, { default = false })
      if hl then
        return fallback_icon or icon or "", hl
      end
    end
  end
  return fallback_icon or "", nil
end

return M

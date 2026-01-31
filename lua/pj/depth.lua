local M = {}

-- Depth state management for dynamic depth control in pickers
M.state = {
  current = nil, -- nil means use pj's default
  pj_default = 3, -- pj binary's default depth
  min = 1,
  max = 10,
}

-- Initialize depth from config
M.setup = function(config)
  if config and config.depth then
    M.state.current = config.depth.initial
    M.state.min = config.depth.min or 1
    M.state.max = config.depth.max or 10
  end
end

-- Get current depth (nil means use pj default)
M.get_current = function()
  return M.state.current
end

-- Set depth directly
M.set = function(depth)
  if depth then
    M.state.current = math.max(M.state.min, math.min(M.state.max, depth))
  else
    M.state.current = nil
  end
  return M.state.current
end

-- Increment depth, returns new depth and whether it changed
M.increment = function()
  local old = M.state.current or M.state.pj_default
  if old >= M.state.max then
    return old, false
  end
  M.state.current = old + 1
  return M.state.current, true
end

-- Decrement depth, returns new depth and whether it changed
M.decrement = function()
  local old = M.state.current or M.state.pj_default
  if old <= M.state.min then
    return old, false
  end
  M.state.current = old - 1
  return M.state.current, true
end

-- Reset to initial/default
M.reset = function()
  local config = require("pj.config").options
  M.state.current = config.depth and config.depth.initial or nil
end

-- Get display string for current depth
M.get_display = function()
  if M.state.current then
    return string.format("depth: %d", M.state.current)
  end
  return "depth: default"
end

return M

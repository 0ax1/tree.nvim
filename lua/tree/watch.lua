--- Filesystem watcher using libuv fs_event.
--- One watcher per expanded directory, synced after each redraw.
--- Changes are debounced (200ms) to avoid redundant refreshes.
local M = {}

---@type table<string, uv_fs_event_t>
local watchers = {}
local debounce_timer = nil
local debounce_ms = 200
local on_change = nil

local function schedule_refresh()
  if debounce_timer then
    debounce_timer:stop()
  end
  debounce_timer = vim.uv.new_timer()
  debounce_timer:start(debounce_ms, 0, vim.schedule_wrap(function()
    debounce_timer:close()
    debounce_timer = nil
    if on_change then on_change() end
  end))
end

local function start_watcher(path)
  if watchers[path] then return end
  local handle = vim.uv.new_fs_event()
  if not handle then return end
  local ok = handle:start(path, {}, function(err)
    if err then return end
    schedule_refresh()
  end)
  if ok == 0 then
    watchers[path] = handle
  else
    handle:close()
  end
end

local function stop_watcher(path)
  local handle = watchers[path]
  if handle then
    handle:stop()
    handle:close()
    watchers[path] = nil
  end
end

--- Update watchers to match the set of currently expanded directories.
--- Starts new watchers and stops stale ones.
---@param flat {node: TreeNode, depth: number}[]
function M.sync(flat)
  local open_dirs = {}
  for _, entry in ipairs(flat) do
    if entry.node.type == "directory" and entry.node.open then
      open_dirs[entry.node.path] = true
    end
  end
  for path in pairs(watchers) do
    if not open_dirs[path] then
      stop_watcher(path)
    end
  end
  for path in pairs(open_dirs) do
    start_watcher(path)
  end
end

--- Stop and close all active watchers.
function M.stop_all()
  for path in pairs(watchers) do
    stop_watcher(path)
  end
end

--- Register the callback invoked (debounced) when any watched directory changes.
---@param callback function
function M.setup(callback)
  on_change = callback
end

return M

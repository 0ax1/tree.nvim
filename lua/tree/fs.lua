local M = {}

---@class TreeNode
---@field name string
---@field path string
---@field type "file"|"directory"
---@field open boolean
---@field children TreeNode[]|nil

---@type TreeNode|nil
local root = nil

local function scandir(path)
  local handle = vim.uv.fs_scandir(path)
  if not handle then return {} end
  local entries = {}
  while true do
    local name, typ = vim.uv.fs_scandir_next(handle)
    if not name then break end
    entries[#entries + 1] = {
      name = name,
      path = path .. "/" .. name,
      type = typ == "directory" and "directory" or "file",
      open = false,
      children = nil,
    }
  end
  table.sort(entries, function(a, b)
    if a.type ~= b.type then
      return a.type == "directory"
    end
    return a.name:lower() < b.name:lower()
  end)
  return entries
end

function M.set_root(path)
  path = vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
  root = {
    name = vim.fn.fnamemodify(path, ":t"),
    path = path,
    type = "directory",
    open = true,
    children = scandir(path),
  }
  return root
end

function M.get_root()
  return root
end

function M.toggle_dir(node)
  if node.type ~= "directory" then return end
  if node.open then
    node.open = false
    node.children = nil
  else
    node.open = true
    node.children = scandir(node.path)
  end
end

function M.refresh_node(node)
  if node.type ~= "directory" or not node.open then return end
  local old = {}
  if node.children then
    for _, child in ipairs(node.children) do
      old[child.path] = child
    end
  end
  local new_children = scandir(node.path)
  for i, child in ipairs(new_children) do
    local prev = old[child.path]
    if prev and prev.type == "directory" and prev.open then
      new_children[i] = prev
      M.refresh_node(prev)
    end
  end
  node.children = new_children
end

function M.refresh()
  if root then
    M.refresh_node(root)
  end
end

--- Expand directories along a path so the target file is visible
---@param target string absolute path to reveal
---@return boolean true if the path was found within the tree
function M.expand_to(target)
  if not root then return false end
  -- target must be under root
  if target:sub(1, #root.path) ~= root.path then return false end

  local function walk(node)
    if node.path == target then return true end
    if node.type ~= "directory" then return false end
    if target:sub(1, #node.path + 1) ~= node.path .. "/" then return false end
    -- this dir is an ancestor — ensure it's open
    if not node.open then
      node.open = true
      node.children = scandir(node.path)
    end
    if node.children then
      for _, child in ipairs(node.children) do
        if walk(child) then return true end
      end
    end
    return false
  end

  return walk(root)
end

--- Flatten tree into ordered list of {node, depth} pairs
---@return {node: TreeNode, depth: number}[]
function M.flatten()
  local result = {}
  local function walk(node, depth)
    result[#result + 1] = { node = node, depth = depth }
    if node.open and node.children then
      for _, child in ipairs(node.children) do
        walk(child, depth + 1)
      end
    end
  end
  if root then
    walk(root, 0)
  end
  return result
end

return M

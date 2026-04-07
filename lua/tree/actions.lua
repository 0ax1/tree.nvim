--- File operations: create, delete, rename, copy/cut/paste.
--- All mutations refresh the tree and git status afterwards.
local fs = require("tree.fs")

local M = {}

local function refresh_tree()
  fs.refresh()
  require("tree.git").refresh(fs.get_root().path, function()
    require("tree.render").draw()
  end)
end

--- Prompt to create a new file or directory under `parent_path`.
--- Append `/` to the name to create a directory.
function M.create(parent_path)
  vim.ui.input({ prompt = "New file/dir (end with / for dir): " }, function(name)
    if not name or name == "" then return end
    local path = parent_path .. "/" .. name
    if name:sub(-1) == "/" then
      vim.fn.mkdir(path:sub(1, -2), "p")
    else
      local dir = vim.fn.fnamemodify(path, ":h")
      vim.fn.mkdir(dir, "p")
      local fd = vim.uv.fs_open(path, "w", 420) -- 0644
      if fd then vim.uv.fs_close(fd) end
    end
    refresh_tree()
  end)
end

--- Prompt to delete a node (with confirmation).
function M.delete(node)
  if node.path == fs.get_root().path then return end
  vim.ui.input({ prompt = "Delete " .. node.name .. "? (y/N): " }, function(ans)
    if ans ~= "y" and ans ~= "Y" then return end
    if node.type == "directory" then
      vim.fn.delete(node.path, "rf")
    else
      vim.fn.delete(node.path)
    end
    refresh_tree()
  end)
end

--- Prompt to rename a node.
function M.rename(node)
  if node.path == fs.get_root().path then return end
  vim.ui.input({ prompt = "Rename: ", default = node.name }, function(name)
    if not name or name == "" or name == node.name then return end
    local dir = vim.fn.fnamemodify(node.path, ":h")
    local new_path = dir .. "/" .. name
    vim.uv.fs_rename(node.path, new_path)
    refresh_tree()
  end)
end

---@type TreeNode|nil
local clipboard = nil
local clip_op = nil ---@type "copy"|"cut"|nil

--- Yank a node for later paste.
function M.copy(node)
  clipboard = node
  clip_op = "copy"
  vim.notify("Copied: " .. node.name)
end

--- Cut a node for later paste (moves on paste).
function M.cut(node)
  clipboard = node
  clip_op = "cut"
  vim.notify("Cut: " .. node.name)
end

--- Paste the clipboard into `dest_dir`.
function M.paste(dest_dir)
  if not clipboard then
    vim.notify("Nothing in clipboard", vim.log.levels.WARN)
    return
  end
  local dest = dest_dir .. "/" .. clipboard.name
  if clip_op == "copy" then
    if clipboard.type == "directory" then
      vim.fn.system({ "cp", "-r", clipboard.path, dest })
    else
      vim.uv.fs_copyfile(clipboard.path, dest)
    end
  elseif clip_op == "cut" then
    vim.uv.fs_rename(clipboard.path, dest)
    clipboard = nil
    clip_op = nil
  end
  refresh_tree()
end

return M

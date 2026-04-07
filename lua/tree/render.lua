local fs = require("tree.fs")
local git = require("tree.git")
local icons = require("tree.icons")
local window = require("tree.window")

local M = {}

local ns = vim.api.nvim_create_namespace("tree")

--- Render the tree into the buffer
---@return {node: TreeNode, depth: number}[] flat list for cursor mapping
function M.draw()
  local buf = window.get_buf()
  local flat = fs.flatten()
  local lines = {}
  local highlights = {}

  for i, entry in ipairs(flat) do
    local node = entry.node
    local depth = entry.depth
    local indent = string.rep("  ", depth)
    local icon, icon_hl
    local git_st = git.get(node.path)
    local git_suffix = git_st and (" " .. git.icon(git_st)) or ""

    if node.type == "directory" then
      icon, icon_hl = icons.for_dir(node.open)
    else
      icon, icon_hl = icons.for_file(node.name)
    end

    local prefix = icon ~= "" and (icon .. " ") or ""
    local line = indent .. prefix .. node.name .. git_suffix
    lines[i] = line

    -- collect highlights
    local col_start = #indent
    if icon_hl then
      highlights[#highlights + 1] = { i - 1, icon_hl, col_start, col_start + #icon }
    end
    if git_st then
      local git_col = #line - #git_suffix
      local git_hl = (git_st == "?" and "TreeGitUntracked")
        or (git_st == "M" and "TreeGitModified")
        or (git_st == "A" and "TreeGitAdded")
        or (git_st == "D" and "TreeGitDeleted")
        or "TreeGitDefault"
      highlights[#highlights + 1] = { i - 1, git_hl, git_col, #line }
    end
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  -- apply highlights
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, ns, hl[2], hl[1], hl[3], hl[4])
  end

  return flat
end

return M

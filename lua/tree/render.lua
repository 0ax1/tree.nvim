--- Renders the tree into the sidebar buffer.
--- Flattens the node tree into lines, applies icon and git highlights.
local fs = require("tree.fs")
local icons = require("tree.icons")
local window = require("tree.window")

local M = {}

local ns = vim.api.nvim_create_namespace("tree")

--- Render the full tree into the buffer. Returns the flat node list for cursor mapping.
---@return {node: TreeNode, depth: number}[]
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

    if node.type == "directory" then
      icon, icon_hl = icons.for_dir(node.open)
    else
      icon, icon_hl = icons.for_file(node.name)
    end

    local prefix = icon ~= "" and (icon .. " ") or ""
    lines[i] = indent .. prefix .. node.name

    local col_start = #indent
    if icon_hl then
      highlights[#highlights + 1] = { i - 1, icon_hl, col_start, col_start + #icon }
    end
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, ns, hl[2], hl[1], hl[3], hl[4])
  end

  return flat
end

return M

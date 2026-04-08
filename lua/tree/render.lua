--- Renders the tree into the sidebar buffer.
local fs = require("tree.fs")
local icons = require("tree.icons")
local window = require("tree.window")

local M = {}

--- Render the full tree into the buffer. Returns the flat node list for cursor mapping.
---@return {node: TreeNode, depth: number}[]
function M.draw()
  local buf = window.get_buf()
  local flat = fs.flatten()
  local lines = {}

  for i, entry in ipairs(flat) do
    local node = entry.node
    local depth = entry.depth
    local indent = string.rep("  ", depth)

    if node.type == "directory" then
      lines[i] = indent .. icons.for_dir(node.open) .. " " .. node.name
    else
      lines[i] = indent .. node.name
    end
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  return flat
end

return M

--- File and directory icons.
--- Uses nvim-web-devicons when available, falls back to text arrows.
--- Set `icons = false` in setup to disable devicons entirely.
local M = {}

local has_devicons, devicons = pcall(require, "nvim-web-devicons")
local enabled = true

local dir_icons = {
  open = "",
  closed = "",
}

function M.setup(opts)
  if opts.icons == false then
    enabled = false
  end
end

function M.for_file(name)
  if not enabled then return "", nil end
  if has_devicons then
    local icon, hl = devicons.get_icon(name, nil, { default = true })
    return icon or "", hl
  end
  return "", nil
end

function M.for_dir(is_open)
  if not enabled then return is_open and "▾" or "▸", nil end
  return is_open and dir_icons.open or dir_icons.closed, "Directory"
end

return M

--- Directory arrow indicators.
--- Configurable via `arrows = { open = "▾", closed = "▸" }` in setup.
local M = {}

local arrows = {
  open = "▾",
  closed = "▸",
}

function M.setup(opts)
  if opts.arrows then
    arrows.open = opts.arrows.open or arrows.open
    arrows.closed = opts.arrows.closed or arrows.closed
  end
end

function M.for_dir(is_open)
  return is_open and arrows.open or arrows.closed
end

return M

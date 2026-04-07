local M = {}

---@type table<string, string> path -> status char
local status_map = {}
local git_root = nil

local status_icons = {
  M = "~", -- modified
  A = "+", -- added
  D = "-", -- deleted
  R = "r", -- renamed
  C = "c", -- copied
  U = "u", -- unmerged
  ["?"] = "?", -- untracked
  ["!"] = "!", -- ignored
}

function M.icon(st)
  return status_icons[st] or st
end

local function parse_porcelain(lines, root)
  local map = {}
  for _, line in ipairs(lines) do
    if #line >= 4 then
      local x, y = line:sub(1, 1), line:sub(2, 2)
      local file = line:sub(4)
      -- strip trailing / and quotes
      file = file:gsub('^"', ""):gsub('"$', ""):gsub("/$", "")
      local abs = root .. "/" .. file
      local st = (y ~= " " and y ~= "?") and y or x
      map[abs] = st
      -- propagate status up to parent dirs
      local dir = vim.fn.fnamemodify(abs, ":h")
      while #dir > #root do
        if not map[dir] then
          map[dir] = st
        end
        dir = vim.fn.fnamemodify(dir, ":h")
      end
    end
  end
  return map
end

function M.refresh(path, callback)
  -- find git root
  vim.system(
    { "git", "-C", path, "rev-parse", "--show-toplevel" },
    { text = true },
    function(result)
      if result.code ~= 0 then
        git_root = nil
        status_map = {}
        if callback then vim.schedule(callback) end
        return
      end
      git_root = vim.trim(result.stdout)
      vim.system(
        { "git", "-C", git_root, "status", "--porcelain", "-u" },
        { text = true },
        function(st_result)
          if st_result.code == 0 then
            local lines = vim.split(st_result.stdout, "\n", { trimempty = true })
            status_map = parse_porcelain(lines, git_root)
          else
            status_map = {}
          end
          if callback then vim.schedule(callback) end
        end
      )
    end
  )
end

function M.get(path)
  return status_map[path]
end

return M

--- Async git status integration.
--- Runs `git status --porcelain -u` in the background via vim.system
--- and builds a path -> status lookup table. Status is propagated up
--- to parent directories so folders show their children's state.
local M = {}

---@type table<string, string> absolute path -> status character
local status_map = {}
local git_root = nil

local status_icons = {
  M = "~",
  A = "+",
  D = "-",
  R = "r",
  C = "c",
  U = "u",
  ["?"] = "?",
  ["!"] = "!",
}

function M.icon(st)
  return status_icons[st] or st
end

--- Parse `git status --porcelain` output into a path -> status map.
--- Propagates status up to parent directories.
local function parse_porcelain(lines, root)
  local map = {}
  for _, line in ipairs(lines) do
    if #line >= 4 then
      local x, y = line:sub(1, 1), line:sub(2, 2)
      local file = line:sub(4)
      file = file:gsub('^"', ""):gsub('"$', ""):gsub("/$", "")
      local abs = root .. "/" .. file
      -- prefer working-tree status (y) over index status (x)
      local st = (y ~= " " and y ~= "?") and y or x
      map[abs] = st
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

--- Refresh git status asynchronously. Calls `callback` on the main thread when done.
function M.refresh(path, callback)
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

--- Look up the git status for an absolute path.
function M.get(path)
  return status_map[path]
end

return M

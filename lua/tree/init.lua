--- tree.nvim — minimal file explorer for Neovim.
--- Entry point: setup, open/close/toggle, keymaps, and buffer-follow.
local fs = require("tree.fs")
local render = require("tree.render")
local window = require("tree.window")
local actions = require("tree.actions")
local watch = require("tree.watch")

local M = {}

--- Flat list of visible nodes, kept in sync with the buffer lines.
--- Used to map cursor line -> tree node.
---@type {node: TreeNode, depth: number}[]
local flat = {}

local function get_node_at_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  return flat[cursor[1]]
end

local function redraw()
  flat = render.draw()
  watch.sync(flat)
end

--- Find the best non-tree window to open a file in (prefer last active).
local function find_target_win()
  local tree_win = window.get_win()
  -- Try the alternate (previously focused) window first.
  local alt = vim.fn.win_getid(vim.fn.winnr("#"))
  if alt ~= 0 and alt ~= tree_win and vim.api.nvim_win_is_valid(alt)
    and vim.api.nvim_win_get_config(alt).relative == "" then
    return alt
  end
  -- Fallback: first regular non-tree window.
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if w ~= tree_win and vim.api.nvim_win_get_config(w).relative == "" then
      return w
    end
  end
end

--- Focus a window without triggering BufEnter autocmds.
local function focus_win(win)
  vim.cmd("noautocmd call win_gotoid(" .. win .. ")")
end

--- Open a file in the previous last-active window.
local function open_file(path)
  local win = find_target_win()
  if win then focus_win(win) end
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

-- Keymap actions --

local function action_open()
  local entry = get_node_at_cursor()
  if not entry then return end
  if entry.node.type == "directory" then
    fs.toggle_dir(entry.node)
    redraw()
  else
    open_file(entry.node.path)
  end
end

local function action_open_split()
  local entry = get_node_at_cursor()
  if not entry or entry.node.type == "directory" then return end
  local win = find_target_win()
  if win then focus_win(win) end
  vim.cmd("split " .. vim.fn.fnameescape(entry.node.path))
end

local function action_open_vsplit()
  local entry = get_node_at_cursor()
  if not entry or entry.node.type == "directory" then return end
  local win = find_target_win()
  if win then focus_win(win) end
  vim.cmd("vsplit " .. vim.fn.fnameescape(entry.node.path))
end

--- Close the current dir, or navigate to parent and close it.
local function action_close_dir()
  local entry = get_node_at_cursor()
  if not entry then return end
  local node = entry.node
  if node.type == "directory" and node.open then
    fs.toggle_dir(node)
  else
    local cursor = vim.api.nvim_win_get_cursor(0)[1]
    for i = cursor - 1, 1, -1 do
      if flat[i].depth < entry.depth and flat[i].node.type == "directory" then
        vim.api.nvim_win_set_cursor(0, { i, 0 })
        if flat[i].node.open then
          fs.toggle_dir(flat[i].node)
        end
        break
      end
    end
  end
  redraw()
end

local function action_create()
  local entry = get_node_at_cursor()
  if not entry then return end
  local dir = entry.node.type == "directory" and entry.node.path
    or vim.fn.fnamemodify(entry.node.path, ":h")
  actions.create(dir)
end

local function action_delete()
  local entry = get_node_at_cursor()
  if not entry then return end
  actions.delete(entry.node)
end

local function action_rename()
  local entry = get_node_at_cursor()
  if not entry then return end
  actions.rename(entry.node)
end

local function action_copy()
  local entry = get_node_at_cursor()
  if entry then actions.copy(entry.node) end
end

local function action_cut()
  local entry = get_node_at_cursor()
  if entry then actions.cut(entry.node) end
end

local function action_paste()
  local entry = get_node_at_cursor()
  if not entry then return end
  local dir = entry.node.type == "directory" and entry.node.path
    or vim.fn.fnamemodify(entry.node.path, ":h")
  actions.paste(dir)
end

local function action_refresh()
  fs.refresh()
  redraw()
end

--- Change root into the directory under cursor.
local function action_cd_into()
  local entry = get_node_at_cursor()
  if not entry or entry.node.type ~= "directory" then return end
  fs.set_root(entry.node.path)
  redraw()
end

--- Change root up to the parent directory.
local function action_cd_up()
  local root = fs.get_root()
  if not root then return end
  local parent = vim.fn.fnamemodify(root.path, ":h")
  if parent == root.path then return end
  fs.set_root(parent)
  redraw()
end

local function set_keymaps(buf)
  local opts = { buffer = buf, noremap = true, silent = true, nowait = true }
  vim.keymap.set("n", "<CR>",  action_open,       opts)
  vim.keymap.set("n", "o",     action_open,       opts)
  vim.keymap.set("n", "l",     action_open,       opts)
  vim.keymap.set("n", "h",     action_close_dir,  opts)
  vim.keymap.set("n", "s",     action_open_split, opts)
  vim.keymap.set("n", "v",     action_open_vsplit,opts)
  vim.keymap.set("n", "a",     action_create,     opts)
  vim.keymap.set("n", "d",     action_delete,     opts)
  vim.keymap.set("n", "r",     action_rename,     opts)
  vim.keymap.set("n", "y",     action_copy,       opts)
  vim.keymap.set("n", "x",     action_cut,        opts)
  vim.keymap.set("n", "p",     action_paste,      opts)
  vim.keymap.set("n", "R",     action_refresh,    opts)
  vim.keymap.set("n", "<C-]>", action_cd_into,    opts)
  vim.keymap.set("n", "-",     action_cd_up,      opts)
  vim.keymap.set("n", "q",     M.close,           opts)
end

--- Open the tree sidebar rooted at `path` (defaults to cwd).
function M.open(path)
  path = path or vim.fn.getcwd()
  fs.set_root(path)
  window.open()
  set_keymaps(window.get_buf())
  watch.setup(function()
    if not window.is_open() then return end
    fs.refresh()
    redraw()
  end)
  redraw()
end

--- Close the tree sidebar and stop all filesystem watchers.
function M.close()
  local win = find_target_win()
  watch.stop_all()
  window.close()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  end
end

function M.toggle(path)
  if window.is_open() then
    M.close()
  else
    M.open(path)
  end
end

--- Reveal a file in the tree: expand ancestors and move cursor to it.
---@param filepath string|nil absolute path, defaults to current buffer
function M.reveal(filepath)
  if not window.is_open() then return end
  filepath = filepath or vim.api.nvim_buf_get_name(0)
  if filepath == "" then return end
  filepath = vim.fn.fnamemodify(filepath, ":p"):gsub("/$", "")
  if not fs.expand_to(filepath) then return end
  flat = render.draw()
  watch.sync(flat)
  for i, entry in ipairs(flat) do
    if entry.node.path == filepath then
      local win = window.get_win()
      if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_cursor(win, { i, 0 })
      end
      return
    end
  end
end

--- Setup tree.nvim.
---@param opts? { width?: number, arrows?: { open?: string, closed?: string } }
function M.setup(opts)
  opts = opts or {}
  window.setup(opts)
  require("tree.icons").setup(opts)

  vim.api.nvim_set_hl(0, "TreeNormal", { link = "Comment", default = true })

  vim.api.nvim_create_user_command("Tree", function(cmd)
    local arg = cmd.args ~= "" and cmd.args or nil
    M.toggle(arg)
  end, { nargs = "?", complete = "dir" })

  -- follow current buffer: reveal the active file in the tree
  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
      if vim.bo.buftype == "" then
        M.reveal()
      end
    end,
  })
end

return M

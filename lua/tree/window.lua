local M = {}

local bufnr = nil
local winnr = nil
local width = 30

function M.setup(opts)
  width = opts.width or 30
end

function M.get_buf()
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    return bufnr
  end
  bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
  vim.api.nvim_set_option_value("swapfile", false, { buf = bufnr })
  vim.api.nvim_set_option_value("filetype", "tree", { buf = bufnr })
  vim.api.nvim_buf_set_name(bufnr, "tree://explorer")
  return bufnr
end

function M.is_open()
  return winnr ~= nil and vim.api.nvim_win_is_valid(winnr)
end

function M.get_win()
  return winnr
end

function M.open()
  if M.is_open() then
    vim.api.nvim_set_current_win(winnr)
    return
  end
  local buf = M.get_buf()
  vim.cmd("topleft " .. width .. "vsplit")
  winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(winnr, buf)
  vim.api.nvim_set_option_value("number", false, { win = winnr })
  vim.api.nvim_set_option_value("relativenumber", false, { win = winnr })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = winnr })
  vim.api.nvim_set_option_value("cursorline", true, { win = winnr })
  vim.api.nvim_set_option_value("winfixwidth", true, { win = winnr })
  vim.api.nvim_set_option_value("wrap", false, { win = winnr })
  vim.api.nvim_set_option_value("winhl", "Normal:TreeNormal", { win = winnr })
  vim.api.nvim_set_option_value("spell", false, { win = winnr })
  vim.api.nvim_set_option_value("list", false, { win = winnr })
  vim.api.nvim_set_option_value("foldcolumn", "0", { win = winnr })
end

function M.close()
  if M.is_open() then
    vim.api.nvim_win_close(winnr, true)
    winnr = nil
  end
end

function M.focus()
  if M.is_open() then
    vim.api.nvim_set_current_win(winnr)
  end
end

return M

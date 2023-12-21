local popup = require("plenary.popup")
local M = {}

M.associations = {}
M.popup_content = {}
M.popup_size = 0
M.popup_winid = nil

local function create_window(size)
  local width = 60
  local height = size
  local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
  local bufnr = vim.api.nvim_create_buf(false, true)

  local win_id, win = popup.create(bufnr, {
    title = "Nexus",
    highlight = "NexusWindow",
    line = math.floor(((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    minwidth = width,
    minheight = height,
    borderchars = borderchars,
  })

  vim.api.nvim_win_set_option(
    win.border.win_id,
    "winhl",
    "Normal:NexusBorder"
  )

  return {
    bufnr = bufnr,
    win_id = win_id,
  }
end

function M.close_window()
  if M.popup_winid ~= nil then
    vim.api.nvim_win_close(M.popup_winid, true)
    M.popup_winid = nil
    M.popup_content = {}
    M.popup_size = 0
  end
end

local get_file_name = function()
  local file_name = vim.fn.expand('%:t:r')
  return file_name
end

local get_file_extension = function()
  local file_extension = vim.fn.expand('%:e')
  return file_extension
end

local get_associated_extensions = function(extension)
  local associated_extensions = {}
  for _, associations in next, M.associations do
    local contains_ext = false
    local exts = {}
    for _, value in next, associations do
      if value == extension then
        contains_ext = true
      else -- insert associated extensions and skipping the one we are checking
        table.insert(exts, value)
      end
    end
    if contains_ext then
      for _, ext in next, exts do
        table.insert(associated_extensions, ext)
      end
    end
  end
  return associated_extensions
end

local get_associated_files = function(name, extensions)
  local associated_files = {}
  local file_directory = vim.fn.expand('%:p:h') .. "/"
  local size = 0
  for _, ext in next, extensions do
    local full_name = name .. "." .. ext -- filename.ext
    if vim.fn.findfile(full_name, file_directory) ~= "" then
      local full_path = file_directory .. full_name -- path/to/filename.ext
      table.insert(associated_files, full_path)
      size = size + 1
    end
  end
  return associated_files, size
end

function M.setup()
  M.associations = {
    {"cpp", "h", "hxx", "cxx", "hpp"},
    {"c", "h"},
  }
end
local function get_or_create_buffer(filepath)
  local buf_exists = vim.fn.bufexists(filepath) ~= 0
  if buf_exists then
    return vim.fn.bufnr(filepath)
  end
  if vim.fn.findfile(filepath) then
    return vim.fn.bufadd(filepath)
  end

  return nil
end

function M.select_menu_item()
  local idx = vim.fn.line(".")
  local buf = get_or_create_buffer(M.popup_content[idx])
  M.close_window()
  if buf ~= nil then
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_option(buf, "buflisted", true)
  end
end

function M.select_menu_item_idx(idx)
  if (idx > M.popup_size) then
    return
  end
  local buf = get_or_create_buffer(M.popup_content[idx])
  vim.api.nvim_win_close(M.popup_winid, true)
  if buf ~= nil then
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_option(buf, "buflisted", true)
  end
  M.popup_winid = nil
end

function M.toggle()
  if M.popup_winid ~= nil and vim.api.nvim_win_is_valid(M.popup_winid) then
    M.close_window()
    return
  end

  local file_name = get_file_name()
  local extension = get_file_extension()
  local associated_extensions = get_associated_extensions(extension)
  local associated_files, size = get_associated_files(file_name, associated_extensions)

  M.popup_content = associated_files
  M.popup_size = size
  if size > 1 then -- more than one associated file, open popup
    local win_info = create_window(size)
    local bufnr = win_info.bufnr
    M.popup_winid = win_info.win_id
    vim.api.nvim_win_set_option(M.popup_winid, "number", true)
    vim.api.nvim_buf_set_name(bufnr, "nexus-menu")
    vim.api.nvim_buf_set_lines(bufnr, 0, #M.popup_content, false, M.popup_content)

    vim.api.nvim_buf_set_option(bufnr, "buftype", "nowrite")
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "delete")
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>", "<Cmd>lua require('nexus').select_menu_item()<CR>", {})
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<Esc>", "<Cmd>lua require('nexus').close_window()<CR>", {})
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<Cmd>lua require('nexus').close_window()<CR>", {})
    vim.api.nvim_buf_set_keymap(bufnr, "n", "1", "<Cmd>lua require('nexus').select_menu_item_idx(1)<CR>", {})
    vim.api.nvim_buf_set_keymap(bufnr, "n", "2", "<Cmd>lua require('nexus').select_menu_item_idx(2)<CR>", {})
    vim.api.nvim_buf_set_keymap(bufnr, "n", "3", "<Cmd>lua require('nexus').select_menu_item_idx(3)<CR>", {})
    vim.api.nvim_buf_set_keymap(bufnr, "n", "4", "<Cmd>lua require('nexus').select_menu_item_idx(4)<CR>", {})
    vim.api.nvim_buf_set_keymap(bufnr, "n", "5", "<Cmd>lua require('nexus').select_menu_item_idx(5)<CR>", {})
    vim.api.nvim_buf_set_keymap(bufnr, "n", "6", "<Cmd>lua require('nexus').select_menu_item_idx(6)<CR>", {})
    vim.api.nvim_buf_set_keymap(bufnr, "n", "7", "<Cmd>lua require('nexus').select_menu_item_idx(7)<CR>", {})
    vim.api.nvim_buf_set_keymap(bufnr, "n", "8", "<Cmd>lua require('nexus').select_menu_item_idx(8)<CR>", {})
    vim.api.nvim_buf_set_keymap(bufnr, "n", "9", "<Cmd>lua require('nexus').select_menu_item_idx(9)<CR>", {})
    vim.api.nvim_buf_set_keymap(bufnr, "n", "0", "<Cmd>lua require('nexus').select_menu_item_idx(10)<CR>", {})
  elseif size == 1 then -- only one associated file, open it
    local buf = get_or_create_buffer(associated_files[1])
    if buf ~= nil then
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_buf_set_option(buf, "buflisted", true)
    end
  end
end

return M

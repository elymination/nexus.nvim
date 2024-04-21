local popup = require("plenary.popup")
local M = {}

local NEXUS_WIN_TITLE = "Nexus"

local MODE_NORMAL = 0
local MODE_VERTICAL = 1
local MODE_HORIZONTAL = 2

M.popup_content = {}
M.popup_size = 0
M.popup_winid = nil
M.popup_mode_winid = nil
M.popup_mode_bufnr = nil
M.popup_mode = MODE_NORMAL
M.longest_filename = 0
M.windows_width = 0

-- configurable through setup
M.associations = {}
M.is_sticky = true
M.show_fullpath = true
M.show_wintitle = true

local function create_window(size)
  M.windows_width = M.longest_filename + 8 -- 4 for line number margin and 4 for symmetry
  local width = M.windows_width
  local height = size
  local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
  local modeborderchars = { "─", "│", "─", "│", "│", "│", "╯", "╰" }
  local bufnr = vim.api.nvim_create_buf(false, true)
  local modebufnr = vim.api.nvim_create_buf(false, true)
  local line = M.is_sticky and vim.fn.winline() + 2 or math.floor(((vim.o.lines - height) / 2) - 1)
  local col = M.is_sticky and vim.fn.wincol() + 1 or math.floor((vim.o.columns - width) / 2)

  local mode_win_id, mode_win = popup.create(modebufnr, {
    title = "",
    highlight = "NexusWindow",
    line = line + size + 1,
    col = col,
    minwidth = width,
    minheight = 1,
    borderchars = modeborderchars,
  })

  local win_id, win = popup.create(bufnr, {
    title = M.show_wintitle and NEXUS_WIN_TITLE or "",
    highlight = "NexusWindow",
    line = line,
    col = col,
    minwidth = width,
    minheight = height,
    borderchars = borderchars,
  })

  vim.api.nvim_win_set_option(
    mode_win.border.win_id,
    "winhl",
    "Normal:NexusBorder"
  )

  vim.api.nvim_win_set_option(
    win.border.win_id,
    "winhl",
    "Normal:NexusBorder"
  )

  return {
    bufnr = bufnr,
    modebufnr = modebufnr,
    win_id = win_id,
    mode_win_id = mode_win_id
  }
end

function M.close_window()
  if M.popup_winid ~= nil then
    vim.api.nvim_win_close(M.popup_winid, true)
    vim.api.nvim_win_close(M.popup_mode_winid, true)
    M.popup_winid = nil
    M.popup_mode_winid = nil
    M.popup_content = {}
    M.popup_size = 0
    M.popup_mode = MODE_NORMAL
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
      if M.show_fullpath then
        local full_path = file_directory .. full_name -- path/to/filename.ext
        table.insert(associated_files, full_path)
      else
        table.insert(associated_files, full_name)
      end
      size = size + 1
    end
  end
  return associated_files, size
end

local get_longest_filename = function(filenames)
  local longest = 0
  for _, name in ipairs(filenames) do
    longest = math.max(string.len(name), longest)
  end
  return longest
end

function M.setup(config)
  if not config then -- default values.
    M.show_fullpath = true
    M.is_sticky = true
    M.associations = {
      {"cpp", "h", "hxx", "cxx", "hpp"},
      {"c", "h"},
    }
  else
    M.associations = config.associations -- cannot be nil. for now.
    M.show_fullpath = config.show_fullpath == nil and true or config.show_fullpath
    M.is_sticky = config.is_sticky == nil and true or config.is_sticky
    M.show_wintitle = config.show_wintitle == nil and true or config.show_wintitle
  end
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
  local mode = M.popup_mode
  M.close_window()
  if buf ~= nil then
    if mode == MODE_VERTICAL then
      vim.cmd("vs")
    elseif mode == MODE_HORIZONTAL then
      vim.cmd("sp")
    end
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_option(buf, "buflisted", true)
  end
end

function M.select_menu_item_idx(idx)
  if idx > M.popup_size then
    return
  end
  local buf = get_or_create_buffer(M.popup_content[idx])
  local mode = M.popup_mode
  M.close_window()
  if buf ~= nil then
    if mode == MODE_VERTICAL then
      vim.cmd("vs")
    elseif mode == MODE_HORIZONTAL then
      vim.cmd("sp")
    end
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_option(buf, "buflisted", true)
  end
end

local construct_spaces_string = function(size)
  local str = ""
  local i = 0
  while i < size do
    str = str .. " "
    i = i + 1
  end
  return str
end

function M.get_mode_string()
  local needed_spaces = M.windows_width / 2
  if M.popup_mode == MODE_NORMAL then
    needed_spaces = needed_spaces - string.len("NORMAL") / 2
    return construct_spaces_string(needed_spaces) .. "NORMAL"
  elseif M.popup_mode == MODE_VERTICAL then
    needed_spaces = needed_spaces - string.len("VERTICAL") / 2
    return construct_spaces_string(needed_spaces) .. "VERTICAL"
  elseif M.popup_mode == MODE_HORIZONTAL then
    needed_spaces = needed_spaces - string.len("HORIZONTAL") / 2
    return construct_spaces_string(needed_spaces) .. "HORIZONTAL"
  end
  return "UNKNOWN_MODE"
end

function M.set_mode(mode)
  if M.popup_winid ~= nil then
    M.popup_mode = mode
    vim.api.nvim_buf_set_lines(M.popup_mode_bufnr, 0, -1, true, {M.get_mode_string()})
  end
end

function M.toggle_mode(mode)
  if M.popup_winid ~= nil then
    if M.popup_mode ~= mode then
      M.set_mode(mode)
    else
      M.set_mode(MODE_NORMAL)
    end
  end
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

  M.longest_filename = get_longest_filename(associated_files)

  M.popup_content = associated_files
  M.popup_size = size
  if size > 1 then -- more than one associated file, open popup
    local win_info = create_window(size)
    local bufnr = win_info.bufnr
    M.popup_winid = win_info.win_id
    M.popup_mode_winid = win_info.mode_win_id
    M.popup_mode_bufnr = win_info.modebufnr
    vim.api.nvim_win_set_option(M.popup_winid, "number", true)
    vim.api.nvim_buf_set_name(bufnr, "nexus-menu")
    vim.api.nvim_buf_set_lines(bufnr, 0, #M.popup_content, false, M.popup_content)

    vim.api.nvim_buf_set_option(bufnr, "buftype", "nowrite")
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "delete")
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
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

    -- mode toggling
    vim.api.nvim_buf_set_keymap(bufnr, "n", "n", "<Cmd>lua require('nexus').set_mode(0)<CR>", {}) -- normal
    vim.api.nvim_buf_set_keymap(bufnr, "n", "v", "<Cmd>lua require('nexus').toggle_mode(1)<CR>", {}) -- vertical
    vim.api.nvim_buf_set_keymap(bufnr, "n", "h", "<Cmd>lua require('nexus').toggle_mode(2)<CR>", {}) -- horizontal

    vim.api.nvim_buf_set_name(M.popup_mode_bufnr, "nexus-menu-mode")
    vim.api.nvim_buf_set_option(M.popup_mode_bufnr, "buftype", "nowrite")
    vim.api.nvim_buf_set_option(M.popup_mode_bufnr, "bufhidden", "delete")
    vim.api.nvim_buf_set_lines(M.popup_mode_bufnr, 0, -1, true, {M.get_mode_string()})

  elseif size == 1 then -- only one associated file, open it
    local buf = get_or_create_buffer(associated_files[1])
    if buf ~= nil then
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_buf_set_option(buf, "buflisted", true)
    end
  end
end

return M

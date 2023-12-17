local M = {}

M.associations = {}

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
  for _, ext in next, extensions do
    local full_name = name .. "." .. ext -- filename.ext
    if vim.fn.findfile(full_name, file_directory) then
      local full_path = file_directory .. full_name -- path/to/filename.ext
      table.insert(associated_files, full_path)
    end
  end
  return associated_files
end

function M.setup()
  M.associations = {
    {"cpp", "h", "hxx", "cxx", "hpp"},
    {"c", "h"},
  }
end

local function get_buffer(filepath)
  local buf_exists = vim.fn.bufexists(filepath) ~= 0
  if buf_exists then
    return vim.fn.bufnr(filepath)
  end

  return nil
end

function M.toggle()
  local file_name = get_file_name()
  local extension = get_file_extension()
  local associated_extensions = get_associated_extensions(extension)
  local associated_files = get_associated_files(file_name, associated_extensions)
  local buf = get_buffer(associated_files[1])
  if buf ~= nil then
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_option(buf, "buflisted", true)
  end
end

return M

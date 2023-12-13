print("yo :)")
vim.opt.rtp:append(vim.fn.stdpath "config" .. "~/Projects/nexus.nvim/lua/nexus")
vim.api.nvim_create_user_command('NexusToggle', function () require('nexus').toggle() end, {})
vim.api.nvim_create_user_command('NexusPrevious', function () require('nexus').previous() end, {})
vim.api.nvim_create_user_command('NexusNext', function () require('nexus').next() end, {})

require('nexus').setup()
print("yo2")

-- Creates an object for the module.
local M = {}

function M.setup()
    vim.api.nvim_create_user_command("NexusToggle", function()
        M.toggle()
    end)
end

print("nexus.lua!")

function M.toggle()
    print("nexus.toggle")
end

function M.previous()
    print("nexus.previous")
end

function M.next()
    print("nexus.next")
end

return M

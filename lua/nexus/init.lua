local nexus = require("nexus")

local M = {}

M.toggle = nexus.toggle
M.previous = nexus.previous
M.next = nexus.next

function M.reset()
  require("plenary.reload").reload_module("nexus")
end
return M

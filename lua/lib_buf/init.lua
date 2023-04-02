local config = require 'lib_buf.config'

local api = vim.api

local M = {}

-- Setup the plugin with user-defined options.
---@param user_opts user_options|nil The user options.
M.setup = function(user_opts) config.setup(user_opts) end

M.giveme123 = function() return 123 end

return M

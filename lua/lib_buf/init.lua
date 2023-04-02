local config = require 'lib_buf.config'

local M = {}

local api = vim.api

-- Setup the plugin with user-defined options.
---@param user_opts user_options|nil The user options.
M.setup = function(user_opts) config.setup(user_opts) end

M.giveme123 = function() return 123 end

-- Sidenode: This function does not return all buffers. There may be further
-- hidden ones. For example direct execution after neovim start on empty buffer
-- lists 3 buffers, but ls! lists 5 ones and thereafter execution of this
-- function also.
-- @return BufferProperties Buffers with properties.
M.currentBuffersWithPropertis = function()
  local bufprops = {}
  local bufs = api.nvim_list_bufs()
  -- local buf_loaded = nvim_buf_is_loaded()
  for i, v in pairs(bufs) do
    local name = api.nvim_buf_get_name(v)
    local is_loaded = api.nvim_buf_is_loaded(v)
    local ty = vim.bo[v].buftype
    local is_ro = vim.bo[v].readonly
    local is_hidden = vim.bo[v].bufhidden
    local is_listed = vim.bo[v].buflisted
    print(i, ", ", v, "name:", name, "loaded:", is_loaded, "ty:",
      ty, "ro:", is_ro, "is_hidden:", is_hidden, "is_listed:", is_listed)
    -- readonly, bufhidden, buflisted
    local row = {name, is_loaded, ty, is_ro, is_hidden, is_listed}
    bufprops[v] = row
  end
  -- for i, v in pairs(bufprops) do
  --   print(i, ", ", vim.inspect(v))
  -- end
  return bufprops
end

return M

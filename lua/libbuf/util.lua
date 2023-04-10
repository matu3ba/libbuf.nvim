--! Utility functions not affecting state of the application.
local Path = require 'plenary.path'

local M = {}
local api = vim.api

-- Check, if filepath is path to existing file.
-- Workaround Path:new(filepath):exists() returning true for nil
---@param filepath string|nil Filepath for checking, if file exists.
M.filepathExists = function(filepath)
  if filepath == nil then return false end
  return Path:new(filepath):exists()
end

-- Function to copy-paste and adjust for using buffer info.
-- TODO: This function does not return all buffers. There may be further
-- hidden ones. For example direct execution after neovim start on empty buffer
-- lists 3 buffers, but ls! lists 5 ones and thereafter execution of this
-- function also.
---@return table bufprops BufferProperties Buffers with properties.
M.currentBuffersWithPropertis = function()
  local bufprops = {}
  local bufs = api.nvim_list_bufs()
  -- local buf_loaded = nvim_buf_is_loaded()
  for _, v in ipairs(bufs) do
    local name = api.nvim_buf_get_name(v)
    local is_loaded = api.nvim_buf_is_loaded(v)
    local ty = vim.bo[v].buftype
    local is_ro = vim.bo[v].readonly
    local is_hidden = vim.bo[v].bufhidden
    local is_listed = vim.bo[v].buflisted
    -- print( i, ', ', v, 'name:', name, 'loaded:', is_loaded, 'ty:', ty, 'ro:', is_ro, 'is_hidden:', is_hidden, 'is_listed:', is_listed)
    -- readonly, bufhidden, buflisted
    local row = { name, is_loaded, ty, is_ro, is_hidden, is_listed }
    bufprops[v] = row
  end
  for i, v in pairs(bufprops) do
    print(i, ', ', vim.inspect(v))
  end
  return bufprops
end

return M

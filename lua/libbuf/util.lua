--! Utility functions not affecting state of the application.
local Path = require 'plenary.path'
local dev = require 'libbuf.dev'

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
---@return table bufprops BufferProperties Buffers with properties as []-table.
M.currentBuffersWithPropertis = function()
  local bufprops = {}
  local bufs = api.nvim_list_bufs()
  for _, buf_h in ipairs(bufs) do
    local filepath = api.nvim_buf_get_name(buf_h)
    local is_hidden = vim.bo[buf_h].bufhidden
    local is_listed = vim.bo[buf_h].buflisted
    local is_loaded = api.nvim_buf_is_loaded(buf_h)
    local is_modified = vim.bo[buf_h].modified
    local is_ro = vim.bo[buf_h].readonly
    local ty = vim.bo[buf_h].buftype
    local buf_table = {}
    buf_table["buf_h"] = buf_h
    buf_table["filepath"] = filepath
    buf_table["is_hidden"] = is_hidden
    buf_table["is_listed"] = is_listed
    buf_table["is_loaded"] = is_loaded
    buf_table["is_modified"] = is_modified
    buf_table["is_ro"] = is_ro
    buf_table["ty"] = ty
    bufprops[buf_h] = buf_table
    dev.log.trace('currentBuffersWithPropertis():  bufprops[' .. tostring(buf_h) .. '] =' .. vim.inspect(buf_table))
  end
  return bufprops
end

return M

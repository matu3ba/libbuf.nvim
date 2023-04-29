--! High level actions
local M = {}
local Path = require 'plenary.path'
local dev = require 'libbuf.dev'
local state = require 'libbuf.state'
local api = vim.api

-- Generate master buffer handle based on input.
---@param mbuf_path string|nil Optional path to master buffer.
---@return integer mbuf_h Master buffer for visualization to user
M.makeHandle = function(mbuf_path)
  local ty_mbuf_path = type(mbuf_path)
  assert(ty_mbuf_path == 'nil' or ty_mbuf_path == 'string')
  local bufs = api.nvim_list_bufs()
  assert(#bufs > 0)
  local mbuf_path_exists = M.filepathExists(mbuf_path)
  local mbuf_h = -1
  for _, v in ipairs(bufs) do
    local name = api.nvim_buf_get_name(v)
    if mbuf_path == name then
      mbuf_h = v
      break
    end
  end
  if mbuf_h == -1 and mbuf_path_exists == true then
    mbuf_h = vim.fn.bufadd(mbuf_path)
  end
  if mbuf_h == -1 then
    mbuf_h = vim.api.nvim_create_buf(true, true)
  end

  return mbuf_h
end

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

-- Insert path to state._dir_storage, if not existing.
---@param any_dirpath string absolute or relative path
---@return integer was_added Ok (0), DirectoryAlreadyExisting (1).
M.addDir = function(any_dirpath)
  local abs_path = Path:new{any_dirpath}:absolute()
  local has_path = state.hasPath(abs_path, state._dir_storage)
  if has_path == true then
    return 1
  else
    state.insertPath(abs_path, state._dir_storage)
    return 0
  end
end

-- Check, if cwd is in state._dir_storage.
---@return boolean has_path Answer.
M.hasCwd = function() return state.hasPath(vim.loop.cwd(), state._dir_storage) end

-- Add rel_filepath to state._filepath_storage, if not existing. Fails, if no relative
-- rel_filepath given (1), pwd not in state._dir_storage (2) or file already existing (3).
---@param any_dirpath string absolute or relative path
---@param rel_filepath string
---@return integer was_added Answer.
M.insertFile = function(any_dirpath, rel_filepath)
  if type(any_dirpath) ~= "string" then return 1 end
  if type(rel_filepath) ~= "string" then return 1 end
  local abs_dirpath = Path:new { rel_filepath }:absolute()
  -- TODO check that abs_dirpath actually exists
  local checkrel_filepath = Path:new { rel_filepath }:make_relative()
  assert(type(checkrel_filepath) == "string")

  if rel_filepath ~= checkrel_filepath then
    dev.log.trace("rel_filepath != checkrel_filepath: '" .. rel_filepath .. "' '" .. checkrel_filepath .. "'")
    return 1
  end
  -- TODO check that file abs_dirpath/rel_filepath actually exists
  if state.hasPath(abs_dirpath, state._dir_storage) == false then
    dev.log.trace(abs_dirpath .. ' not in state._dir_storage')
    return 2
  end
  if state.hasPath(rel_filepath, state._filepath_storage) then
    dev.log.trace(rel_filepath .. ' already in state._filepath_storage')
    return 3
  end
  state.insertPath(rel_filepath, state._filepath_storage)
  state.insertDirToFile(abs_dirpath, rel_filepath)
  return 0
end

-- Add directory (if necessary) and rel_filepath to state._dir_storage and
-- state._filepath_storage. Fails, if no relative rel_filepath given (1) or file
-- already existing (2).
----@param rel_filepath string
----@return integer was_added Answer.
-- M.insertDirAndFile = function(rel_filepath)
--   if type(rel_filepath) ~= "string" then return 1 end
--   local p_in = Path:new { rel_filepath }
--   local p_rel = p_in:make_relative()
--   assert(type(p_rel) == "string")
--   if rel_filepath ~= p_rel then
--     dev.log.trace("rel_filepath != p_rel: '" .. rel_filepath .. "' '" .. p_rel .. "'")
--     return 1
--   end
--   if state.hasPath(rel_filepath, state._filepath_storage) then
--     dev.log.trace(rel_filepath .. ' already in state._filepath_storage')
--     return 2
--   end
--   -- TODO check that file abs_dirpath/rel_filepath actually exists
--   if M.hasCwd() == false then
--     state.insertPath(vim.loop.cwd(), state._dir_storage)
--   end
--   state.insertPath(rel_filepath, state._filepath_storage)
--   return 0
-- end

return M

--! Fast index for file annotations. See ./DESIGN.md for details.
local M = {}
local dev = require 'libbuf.dev'
local xxh32 = require 'libbuf.luaxxhash'

-- naive directory storage with xxhash->absolute path
-- A more optimized version would use wyhash->absolute path
---@type table Contains abs_dirpath_hash->abs_dirpath
M._dir_storage = {}

-- naive file path storage with xxhash->relative path
-- A more optimized version would use wyhash->relative path
-- Filepaths are always relative to a storage directory.
---@type table Contains rel_filepath_hash->rel_filepath
M._filepath_storage = {}

-- Current master buffer handle omitted from printing.
---@type integer
M._mbuf_h = -1
-- Current state including annotations of all buffer handlers
---@type table
M._mbuf = {}
-- Last written content to file
---@type table
M._written_mbuf = {}
-- Optional path to master buffer for writing
---@type table
M._write_mbuf_path = nil

-- Dump state into given path
---@param dump_filepath string The filepath to overwrite the content into.
M.dumpState = function(dump_filepath)
  local fp = assert(io.open(dump_filepath, 'w'))
  fp:write 'dir_storage\n'
  for i, dirpath in pairs(M._dir_storage) do
    fp:write(tostring(i) .. ': ' .. dirpath .. '\n')
  end
  fp:write 'filepath_storage\n'
  for i, filepath in pairs(M._filepath_storage) do
    fp:write(tostring(i) .. ': ' .. filepath .. '\n')
  end
  fp:close()
end

-- Insert path to state._dir_storage xor state._filepath_storage
-- Does not check, if item is existing in array.
---@param path string directory or filepath
---@param pathtable table path table [assumed to be state._dir_storage or state._filepath_storage]
M.insertPath = function(path, pathtable)
  local hash = xxh32(path)
  pathtable[hash] = path
  dev.log.trace('added to ' .. tostring(pathtable) .. path .. ' with hash ' .. tostring(hash))
end

-- Remove path from state._dir_storage xor state._filepath_storage
-- Does not check, if item is existing in array.
---@param path string directory or filepath
---@param pathtable table path table [assumed to be state._dir_storage or state._filepath_storage]
M.removePath = function(path, pathtable)
  local hash = xxh32(path)
  pathtable[hash] = nil
  dev.log.trace('removed from ' .. tostring(pathtable) .. path .. ' with hash ' .. tostring(hash))
end

-- Check, if path is in state._dir_storage or state._filepath_storage
---@param path string directory or filepath
---@param pathtable table path table [assumed to be state._dir_storage or state._filepath_storage]
---@return boolean has_path Answer.
M.hasPath = function(path, pathtable)
  local hash = xxh32(path)
  return pathtable[hash] ~= nil
end

-- Insert the by abs_dirpath owned rel_filepath into the table or creates a new
-- one for abs_dirpath
---@param abs_dirpath string directory or filepath
---@param rel_filepath string path table [assumed to be state._dir_storage or state._filepath_storage]
---@return integer status Ok (0) or EntryAlreadyExist (1)
M.insertDirToFile = function(abs_dirpath, rel_filepath)
  local abs_dirpath_hash = xxh32(abs_dirpath)
  local rel_filepath_hash = xxh32(rel_filepath)
  if M._dirtofilepaths_storage[abs_dirpath_hash] == nil then
    M._dirtofilepaths_storage[abs_dirpath_hash] = {}
  end
  if M._dirtofilepaths_storage[abs_dirpath_hash][rel_filepath_hash] ~= nil then
    return 1
  end
  M._dirtofilepaths_storage[abs_dirpath_hash][rel_filepath_hash] = rel_filepath_hash
  return 0
end

return M

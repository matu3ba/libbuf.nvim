local M = {}
local dev = require 'libbuf.dev'
local xxh32 = require 'libbuf.luaxxhash'

-- naive directory storage with xxhash->absolute path
-- A more optimized version would use wyhash->absolute path
M._dir_storage = {}

-- naive file path storage with xxhash->relative path
-- A more optimized version would use wyhash->relative path
M._filepath_storage = {}

-- Current master buffer handle omitted from printing.
M._mbuf_h = -1
-- Current state including annotations of all buffer handlers
-- TODO: YAGNI, only necessary info.
M._mbuf = {}
-- Last written content to file
M._written_mbuf = {}
-- Optional path to master buffer for writing
M._write_mbuf_path = nil

-- Dump state into given path
---@param dump_filepath string The filepath to oveerwrite the content into.
M.dumpState = function(dump_filepath)
  local fp = assert(io.open(dump_filepath, 'w'))
  fp:write 'dir_storage\n'
  for i, dirpath in ipairs(M._dir_storage) do
    fp:write(tostring(i) .. ': ' .. dirpath .. '\n')
  end
  fp:write '_filepath_storage\n'
  for i, filepath in ipairs(M._filepath_storage) do
    fp:write(tostring(i) .. ': ' .. filepath .. '\n')
  end
  fp:close()
end

-- Add path to state._dir_storage or state._filepath_storage
-- Does not check, if item is existing in array.
---@param path string directory or filepath
---@param pathtable table path table [assumed to be state._dir_storage or state._filepath_storage]
M.addPath = function(path, pathtable)
  local hash = xxh32(path)
  pathtable[hash] = path
  dev.log.trace('added to pathtable ' .. path)
end

-- Check, if path is in state._dir_storage or state._filepath_storage
---@param path string directory or filepath
---@param pathtable table path table [assumed to be state._dir_storage or state._filepath_storage]
---@return boolean has_path Answer.
M.hasPath = function(path, pathtable)
  local hash = xxh32(path)
  return pathtable[hash] ~= nil
end

return M

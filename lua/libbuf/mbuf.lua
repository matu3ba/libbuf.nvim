--! Functions related to master buffer.
local M = {}
local api = vim.api
local util = require 'libbuf.util'

-- Generate master buffer handle based on input.
---@param mbuf_path string|nil Optional path to master buffer.
---@return integer mbuf_h Master buffer for visualization to user
M.makeHandle = function(mbuf_path)
  local fp = assert(io.open('/tmp/tmpfile', 'w')) --DEBUG
  local ty_mbuf_path = type(mbuf_path)
  assert(ty_mbuf_path == 'nil' or ty_mbuf_path == 'string')
  local bufs = api.nvim_list_bufs()
  assert(#bufs > 0)
  local mbuf_path_exists = util.filepathExists(mbuf_path)
  fp:write('mbuf_path_exists: ' .. tostring(mbuf_path_exists) .. '\n') --DEBUG
  local mbuf_h = -1
  for _, v in ipairs(bufs) do
    local name = api.nvim_buf_get_name(v)
    if mbuf_path == name then
      mbuf_h = v
      fp:write('found: ' .. tostring(mbuf_h) .. '\n') --DEBUG
      break
    end
  end
  if mbuf_h == -1 and mbuf_path_exists == true then
    fp:write('bufadd: ' .. tostring(mbuf_h) .. '\n') --DEBUG
    mbuf_h = vim.fn.bufadd(mbuf_path)
  end
  if mbuf_h == -1 then
    mbuf_h = vim.api.nvim_create_buf(true, true)
    fp:write('scratch creation: ' .. tostring(mbuf_h) .. '\n') --DEBUG
  end
  fp:close() --DEBUG

  return mbuf_h
end

return M

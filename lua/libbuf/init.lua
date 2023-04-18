--! Setup code with default examples.
local state = require 'libbuf.state'

local M = {}
local api = vim.api

-- Filepaths are recreated in the session file, but shada has them not on default.
-- See :h Initialization. Once the sessions is initialized, v:this_session is set.
-- Once neovim is initialized, v:vim_did_enter is set.
-- local is_initialized = vim.v.vim_did_enter
-- local session = vim.v.this_session

-- Setup after neovim is fully initialized to allow loading of shada and session files.
---@param user_setup_fn function User function for setup, which is delayed
--- until neovim is fully initialized.
M.delayedSetup = function(user_setup_fn)
  local is_initialized = vim.v.vim_did_enter
  if is_initialized == false then
    vim.schedule(M.delayedSetup)
  else
    user_setup_fn()
  end
end

-- readMBufState
-- writeMBufState

-- Populate master buffer based on view_config and attach autocommands to
-- modify upon buffer path and property modifications (not content).
---@param mbuf_h integer Master buffer handle.
---@param readwrite_fn function Function for printing buffer info.
---@param setup_autocmds function|nil Optional autocommands to update neovim buffer state + mbuf_path.
---@return integer status Status code.
M.default_populateMasterBuf = function(mbuf_h, readwrite_fn, setup_autocmds)
  local _ = setup_autocmds
  state._mbuf_h = mbuf_h
  readwrite_fn(state._mbuf, state._mbuf_h)
  -- setup_autocmds(state._mbuf, state._mbuf_h)
  return 0
end

-- Default readwrite_fn to populate master buffer
---@param state_table table State table
---@param mbuf_h integer Master buffer handle for printing into
M.default_readwrite_fn = function(state_table, mbuf_h)
  -- print("buffer handle, user group, filepath, marker")
  -- print(vim.inspect(state_table))
  assert(type(state_table) == 'table')
  assert(type(mbuf_h) == 'number')
  local i = 1
  local mbuf_content_arr = {}
  mbuf_content_arr[i] = 'bh |ug     |fpa:ma'
  i = i + 1
  for _, v in pairs(state_table) do
    if mbuf_h ~= v then
      local bh = state_table['buf_handle']
      if bh == nil then bh = -1 end
      local ug = state_table['user_group']
      if ug == nil then ug = 'invalid' end
      local fpa = state_table['filepath']
      if fpa == nil then fpa = 'invalid' end
      local ma = state_table['marker']
      if ma == nil then ma = 'invalid' end
      local new_line = string.format('%03d|%7s|%s:%s', bh, ug, fpa, ma)
      mbuf_content_arr[i] = new_line
      i = i + 1
    end
  end
  -- local fp = assert(io.open("/tmp/tmpfile", "a"))                    --DEBUG
  -- for ti, v in pairs(mbuf_content_arr) do                            --DEBUG
  --   fp:write("i: " .. tostring(ti) .." ")                            --DEBUG
  --   fp:write(v)                                                      --DEBUG
  --   fp:write("\n")                                                   --DEBUG
  -- end                                                                --DEBUG
  -- fp:write("mbuf_h " .. tostring(mbuf_h))                            --DEBUG
  -- assert(type(mbuf_h) == "number")                                   --DEBUG
  -- fp:write("type(mbuf_h): " .. type(mbuf_content_arr))               --DEBUG
  -- assert(type(mbuf_content_arr) == "table")                          --DEBUG
  -- fp:write("mbuf_content_arr: " .. vim.inspect(mbuf_content_arr))    --DEBUG
  -- fp:close()                                                         --DEBUG
  api.nvim_buf_set_lines(mbuf_h, 0, -1, false, mbuf_content_arr)
end

-- Add cwd to state._dir_storage, if not existing.
M.addCwd = function()
  local cwd = vim.loop.cwd()
  local has_path = state.hasPath(cwd, state._dir_storage)
  if has_path == false then state.addPath(cwd, state._dir_storage) end
end

-- Check, if cwwd is in state._dir_storage.
---@return boolean has_path Answer.
M.hasCwd = function() return state.hasPath(vim.loop.cwd(), state._dir_storage) end

return M

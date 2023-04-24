--! Setup code with default examples.
local state = require 'libbuf.state'
local dev = require 'libbuf.dev'
local Path = require 'plenary.path'

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

-- Select master buffer
M.showMasterBuf = function() vim.cmd("buffer " .. tostring(state._mbuf_h)) end

-- Set field "group" with "cli_args" for cli arguments and "init" otherwise.
---@param mbuf_props table The table containing the tables containing buffer properties.
M.annotateGroup_cliargs_init = function(mbuf_props)
  local file_args = 0
  for i, v in ipairs(vim.v.argv) do
    -- skip neovim binary name
    if i > 1 then
      -- skip options (true disables pattern matching)
      if v:find('-', 1, true) ~= 1 then
        file_args = file_args + 1
      end
    end
  end
  local fcnt = 0
  while fcnt < file_args do
    mbuf_props[fcnt+1]["group"] = "cli_args" -- tables start with 1
    fcnt = fcnt + 1
  end
  for i,_ in ipairs(mbuf_props) do
    if i > fcnt then
      mbuf_props[i]["group"] = "init"
    end
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

-- Default bufinfo for compact printing of buffer info.
---@param buf_ty string The buffer type.
---@param buf_ro boolean If buffer is read-only.
---@param buf_modified boolean If buffer has been modified.
M.default_bufinfo = function(buf_ty, buf_ro, buf_modified)
  if buf_ro == true then return 'ro ' end
  local buf_info
  if buf_ty == '' then
    buf_info = '  '
  elseif buf_ty == 'acwrite' then
    buf_info = 'ac'
  elseif buf_ty == 'help' then
    buf_info = 'he'
  elseif buf_ty == 'nofile' then
    buf_info = '[]'
  elseif buf_ty == 'nowrite' then
    buf_info = 'nw'
  elseif buf_ty == 'quickfix' then
    buf_info = 'qf'
  elseif buf_ty == 'terminal' then
    buf_info = 'te'
  elseif buf_ty == 'prompt' then
    buf_info = 'pr'
  else
    buf_info = '  '
  end
  if buf_modified then
    buf_info = buf_info .. '+'
  else
    buf_info = buf_info .. ' '
  end
  return buf_info
end

-- Default readwrite_fn to populate master buffer
---@param state_table table State table [table containing all buffers, which are table]
---@param mbuf_h integer Master buffer handle for printing into
M.default_readwrite_fn = function(state_table, mbuf_h)
  -- print("buffer handle, user group, filepath, marker")
  -- print(vim.inspect(state_table))
  assert(type(state_table) == 'table')
  assert(type(mbuf_h) == 'number')
  dev.log.trace('default_readwrite_fn():' .. vim.inspect(state_table))
  local i = 1
  local mbuf_content_arr = {}
  mbuf_content_arr[i] = 'handle|ty | group     |filepath:line:column'
  i = i + 1
  for v_i, buf_table in pairs(state_table) do
    dev.log.trace(tostring(v_i) .. ': ' .. vim.inspect(buf_table))
    if mbuf_h ~= buf_table['buf_h'] then
      local bh = buf_table['buf_h']
      if bh == nil then bh = -1 end
      local info = M.default_bufinfo(buf_table['ty'], buf_table['is_ro'], buf_table['is_modified'])
      local group = buf_table['group']
      if group == nil then group = 'invalid' end
      local fpa = buf_table['filepath']
      if fpa == nil then fpa = 'invalid' end
      local ma_col = buf_table['mark_col']
      if ma_col == nil then ma_col = 1 end
      local ma_line = buf_table['mark_line']
      if ma_line == nil then ma_line = 0 end
      local new_line = string.format('%06d|%3s|%10s|%s:%d:%d', bh, info, group, fpa, ma_col, ma_line)
      dev.log.trace('new_line:' .. new_line)
      mbuf_content_arr[i] = new_line
      i = i + 1
    end
  end
  api.nvim_buf_set_lines(mbuf_h, 0, -1, false, mbuf_content_arr)
end

-- Add cwd to state._dir_storage, if not existing. Ok (0) or failure (1),
-- if directory already existing.
---@return integer was_added Answer.
M.addDir = function()
  local cwd = vim.loop.cwd()
  local has_path = state.hasPath(cwd, state._dir_storage)
  if has_path == true then
    return 1
  else
    state.addPath(cwd, state._dir_storage)
    return 0
  end
end

-- Check, if cwd is in state._dir_storage.
---@return boolean has_path Answer.
M.hasCwd = function() return state.hasPath(vim.loop.cwd(), state._dir_storage) end

-- Add filepath to state._filepath_storage, if not existing. Fails, if no relative
-- filepath given (1), pwd not in state._dir_storage (2) or file already existing (3).
---@return integer was_added Answer.
M.addFile = function(filepath)
  if type(filepath) ~= string then return 1 end
  local p_in = Path:new { filepath }
  local p_rel = p_in:make_relative()
  if p_in ~= p_rel then
    dev.log.trace('p_in != p_rel: ' .. tostring(p_in) .. ' ' .. tostring(p_rel))
    return 1
  end
  if M.hasCwd() == false then
    dev.log.trace(vim.loop.cwd() .. ' not in state._dir_storage')
    return 2
  end
  if state.hasPath(filepath, state._filepath_storage) then
    dev.log.trace(filepath .. ' already in state._filepath_storage')
    return 3
  end
  state.addPath(filepath, state._filepath_storage)
  return 0
end

-- Add directory (if necessary) and filepath to state._dir_storage and
-- state._filepath_storage. Fails, if no relative filepath given (1) or file
-- already existing (2).
---@return integer was_added Answer.
M.addDirAndFile = function(filepath)
  if type(filepath) ~= string then return 1 end
  local p_in = Path:new { filepath }
  local p_rel = p_in:make_relative()
  if p_in ~= p_rel then
    dev.log.trace('p_in != p_rel: ' .. tostring(p_in) .. ' ' .. tostring(p_rel))
    return 1
  end
  if state.hasPath(filepath, state._filepath_storage) then
    dev.log.trace(filepath .. ' already in state._filepath_storage')
    return 2
  end
  if M.hasCwd() == false then
    state.addPath(vim.loop.cwd(), state._dir_storage)
  end
  state.addPath(filepath, state._filepath_storage)
  return 0
end

return M

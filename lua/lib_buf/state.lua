local M = {}

-- Current master buffer id insider master buf
M._master_buf_id = -1
-- Current state including annotations of all buffers
M._master_buf = {}
-- Last written to file state
M._written_master_buf = {}

-- Note: All filepaths are recreated in the session file, but for some reason not in shada.
-- So ignore shada state. :h Initialization
-- Once the sessions is initialized, v:this_session is set.
-- local session = vim.v.this_session
-- Once neovim is initialized, v:vim_did_enter is set
-- local is_initialized = vim.v.vim_did_enter

-- Supported use ccases:
-- 1. search for persistent buffers in local dir
-- 2. use the user provides table
-- 3. user provides path to file with string table
-- 4. user provides string table
---@param args user_options|nil The user options.
---@return number status_code The status code. 0 success, 1 failure.
M.init = function(args)
  local tmp_config = {}
  local is_table = false

  if args == nil then
    -- 1 parse bufstate
    -- TODO implement
    return 0
  elseif type(args) == "table" then
    is_table = true
    -- 2 check table
    -- TODO implement
    tmp_config = args
    return 0
  elseif type(args) == "string" then
    -- 3+4 parse path or table
    -- TODO implement
    return 0
  end
  if is_table == false then
    check(tmp_config)
  end

end

---@param filepath user_filepath|nil User filepath for the buffer state.
---@return number status_code Status code. 0 success, 1 failure.
M.write = function(filepath)
  -- TODO implement
  return 0
end


---@param config_table config_table|nil The user options.
---@return number status_code Status code. 0 success, 1 failure.
M.check = function(config_table)
  -- TODO implement
  return 0
end


return M

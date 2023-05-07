--! High level actions
local M = {}
local Job = require 'plenary.job'
local Path = require 'plenary.path'
local dev = require 'libbuf.dev'
local state = require 'libbuf.state'
local api = vim.api

---Generate buffer handle based on input.
---@param buf_path string|nil Optional path to buffer.
---@return integer buf_h Created or added listed, readable and writable buffer
M.createHandle = function(buf_path)
  local ty_mbuf_path = type(buf_path)
  assert(ty_mbuf_path == 'nil' or ty_mbuf_path == 'string')
  local bufs = api.nvim_list_bufs()
  assert(#bufs > 0)
  local mbuf_path_exists = M.filepathExists(buf_path)
  local buf_h = -1
  for _, v in ipairs(bufs) do
    local name = api.nvim_buf_get_name(v)
    if buf_path == name then
      buf_h = v
      break
    end
  end
  if buf_h == -1 and mbuf_path_exists == true then
    buf_h = vim.fn.bufadd(buf_path)
  end
  if buf_h == -1 then
    buf_h = vim.api.nvim_create_buf(true, true)
  end

  return buf_h
end

-- TODO
-- deleteHandle

---Check, if filepath is path to existing file.
---Workaround Path:new(filepath):exists() returning true for nil
---@param filepath string|nil Filepath for checking, if file exists.
M.filepathExists = function(filepath)
  if filepath == nil then return false end
  return Path:new(filepath):exists()
end

---Function to copy-paste and adjust for using buffer info.
---@param buf_h integer Buffer handle.
---@return table thisbuf_table Buffer with properties as table.
M.currentBufferWithProperty = function (buf_h)
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
  dev.log.trace('currentBufferWithProperty():  bufprops['
    .. tostring(buf_h) .. '] ='
    .. vim.inspect(buf_table))
  return buf_table
end

---Function to copy-paste and adjust for using buffer info.
---@return table bufprops BufferProperties Buffers with properties as []-table.
M.currentBuffersWithPropertis = function()
  local bufprops = {}
  local bufs = api.nvim_list_bufs()
  for _, buf_h in ipairs(bufs) do
    local buf_table = M.currentBufferWithProperty(buf_h)
    bufprops[buf_h] = buf_table
  end
  return bufprops
end

---Insert path to state._dir_storage, if not existing.
---@param any_dirpath string absolute or relative path
---@return integer was_added Ok (0), DirectoryAlreadyExisting (1).
M.insertDir = function(any_dirpath)
  local abs_path = Path:new{any_dirpath}:absolute()
  local has_path = state.hasPath(abs_path, state._dir_storage)
  if has_path == true then
    return 1
  else
    state.insertPath(abs_path, state._dir_storage)
    return 0
  end
end

-- TODO
-- removeDir

---Check, if cwd is in state._dir_storage. Typically cwd is git root/lsp root.
---@return boolean has_path Answer.
M.hasCwd = function() return state.hasPath(vim.loop.cwd(), state._dir_storage) end

---Add rel_filepath to state._filepath_storage, if not existing. Fails, if no relative
---rel_filepath given (1), pwd not in state._dir_storage (2) or file already existing (3).
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

-- TODO
-- M.removeFile = function(any_dirpath, rel_filepath)

---Runs command and sets buffer content to result
---Assume: If necessary, cmd_args contains path arguments (ie for rg).
---@param buf_h integer Buffer handle
---@param cmd_exe string Command
---@param cmd_args string[] Command arguments
M.runCmdWriteIntoBuffer = function(buf_h, cmd_exe, cmd_args)
  dev.log.trace("buf_h: '" .. buf_h)
  dev.log.trace("cmd_exe: '" .. cmd_exe .. "', cmd_args: " .. vim.inspect(cmd_args))
  local job = Job:new {
    command = cmd_exe,
    args = cmd_args,
    enable_recording = false,
    on_stdout = vim.schedule_wrap(function(_, data_line)
      if not data_line or data_line == "" then return end
      api.nvim_buf_set_lines(buf_h, -1, -1, true, { data_line })
    end),
    maximum_results = 1000000, -- maximum 10^6 lines
  }
  return job:sync()
end

---Splits naively cmdline string into cmd_exe and cmd_args by emptyspace.
---@param cmdline string
---@return integer[] Table of 2 elements with cmd_exe and cmd_args
M.splitCmdLine = function(cmdline)
  local cmdinfo = {}
  local cmd_args = {}
  local i = 1
  for s in vim.gsplit(cmdline, ' ', {trimempty=true}) do
    if i == 1 then
      cmdinfo[1] = s
    else
      cmd_args[i-1] = s
    end
    i = i+1
  end
  cmdinfo[2] = cmd_args
  return cmdinfo
end

return M

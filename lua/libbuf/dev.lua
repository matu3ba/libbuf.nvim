--! Cleaned up from https://github.com/ThePrimeagen/harpoon
-- luacheck: globals vim

-- Don't include this file, we should manually include it via
-- require("libbuf.dev").reload();
--
-- A quick mapping can be setup using something like:
-- :nmap <leader>rr :lua require("libbuf.dev").reload()<CR>
local M = {}

function M.reload() require('plenary.reload').reload_module 'libbuf' end

local log_levels = { 'trace', 'debug', 'info', 'warn', 'error', 'fatal' }
local function set_log_level()
  -- local log_level = vim.env.LIBBUF_LOG or vim.g.libbuf_log_level
  local log_level = vim.g.libbuf_log_level

  for _, level in pairs(log_levels) do
    if level == log_level then return log_level end
  end

  return 'warn' -- default, if user hasn't set to one from log_levels
end

local log_level = set_log_level()
M.log = require('plenary.log').new {
  plugin = 'libbuf',
  level = log_level,
  use_console = false,
  highlights = false,
  -- pending upstream prs https://github.com/nvim-lua/plenary.nvim/pull/486 + 487
  -- outfile = string.format("%s/%s.log", vim.api.nvim_call_function("stdpath", { "data" }), 'libbuf'),
  -- fmt_msg = function(is_console, _, src_path, src_line, msg)
  --   local srcinfo = src_path .. ":" .. src_line
  --   if is_console then
  --     return string.format("%s: %s", srcinfo, msg)
  --   else
  --     return string.format("%s: %s\n", srcinfo, msg)
  --   end
  -- end,
}

return M

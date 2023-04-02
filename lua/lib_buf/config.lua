local M = {}

M.defaults = {}
-- current config
M._config = M.defaults

function M.setup(user_config)
  user_config = user_config or {}
end

return M

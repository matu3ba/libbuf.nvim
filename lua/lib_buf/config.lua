local M = {}

function M.setup(user_config)
  user_config = user_config or {}

  user_config = user_config or {}

  M._config = vim.tbl_deep_extend('force', utils.tbl_deep_clone(M.defaults), user_config)
end

return M

describe('Test example', function()
  it('Test can access vim namespace', function() assert.are.same(vim.trim '  a ', 'a') end)
end)

describe('Test example', function()
  it('Test giveme123', function() assert.is.same(require('lib_buf').giveme123(), 123) end)
end)

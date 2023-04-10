-- describe('Test example', function()
--   it('Test can access vim namespace', function()
--     assert.are.same(vim.trim '  a ', 'a')
--   end)
-- end)

-- require('libbuf').giveme123()
-- assert.is.same(require('libbuf').giveme123(), 123)
-- assert.are.same(vim.trim '  a ', 'a')
-- local cwd = vim.loop.cwd()
-- local fp = assert(io.open("/tmp/tmpfile", "w")) --DEBUG
-- local cwd_file =  Path:new { cwd, "README.md" } --DEBUG
-- fp:write(cwd_file:)                             --DEBUG
-- fp:write("\n")                                  --DEBUG
-- fp:close()                                      --DEBUG

-- local Path = require("plenary.path")

describe('initialization of master buffer', function()
  it('populateMasterBuf()', function()
    local libbuf = require 'libbuf'
    local mbuf_h = libbuf.populateMasterBuf(nil, libbuf.default_readwrite_fn, nil)
    local mbuf_content_arr = vim.api.nvim_buf_get_lines(mbuf_h, 0, -1, false)

    local fp = assert(io.open('/tmp/tmpfile', 'a')) --DEBUG
    for _, v in pairs(mbuf_content_arr) do --DEBUG
      fp:write(v) --DEBUG
      fp:write '\n' --DEBUG
    end --DEBUG
    fp:close() --DEBUG

    -- local cwd = vim.loop.cwd()
    -- with api.nvim_buf_set_lines(mbuf_h, 0, -1, false, {})
    -- it works as expected
    assert.is.same(mbuf_content_arr[0], nil)

    -- assert.is.same(mbuf_content_arr[0], "bh |ug    |fpa:ma")
    -- assert.is.same(mbuf_content_arr[1], "   |      |:")
    -- assert.is.same(mbuf_content_arr[2], "   |      |:")
    -- assert.is.same(mbuf_content_arr[3], "   |      |:")
    -- assert.is.same(mbuf_content_arr[4], "   |      |:")
    -- assert.is.same(mbuf_content_arr[5], "   |      |:")
  end)
  -- it('default_readwrite_fn()', function()
  -- end)
  -- it('currentBuffersWithPropertis()', function()
  -- end)
end)

-- describe('state.lua', function()
--   it('printState()', function()
--   end)
-- end)
--
-- describe('config.lua', function()
--   it('printConfig()', function()
--   end)
-- end)

-- TODO: tests config + printing buffer info
-- TODO: scratch window + restore old view + cursosr
-- TODO: global representation for config?
--
-- user provided:
-- TODO: use case of keybindings via index as annotation < most natural + saving space
-- TODO: use case of keybinding via group as annotation
-- TOOD: filters

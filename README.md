#### Low level library for buffers in neovim ####

Goals: Master buffer to control all buffers. Functions to attach info and
actions based on info. Storage and load helpers. Markers. Project search.
Out-of-band text color storage and loader from program output (use shell as runner).

Usage:
```lua
-- lazy config table
return {
  -- ...
  { 'matu3ba/lib_buf.nvim', config = function() require('lib_buf').setup({ dev_autocmd = true, }) end, },
}

```
```lua
-- buf.nvim
local ok_buf, buf = pcall(require, 'buf.nvim')
if not ok_buf then return end

-- TODO something cool
```

#### Developing dependencies:
- luacheck
  * `lurocks install --local luacheck`
  * `luarocks install --local lanes`
- luacov
  * `luarocks install luacov`
- stylua
  * `cargo install stylua`

##### Developing manual commands
- luacheck
  * `luacheck .`
  * `luacheck --no-color -qqq --formatter plain .`
  * best to be used with nvim-lint
- luacov
  * `luajit -lluacov test/*` && evaluate
- stylua
  * `stylua --color Always lua/ tests/`
  * `stylua --color Never --check lua/ tests/`
- plenary
  * `nvim --headless --noplugin -u tests/minimal.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal.lua'}"`
  * `env -i PATH="$PATH" nvim --headless --noplugin -u tests/minimal.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal.lua'}"`

#### Developing command suggestion
```lua
local has_plenary, plenary = pcall(require, 'plenary')
if not has_plenary then print 'Please install plenary for testing.'; return end
local add_cmd = vim.api.nvim_create_user_command
add_cmd('CheckFmt', function()
  local stylua_run = plenary.job:new({ command = 'stylua', args = { '--color', 'always', '--check', 'lua/', 'tests/' } })
  stylua_run:sync()
  if stylua_run.code ~= 0 then print 'Must format.'; end
end, {})
add_cmd('FmtThis', function()
  local stylua_run = plenary.job:new({ command = 'stylua', args = { '--color', 'always', '--check', 'lua/', 'tests/' } })
  stylua_run:sync()
  if stylua_run.code ~= 0 then print [[Formatting had warning or error. Run 'stylua .']]; end
end, {})
```

https://github.com/nvim-lua/plenary.nvim/issues/474 prevents us from
using plenary for spawning another neovim instance like this:
```lua
add_cmd('CheckTests' function()
  -- luacheck: push ignore
  local tests_run = plenary.job:new({ command = 'nvim', args = { '--headless', '--noplugin', '-u', 'tests/minimal.lua', '-c', [["PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal.lua'}"]] } })
  -- luacheck: pop ignore
  tests_run:start()
  tests_run:sync()
  print(vim.inspect.inspect(tests_run:result()))
end, {})
```
So one is forced to use visual inspection of the CLI output instead.

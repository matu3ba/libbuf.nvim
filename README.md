#### Low level library for buffers in neovim ####

Goals: Master buffer to control all buffers based on user-annotated dirs.
Functions to attach info and actions based on info. Storage and load helpers. Markers.
Project search. Out-of-band text color storage and loader from program output (use shell as runner).

Main problems
- How to switch between file paths of different projects or same project?
- How to remain having a reproducible representation of file path buffers and their content?
  * Shells drawbacks
    + Neovim terminal reflow is broken, so resizing terminals breaks content
    + Shells offer not option to capture and store + reload output with colors
    + Terminal escape codes compromise security
    + **But** shell syntax is dense to write and there is no portable process
      alternative yet to replace it.
  * User changes affecting buffer load order makes relying on buffer handles not feasible
  * No user control over which file paths should be stored for each project (harpoon)

Main problem
- No annotating of buffers with info according to user or plugin and
  enabling logic based on that.

Solutions
- Use and improve ideas from arcan lash and add user-controllable directories on top.
- 1 representation for (project) directories
- 1 representation for file paths relative to (project) directories
- Customizable buffer storage for process execution results to emulate terminal
  and conditionally apply colors.
- Make a library with sane defaults for common directories, files and terminal things

Usage:
```lua
return {
  -- ...
  { 'matu3ba/buf.nvim' }
}

```
```lua
-- buf.nvim
local ok_buf, buf = pcall(require, 'buf.nvim')
if not ok_buf then return end

-- TODO demonstrate implemented use cases
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

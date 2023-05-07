#### Low level library for buffers in neovim ####

wip todo. see ./TODO and my dotfiles.

Goals: Master buffer to control all buffers based on user-annotated directories.
Functions to attach info and actions based on info. Storage and load helpers: Markers.
Project search. Text color storage and loader from program output.
Constrainable runner based on plenary job. Buffer colorizer from terminal escape codes.

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
  * No tight user control over which file paths should be stored for each project (harpoon json cluttered)

Main source of problem
- No annotating of buffers and directories with info according to user or plugin to enable logic based on that.

Solutions
- Use and improve ideas from arcan lash and add user-controllable directories on top.
- 1 representation for (project) directories
- 1 representation for file paths relative to (project) directories
- Customizable buffer storage for process execution results to emulate terminal
  and conditionally apply colors.
- Make a library with sane defaults for common directories, files and terminal things
- Test every common code path, 100% coverage.

Usage:
```lua
return {
  -- ...
  { 'matu3ba/libbuf.nvim' },
}
```
```lua
--! Dependency libbuf.nvim
local ok_buf, buf = pcall(require, 'libbuf')
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
  * `cargo install stylua --features lua52` for goto support (in luajit)

##### Developing manual commands
- luacheck
  * `luacheck .`
  * `luacheck --no-color -qqq --formatter plain .`
  * best to be used with nvim-lint
- luacov (TODO)
  * `luajit -lluacov test/*` && evaluate
- stylua
  * `stylua --color Always lua/ tests/`
  * `stylua --color Never --check lua/ tests/`
- plenary
  * `nvim --headless --noplugin -u tests/minimal.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal.lua'}"`
  * `env -i PATH="$PATH" nvim --headless --noplugin -u tests/minimal.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal.lua'}"`

#### Developing suggestions

1. Formatting and checking formatting:
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

2. Use luacheck as linter, for example with `mfussenegger/nvim-lint` and this setup:
```lua
--! Dependency nvim-lint
local ok_lint, lint = pcall(require, 'lint')
if not ok_lint then return end
lint.linters_by_ft = {
  -- luacheck: push ignore
  -- luacheck: pop ignore
  -- luacheck: globals vim
  -- luacheck: no max line length
  -- See also https://github.com/LuaLS/lua-language-server/wiki/Annotations
  lua = { 'luacheck' },
}
vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
  callback = function() lint.try_lint() end,
})
```

3. Use lua language server with the following config (checkThirdParty is unfortunately needed):
```lua
  ---@diagnostic disable
  ---@diagnostic enable
  -- optionally with postfix disable:doesNotExist
lsp.configure('lua_ls', {
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
        -- path = runtime_path,
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { 'vim' },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file('', true),
        checkThirdParty = false,
      },
      -- Do not send telemetry data containing a randomized but unique identifier
      telemetry = {
        enable = false,
      },
    },
  },
  -- force_setup = true,
})
```

4. Use plenary busted for testing, which for now only works in cli with
```sh
env -i PATH="$PATH" nvim --headless --noplugin -u tests/minimal.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal.lua'}"
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

5. Watch out for string table being dict and requiring iteration via `pairs` or
returning no output otherwise. On the contrary, []type is a vector with continuous
indices (and unobservable layout), which should be iterated via `ipairs`.

6. Write your own logging, because plenary.log gobbles the command line and provides
no customizable format.

7. `E5113: Error while calling lua chunk <filepath> attempt to index upvalue 'luafilename' (a boolean value)`
is most likely cause by missing `return M`.

8. If you have non-oneshot or non-trivial applications like telescope.nvim,
design your library/plugin to use dedicated memory tracing.
This means to define run sequences, ideally with fuzzing of your api, and compare collected
memory usage with expected ones.
Use neovim with only the minimal plugins needed and ideally with a long and randomly,
but reproducible sequence of api calls, and call
A simplified script would look like
```lua
local time_start = os.time()
local mem_KBytes = collectgarbage("count") -- memory currently occupied by Lua
local CPU_seconds = os.clock()                  -- CPU time consumed
local runtime_seconds = os.time() - time_start  -- "wall clock" time elapsed
print(mem_KBytes, CPU_seconds, runtime_seconds) -- prints 24.0205078125  5.000009  5
-- api call 1
local mem_KBytes = collectgarbage("count") -- memory currently occupied by Lua
local CPU_seconds = os.clock()                  -- CPU time consumed
local runtime_seconds = os.time() - time_start  -- "wall clock" time elapsed
print(mem_KBytes, CPU_seconds, runtime_seconds) -- prints 24.0205078125  5.000009  5
-- function to compare with expected deviation
-- api call 2
-- ..
```
Unfortunately, plenary.nvim has not yet example code for these kind of applications and the
[solution by tarantool is complex](https://github.com/tarantool/luajit/blob/0cfc06f8be66af0b30072db5233eda6b13de2e09/tools/memprof.lua).

9. Adjust the default logger of plenary. Using corrrectly `debug.getinfo` is tricky.
Reasonable settings, if accurate timings are not needed and absolute paths are wanted, are
```lua
M.log = require('plenary.log').new {
  plugin = 'libbuf',
  level = log_level,
  use_console = false,
  highlights = false,
  -- might not be upstreamed yet
  fmt_msg = function(is_console, mode_name,, src_path, src_line, msg)
    local srcinfo = src_path .. ":" .. src_line
    if is_console then
      return string.format("%s: %s", lineinfo, msg)
    else
      return string.format("%s: %s\n", lineinfo, msg)
    end
  end,
}
```

10. One-line flat table printing: `table.foreach(parts, print)`

11. One-line [] array insertion: `array[#array+1]=value`

12. Plenary and ripgrep have surprisingly annoying behavior, so the following
does not work
```lua
local Job = require("plenary.job")
Job:new({
  command = "rg",
  args = { "test" },
  on_stdout = vim.schedule_wrap(function(_, data)
    if not data or data == "" then return end
    vim.api.nvim_buf_set_lines(0, -1, -1, false, { data })
  end),
}):sync()
```
and neither setting `cwd = vim.loop.cwd()`.

13. on_stdout with `vim.schedule_wrap` requires to use it at the top level, since
callbacks must be wrapped at once. Neovim does not warn on incorrect usage and
silently does nothing in that case.

14. Telescope simplifies the indirection between 1. input history, 2. input, 3. path
and 4. results.

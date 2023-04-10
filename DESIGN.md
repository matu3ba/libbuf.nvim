See `lua/libbuf/state.lua` for the plugin state read from and written to memory.

Principle
- 1. `state._dir_storage` and `state._filepath_storage` contain file paths
relating to files on the file system, which have annotations.
- 2. Annotations are user_date + index into `state._dir_storage` and
index into `state._filepath_storage`.
- 3. Master buffer provides an overview over all buffers with annotations.
- 4. Terminals are handled special to make completion and search work, but
execution and collection of results is redirected to plenary jobs and temporary
files and color description files.

Problems
- 1. Subprojects are not modeled accurately. Consider
```
/home/user/proj1
/home/user/proj1/subproj2
/home/user/proj1/subproj2/src/file1
/home/user/proj1/subproj3/src/file1
```
`subproj2` and `subproj3` are not modeled as being subprojects of `proj1`, so
the prefix path is "wasted", but this sounds like an acceptable tradeoff.

2. Another problem is that pruning files requires walking through all paths
and so does re-indexing, but this sounds okay for now as long as the usage
references are not stored dezentral.

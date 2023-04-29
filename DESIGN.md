See `lua/libbuf/state.lua` for the plugin state read from and written to memory.

Principle
- 1. `state._dir_storage` and `state._filepath_storage` contain file paths
relating to files on the file system, which have annotations.
- 2. Dependencies for lookup and cleanup are modeled via bidirectional edges
  * Directories can own abs_dirpaths or rel_filepaths and each of those know
    which directory owns them (or if none, but only in case of a directory)
  * Edges are represented as
```
Edges
absdirpath_hash -> {any_hash1, any_hash2, ..}
```
  * Note: Ownership can be retrieved from comparing the paths
  `absdirpath_hash with any_hashX`, because
    - 1. `dirpaths` must be absolute making them always owning filepaths
    - 2. `dirpath1` can only own `dirpath2`, when `dirpath1` is prefix of `dirpath2`.
- 2. Annotations can be indexed via non-continuous integers:
```
For unmapped handles all indices are negative:
-1 -> { hash:{hash_abs_dir,hash_rel_filepath}, group:groupname, etc }
For mapped handles all indices are positive including 0:
0 -> { hash:{hash_abs_dir,hash_rel_filepath}, group:groupname, etc }
```
- 3. Master buffer provides an overview over all buffers with annotations.
- 4. Terminals are handled special to make completion and search work, but
execution and collection of results is redirected to plenary jobs to retrieve
the file including terminal escapes for the color codes.

Problems
- 1. Subprojects are not modeled accurately. Consider
```
/home/user/proj1
/home/user/proj1/subproj2
/home/user/proj1/subproj2/src/file1
/home/user/proj1/subproj3/src/file1
```
`subproj2` and `subproj3` are not modeled as being subprojects of `proj1`, so
the prefix path is "wasted".

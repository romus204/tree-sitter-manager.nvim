## Running Tests

0. Download or update dependencies [mini.nvim](https://github.com/nvim-mini/mini.nvim):
    ```sh
    make update
    ```
0. Run headless tests:
    ```sh
    make test                   # run all modules on a predefined set of languages
    make test_xxx               # run tests/test_xxx.lua
    make test       python bash # run only for python and bash
    make test_xxx   python bash
    make test       all         # run all cases for all languages
    make test_xxx   all         # run test_xxx for all languages
    ```
0. Run tests interactively.
    ```sh
    make nvim
    make nvim tests/test_xxx.lua   # open test_xxx.lua
    ```
    ```vim
    :lua MiniTest.run()            -- run all modules
    :lua MiniTest.run_file()       -- run current file
    ```
    See [MiniTest](https://github.com/nvim-mini/mini.nvim/blob/main/TESTING.md) for more.

    To change the set of languages to run the tests on, set the environment variable
    `LANGUAGES` to a space-separated list of languages. This is what `make test`
    does under the hood.

## Writing Tests

Get familiar with [MiniTest](https://github.com/nvim-mini/mini.nvim/blob/main/TESTING.md).

There is a helper module at `tests/child.lua` to spawn and run tests in an isolated neovim child process.
This is necessary to test asynchronous functions (See [mini.nvim#1930](https://github.com/nvim-mini/mini.nvim/issues/1930)).

### Global Variables
- `_G.languages`: a list of languages passed to `make test ...`
- `eq`, `neq`, `er`, `ner`: aliases to `MiniTest.expect.equality`, `no_equality`, `error`, `no_error`
- `child`: `require("tests.child")`
- `tsm`: `require("tree-sitter-manager")`
- `config`: `require("tree-sitter-manager.config")`
- `installer`: `require("tree-sitter-manager.installer")`
- etc.

### Global Functions
- `new_set(opts, tbl)`: do `MiniTest.new_set(opts, tbl)`
  with default hooks for `child.setup()`, `child.cleanup()`. Every test file
  should `setup` the child process at the start and `cleanup` the child process
  afterwards.
- `parametrize(list)`: nest every item into a singleton, i.e. does the following:
  ```lua
  vim.iter(list):map(function(x) return { x } end):totable()
  ```

### Example
Create a file `tests/test_install.lua`:
```lua
-- list languages you want to test
local languages = _G.languages or { "bash", "python", "java" }

local T = new_set({
    hooks = {
        pre_once = function()
            child.setup({ highlight = true })
        end,
    },
    parametrize = parametrize(languages),
})

T["test-case"] = function(lang)
    child.fails(lang, "parser") -- parser isn't installed yet

    -- Parameters:
    -- languages to be installed
    -- timeout (default 60,000 ms)
    -- return_error (default false), whether to return the error message or throw it
    child.install(languages, 60000, false)

    child.works(lang, "parser") -- checks parser
    child.works(lang, "highlights") -- check highlights queries
end

return T
```

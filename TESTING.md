## Running Tests

0. Set up the test environment:
    ```sh
    make env
    ```
0. Run headless tests:
    ```sh
    make test       # run all tests
    make test_xxx   # run tests/test_file.lua
    ```
0. Run tests interactively.
    ```sh
    make nvim
    make nvim tests/test_xxx.lua   # open test_xxx.lua
    ```
    ```vim
    :lua MiniTest.run()             -- run all tests
    :lua MiniTest.run_file()        -- run current file
    ```
    See [MiniTest](https://github.com/nvim-mini/mini.nvim/blob/main/TESTING.md) for more.

## Writing Tests

Get familiar with [MiniTest](https://github.com/nvim-mini/mini.nvim/blob/main/TESTING.md).

There is a helper module at `tests/child.lua`. To spawn and run tests in an isolated neovim child process.
This is necessary to test asynchronous functions (See [mini.nvim#1930](https://github.com/nvim-mini/mini.nvim/issues/1930)). Basic example, create a file `tests/test_install_bash.lua`:
```lua
local neq = MiniTest.expect.no_equality
local nerr = MiniTest.expect.no_error
local child = require("tests.child")
local T = MiniTest.new_set({
    hooks = {
        -- setup will set a unique parent directory to `parser_dir` and `query_dir`
        pre_once = function()
            child:setup()
        end,
        post_once = function()
            child:cleanup()
        end,
    }
})
T["test-case"] = function()
    -- add more options to tree-sitter-manager.setup()
    child:update_config({ highlight = false })
    child.cmd("TSInstall bash")
    -- wait until bash is installed
    child:parser_wait("bash")
    -- ensure that treesitter works for starlark
    neq({}, vim.treesitter.query.get_files("bash", "highlights"))
    nerr(function()
        vim.treesitter.get_string_parser("", "bash")
    end)
end
return T
```

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

    To change the set of languages to run the tests on set `vim.env.LANGUAGES`
    to a space-separated list of languages. This is what `make test` does under
    the hood.

## Writing Tests

Get familiar with [MiniTest](https://github.com/nvim-mini/mini.nvim/blob/main/TESTING.md).

There is a helper module at `tests/child.lua`. To spawn and run tests in an isolated neovim child process.
This is necessary to test asynchronous functions (See [mini.nvim#1930](https://github.com/nvim-mini/mini.nvim/issues/1930)). Basic example, create a file `tests/test_install_bash.lua`:
```lua
-- list languages you want to test
local languages = { "bash", "python", "java" }
if vim.env.LANGUAGES then
    -- this allows `make test zig rust` to work
    languages = vim.split(vim.env.LANGUAGES, " ")
end

local child = require("tests.child")
local neq = MiniTest.expect.no_equality
local nerr = MiniTest.expect.no_error

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
    child.cmd("TSInstall " .. table.concat(languages, " "))
    -- wait until bash finishes installation
    -- and check if treesitter works
    child:check_installed(languages)
end

return T
```

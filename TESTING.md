0. Set up the test environment:
    ```sh
    make env
    ```
0. Run headless tests:
    ```sh
    make test                                   # run all tests
    FILE=tests/test_file.lua make test_file     # run test_file.lua
    ```
0. Run tests interactively.
    ```sh
    make nvim
    make nvim tests/test_file.lua   # open a test_file.lua
    ```
    ```vim
    :lua MiniTest.run()             -- run all tests
    :lua MiniTest.run_file()        -- run current file
    :lua MiniTest.run_at_location() -- run the file at a specific line
    ```
    See [MiniTest](https://github.com/nvim-mini/mini.nvim/blob/main/TESTING.md).

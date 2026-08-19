local repos = require("tree-sitter-manager.repos")

local M = {}
local datapath = vim.fn.stdpath("data")

---@class tree_sitter_manager.Config
---@field parser_dir? string Directory to install compiled parsers into. Defaults to `stdpath('data')/site/parser`.
---@field query_dir? string Directory to install query files into. Defaults to `stdpath('data')/site/queries`.
---@field languages? table<string, string|tree_sitter_manager.LanguageSpec> User-defined language repos to use instead of the built-in ones. Can either be a string (a git URL), or a more detailed LanguageSpec.
---@field assume_installed? string[] Languages to never install.
---@field ensure_installed? string|string[] Languages to install on `setup()` if not already present. Use `"all"` to install all languages.
---@field auto_install? boolean Install missing parsers automatically on `FileType`.
---@field noauto_install? string[] Languages to opt-out from `auto_install`.
---@field highlight? boolean|string[] Enable `vim.treesitter.start()` for installed parsers. `true` enables all, or pass a list of languages.
---@field nohighlight? string[] Languages to disable highlighting for.
---@field nerdfont? boolean Enable nerdfont glyphs.
---@field border? string|string[] Border style passed to `nvim_open_win` for the manager UI.
---@field min_width? number Minimum width of the TUI window.
---@field min_height? number Minimum height of the TUI window.
---@field async_size? number Maximum number of async jobs.

---@type tree_sitter_manager.Config
M.cfg = {
    parser_dir = vim.fs.joinpath(datapath, "site/parser"),
    query_dir = vim.fs.joinpath(datapath, "site/queries"),
    languages = {},
    assume_installed = {},
    ensure_installed = {},
    auto_install = false,
    noauto_install = {},
    highlight = true,
    nohighlight = {},
    nerdfont = true,
    border = "rounded",
    min_width = 78,
    min_height = 40,
    async_size = 64,
}

M.base_repos = repos
M.effective_repos = repos
M.languages = vim.tbl_keys(repos)

return M

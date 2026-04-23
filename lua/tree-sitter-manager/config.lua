local repos = require("tree-sitter-manager.repos")

local M = {}

---@class tree-sitter-manager.Config
---@field parser_dir? string Directory to install compiled parsers into. Defaults to `stdpath('data')/site/parser`.
---@field query_dir? string Directory to install query files into. Defaults to `stdpath('data')/site/queries`.
---@field languages? table<string, string|tree-sitter-manager.LanguageSpec> User-defined language repos to use instead of the built-in ones. Can either be a string (a git URL), or a more detailed LanguageSpec.
---@field ensure_installed? string[] Languages to install on `setup()` if not already present.
---@field border? string|string[] Border style passed to `nvim_open_win` for the manager UI.
---@field auto_install? boolean Install missing parsers automatically on `FileType`.
---@field highlight? boolean|string[] Enable `vim.treesitter.start()` for installed parsers. `true` enables all, or pass a list of languages.
---@field nohighlight? string[] Languages to disable highlighting for.

---@class tree-sitter-manager.LanguageSpec
---@field install_info? tree-sitter-manager.InstallInfo Information about how to fetch and build the grammar.
---@field requires? string[] Other languages that are dependencies of this one and must be installed first.

---@class tree-sitter-manager.InstallInfo
---@field url string Git URL of the grammar repository.
---@field location? string Sub-directory within the repo where the grammar is stored. Defaults to the name of the language.
---@field revision? string Git revision to check out after cloning. Takes priority over `branch`.
---@field branch? string Git branch to check out after cloning. Ignored if `revision` is set.
---@field generate? boolean Run `tree-sitter generate` before building. Defaults to false.
---@field use_repo_queries? boolean Use queries from the cloned repo's `queries/` directory instead of those bundled with the plugin. Defaults to false.
M.cfg = {
    parser_dir = vim.fn.stdpath("data") .. "/site/parser",
    query_dir = vim.fn.stdpath("data") .. "/site/queries",
    languages = {},
    ensure_installed = {},
    border = nil,
    auto_install = false,
    highlight = true,
    nohighlight = {},
}

M.base_repos = repos
M.effective_repos = repos
M.languages = vim.tbl_keys(repos)
table.sort(M.languages)

return M

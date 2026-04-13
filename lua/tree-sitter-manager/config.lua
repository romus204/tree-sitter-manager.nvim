local repos = require("tree-sitter-manager.repos")

local M = {}

M.cfg = {
    parser_dir = vim.fn.stdpath("data") .. "/site/parser",
    query_dir = vim.fn.stdpath("data") .. "/site/queries",
    ---@type table<string, string|{install_info?: {url: string, location?: string, revision?: string, branch?: string, generate?: boolean, use_repo_queries?: boolean}, requires?: string[]}>
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

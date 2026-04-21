local M = {}

M.check = function()
    vim.health.start("tree-sitter-manager")

    -- Ensure dependencies are installed
    if vim.fn.executable("tree-sitter") == 0 then
        vim.health.error("tree-sitter CLI must be installed")
    else
        local version = vim.system({ "tree-sitter", "--version" }):wait()
        local strip_trailing_newline = string.sub(version.stdout, 1, -2)
        vim.health.ok("tree-sitter CLI is installed: " .. strip_trailing_newline)
    end

end

return M

local M = {}

M.check = function()
    vim.health.start("tree-sitter-manager")

    -- Ensure dependencies are installed
    local dependencies = {
        -- Format is { command_name, human_readable_name }
        { "tree-sitter", "the tree-sitter CLI" },
        { "git", "git" },
        { "cc", "a C compiler" },
    }
    for _, dependency in pairs(dependencies) do
        local command_name = dependency[1]
        local human_readable_name = dependency[2]
        if vim.fn.executable(command_name) == 0 then
            vim.health.error(human_readable_name .. " must be installed")
        else
            local version = vim.system({ command_name, "--version" }):wait()
            local first_line = vim.fn.split(version.stdout, "\n")[1]
            vim.health.ok(human_readable_name .. " is installed: " .. first_line)
        end
    end

end

return M

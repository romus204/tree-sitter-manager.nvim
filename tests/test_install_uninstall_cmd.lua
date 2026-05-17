local err = MiniTest.expect.error
local fs = vim.fs

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            local site = fs.joinpath(vim.fn.stdpath("data"), "site")
            fs.rm(fs.joinpath(site, "parser"), { recursive = true })
            fs.rm(fs.joinpath(site, "queries"), { recursive = true })
            require("tree-sitter-manager").setup()
            util = require("tree-sitter-manager.util")
        end,
    },
})

T["install"] = function()
    vim.cmd.TSInstall("bash")
    local success = vim.wait(60000, function()
        return vim.uv.fs_stat(util.ppath("csv"))
    end, 50)
    if not success then
        error("timeout: building csv treesitter")
    end
    vim.treesitter.get_string_parser("", "csv")
end

T["uninstall"] = function()
    vim.cmd.TSUninstall("csv")
    err(function()
        vim.treesitter.get_string_parser("", "csv")
    end, "No parser for language")
end

return T

local eq = MiniTest.expect.equality
local neq = MiniTest.expect.no_equality

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            require("tree-sitter-manager").setup({
                ensure_installed = { "starlark" },
                auto_install = true,
                highlight = true,
            })
            local util = require("tree-sitter-manager.util")
            local success = vim.wait(60000, function()
                return vim.uv.fs_stat(util.ppath("starlark"))
            end, 50)
            if not success then
                error("timeout: building starlark treesitter")
            end
        end
    },
})

T["config"] = function()
    local autocmds = vim.api.nvim_get_autocmds({
        event = "FileType",
        pattern = "bzl",
    })
    neq(#autocmds, 0, { "zero autocommands created" })
    eq(vim.iter(autocmds):any(function(autocmd)
        return autocmd.desc == "Auto-enable treesitter for installed parsers"
    end), true, { "no highlight autocmd created" })
end

return T

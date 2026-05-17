local eq = MiniTest.expect.equality
local neq = MiniTest.expect.no_equality

local lang = { ["starlark"] = { "bzl" } }
local child = require("tests.child")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child:setup()
        end,
        post_case = function()
            child:cleanup()
        end,
    },
})

T["auto-highlight"] = function()
    local config = child:update_config({
        auto_install = true,
        highlight = true,
    })
    local languages = vim.tbl_keys(lang)
    child:update_config({ ensure_installed = languages })
    child:parser_wait(languages)

    require("tree-sitter-manager").setup(config)
    local autocmds = vim.api.nvim_get_autocmds({
        event = "FileType",
        pattern = vim.iter(vim.tbl_values(lang)):flatten():totable(),
    })
    eq(
        true,
        vim.iter(autocmds):any(function(autocmd)
            return autocmd.desc == "Auto-enable treesitter for installed parsers"
        end)
    )
end

return T

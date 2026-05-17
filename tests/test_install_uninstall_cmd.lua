local eq = MiniTest.expect.equality
local nerr = MiniTest.expect.no_error

local lang = { "bash" }
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

T["install_uninstall"] = function()
    child.cmd("TSInstall " .. table.concat(lang, " "))
    child:parser_wait(lang)
    for _, l in ipairs(lang) do
        nerr(function()
            vim.treesitter.get_string_parser("", l)
        end)
    end
    vim.cmd.TSUninstall({ args = lang, mods = { silent = true } })
    for _, l in ipairs(lang) do
        eq(vim.treesitter.query.get_files(l, "highlights"), {})
    end
end

return T

local nerr = MiniTest.expect.no_error
local neq = MiniTest.expect.no_equality
local err = MiniTest.expect.error
local eq = MiniTest.expect.equality

local lang = { "bash", "csv", "terraform", "helm", "ocaml" }
local child = require("tests.child")

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup()
        end,
        post_once = function()
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
        neq(nil, vim.treesitter.query.get(l, "highlights"))
    end
    child.cmd("TSUninstall " .. table.concat(lang, " "))
    child.restart()
    for _, l in ipairs(lang) do
        err(function()
            child.lua("vim.treesitter.get_string_parser('', l)")
        end)
        eq({}, vim.treesitter.query.get_files(l, "highlights"))
    end
end

return T

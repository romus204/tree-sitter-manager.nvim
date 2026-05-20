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
    child:check_installed(lang)
    child.cmd("TSUninstall " .. table.concat(lang, " "))
    vim.wait(500)
    child.restart()
    child:check_not_installed(lang)
end

return T

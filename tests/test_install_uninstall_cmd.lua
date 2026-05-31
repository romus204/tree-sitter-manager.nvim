local languages = _G.languages or { "bash", "csv", "terraform", "helm", "ocaml" }
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
    child.cmd("TSInstall " .. table.concat(languages, " "))
    child:check_installed(languages)
    child.cmd("TSUninstall " .. table.concat(languages, " "))
    vim.wait(500)
    child.restart()
    child:check_not_installed(languages)
end

return T

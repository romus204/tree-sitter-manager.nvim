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
    -- wait for the parsers to successfully install
    child:wait(languages)
    child.cmd("TSUninstall " .. table.concat(languages, " "))
    child.restart()
    -- verify that the parsers are uninstalled
    child:fails(languages)
end

return T

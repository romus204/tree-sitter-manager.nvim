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
    for _, lang in ipairs(languages) do
        er(function()
            child.lua("vim.treesitter.get_string_parser('', '" .. lang .. "')")
        end)
        eq(true, child.lua_get("nil == vim.treesitter.query.get('" .. lang .. "', 'highlights')"))
    end
end

return T

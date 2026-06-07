local languages = _G.languages or { "starlark", "python", "javascript", "razor" }
local child = require("tests.child")
local eq = MiniTest.expect.equality

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup()
        end,
        post_once = function()
            child:cleanup()
        end,
    },
    parametrize = vim.iter(languages)
        :map(function(lang)
            return { lang }
        end)
        :totable(),
})

T["before_install"] = function(lang)
    eq(true, child.lua_get("nil == vim.treesitter.query.get('" .. lang .. "', 'highlights')"))
end

T["after_install"] = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:update_config({ ensure_installed = languages })
            child:parser_wait(languages)
        end,
    },
    parametrize = { { "highlights" } },
})
T["after_install"]["not_cleared"] = function(lang, query)
    eq(true, child.lua_get("nil ~= vim.treesitter.query.get('" .. lang .. "', '" .. query .. "')"))
end
T["after_install"]["cleared"] = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child.lua("vim.treesitter.query.get:clear()")
        end,
    },
})
T["after_install"]["cleared"]["query"] = function(lang, query)
    eq(true, child.lua_get("nil ~= vim.treesitter.query.get('" .. lang .. "', '" .. query .. "')"))
end

return T

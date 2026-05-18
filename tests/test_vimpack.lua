local neq = MiniTest.expect.no_equality
local eq = MiniTest.expect.equality

local child = require("tests.child")
local function cleanup()
    vim.pack.del(vim.iter(vim.pack.get())
        :map(function(v)
            return v.spec.name
        end)
        :totable())
end

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child:setup()
            cleanup()
        end,
        post_case = function()
            child:cleanup()
            cleanup()
        end,
    },
})

T["vim.pack"] = function()
    child.lua([[
    vim.pack.add({ "https://github.com/romus204/tree-sitter-manager.nvim" }, { confirm = false })
    ]])
    local packs = child.lua_get([[vim.pack.get({ "tree-sitter-manager.nvim" })]])
    eq(true, packs and #packs > 0 and packs[1].active)
end

return T

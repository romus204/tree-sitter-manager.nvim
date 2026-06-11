local function cleanup()
    child.lua([[
    vim.pack.del(vim.iter(vim.pack.get())
        :map(function(v)
            return v.spec.name
        end)
        :totable(),
        { force = true }
    )
    ]])
end

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup()
            cleanup()
        end,
        post_once = function()
            cleanup()
            child:cleanup()
        end,
    },
})

T["vim.pack"] = function()
    -- check vim.pack installation
    child.lua([[
    vim.pack.add({ "https://github.com/romus204/tree-sitter-manager.nvim" }, { confirm = false })
    ]])
    local packs = child.lua_get([[vim.pack.get({ "tree-sitter-manager.nvim" })]])
    eq(true, packs and #packs > 0 and packs[1].active)
end

return T

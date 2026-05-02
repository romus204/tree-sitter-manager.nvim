local clear_packages = function()
    vim.pack.del(
        vim.iter(vim.pack.get())
        :map(function(v) return v.spec.name end)
        :totable()
    )
end

local T = MiniTest.new_set({
    hooks = { pre_once = clear_packages },
})

T['vim.pack'] = function()
    vim.pack.add(
        { 'https://github.com/romus204/tree-sitter-manager.nvim' },
        { confirm = false, }
    )
end

return T

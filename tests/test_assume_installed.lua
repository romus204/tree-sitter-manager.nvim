local languages = _G.languages or { "c", "lua", "markdown", "markdown_inline", "query", "vim", "vimdoc" }
local requiredby = vim.iter(languages):fold({}, function(acc, lang)
    for _, dep in ipairs(config.languages) do
        if vim.list_contains(util.get_requires(dep), lang) then
            acc[lang] = dep
            break
        end
    end
    return acc
end)
install_list = { unpack(languages), unpack(vim.tbl_values(requiredby)) }

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup({
                assume_installed = languages,
                ensure_installed = install_list,
            })
        end,
        post_once = function()
            child:cleanup()
        end,
    },
    parametrize = vim.iter(languages):fold({}, function(acc, lang)
        table.insert(acc, { lang, false })
        local dep = requiredby[lang]
        if dep then
            table.insert(acc, { lang, dep })
        end
        return acc
    end),
})

T["assume_installed"] = function(lang, dep)
    -- parser for lang should already be installed
    child:wait(lang, 0)
    -- verify installation for the dependant language
    if dep then
        child:wait(dep)
    end
end

T["query"] = function(lang, dep)
    if dep then
        child:works(dep)
    end
end

return T

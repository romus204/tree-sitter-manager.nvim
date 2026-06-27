local T = new_set({
    hooks = {
        pre_once = function()
            child.setup({
                languages = {
                    razor = {
                        install_info = {
                            revision = "a3399c26610817c6d32c7643793caf3729cfb6d2",
                            url = "https://github.com/tris203/tree-sitter-razor",
                            queries = "queries",
                        },
                    },
                },
                ensure_installed = { "perl", "prolog", "razor" },
            })
        end,
        pre_case = function()
            if _G.languages then
                MiniTest.skip()
            end
        end,
    },
    parametrize = {
        { "generate", "perl" },
        { "location", "prolog" },
        { "queries", "razor" },
    },
})

T["case"] = function(option, language)
    child.wait(language)
    child.works(language)
end

return T

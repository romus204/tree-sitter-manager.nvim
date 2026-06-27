local T = new_set({
    hooks = {
        pre_case = function()
            if _G.languages then
                MiniTest.skip()
            end
        end,
    },
})

T["new_language_fails"] = function()
    child.setup({
        languages = {
            console = {
                install_info = {
                    url = "/home/sroeca/src/pappasam/tree-sitter-console",
                    branch = "main",
                    queries = "queries",
                },
            },
        },
    })
    child.cmd("TSInstall console")
    er(function()
        child.wait("console")
    end, "does not exist")
end

T["override_works"] = function()
    child.setup({
        languages = {
            matlab = {
                install_info = {
                    revision = "c2390a59016f74e7d5f75ef09510768b4f30217e",
                    url = "https://github.com/acristoffers/tree-sitter-matlab",
                    queries = "queries/neovim",
                },
            },
        },
        ensure_installed = { "matlab" },
    })
    child.wait("matlab")
    child.works("matlab")
end

T["override_fails"] = function()
    child.setup({
        languages = {
            matlab = {
                install_info = {
                    revision = "c2390a59016f74e7d5f75ef09510768b4f30217e",
                    url = "https://github.com/acristoffers/tree-sitter-matlab",
                    queries = "queries",
                },
            },
        },
        ensure_installed = { "matlab" },
    })
    child.wait("matlab")
    -- in the future this should fail
    -- child.fails("matlab")
end

return T

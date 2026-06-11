local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup()
        end,
        pre_case = function()
            child.restart()
        end,
        post_case = function()
            child:cleanup()
        end,
    },
})

T["revision"] = function()
    -- check installation with revision
    local lang = _G.languages or { "tsv" }
    child.lua("installer.install(" .. vim.inspect(lang) .. ")")
    child:wait(lang)
end

T["branch_revision"] = function()
    -- check installation with branch and revision (revision takes priority)
    child.cmd("TSInstall sql")
    child:wait("sql")
end

T["branch"] = function()
    -- check installation with branch
    local lang = _G.languages or { "sql" }
    local base_repos = config.base_repos
    child:update({
        ensure_installed = lang,
        languages = vim.iter(lang):fold({}, function(acc, l)
            acc[l] = {
                install_info = {
                    branch = "main",
                    url = base_repos[l].install_info.url,
                },
            }
            return acc
        end),
    })
    child:wait(lang)
end

T["no_branch_no_rev"] = function()
    -- check installation from HEAD
    local lang = _G.languages or { "sql" }
    local base_repos = config.base_repos
    child:update({
        ensure_installed = lang,
        languages = vim.iter(lang):fold({}, function(acc, l)
            acc[l] = {
                install_info = base_repos[l].install_info.url,
            }
            return acc
        end),
    })
    child:wait(lang)
end

T["pre_2.49.0"] = MiniTest.new_set({
    hooks = {
        pre_once = function()
            -- simulate git pre 2.49
            child.restart()
            child.lua([[
            system = vim.system
            vim.system = function(cmd, ...)
                if type(cmd) == "table" and cmd[1] == "git" and cmd[2] == "version" then
                    return {
                        wait = function(self, ...)
                            return {
                                code = 0,
                                signal = 0,
                                stdout = "git version 2.47.0\n",
                                stderr = "",
                            }
                        end,
                    }
                end
                return system(cmd, ...)
            end
            ]])
        end,
        post_once = function()
            child:cleanup()
        end,
    },
})
T["pre_2.49.0"]["revision"] = function()
    -- check installation with revision pre 2.49
    local lang = _G.languages or { "tsv" }
    child.lua("installer.install(" .. vim.inspect(lang) .. ")")
    child:wait(lang)
end

return T

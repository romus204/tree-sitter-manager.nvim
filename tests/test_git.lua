local T = new_set()

T["revision"] = function()
    -- check installation with revision
    local languages = _G.languages or { "tsv" }
    child.lua("installer.install(" .. vim.inspect(languages) .. ")")
    child.wait(languages)
end

T["branch_revision"] = function()
    if _G.languages then
        MiniTest.skip()
    end
    -- check installation with branch and revision (revision takes priority)
    local languages = { "perl" }
    child.setup({
        ensure_installed = languages,
        languages = vim.iter(languages):fold({}, function(acc, lang)
            local info = util.get_repo_info(lang)
            info.revision = "release"
            info.branch = "master"
            info.generate = false
            acc[lang] = { install_info = info }
            return acc
        end),
    })
    child.wait(languages, 180000)
end

T["branch"] = function()
    if _G.languages then
        MiniTest.skip()
    end
    -- check installation with branch
    local languages = { "perl" }
    child.setup({
        ensure_installed = languages,
        languages = vim.iter(languages):fold({}, function(acc, lang)
            local info = util.get_repo_info(lang)
            info.revision = nil
            info.branch = "master"
            info.generate = true
            acc[lang] = { install_info = info }
            return acc
        end),
    })
    child.wait(languages, 180000)
end

T["no_branch_no_rev"] = function()
    if _G.languages then
        MiniTest.skip()
    end
    -- check installation from HEAD
    local languages = { "perl" }
    child.setup({
        ensure_installed = languages,
        languages = vim.iter(languages):fold({}, function(acc, lang)
            local info = util.get_repo_info(lang)
            info.revision = nil
            info.branch = nil
            info.generate = true
            acc[lang] = { install_info = info }
            return acc
        end),
    })
    child.wait(languages, 180000)
end

T["GIT_WORK_TREE"] = function()
    local languages = _G.languages or { "tsv" }
    child.cmd("let $GIT_WORK_TREE = '.'")
    child.lua("installer.install(" .. vim.inspect(languages) .. ")")
    child.wait(languages)
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
    },
})
-- check installation with revision pre 2.49
T["pre_2.49.0"]["revision"] = function()
    local languages = _G.languages or { "tsv" }
    child.lua("installer.install(" .. vim.inspect(languages) .. ")")
    child.wait(languages)
end
T["pre_2.49.0"]["GIT_WORK_TREE"] = function()
    local languages = _G.languages or { "tsv" }
    child.cmd("let $GIT_WORK_TREE = '.'")
    child.lua("installer.install(" .. vim.inspect(languages) .. ")")
    child.wait(languages)
end

return T

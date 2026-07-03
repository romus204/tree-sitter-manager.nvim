local T = new_set({ hooks = { pre_case = child.setup, post_case = child.cleanup } })

T["revision"] = function()
    -- check installation with revision
    child.install(_G.languages or { "tsv" })
end

T["branch_revision"] = function()
    if _G.languages then
        MiniTest.skip("skip smoke tests")
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
    child.wait(languages)
end

T["branch"] = function()
    if _G.languages then
        MiniTest.skip("skip smoke tests")
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
    child.wait(languages)
end

T["no_branch_no_rev"] = function()
    if _G.languages then
        MiniTest.skip("skip smoke tests")
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
    child.wait(languages)
end

T["GIT_WORK_TREE"] = function()
    child.cmd("let $GIT_WORK_TREE = '.'")
    child.install(_G.languages or { "tsv" })
end

T["pre_2.49.0"] = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- simulate git pre 2.49
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
            local version = { child.lua_get('util.run({ "git", "version" }).output'):match("(%d+)%.(%d+)%.(%d+)") }
            local major, minor, patch = unpack(vim.iter(version):map(tonumber):totable())
            eq(true, major < 2 or major == 2 and minor < 49)
        end,
    },
})
-- check installation with revision pre 2.49
T["pre_2.49.0"]["revision"] = function()
    child.install(_G.languages or { "tsv" })
end
T["pre_2.49.0"]["GIT_WORK_TREE"] = function()
    child.cmd("let $GIT_WORK_TREE = '.'")
    child.install(_G.languages or { "tsv" })
end

return T

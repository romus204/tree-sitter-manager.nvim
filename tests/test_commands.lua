local languages = _G.languages or { "bash", "csv", "terraform", "helm", "ocaml" }
local child = require("tests.child")
local util = require("tree-sitter-manager.util")

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup()
        end,
        post_once = function()
            child:cleanup()
        end,
    },
})

T["TSInstall"] = function()
    child.cmd("TSInstall " .. table.concat(languages, " "))
    child:wait(languages)
    child:works(languages)
end

T["TSUpdate"] = function()
    -- edit revision to FETCH_HEAD~
    child:update({
        languages = vim.iter(languages):fold({}, function(acc, lang)
            local info = util.get_repo_info(lang)
            local tmpdir = vim.fn.tempname()
            local ok, sha
            if not util.run({ "git", "init", tmpdir }) then
                error("git init")
            end
            if not util.run({ "git", "remote", "add", "origin", info.url }, tmpdir) then
                error("git remote add origin " .. info.url)
            end
            if not util.run({ "git", "fetch", "--depth=2", "origin", info.revision }, tmpdir) then
                error("git fetch origin " .. info.revision)
            end
            ok, sha = util.run({ "git", "rev-parse", "FETCH_HEAD~" }, tmpdir)
            if not ok then
                error("git rev-parse HEAD~")
            end
            info.revision = sha
            acc[lang] = info
            return acc
        end),
    })
    child.cmd("TSUpdate " .. table.concat(languages, " "))
    child:wait(languages)
    child:works(languages)
end

T["TSUninstall"] = function()
    child.cmd("TSUninstall " .. table.concat(languages, " "))
    child.restart()
    child:fails(languages)
end

return T

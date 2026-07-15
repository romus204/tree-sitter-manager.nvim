local languages = _G.languages or { "tsv", "tsx" }

local T = new_set({
    hooks = {
        pre_case = function()
            child.setup()
            child.lua([[
            fs_symlink = vim.uv.fs_symlink
            vim.uv.fs_symlink = function(src, dst)
                src = #src <= 23 and src or "..." .. src:sub(-20)
                dst = #dst <= 23 and dst or "..." .. dst:sub(-20)
                return false, "EPERM: operation not permitted: " .. src .. " -> " .. dst
            end
            ]])
        end,
        post_once = function()
            child.cleanup()
        end,
    },
})

T.pass = new_set({
    hooks = {
        pre_once = function()
            child.install(languages)
        end,
    },
    parametrize = parametrize_with_queries(languages),
}, { query = child.works })

T.fail = function()
    child.lua([[
    local notify = vim.notify
    vim.notify = function(msg, level)
        if level == vim.log.levels.WARN or level == vim.log.levels.ERROR then
            local copy_dir = util.copy_dir
            util.copy_dir = function()
                util.copy_dir = copy_dir
                return { ok = false, error = msg }
            end
        end
        notify(msg, level)
    end]])
    er(function()
        child.install(languages)
    end, "EPERM")
end

return T

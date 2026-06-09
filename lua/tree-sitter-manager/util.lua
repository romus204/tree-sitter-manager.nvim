local src = debug.getinfo(1, "S").source
local abs = src:sub(1, 1) == "@" and vim.fn.fnamemodify(src:sub(2), ":p") or ""

local config = require("tree-sitter-manager.config")

local M = {}

M.PLUGIN_ROOT = abs ~= "" and vim.fn.fnamemodify(abs, ":h:h:h") or vim.fn.stdpath("config")

function M.ext()
    local sys = vim.uv.os_uname().sysname
    return sys:match("Windows") and ".dll" or sys:match("Darwin") and ".dylib" or ".so"
end

function M.ppath(lang)
    return vim.fs.joinpath(config.cfg.parser_dir, lang .. M.ext())
end

function M.qpath(lang)
    return vim.fs.joinpath(config.cfg.query_dir, lang)
end

function M.get_requires(lang)
    local entry = config.effective_repos[lang]
    return (type(entry) == "table" and entry.requires) or {}
end

function M.get_repo_info(lang)
    local entry = config.effective_repos[lang]
    if not entry then
        return nil
    end
    if type(entry) == "string" then
        return { url = entry, location = lang }
    end
    if entry.install_info then
        return {
            url = entry.install_info.url,
            location = entry.install_info.location,
            revision = entry.install_info.revision,
            branch = entry.install_info.branch,
            generate = entry.install_info.generate,
            queries = entry.install_info.queries or "queries",
            use_repo_queries = entry.install_info.use_repo_queries,
        }
    end
    return nil
end

function M.is_only_query(lang)
    local info = M.get_repo_info(lang)
    return not info or not info.url
end

function M.is_installed(lang)
    if vim.list_contains(config.cfg.assume_installed, lang) then
        return true
    elseif M.is_only_query(lang) then
        return nil ~= vim.uv.fs_stat(M.qpath(lang))
    else
        return nil ~= vim.uv.fs_stat(M.ppath(lang))
    end
end

function M.run(args, cwd)
    local opts = { text = true, cwd = cwd }
    local res = vim.system(args, opts):wait()
    if res.code ~= 0 then
        local args = table.concat(args, " ")
        local stderr = res.stderr or ""
        vim.notify("Failed " .. args .. "\n" .. stderr, vim.log.levels.ERROR)
    end
    return res.code == 0, res.stdout or ""
end

function M.run_async(args, ...)
    -- Both signatures work:
    -- run_async(args, cwd, callback)
    -- run_async(args, callback, cwd)
    local arg2, arg3 = ...
    local opts = { text = true }
    local callback = function() end
    if type(arg2) == "string" then
        opts.cwd = arg2
    elseif type(arg2) == "function" then
        callback = arg2
    end
    if type(arg3) == "string" then
        opts.cwd = arg3
    elseif type(arg3) == "function" then
        callback = arg3
    end
    vim.system(args, opts, function(res)
        vim.schedule(function()
            if res.code ~= 0 then
                local args = table.concat(args, " ")
                local stderr = res.stderr or ""
                vim.notify("Failed " .. args .. "\n" .. stderr, vim.log.levels.ERROR)
            end
            callback(res.code == 0)
        end)
    end)
end

function M.copy_dir(src, dst)
    vim.fn.mkdir(dst, "p")
    local handle = vim.uv.fs_scandir(src)
    if not handle then
        return
    end
    while true do
        local name, ftype = vim.uv.fs_scandir_next(handle)
        if not name then
            break
        end
        local s = vim.fs.joinpath(src, name)
        local d = vim.fs.joinpath(dst, name)
        if ftype == "directory" then
            M.copy_dir(s, d)
        else
            vim.uv.fs_copyfile(s, d)
        end
    end
end

return M

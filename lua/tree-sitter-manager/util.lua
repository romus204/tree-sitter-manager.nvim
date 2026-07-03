local src = debug.getinfo(1, "S").source
local abs = src:sub(1, 1) == "@" and vim.fn.fnamemodify(src:sub(2), ":p") or ""

local config = require("tree-sitter-manager.config")

local M = {}

M.PLUGIN_ROOT = abs ~= "" and vim.fn.fnamemodify(abs, ":h:h:h") or vim.fn.stdpath("config")

---@vararg table lists to be concatenated (out-of-place)
---@return table concatenated list
function M.concat(...)
    return vim.iter({ ... }):flatten():totable()
end

---Compose functions
---@vararg fun
---@return fun
function M.compose(f, ...)
    local g = ... and M.compose(...)
    return not g and f or function(...)
        return f(g(...))
    end
end

---Logical not of the function output
---@param f fun
---@return fun
function M.no(f)
    return function(...)
        return not f(...)
    end
end

---@return fun getter function
function M.get(tbl)
    return function(key)
        return tbl[key]
    end
end

---@return fun checks inclusion
function M.isin(list)
    return function(val)
        return vim.list_contains(list, val)
    end
end

M.notin = M.compose(M.no, M.isin)

---@return string parser extension
function M.ext()
    local sys = vim.uv.os_uname().sysname
    return sys:match("Windows") and ".dll" or sys:match("Darwin") and ".dylib" or ".so"
end

---@return string parser path
function M.ppath(lang)
    return vim.fs.joinpath(config.cfg.parser_dir, lang .. M.ext())
end

---@return string query path
function M.qpath(lang)
    return vim.fs.joinpath(config.cfg.query_dir, lang)
end

---Flat dependency tree.
---@return string[]
function M.get_requires(lang)
    local entry = config.effective_repos[lang]
    local deps = entry and entry.requires or {}

    for _, lang in ipairs(deps) do
        entry = config.effective_repos[lang]
        local _deps = entry and entry.requires or {}
        vim.list.unique(vim.list_extend(deps, _deps))
    end

    return deps
end

---@return table
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
            queries = entry.install_info.queries,
        }
    end
    return nil
end

---@return bool
function M.is_only_query(lang)
    local info = M.get_repo_info(lang)
    return not info or not info.url
end

---@return bool
function M.is_installed(lang)
    if vim.list_contains(config.cfg.assume_installed, lang) then
        return true
    elseif M.is_only_query(lang) then
        return nil ~= vim.uv.fs_stat(M.qpath(lang))
    else
        return nil ~= vim.uv.fs_stat(M.ppath(lang))
    end
end

---@class Status
---@field ok? boolean
---@field error? string
---@field output? string

---@param args string[]
---@param cwd string
---@return Status
function M.run(args, cwd)
    local out = vim.system(args, { text = true, cwd = cwd }):wait()
    local err = table.concat(args, " ") .. "\n" .. (out.stderr or "")
    return { ok = out.code == 0, error = err, output = out.stdout }
end

---@param args string[]
---@param cwd string
---@param status Status
---@param callback fun(out:Status)
function M.run_async(args, cwd, status, callback)
    callback = callback or function() end

    if not status.ok then
        callback(status)
        return
    end

    vim.system(args, { text = true, cwd = cwd }, function(out)
        vim.schedule(function()
            local err = table.concat(args, " ") .. "\n" .. (out.stderr or "")
            callback({ ok = out.code == 0, error = err, output = out.stdout })
        end)
    end)
end

function M.copy_dir(src, dst)
    local ok, err = pcall(vim.fn.mkdir, dst, "p")

    if ok then
        for name, ftype in vim.fs.dir(src) do
            local s = vim.fs.joinpath(src, name)
            local d = vim.fs.joinpath(dst, name)
            if ftype == "directory" then
                res = M.copy_dir(s, d)
                ok, err = res.ok, res.error
            else
                ok, err, errno = vim.uv.fs_copyfile(s, d)
            end
            if not ok then
                break
            end
        end
    end

    if ok then
        return { ok = true }
    else
        return { ok = false, error = "copy_dir(" .. src .. ", " .. dst .. ")\n" .. err }
    end
end

return M

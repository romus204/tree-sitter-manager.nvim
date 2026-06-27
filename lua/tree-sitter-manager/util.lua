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
            queries = entry.install_info.queries,
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

---@vararg table lists to be concatenated (out-of-place)
---@return table concatenated list
function M.concat(...)
    return vim.iter({ ... }):flatten():totable()
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

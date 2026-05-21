local config = require("tree-sitter-manager.config")
local util = require("tree-sitter-manager.util")

local M = {}

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

function M.get_requires(lang)
    local entry = config.effective_repos[lang]
    return (type(entry) == "table" and entry.requires) or {}
end

function M.is_only_query(lang)
    local info = M.get_repo_info(lang)
    return not info or not info.url
end

local function copy_queries(lang, query_dir, build_path)
    local bundled = vim.fs.joinpath(util.PLUGIN_ROOT, "runtime/queries", lang)
    local source = bundled
    if query_dir then
        source = vim.fs.joinpath(build_path, query_dir)
        if not vim.uv.fs_stat(source) then
            source = bundled
            vim.notify(
                "⚠ No " .. query_dir .. "/ found for " .. lang .. ", falling back to bundled queries",
                vim.log.levels.WARN
            )
        end
    end
    util.copy_dir(source, util.qpath(lang))
end

function M._install_single(lang, callback)
    callback = callback or function() end -- backward compatibility API
    if M.is_only_query(lang) then
        copy_queries(lang)
        vim.notify("✓ Installed  " .. lang)
        callback(true)
        return
    end

    local info = M.get_repo_info(lang)
    local revision = info.revision and "--revision=" .. info.revision
    local branch = info.branch and "--branch=" .. info.branch
    local tmpdir = vim.fn.tempname()
    local build_path = vim.fs.joinpath(tmpdir, info.location)

    vim.notify("⬇ Cloning " .. lang)
    util.run_async({ "git", "clone", "--depth=1", revision or branch, info.url, tmpdir }, function(ok)
        if ok then
            if info.generate then
                ok = util.run({ "tree-sitter", "generate" }, build_path)
            end
            if ok then
                vim.notify("🔨 Building " .. lang)
                ok = util.run({ "tree-sitter", "build", "-o", util.ppath(lang) }, build_path)
            end
            if ok then
                copy_queries(lang, info.use_repo_queries and info.queries, build_path)
                vim.notify("✓ Installed  " .. lang)
            end
        end
        vim.fn.delete(tmpdir, "rf")
        callback(ok)
    end)
end

local function install_with_deps(lang, callback, installing)
    callback = callback or function() end
    installing = installing or {}
    if installing[lang] then
        vim.notify("⚠ Circular dependency: " .. lang, vim.log.levels.WARN)
        callback(false)
        return
    end
    installing[lang] = true

    local deps = M.get_requires(lang)
    local function install_deps(i)
        if i > #deps then
            M._install_single(lang, callback)
            return
        end
        local dep = deps[i]
        if not vim.uv.fs_stat(util.ppath(dep)) then
            vim.notify("📦 Installing dependency: " .. dep, vim.log.levels.INFO)
            install_with_deps(dep, function(ok)
                if not ok then
                    callback(false)
                    return
                end
                install_deps(i + 1)
            end, vim.deepcopy(installing))
        else
            install_deps(i + 1)
        end
    end
    install_deps(1)
end

function M.install(lang, callback)
    install_with_deps(lang, callback)
end

function M.remove(lang)
    if vim.uv.fs_stat(util.ppath(lang)) then
        vim.uv.fs_unlink(util.ppath(lang))
    end
    local qd = vim.fs.joinpath(config.cfg.query_dir, lang)
    if vim.uv.fs_stat(qd) then
        vim.fn.delete(qd, "rf")
    end
    vim.notify("✕ " .. lang)
end

function M.install_new(lang, verbose)
    if not config.effective_repos[lang] then
        if verbose then
            vim.notify("⚠ Parser not found in repos: " .. lang, vim.log.levels.WARN)
        end
        return
    end

    local installed = false
    if M.is_only_query(lang) then
        installed = vim.uv.fs_stat(util.qpath(lang)) ~= nil
    else
        installed = vim.uv.fs_stat(util.ppath(lang)) ~= nil
    end
    if not installed then
        M.install(lang)
    end
end

return M

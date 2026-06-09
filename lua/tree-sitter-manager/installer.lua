local config = require("tree-sitter-manager.config")
local util = require("tree-sitter-manager.util")

local M = { status = {} }

local function copy_queries(lang, source)
    local bundled = vim.fs.joinpath(util.PLUGIN_ROOT, "runtime/queries", lang)
    source = source or bundled
    if source then
        if not vim.uv.fs_stat(source) then
            vim.notify(
                "⚠ " .. source .. " not found for " .. lang .. ", falling back to bundled queries",
                vim.log.levels.WARN
            )
            source = bundled
        end
    end
    util.copy_dir(source, util.qpath(lang))
end

local function treesitter_build(lang, query_dir, build_path, generate)
    vim.notify("🔨 Building " .. lang)
    local ok, err = true
    if generate then
        ok, err = util.run({ "tree-sitter", "generate" }, build_path)
    end
    if ok then
        ok, err = util.run({ "tree-sitter", "build", "-o", util.ppath(lang) }, build_path)
    end
    if ok then
        copy_queries(lang, query_dir and vim.fs.joinpath(build_path, query_dir))
    end
    return ok, err
end

function M._install_single(lang, callback)
    local _callback = callback or function() end
    callback = function(ok, err)
        if ok then
            vim.notify("✓ Installed  " .. lang)
            vim.treesitter.query.get:clear()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                vim.bo[buf].filetype = vim.bo[buf].filetype
            end
        end
        M.status[lang] = { ok = ok, error = err }
        _callback(ok)
    end

    if util.is_only_query(lang) then
        copy_queries(lang)
        callback(true)
        return
    end

    local ok, version = util.run({ "git", "version" })
    if not ok then
        vim.notify("⚠ Git not installed", vim.log.levels.WARN)
        callback(false, "Git not installed")
        return
    end
    version = { version:match("(%d+)%.(%d+)%.(%d+)") }
    local major = tonumber(version[1])
    local minor = tonumber(version[2])
    local patch = tonumber(version[3])

    local info = util.get_repo_info(lang)
    local tmpdir = vim.fn.tempname()
    local build_path = vim.fs.joinpath(tmpdir, info.location)

    if info.revision and (major < 2 or major == 2 and minor < 49) then
        -- Git pre 2.49.0 doesn't have --revision flag
        local ok, err = util.run({ "git", "init", tmpdir })
        if ok then
            ok, err = util.run({ "git", "remote", "add", "origin", info.url }, tmpdir)
        end
        if not ok then
            vim.fn.delete(tmpdir, "rf")
            callback(false, err)
        end
        vim.notify("⬇ Fetching " .. lang)
        util.run_async({ "git", "fetch", "--depth=1", "origin", info.revision }, tmpdir, function(ok, err)
            if ok then
                ok, err = util.run({ "git", "checkout", "FETCH_HEAD" }, tmpdir)
            end
            if ok then
                ok = treesitter_build(lang, info.use_repo_queries and info.queries, build_path, info.generate)
            end
            vim.fn.delete(tmpdir, "rf")
            callback(ok, err)
        end)
    else
        local revision = info.revision and "--revision=" .. info.revision
        local branch = info.branch and "--branch=" .. info.branch
        vim.notify("⬇ Cloning " .. lang)
        util.run_async({ "git", "clone", "--depth=1", revision or branch, info.url, tmpdir }, function(ok)
            if ok then
                ok = treesitter_build(lang, info.use_repo_queries and info.queries, build_path, info.generate)
            end
            vim.fn.delete(tmpdir, "rf")
            callback(ok)
        end)
    end
end

local function install_with_deps(lang, callback, installing)
    callback = callback or function() end
    installing = installing or {}
    if installing[lang] then
        M.status[lang] = { ok = false, error = "Circular dependency" }
        vim.notify("⚠ Circular dependency: " .. lang, vim.log.levels.WARN)
        callback(false)
        return
    end
    installing[lang] = true
    M.status[lang] = {} -- empty table: the parser is being installed

    local deps = util.get_requires(lang)
    local function install_deps(i)
        if i > #deps then
            M._install_single(lang, callback)
            return
        end
        local dep = deps[i]
        if not util.is_installed(dep) then
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
    vim.fs.rm(util.ppath(lang), { recursive = true, force = true })
    vim.fs.rm(util.qpath(lang), { recursive = true, force = true })
    vim.notify("✕ " .. lang)
end

function M.install_new(lang, verbose)
    if not config.effective_repos[lang] then
        M.status[lang] = { ok = false, error = "Parser not found in repos" }
        if verbose then
            vim.notify("⚠ Parser not found in repos: " .. lang, vim.log.levels.WARN)
        end
    elseif not util.is_installed(lang) then
        M.install(lang)
    else
        M.status[lang] = { ok = true }
    end
end

return M

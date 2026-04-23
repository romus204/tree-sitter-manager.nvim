local config = require("tree-sitter-manager.config")
local util = require("tree-sitter-manager.util")

local M = {}

function M.get_repo_info(lang)
    local entry = config.effective_repos[lang]
    if not entry then return nil end
    if type(entry) == "string" then return { url = entry, location = lang } end
    if entry.install_info then
        return {
            url = entry.install_info.url,
            location = entry.install_info.location,
            revision = entry.install_info.revision,
            branch = entry.install_info.branch,
            generate = entry.install_info.generate,
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

local function copy_queries(lang, location)
    local s = util.PLUGIN_ROOT .. "/runtime/queries/" .. location
    local d = config.cfg.query_dir .. "/" .. lang
    if vim.uv.fs_stat(s) then
        util.copy_dir(s, d)
    end
end

local function copy_queries_from_repo(lang, build_dir)
    local qs = build_dir .. "/queries"
    if vim.uv.fs_stat(qs) then
        util.copy_dir(qs, config.cfg.query_dir .. "/" .. lang)
        return true
    end
    return false
end

function M._install_single(lang, callback)
    callback = callback or function() end
    local info = M.get_repo_info(lang)
    if not info or not info.url then
        copy_queries(lang, lang)
        vim.notify("✓ " .. lang .. " installed")
        callback(true)
        return
    end

    local tmp = vim.fn.tempname()
    local location = info.location or lang

    vim.notify("⬇ Cloning " .. lang)
    util.run_cmd({ "git", "clone", info.url, tmp }, nil, function(clone)
        if not clone.ok then
            vim.notify("Clone failed:\n" .. clone.output:sub(1, 300), 3)
            callback(false)
            return
        end

        local function after_checkout()
            local build_dir = tmp
            if info.location then
                build_dir = tmp .. "/" .. location
            end

            local function do_build()
                vim.notify("🔨 Building " .. lang)
                util.run_cmd({ "tree-sitter", "build", "-o", util.ppath(lang) }, build_dir, function(build)
                    if not build.ok then
                        local err = build.output
                        if #err > 500 then err = err:sub(-500) end
                        vim.notify("Build failed for " .. lang .. ":\n" .. err, 3)
                        vim.fn.delete(tmp, "rf")
                        callback(false)
                        return
                    end

                    local used_repo_queries = false
                    if info.use_repo_queries then
                        used_repo_queries = copy_queries_from_repo(lang, build_dir)
                        if not used_repo_queries then
                            vim.notify("⚠ No queries/ found in repo for " .. lang .. ", falling back to bundled queries", 2)
                        end
                    end

                    vim.fn.delete(tmp, "rf")

                    if not used_repo_queries then
                        copy_queries(lang, location)
                    end

                    vim.notify("✓ " .. lang .. " installed")
                    callback(true)
                end)
            end

            if info.generate then
                util.run_cmd({ "tree-sitter", "generate" }, build_dir, function(gen)
                    if not gen.ok then
                        vim.notify("Generate failed for " .. lang .. ":\n" .. gen.output:sub(1, 300), 3)
                        vim.fn.delete(tmp, "rf")
                        callback(false)
                        return
                    end
                    do_build()
                end)
            else
                do_build()
            end
        end

        local ref = info.revision or info.branch
        if ref then
            vim.notify("🔖 Checkout " .. ref)
            util.run_cmd({ "git", "checkout", ref }, tmp, function(checkout)
                if not checkout.ok then
                    vim.notify("⚠ Checkout failed:\n" .. checkout.output:sub(1, 200), 2)
                end
                after_checkout()
            end)
        else
            after_checkout()
        end
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
                if not ok then callback(false) return end
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
    if vim.uv.fs_stat(util.ppath(lang)) then vim.uv.fs_unlink(util.ppath(lang)) end
    local qd = config.cfg.query_dir .. "/" .. lang
    if vim.uv.fs_stat(qd) then vim.fn.delete(qd, "rf") end
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
    if not installed then M.install(lang) end
end

return M

local M = {}
local repos = require("tree-sitter-manager.repos")
local languages = vim.tbl_keys(repos)
table.sort(languages)

local src = debug.getinfo(1, "S").source
local abs = src:sub(1, 1) == "@" and vim.fn.fnamemodify(src:sub(2), ":p") or ""
local PLUGIN_ROOT = abs ~= "" and vim.fn.fnamemodify(abs, ":h:h:h") or vim.fn.stdpath("config")

local footer = " [i] Install  [x] Remove  [u] Update  [r] Refresh  [q] Close "

local cfg = {
    parser_dir = vim.fn.stdpath("data") .. "/site/parser",
    query_dir = vim.fn.stdpath("data") .. "/site/queries",
}

local function ext()
    local sys = vim.uv.os_uname().sysname
    return sys:match("Windows") and ".dll" or sys:match("Darwin") and ".dylib" or ".so"
end

local function ppath(l) return cfg.parser_dir .. "/" .. l .. ext() end
local function qpath(l) return cfg.query_dir .. "/" .. l end

local function run_cmd(cmd)
    local res = vim.system({ "sh", "-c", cmd }, { text = true }):wait()
    local out = (res.stderr ~= "" and res.stderr) or res.stdout or ""
    return { ok = res.code == 0, output = out }
end

local function get_repo_info(lang)
    local entry = repos[lang]
    if not entry then return nil end
    if type(entry) == "string" then return { url = entry, location = lang } end
    if entry.install_info then
        return {
            url = entry.install_info.url,
            location = entry.install_info.location or lang,
            revision = entry.install_info.revision,
            branch = entry.install_info.branch,
            generate = entry.install_info.generate,
        }
    end
    return nil
end

local function get_requires(lang)
    local entry = repos[lang]
    return (type(entry) == "table" and entry.requires) or {}
end

local function install_with_deps(lang, installing)
    installing = installing or {}
    if installing[lang] then
        vim.notify("⚠ Circular dependency: " .. lang, vim.log.levels.WARN)
        return false
    end
    installing[lang] = true

    for _, dep in ipairs(get_requires(lang)) do
        if not vim.uv.fs_stat(ppath(dep)) then
            vim.notify("📦 Installing dependency: " .. dep, vim.log.levels.INFO)
            if not install_with_deps(dep, vim.deepcopy(installing)) then return false end
        end
    end
    return M._install_single(lang)
end

local function copy_queries(lang, location)
    local s = PLUGIN_ROOT .. "/runtime/queries/" .. location
    local d = cfg.query_dir .. "/" .. lang
    if vim.uv.fs_stat(s) then
        vim.fn.mkdir(d, "p")
        local cp = run_cmd(string.format('cp -a "%s/." "%s/" 2>&1', s, d))
        if not cp.ok then vim.notify("⚠ cp failed:\n" .. cp.output:sub(1, 200), 2) end
    end
end

function M._install_single(lang)
    local info = get_repo_info(lang)
    if not info or not info.url then
        copy_queries(lang, lang) -- if only queries require
        vim.notify("✓ " .. lang .. " installed")
        return true
    end

    local tmp = vim.fn.tempname()
    local location = info.location or lang

    vim.notify("⬇ Cloning " .. lang)
    local clone = run_cmd(string.format('git clone "%s" "%s"', info.url, tmp))
    if not clone.ok then
        return vim.notify("Clone failed:\n" .. clone.output:sub(1, 300), 3), false
    end

    local ref = info.revision or info.branch
    if ref then
        vim.notify("🔖 Checkout " .. ref)
        local checkout = run_cmd(string.format('cd "%s" && git checkout "%s"', tmp, ref))
        if not checkout.ok then
            vim.notify("⚠ Checkout failed:\n" .. checkout.output:sub(1, 200), 2)
        end
    end

    local build_dir = tmp
    if repos[lang].install_info.location then
        vim.notify("LOCATION " .. info.location)
        build_dir = tmp .. "/" .. location
    end

    vim.notify("🔨 Building " .. lang)
    local build = {}
    if info.generate then
        build = run_cmd(string.format('cd "%s" && tree-sitter generate && tree-sitter build -o "%s"', build_dir,
            ppath(lang)))
    else
        build = run_cmd(string.format('cd "%s" && tree-sitter build -o "%s"', build_dir, ppath(lang)))
    end

    if not build.ok then
        local err = build.output
        if #err > 500 then err = err:sub(-500) end
        vim.notify("Build failed for " .. lang .. ":\n" .. err, 3)
        vim.fn.delete(tmp, "rf")
        return false
    end
    vim.fn.delete(tmp, "rf")

    copy_queries(lang, location)

    vim.notify("✓ " .. lang .. " installed")
    return true
end

local function install(lang) install_with_deps(lang) end

local function remove(lang)
    if vim.uv.fs_stat(ppath(lang)) then vim.uv.fs_unlink(ppath(lang)) end
    local qd = cfg.query_dir .. "/" .. lang
    if vim.uv.fs_stat(qd) then vim.fn.delete(qd, "rf") end
    vim.notify("✕ " .. lang)
end

local function is_only_query(lang)
    local info = get_repo_info(lang)
    return not info or not info.url
end

--TODO: DO REFACTOR
local function get_status_icon(lang)
    if is_only_query(lang) then
        if not vim.uv.fs_stat(qpath(lang)) then return "❌" end
    else
        if not vim.uv.fs_stat(ppath(lang)) then return "❌" end
    end

    for _, dep in ipairs(get_requires(lang)) do
        if is_only_query(dep) then
            if not vim.uv.fs_stat(qpath(dep)) then return "⚠️" end
        else
            if not vim.uv.fs_stat(ppath(dep)) then return "⚠️" end
        end
    end

    return "✅"
end

local function get_meta_suffix(lang)
    local info = get_repo_info(lang)
    local parts = {}
    if info and info.revision then table.insert(parts, string.sub(info.revision, 1, 7)) end
    local reqs = get_requires(lang)
    if #reqs > 0 then table.insert(parts, "requires:" .. table.concat(reqs, ",")) end
    return #parts > 0 and "  " .. table.concat(parts, " ") or ""
end

local function render(buf)
    local lines = { " 🌳  Tree-sitter Parser Manager ", " ────────────────────────────────" }
    for _, l in ipairs(languages) do
        table.insert(lines, string.format("   %-12s  %s%s", l, get_status_icon(l), get_meta_suffix(l)))
    end

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
end

function M.setup(opts)
    cfg = vim.tbl_deep_extend("force", cfg, opts or {})
    vim.fn.mkdir(cfg.parser_dir, "p")
    vim.fn.mkdir(cfg.query_dir, "p")

    local parser_parent = vim.fn.fnamemodify(cfg.parser_dir, ":h")
    local query_parent = vim.fn.fnamemodify(cfg.query_dir, ":h")
    local rtp = vim.opt.rtp:get()

    if not vim.tbl_contains(rtp, parser_parent) then vim.opt.rtp:prepend(parser_parent) end
    if not vim.tbl_contains(rtp, query_parent) then vim.opt.rtp:prepend(query_parent) end

    vim.api.nvim_create_user_command("TSManager", function() M.open() end,
        { nargs = 0, desc = "Open Tree-sitter Parsers Manager" })

    local installed_ft = {}
    for _, lang in ipairs(languages) do
        if vim.uv.fs_stat(ppath(lang)) then table.insert(installed_ft, lang) end
    end
    if #installed_ft > 0 then
        vim.api.nvim_create_autocmd('FileType', {
            pattern = installed_ft,
            callback = function() vim.treesitter.start() end,
            desc = 'Auto-enable treesitter for installed parsers'
        })
    end
end

function M.open()
    local max_w = #footer
    for _, l in ipairs(languages) do max_w = math.max(max_w, #("   " .. l .. "  ✅  abc1234  requires:x,y")) end
    local w = math.max(max_w + 4, 40)
    local h = math.min(#languages + 6, vim.o.lines - 15)

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = w,
        height = h,
        style = "minimal",
        border = "rounded",
        row = math.floor((vim.o.lines - h) / 2),
        col = math.floor((vim.o.columns - w) / 2),
        title = footer,
        title_pos = "center"
    })
    render(buf)

    local close_fn = function() vim.api.nvim_win_close(win, true) end
    vim.keymap.set("n", "q", close_fn, { buffer = buf, noremap = true, silent = true })
    vim.keymap.set("n", "<Esc>", close_fn, { buffer = buf, noremap = true, silent = true })
    vim.keymap.set("n", "r", function() render(buf) end, { buffer = buf, noremap = true, silent = true })
    vim.keymap.set("n", "i", function() M._act("install") end, { buffer = buf, noremap = true, silent = true })
    vim.keymap.set("n", "x", function() M._act("remove") end, { buffer = buf, noremap = true, silent = true })
    vim.keymap.set("n", "u", function() M._act("update") end, { buffer = buf, noremap = true, silent = true })
end

function M._act(action)
    local lang = vim.api.nvim_get_current_line():match("^%s*([%w_]+)")
    if not lang or not repos[lang] then return end
    if action == "install" then
        install(lang)
    elseif action == "remove" then
        remove(lang)
    elseif action == "update" then
        remove(lang)
        install(lang)
    end
    render(vim.api.nvim_get_current_buf())
end

return M

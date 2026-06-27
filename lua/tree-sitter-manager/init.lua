local state = require("tree-sitter-manager.config")
local util = require("tree-sitter-manager.util")
local installer = require("tree-sitter-manager.installer")
local ui = require("tree-sitter-manager.ui")

-- Preserve public API surface for backward compatibility
local M = require("tree-sitter-manager.backport")

local function filter_filetypes(filter)
    return vim.iter(state.languages):filter(filter):map(vim.treesitter.language.get_filetypes):flatten():totable()
end

local function iter_startswith(_argLead)
    return vim.iter(state.languages):filter(function(lang)
        return vim.startswith(lang, _argLead)
    end)
end

function M.setup(opts)
    state.cfg = vim.tbl_deep_extend("force", state.cfg, opts or {})

    state.cfg.parser_dir = vim.fs.normalize(state.cfg.parser_dir)
    state.cfg.query_dir = vim.fs.normalize(state.cfg.query_dir)

    -- Merge built-in repos with user-defined language overrides.
    -- User entries take precedence, allowing custom forks and new languages.
    state.effective_repos = vim.deepcopy(state.base_repos)
    for lang, info in pairs(state.cfg.languages) do
        info.install_info = M.backport_use_repo_queries(info.install_info)
        state.effective_repos[lang] = vim.tbl_extend("force", state.effective_repos[lang] or {}, info)
    end
    state.languages = vim.tbl_keys(state.effective_repos)
    table.sort(state.languages)

    installer.setup()
    ui.setup()

    vim.fn.mkdir(state.cfg.parser_dir, "p")
    vim.fn.mkdir(state.cfg.query_dir, "p")

    local parser_parent = vim.fn.fnamemodify(state.cfg.parser_dir, ":h")
    local query_parent = vim.fn.fnamemodify(state.cfg.query_dir, ":h")
    local rtp = vim.opt.rtp:get()

    if not vim.tbl_contains(rtp, parser_parent) then
        vim.opt.rtp:prepend(parser_parent)
    end
    if not vim.tbl_contains(rtp, query_parent) then
        vim.opt.rtp:prepend(query_parent)
    end

    local ensure_list = state.cfg.ensure_installed
    if ensure_list == "all" then
        ensure_list = state.languages
    else
        ensure_list = ensure_list or {}
    end
    installer.install(ensure_list)

    if state.cfg.auto_install then
        local filetypes = filter_filetypes(function(lang)
            return not vim.list_contains(state.cfg.noauto_install, vim.treesitter.language.get_lang(lang))
        end)
        if #filetypes > 0 then
            vim.api.nvim_create_autocmd("FileType", {
                pattern = filetypes,
                callback = function(a)
                    installer.install(vim.treesitter.language.get_lang(a.match))
                end,
                desc = "Auto-install treesitter parsers",
            })
        end
    end

    if state.cfg.highlight then
        local filetypes = filter_filetypes(function(lang)
            return not vim.list_contains(state.cfg.nohighlight, lang)
                and (state.cfg.highlight == true or vim.list_contains(state.cfg.highlight, lang))
        end)
        if #filetypes > 0 then
            vim.api.nvim_create_autocmd("FileType", {
                pattern = filetypes,
                callback = function(a)
                    pcall(vim.treesitter.start)
                end,
                desc = "Auto-enable treesitter highlighting",
            })
        end
    end

    vim.api.nvim_create_user_command("TSManager", function()
        ui.open()
    end, { nargs = 0, desc = "Open Tree-sitter Parsers Manager" })

    vim.api.nvim_create_user_command("TSInstall", function(args)
        installer.install(args.fargs, ui.render)
        ui.render(true)
    end, {
        nargs = "+",
        bar = true,
        complete = function(_argLead, _cmdLine, _cursorPos)
            return iter_startswith(_argLead)
                :filter(function(lang)
                    return not util.is_installed(lang)
                end)
                :totable()
        end,
        desc = "Install treesitter parsers",
    })

    vim.api.nvim_create_user_command("TSUninstall", function(args)
        installer.remove(args.fargs, ui.render)
        ui.render(true)
    end, {
        nargs = "+",
        bar = true,
        complete = function(_argLead, _cmdLine, _cursorPos)
            return iter_startswith(_argLead)
                :filter(function(lang)
                    return util.is_installed(lang)
                end)
                :totable()
        end,
        desc = "Remove treesitter parsers",
    })

    vim.api.nvim_create_user_command("TSUpdate", function(args)
        installer.update(args.fargs, ui.render)
        ui.render(true)
    end, {
        nargs = "+",
        bar = true,
        complete = function(_argLead, _cmdLine, _cursorPos)
            return iter_startswith(_argLead):totable()
        end,
        desc = "Update treesitter parsers",
    })
end

return M

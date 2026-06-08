local M = {}

local state = require("tree-sitter-manager.config")
local util = require("tree-sitter-manager.util")
local installer = require("tree-sitter-manager.installer")
local ui = require("tree-sitter-manager.ui")

-- Preserve public API surface for backward compatibility
M._install_single = installer._install_single
M.open = ui.open
M._act = ui._act

function M.setup(opts)
    state.cfg = vim.tbl_deep_extend("force", state.cfg, opts or {})

    state.cfg.parser_dir = vim.fs.normalize(state.cfg.parser_dir)
    state.cfg.query_dir = vim.fs.normalize(state.cfg.query_dir)

    -- Mergebuilt-in repos with user-defined language overrides.
    -- User entries take precedence, allowing custom forks and new languages.
    state.effective_repos = vim.tbl_deep_extend("force", vim.deepcopy(state.base_repos), state.cfg.languages)
    state.languages = vim.tbl_keys(state.effective_repos)
    table.sort(state.languages)

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
    for _, lang in ipairs(ensure_list) do
        installer.install_new(lang, true)
    end

    if state.cfg.auto_install then
        vim.api.nvim_create_autocmd("FileType", {
            callback = function(a)
                installer.install_new(a.match)
            end,
        })
    end

    if state.cfg.highlight then
        local filetypes = {}
        for _, lang in ipairs(state.languages) do
            if
                (state.cfg.highlight == true or vim.list_contains(state.cfg.highlight, lang))
                and not vim.list_contains(state.cfg.nohighlight, lang)
            then
                table.insert(filetypes, lang)
                vim.list_extend(filetypes, state.filetypes[lang] or {})
            end
        end
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
        M.open()
    end, { nargs = 0, desc = "Open Tree-sitter Parsers Manager" })

    vim.api.nvim_create_user_command("TSInstall", function(args)
        for _, lang in ipairs(args.fargs) do
            installer.install_new(lang, true)
        end
    end, {
        nargs = "+",
        bar = true,
        complete = function(_argLead, _cmdLine, _cursorPos)
            return state.languages
        end,
        desc = "Install treesitter parsers",
    })

    vim.api.nvim_create_user_command("TSUninstall", function(args)
        for _, lang in ipairs(args.fargs) do
            installer.remove(lang)
        end
    end, {
        nargs = "+",
        bar = true,
        complete = function(_argLead, _cmdLine, _cursorPos)
            return state.languages
        end,
        desc = "Remove treesitter parsers",
    })
end

return M

-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.cmd([[let &rtp.=','.getcwd()]])

-- Add 'mini.nvim' to 'runtimepath' to be able to use 'mini.test'
-- Assumed that 'mini.nvim' is stored in 'deps/mini.nvim'
vim.cmd("set rtp+=deps/mini.nvim")

require("vim._core.ui2").enable()

-- Set up 'tree-sitter-manager'
vim.cmd.runtime("plugin/filetypes.lua")
_G.tsm = require("tree-sitter-manager")
_G.backport = require("tree-sitter-manager.backport")
_G.config = require("tree-sitter-manager.config")
_G.health = require("tree-sitter-manager.health")
_G.installer = require("tree-sitter-manager.installer")
_G.repos = require("tree-sitter-manager.repos")
_G.ui = require("tree-sitter-manager.ui")
_G.util = require("tree-sitter-manager.util")

-- Parse the list of languages to test
if vim.env.LANGUAGES == "all" then
    _G.languages = vim.tbl_keys(require("tree-sitter-manager.repos"))
    table.sort(languages)
elseif vim.env.LANGUAGES then
    _G.languages = vim.split(vim.env.LANGUAGES, " ")
end

-- Set up 'mini.test'
require("mini.test").setup({
    collect = {
        filter_cases = function(case)
            local skip_smoke_tests = { "tests/test_git.lua", "tests/test_custom_repos.lua", "tests/test_vimpack.lua" }
            if _G.languages and vim.list_contains(skip_smoke_tests, case.desc[1]) then
                return false
            end
            return true
        end,
    },
})
_G.eq = MiniTest.expect.equality
_G.neq = MiniTest.expect.no_equality
_G.er = MiniTest.expect.error
_G.ner = MiniTest.expect.no_error

-- Set up 'tests.child'
_G.child = require("tests.child")

function _G.new_set(opts, tbl)
    local _opts = { hooks = {
        pre_once = child.setup,
        post_once = child.cleanup,
    } }
    opts = vim.tbl_deep_extend("force", _opts, opts or {})
    return MiniTest.new_set(opts, tbl)
end

function _G.parametrize(list)
    return vim.iter(list)
        :map(function(x)
            return { x }
        end)
        :totable()
end

function _G.parametrize_with_queries(languages)
    return vim.iter(languages)
        :map(function(lang)
            if util.is_only_query(lang) then
                return { { lang } }
            end
            local paths = vim.fn.glob("runtime/queries/" .. lang .. "/*.scm", true, true)
            local queries = vim.iter(paths)
                :map(function(path)
                    return { lang, vim.fn.fnamemodify(path, ":t:r") }
                end)
                :totable()
            table.insert(queries, 1, { lang, "parser" })
            return queries
        end)
        :flatten()
        :totable()
end

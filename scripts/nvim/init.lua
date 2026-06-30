-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.cmd([[let &rtp.=','.getcwd()]])

-- Add 'mini.nvim' to 'runtimepath' to be able to use 'mini.test'
-- Assumed that 'mini.nvim' is stored in 'deps/mini.nvim'
vim.cmd("set rtp+=deps/mini.nvim")

-- Set up 'mini.test'
require("mini.test").setup()
eq = MiniTest.expect.equality
neq = MiniTest.expect.no_equality
er = MiniTest.expect.error
ner = MiniTest.expect.no_error

-- Set up 'tree-sitter-manager'
vim.cmd.runtime("plugin/filetypes.lua")
tsm = require("tree-sitter-manager")
backport = require("tree-sitter-manager.backport")
config = require("tree-sitter-manager.config")
health = require("tree-sitter-manager.health")
installer = require("tree-sitter-manager.installer")
repos = require("tree-sitter-manager.repos")
ui = require("tree-sitter-manager.ui")
util = require("tree-sitter-manager.util")

-- Set up 'tests.child'
child = require("tests.child")

-- Parse the list of languages to test
if vim.env.LANGUAGES == "all" then
    _G.languages = vim.tbl_keys(require("tree-sitter-manager.repos"))
elseif vim.env.LANGUAGES then
    _G.languages = vim.split(vim.env.LANGUAGES, " ")
end

function new_set(opts, tbl)
    local _opts = {
        hooks = {
            pre_once = function()
                child.setup()
            end,
            post_once = function()
                child.cleanup()
            end,
        },
    }
    opts = vim.tbl_deep_extend("force", _opts, opts or {})
    return MiniTest.new_set(opts, tbl)
end

function parametrize(list)
    return vim.iter(list)
        :map(function(x)
            return { x }
        end)
        :totable()
end

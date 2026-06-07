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

-- Parse the list of languages to test
if vim.env.LANGUAGES then
    _G.languages = vim.split(vim.env.LANGUAGES, " ")
end

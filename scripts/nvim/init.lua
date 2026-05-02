vim.env.XDG_CONFIG_HOME = vim.uv.cwd() .. '/scripts'
vim.env.XDG_DATA_HOME = vim.uv.cwd() .. '/scripts'
vim.env.XDG_STATE_HOME = vim.uv.cwd() .. '/scripts'

-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.cmd([[let &rtp.=','.getcwd()]])

-- Add 'mini.nvim' to 'runtimepath' to be able to use 'mini.test'
-- Assumed that 'mini.nvim' is stored in 'deps/mini.nvim'
vim.cmd('set rtp+=deps/mini.nvim')

-- Set up 'mini.test'
require('mini.test').setup()

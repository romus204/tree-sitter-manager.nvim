# 🌳 tree-sitter-manager.nvim

A lightweight Tree-sitter parser manager for Neovim.

<img width="560" height="573" alt="изображение" src="https://github.com/user-attachments/assets/8ec50e9a-6c5a-4484-b231-5c13e069b1fc" />

## 📜 Why this plugin?

Although Neovim 0.12 integrated Tree-sitter into the core, it still lacks a built-in parser installer. With [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) now archived, this plugin provides a lightweight, actively maintained alternative that makes installing parsers and adding new languages effortless.

**tree-sitter-manager.nvim** provides a minimal alternative for:
- Installing and removing Tree-sitter parsers
- Automatically copying queries for syntax highlighting
- Managing parsers through a clean TUI interface

## ✨ Features

- 🎯 Install parsers directly from Tree-sitter repositories
- ⚡ Dynamic FileType autocmd registration for installed parsers
- 🔧 Works with any plugin manager (lazy, packer, vim-plug, native packages)
- 🔀 **Custom/fork repositories**: Override any language or add new ones via `setup()`
- 📂 **Repository queries**: Use `use_repo_queries` to use query files bundled in the grammar repo itself

## 📋 Requirements

### Mandatory
- **Neovim 0.12+** 
- **tree-sitter CLI** 
- **git** (for cloning parser repositories)
- **C compiler** (gcc/clang for building parsers)

### Optional
- Nerd Font (for proper display of icons ✅❌📦)

## 📦 Installation

### lazy.nvim
```lua
{
  "romus204/tree-sitter-manager.nvim",
  dependencies = {}, -- tree-sitter CLI must be installed system-wide
  config = function()
    require("tree-sitter-manager").setup({
      -- Optional: custom paths
      -- parser_dir = vim.fn.stdpath("data") .. "/site/parser",
      -- query_dir = vim.fn.stdpath("data") .. "/site/queries",
    })
  end
}
```

## 🔀 Custom / Fork Repositories

You can override built-in language definitions or add entirely new ones via the `languages`
option in `setup()`. This keeps `repos.lua` clean — no changes to the plugin repository are
needed.

### Override a built-in language with a fork

```lua
require("tree-sitter-manager").setup({
  languages = {
    cpp = {
      install_info = {
        url = "https://github.com/myfork/tree-sitter-cpp",
        revision = "abc1234",
        -- Use the query files that ship with the forked repo instead of
        -- the bundled queries. The parser's queries/ directory is copied
        -- automatically during installation.
        use_repo_queries = true,
      },
    },
  },
})
```

### Add a language not in the built-in list

```lua
require("tree-sitter-manager").setup({
  languages = {
    mylang = {
      install_info = {
        url = "https://github.com/someone/tree-sitter-mylang",
        use_repo_queries = true, -- copy queries/ from the cloned repo
      },
    },
  },
})
```

### `use_repo_queries` behaviour

| Value | Query source |
|-------|-------------|
| `false` (default) | Queries bundled in `runtime/queries/<lang>/` of this plugin |
| `true` | `queries/` directory inside the cloned grammar repository |

If `use_repo_queries = true` but the repo has no `queries/` directory, a warning is shown
and the plugin falls back to the bundled queries automatically.

## 🚀 Usage

`:TSManager` - Open the parser management interface

## ⌨️ Keybindings
	
`i` - Install parser under cursor  
`x` - Remove parser under cursor  
`u` - Update parser under cursor  
`r` - Refresh installation status  
`q / <Esc>` - Close window  

## 📚 Queries
Syntax highlighting queries (highlights.scm, injections.scm, etc.) were sourced from the archived [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
 repository and placed in `runtime/queries/`.

## 🔗 Parser Repository Links

Parser repository URLs in `repos.lua` are sourced from the archived [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) repository. 

> ⚠️ **Disclaimer**: These links are provided as-is. Due to the large number of parsers, each URL cannot be manually verified for current availability or compatibility. If you encounter a broken link, outdated revision, or build failure, please:
> - Open an [issue](https://github.com/romus204/tree-sitter-manager.nvim/issues) with details
> - Or submit a [pull request](https://github.com/romus204/tree-sitter-manager.nvim/pulls) with a fix

Your contributions help keep this plugin reliable for everyone. 🙏

## ⚠️ Known Limitations

- Unix-first development: Primarily tested on macOS/Linux. Windows support may require additional testing.
- Requires tree-sitter CLI: Ensure tree-sitter is available in your $PATH.
- No auto-updates: To update a parser, update it manually (u) or remove (x) and reinstall (i) it.

## 🤝 Contributing
Pull requests are welcome! Especially for:

- Adding new languages to repos.lua
- UI/UX improvements
- Bug fixes

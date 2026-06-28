# tree-sitter-manager.nvim
A lightweight Tree-sitter parser manager for Neovim.

<img width="560" height="573" alt="изображение" src="https://github.com/user-attachments/assets/8ec50e9a-6c5a-4484-b231-5c13e069b1fc" />

## Why this plugin?
Although Neovim 0.12 integrated Tree-sitter into the core, it still lacks a built-in parser installer. With [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) now archived, this plugin provides a lightweight, actively maintained alternative that makes installing parsers and adding new languages effortless.

**tree-sitter-manager.nvim** provides a minimal alternative for:
- Installing and removing Tree-sitter parsers
- Automatically copying queries for syntax highlighting
- Managing parsers through a clean TUI interface

## Features
- Install parsers directly from Tree-sitter repositories
- Dynamic FileType autocmd registration for installed parsers
- Works with any plugin manager (lazy, packer, vim-plug, native packages)
- **Custom/fork repositories**: Override any language or add new ones via `setup()`
- **Repository queries**: Set `queries` to the relative path of the queries directory in the repo

## Requirements
### Mandatory
- **Neovim 0.12+**
- **tree-sitter CLI**
- **git** (for cloning parser repositories)
- **C compiler** (gcc/clang for building parsers)

### Optional
- Nerd Font (for proper display of icons ✅❌📦)

## Installation
### lazy.nvim
```lua
{
  "romus204/tree-sitter-manager.nvim",
  dependencies = {}, -- tree-sitter CLI must be installed system-wide
  config = function()
    require("tree-sitter-manager").setup()
  end,
}
```

### vim.pack
```lua
vim.pack.add {
  { src = "https://github.com/romus204/tree-sitter-manager.nvim" }
}

require("tree-sitter-manager").setup()
```

## Default Options
```lua
require("tree-sitter-manager").setup({
  -- Default Options
  parser_dir = vim.fn.stdpath("data") .. "/site/parser",
  query_dir = vim.fn.stdpath("data") .. "/site/queries",
  assume_installed = {}, -- blacklist languages
  ensure_installed = {}, -- parsers to install at startup
  auto_install = false, -- auto-install when a new filetype is encountered
  noauto_install = {}, -- blacklist from auto_install
  highlight = true, -- enable treesitter highlighting (use list to whitelist)
  nohighlight = {}, -- blacklist from highlight
  languages = {}, -- override or add new parser sources
  nerdfont = true, -- use Nerd Font icons in the manager UI
  border = "rounded", -- border style for the TUI window
  min_width = 78, -- minimum size of the TUI
  min_height = 40,
})
```

## Custom / Fork Repositories
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
        queries = "queries",
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
        queries = "queries/subdir",
      },
    },
  },
})
```

### `queries` behaviour
If `queries` is unset or `nil` bundled `runtime/queries/<lang>/` will be
symlinked to the `query_dir` location. Set it to the relative path of the
queries directory in the repository, often `"queries"`, to use the shipped
queries.

## Automatic Installation
You can automatically install missing parsers upon editing a new file by
setting `auto_install = true`. To opt-out of some languages, while auto-install
is enabled, use the `noauto_install` option.
```lua
require("tree-sitter-manager").setup({
  auto_install = true,
  -- Use built-in Neovim treesitter parsers
  noauto_install = {
    "c", "lua", "markdown", "markdown_inline", "query", "vim", "vimdoc"
  },
})
```

## Treesitter Highlighting
Treesitter highlighting is enabled by default. If you prefer to use standard regex highlighting for specific languages, use the `nohighlight` option.
```lua
require("tree-sitter-manager").setup({
  -- Use regex highlighting for these languages
  nohighlight = { "yaml", "zsh" },
})
```
Alternatively, if you prefer an "opt-in" approach, use the `highlight` option.
```lua
require("tree-sitter-manager").setup({
  -- Only enable treesitter highlighting for these languages
  highlight = { "lua", "c" },

  -- Disable treesitter highlighting
  -- highlight = {},
})
```

## Usage
`:TSManager` - Open the parser management interface<br/>
`:TSInstall` - Install parsers provided as arguments<br/>
`:TSUninstall` - Uninstall parsers<br/>
`:TSUpdate` - Update parsers. Add `bang` to force update all.<br/>

## Keybindings
`i` - Install parser under cursor<br/>
`x` - Remove parser under cursor<br/>
`u` - Update parser under cursor<br/>
`r` - Refresh installation status<br/>
`q / <Esc>` - Close window<br/>

## Queries
Syntax highlighting queries (highlights.scm, injections.scm, etc.) were sourced from the archived [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) repository and placed in `runtime/queries/`.

## Parser Repository Links
Parser repository URLs in `repos.lua` are sourced from the archived [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) repository.

> [!WARNING]
> These links are provided as-is. Due to the large number of parsers, each URL cannot be manually verified for current availability or compatibility. If you encounter a broken link, outdated revision, or build failure, please:
> - Open an [issue](https://github.com/romus204/tree-sitter-manager.nvim/issues) with details
> - Or submit a [pull request](https://github.com/romus204/tree-sitter-manager.nvim/pulls) with a fix

Your contributions help keep this plugin reliable for everyone.

## Known Limitations
- Unix-first development: Primarily tested on macOS/Linux. Windows support may require additional testing.
- Requires tree-sitter CLI: Ensure tree-sitter is available in your $PATH.
- No auto-updates: To update a parser, update it manually (u) or remove (x) and reinstall (i) it.

## Contributing
Pull requests are welcome! Especially for:

- Adding new languages to repos.lua
- UI/UX improvements
- Bug fixes

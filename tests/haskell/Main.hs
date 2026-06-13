-- https://github.com/ejconlon/nvim-ts-hs-repro
-- crashes with "corrupted size vs. prev_size"
-- affected:
--   url: "https://github.com/tree-sitter-grammars/tree-sitter-haskell"
--   rev: "7fa19f195803a77855f036ee7f49e4b22856e338"
-- fix:
--   url: "https://github.com/tree-sitter-grammars/tree-sitter-haskell"
--   rev: "98aedbd2d6947a168ba3ba3755d70b0cb6b78395"
module Main
  ( Level,
  )
where

data Level
  = -- | A fatal diagnostic that should reject the current operation.
    Error
  | -- | A non-fatal diagnostic worth surfacing to users.
    Warn
  | Info

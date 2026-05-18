local nerr = MiniTest.expect.no_error
local neq = MiniTest.expect.no_equality

local languages = { "terraform", "ocaml", "helm" }
local child = require("tests.child")

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup()
            child:update_config({ ensure_installed = languages })
            child:parser_wait(languages)
        end,
        post_once = function()
            child:cleanup()
        end,
    },
})

for _, lang in ipairs(languages) do
    T["bundled-queries-" .. lang] = function()
        nerr(function()
            vim.treesitter.get_string_parser("", lang)
        end)
        neq(nil, vim.treesitter.query.get(lang, "highlights"))
    end
end

return T

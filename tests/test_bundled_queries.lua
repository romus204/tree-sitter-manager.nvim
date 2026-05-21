local languages = { "terraform", "ocaml", "helm" }
if vim.env.LANGUAGES then
    languages = vim.split(vim.env.LANGUAGES, " ")
end

local child = require("tests.child")
local nerr = MiniTest.expect.no_error
local neq = MiniTest.expect.no_equality

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup()
            child:update_config({ ensure_installed = languages })
        end,
        post_once = function()
            child:cleanup()
        end,
    },
})

for _, lang in ipairs(languages) do
    T["bundled-queries-" .. lang] = function()
        child:check_installed({ lang })
    end
end

return T

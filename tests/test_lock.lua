local T = new_set({
    hooks = {
        pre_once = function()
            lock.set_test()
        end,
    },
})

T.TSLocalPass = function()
    local cpp = lock.lock_get("cpp")
    eq(cpp, nil)
    lock.lock_set("cpp", "abcd7b9s")
    cpp = lock.lock_get("cpp")
    eq(cpp, "abcd7b9s")
end

return T

local T = new_set()

T.TSLocalPass = function()
    local cpp = lock.lock_get("cpp", true)
    eq(cpp, nil)
    lock.lock_set("cpp", "abcd7b9s", true)
    cpp = lock.lock_get("cpp", true)
    eq(cpp, "abcd7b9s")
end

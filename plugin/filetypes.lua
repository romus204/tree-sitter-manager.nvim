filetypes = require("tree-sitter-manager.filetypes")

for lang, ft in pairs(filetypes) do
    vim.treesitter.language.register(lang, ft)
end

-- Extensions that Neovim does not detect natively.

-- Lines of a buffer; none when Neovim matches a filename alone (bufnr -1).
local function buf_lines(bufnr, last)
    return bufnr >= 0 and vim.api.nvim_buf_get_lines(bufnr, 0, last, false) or {}
end

-- The pattern that stops a scan inside a string literal opened by the key:
-- its closing quote or a backslash escape.
local STRING_STOP = { ['"'] = '[\\"]', ["'"] = "[\\']", ["`"] = "[\\`]" }

-- Whether a tag opener ({%, {{, {#) appears outside strings and comments,
-- where a ucode script cannot have one.
local function has_code_position_tag(text)
    if not text:find("{[%%{#]") then
        return false
    end
    local i = 1
    while true do
        i = text:find("[/\"'`{]", i)
        if not i then
            return false
        end
        local c, d = text:sub(i, i), text:sub(i + 1, i + 1)
        if c == "/" and d == "/" then
            i = text:find("\n", i + 2, true) or #text + 1
        elseif c == "/" and d == "*" then
            local e = text:find("*/", i + 2, true)
            i = e and e + 2 or #text + 1
        elseif c == "{" then
            if d == "%" or d == "{" or d == "#" then
                return true
            end
            i = i + 1
        elseif c == "/" then
            i = i + 1
        else
            local j = i + 1
            while true do
                j = text:find(STRING_STOP[c], j)
                if not j then
                    return false
                elseif text:sub(j, j) == "\\" then
                    j = j + 2
                else
                    break
                end
            end
            i = j + 1
        end
    end
end

-- .uc and .ucode hold both ucode scripts and ucode_markup templates. As ucode
-- itself does, a #! line picks the mode first: utpl or -T is a template, -R a
-- script. Otherwise the content decides.
local function ucode_or_markup(_, bufnr)
    local lines = buf_lines(bufnr, -1)
    local first = lines[1] or ""
    if first:sub(1, 2) == "#!" then
        if first:find("utpl", 1, true) or first:find("-T", 1, true) then
            return "ucode_markup"
        elseif first:find("-R", 1, true) then
            return "ucode"
        end
    end
    return has_code_position_tag(table.concat(lines, "\n")) and "ucode_markup" or "ucode"
end

-- The program a #! line runs, looking past env and its flags.
local function shebang_program(line)
    if line:sub(1, 2) ~= "#!" then
        return nil
    end
    local words = vim.split(line:sub(3), "%s+", { trimempty = true })
    local prog = words[1] and words[1]:match("[^/]*$")
    if prog == "env" then
        for k = 2, #words do
            if words[k]:sub(1, 1) ~= "-" then
                return words[k]:match("[^/]*$")
            end
        end
    end
    return prog
end

vim.filetype.add({
    extension = {
        uc = ucode_or_markup,
        ucode = ucode_or_markup,
        ut = "ucode_markup",
        utpl = "ucode_markup",
    },
    pattern = {
        -- An extensionless file whose #! line runs ucode or utpl.
        [".*"] = {
            function(path, bufnr)
                local prog = shebang_program(buf_lines(bufnr, 1)[1] or "")
                if prog == "ucode" or prog == "utpl" then
                    return ucode_or_markup(path, bufnr)
                end
            end,
            { priority = -math.huge },
        },
    },
})

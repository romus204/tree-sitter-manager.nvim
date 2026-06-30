local config = require("tree-sitter-manager.config")
local util = require("tree-sitter-manager.util")
local installer = require("tree-sitter-manager.installer")
local backport = require("tree-sitter-manager.backport")
local ns = vim.api.nvim_create_namespace("tree-sitter-manager.spinner")

local title_asci = " Tree-sitter Parser Manager "
local title_nerd = " 🌳 Tree-sitter Parser Manager "
local title

local status_asci = { "OK", "!!", "..", "  " }
local status_nerd = { "✅", "⚠️", "❌", "  " }
local status_icon
local icon_col

local footer = " [i] Install  [x] Remove  [u] Update  [r] Refresh  [f] Filter  [q] Close "

local filter_type = {
    --ok    warn  miss  installing
    { true, true, true, true }, --    all
    { true, true, false, true }, --   installed
    { false, true, false, true }, --  warning
    { false, false, true, false }, -- missing
}
local filter_idx

local frames = { "⣾ ", "⣽ ", "⣻ ", "⢿ ", "⡿ ", "⣟ ", "⣯ ", "⣷ " }
local frame_idx

local buf, win, langs, formatter, spinner, content_width

local M = {}

function M.setup()
    title = config.cfg.nerdfont and title_nerd or title_asci
    status_icon = config.cfg.nerdfont and status_nerd or status_asci
    local langwidth = vim.iter(config.languages):map(string.len):fold(0, math.max)
    formatter = "   %-" .. langwidth .. "s  %s%s"
    icon_col = 3 + langwidth + 2
end

local function get_status(lang)
    if installer.installing[lang] then
        return 4 -- installing
    elseif not util.is_installed(lang) then
        return 3 -- missing
    elseif vim.list_contains(config.cfg.assume_installed, lang) then
        return 1 -- ok
    elseif vim.iter(util.get_requires(lang)):all(util.is_installed) then
        return 1 -- ok
    else
        return 2 -- warning
    end
end

local function get_status_icon_iter(langs)
    local function get_icon(status)
        return status_icon[status]
    end
    return vim.iter(langs):map(get_status):map(get_icon)
end

local function get_meta_suffix(lang)
    local info = util.get_repo_info(lang)
    local parts = {}
    if info and info.revision then
        local rev = #info.revision == 40 and string.sub(info.revision, 1, 7) or info.revision
        table.insert(parts, string.format("%-7s", rev))
    end
    local reqs = util.get_requires(lang)
    if #reqs > 0 then
        vim.list_extend(parts, { "requires:", unpack(reqs) })
    end
    return #parts > 0 and "  " .. table.concat(parts, " ") or ""
end

local function get_langs_filtered()
    local function filter(lang)
        return filter_type[filter_idx][get_status(lang)]
    end
    return vim.iter(config.languages):filter(filter):totable()
end

local function cycle_filter()
    local new_langs
    repeat -- skip empty results and duplicates
        filter_idx = (filter_idx % 4) + 1
        new_langs = get_langs_filtered()
    until filter_idx == 1 or #new_langs > 0 and not vim.deep_equal(langs, new_langs)
    langs = new_langs
    M.render()
end

local function render_spinner()
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for row, lang in ipairs(langs) do
        if installer.installing[lang] then
            vim.api.nvim_buf_set_extmark(buf, ns, row - 1, icon_col, {
                virt_text = { { frames[frame_idx], "Special" } },
                virt_text_pos = "overlay",
            })
        end
    end
end

local act = setmetatable({}, {
    __index = function(act, action)
        local function _action()
            local lang = vim.api.nvim_get_current_line():match("^%s*([%w_]+)")
            if lang then
                installer[action](lang, M.render)
                M.render(true)
            end
        end
        rawset(act, action, _action)
        return _action
    end,
})

function M.render(out)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        return 0
    elseif out then -- update langs on callback
        table.sort(vim.list.unique(vim.list_extend(langs, get_langs_filtered())))
    end

    local status = get_status_icon_iter(langs)
    local meta = vim.iter(langs):map(get_meta_suffix)
    local lines = vim.iter(langs)
        :map(function(lang)
            return formatter:format(lang, status:next(), meta:next())
        end)
        :totable()

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    render_spinner()

    content_width = vim.iter(lines):map(string.len):fold(0, math.max)
end

local function close()
    spinner:stop()
    vim.api.nvim_win_close(win, true)
end

local function get_dims()
    local w = math.max(config.cfg.min_width, #footer + 4, content_width + 3)
    local h = math.max(config.cfg.min_height, vim.o.lines - 15)
    local r = math.floor((vim.o.lines - h) / 2 - 1)
    local c = math.floor((vim.o.columns - w) / 2 - 1)

    return w, h, r, c
end

local function resize()
    if not win or not vim.api.nvim_win_is_valid(win) then
        return
    end

    local w, h, r, c = get_dims()
    vim.api.nvim_win_set_config(win, {
        relative = "editor",
        width = w,
        height = h,
        row = r,
        col = c,
    })
end

function M.open()
    langs = config.languages
    filter_idx = 1
    frame_idx = 1

    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        buf = vim.api.nvim_create_buf(false, true)
        local opts = { buf = buf, noremap = true, silent = true }
        vim.keymap.set("n", "q", close, opts)
        vim.keymap.set("n", "<Esc>", close, opts)
        vim.keymap.set("n", "r", M.open, opts)
        vim.keymap.set("n", "i", act.install, opts)
        vim.keymap.set("n", "x", act.remove, opts)
        vim.keymap.set("n", "u", act.update, opts)
        vim.keymap.set("n", "f", cycle_filter, opts)

        vim.api.nvim_create_autocmd("VimResized", {
            group = vim.api.nvim_create_augroup("tree-sitter-manager.ui", {}),
            callback = resize,
        })
    end

    M.render()

    if not win or not vim.api.nvim_win_is_valid(win) then
        local w, h, r, c = get_dims()
        win = vim.api.nvim_open_win(buf, true, {
            relative = "editor",
            width = w,
            height = h,
            style = "minimal",
            border = config.cfg.border,
            row = r,
            col = c,
            title = title,
            title_pos = "center",
            footer = footer,
            footer_pos = "center",
        })
    end

    if not spinner then
        spinner = vim.uv.new_timer()
    end

    spinner:start(
        0,
        80,
        vim.schedule_wrap(function()
            frame_idx = (frame_idx % #frames) + 1
            render_spinner()
        end)
    )
end

-- Backward compatibility
backport.open = M.open
function backport._act(action)
    act[action]()
end

return M

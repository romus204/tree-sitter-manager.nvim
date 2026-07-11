---@type tree_sitter_manager.Languages
local oldrepos = vim.deepcopy(repos)

---@type table<string, util.AsyncJob>
local jobs = vim.iter(repos):fold({}, function(jobs, lang, parser)
    local cmd
    if parser.tier == 1 then
        cmd = { "git", "-c", "-versionsort.suffix=-", "ls-remote", "--tags", "--refs", "--sort=v:refname" }
    elseif parser.tier == 2 then
        cmd = { "git", "ls-remote" }
    else
        return jobs
    end
    table.insert(cmd, parser.install_info.url)
    jobs[lang] = util.run(cmd)
    return jobs
end)

io.write("Fetch revisions:")
io.flush()

local updates = vim.iter(jobs):map(function(lang, job)
    io.write(" " .. lang)
    io.flush()

    local status = job:wait()
    if not status.ok then
        vim.notify(status.error, vim.log.levels.ERROR)
        return
    end

    local stdout = vim.split(status.output or "", "\n")
    local parser = repos[lang]
    local info = parser.install_info
    local sha ---@type string?
    if parser.tier == 1 then
        sha = stdout[#stdout - 1] and stdout[#stdout - 1]:match("v[%d%.]+$")
    elseif parser.tier == 2 then
        sha = vim.split(not info.branch and stdout[1] or vim.iter(stdout):find(function(line)
            return line:find(vim.pesc(info.branch))
        end), "\t")[1]
    end

    if sha and sha ~= "" and info.revision ~= sha then
        info.revision = sha
        return lang
    end
end)
updates = updates:totable() ---[=[@as string[]]=]
table.sort(updates)

io.write("\n\n")

if #updates == 0 then
    io.write("\nAll parsers up to date!\n")
    os.exit()
end

local function update_repos()
    local header = "---@type tree_sitter_manager.Languages\nreturn "
    local content = header .. vim.inspect(repos)
    local status = util.run({ "stylua", "-" }, { stdin = content }):wait()
    if not status.ok then
        vim.notify(status.error, vim.log.levels.ERROR)
    else
        content = status.output
    end
    util.write("lua/tree-sitter-manager/repos.lua", content)
end

update_repos()

local reporter = MiniTest.gen_reporter.stdout()
local finish = reporter.finish

function reporter.finish()
    io.write("\n\n")

    local reports = vim.defaulttable(function()
        return ""
    end)
    for _, case in ipairs(MiniTest.current.all_cases) do
        local lang = unpack(case.args)
        reports[lang] = reports[lang] .. table.concat(case.exec.fails, "\n")
    end

    local pass, fail = {}, {}
    for lang, report in pairs(reports) do
        if report == "" then
            table.insert(pass, lang)
        else
            fail[lang] = report
            repos[lang].install_info.revision = oldrepos[lang].install_info.revision
        end
    end

    local output = os.getenv("GITHUB_OUTPUT") or "/dev/stdout"

    if pass then
        table.sort(pass)
        util.write(output, ("PASS=%s\n"):format(table.concat(pass, " ")))
    end

    if fail then
        update_repos()
        util.write(output, ("FAIL=%s\n"):format(vim.json.encode(fail, { sort_keys = true })))
    end

    finish()
end

_G.languages = updates
MiniTest.run_file("tests/test_all_queries.lua", { execute = { reporter = reporter } })

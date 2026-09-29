--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")

local passed = 0
local failed = 0

local function reportFailure(name: string, message: unknown)
    failed += 1
    print("FAIL " .. name .. ": " .. tostring(message))
end

local function runSpec(fileName: string)
    local cases = require("./" .. string.sub(fileName, 1, -6))
    assert(type(cases) == "table", "spec must return a table of named test functions")
    local names: { string } = {}
    for name, callback in cases do
        assert(type(name) == "string" and name ~= "", "test name must be a nonempty string")
        assert(type(callback) == "function", "test must be a function: " .. name)
        table.insert(names, name)
    end
    assert(#names > 0, "spec contains no tests")
    table.sort(names)
    for _, name in names do
        local ok, message = pcall(cases[name])
        local label = fileName .. " / " .. name
        if ok then
            passed += 1
            print("PASS " .. label)
        else
            reportFailure(label, message)
        end
    end
end

local function run()
    -- Run from repository root; filesystem paths and require paths have different bases.
    assert(fs.isFile("tests/run.luau"), "run lune run tests/run from repository root")
    local files: { string } = {}
    for _, name in fs.readDir("tests") do
        if string.match(name, "%.spec%.luau$") and fs.isFile("tests/" .. name) then
            table.insert(files, name)
        end
    end
    assert(#files > 0, "no tests/*.spec.luau found")
    table.sort(files)
    for _, name in files do
        local ok, message = pcall(runSpec, name)
        if not ok then
            reportFailure(name .. " (load/contract)", message)
        end
    end
end

local ok, message = pcall(run)
if not ok then
    reportFailure("discovery", message)
end
print(string.format("Results: %d passed, %d failed", passed, failed))
process.exit(if failed > 0 then 1 else 0)

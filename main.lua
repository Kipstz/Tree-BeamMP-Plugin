Tree = Tree or {}
Tree.Version = "0.0.1"
Tree.Author = "Tree Framework Team"

local originalPrint = print

local colors = {
    ["^r"] = "\27[0m",     -- reset
    ["^p"] = "\n",         -- newline
    ["^n"] = "\27[4m",     -- underline
    ["^l"] = "\27[1m",     -- bold
    ["^m"] = "\27[9m",     -- strike-through
    ["^o"] = "\27[3m",     -- italic
    ["^0"] = "\27[30m",    -- black
    ["^1"] = "\27[34m",    -- blue
    ["^2"] = "\27[32m",    -- green
    ["^3"] = "\27[96m",    -- light blue
    ["^4"] = "\27[31m",    -- red
    ["^5"] = "\27[95m",    -- pink
    ["^6"] = "\27[33m",    -- orange
    ["^7"] = "\27[37m",    -- grey
    ["^8"] = "\27[90m",    -- dark grey
    ["^9"] = "\27[35m",    -- light purple
    ["^a"] = "\27[92m",    -- light green
    ["^b"] = "\27[94m",    -- light blue
    ["^c"] = "\27[91m",    -- dark orange
    ["^d"] = "\27[93m",    -- light pinks
    ["^e"] = "\27[93m",    -- yellow
    ["^f"] = "\27[97m"     -- white
}

print = function(...)
    local args = {...}
    for i, arg in ipairs(args) do
        if type(arg) == "string" then
            for code, ansi in pairs(colors) do
                arg = arg:gsub("%"..code, ansi)
            end
            arg = arg .. "\27[0m"
            args[i] = arg
        end
    end
    originalPrint(table.unpack(args))
end

print("^2[Tree Framework] v1.0.0 - BeamMP Plugin System^r")

local function getScriptDir()
    local info = debug.getinfo(1, "S")
    if info and info.source then
        local source = info.source
        if source:sub(1, 1) == "@" then
            source = source:sub(2)
        end
        
        local dir
        if source:find("\\") then
            dir = source:match("(.*)\\")
            if dir then dir = dir .. "\\" end
        else
            dir = source:match("(.*)/")  
            if dir then dir = dir .. "/" end
        end
        
        return dir or "./"
    end
    return "./"
end

local scriptDir = getScriptDir()

dofile(scriptDir .. "_tree/utils.lua")
dofile(scriptDir .. "_tree/manifest.lua")
dofile(scriptDir .. "_tree/loader.lua")
function Tree.Init(manifestPath)
    if not manifestPath then
        print("^1[Tree Framework] Error: No manifest path provided^7")
        return false
    end
    
    local scriptDir = Tree.Utils.getScriptDirectory()
    local fullManifestPath = Tree.Utils.resolvePath(scriptDir, manifestPath)
    
    if not Tree.Utils.fileExists(fullManifestPath) then
        print("^1[Tree Framework] Error: Manifest not found: " .. fullManifestPath .. "^7")
        return false
    end
    
    local manifest = Tree.Manifest.parse(fullManifestPath)
    if not manifest then
        print("^1[Tree Framework] Error: Failed to parse manifest^7")
        return false
    end
    
    local info = {}
    if manifest.description then table.insert(info, manifest.description) end
    if manifest.author then table.insert(info, "by " .. manifest.author) end
    if manifest.version then table.insert(info, "v" .. manifest.version) end
    
    if #info > 0 then
        print("^2[Tree Framework] Loading: " .. table.concat(info, " ") .. "^7")
    end
    
    local scriptBasePath = fullManifestPath:match("(.*[/\\])")
    local filesLoaded = Tree.Loader.loadFromManifest(manifest, scriptBasePath)
    
    if filesLoaded > 0 then
        print("^2[Tree Framework] Ready! " .. filesLoaded .. " files loaded^7")
        
        if Tree.OnScriptLoaded then
            Tree.OnScriptLoaded(manifest)
        end
        
        return true
    else
        print("^3[Tree Framework] Warning: No files were loaded^7")
        return false
    end
end

function Tree.GetInfo()
    return {
        version = Tree.Version,
        author = Tree.Author,
        loadedFiles = Tree.Loader.getLoadedFiles()
    }
end

function Tree.LoadScript(scriptPath)
    local manifestPath = scriptPath .. "/manifest.lua"
    return Tree.Init(manifestPath)
end

Tree.OnScriptLoaded = nil

function Tree.Debug(...)
    local args = {...}
    local message = "^5[Tree Debug]^7 "
    for i, arg in ipairs(args) do
        if type(arg) == "table" then
            message = message .. "Table:"
            Tree.Utils.printTable(arg)
        else
            message = message .. tostring(arg)
            if i < #args then message = message .. " " end
        end
    end
    if #args > 0 then
        print(message)
    end
end

local manifestPath = scriptDir .. "manifest.lua"
if Tree.Utils.fileExists(manifestPath) then
    Tree.Init(manifestPath)
else
    print("^3[Tree Framework] No manifest.lua found^7")
end
_G.Tree = Tree
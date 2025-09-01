Tree = Tree or {}
Tree.Version = "0.0.1"
Tree.Author = "Tree Framework Team"

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
dofile(scriptDir .. "_tree/colors.lua")
dofile(scriptDir .. "_tree/threads.lua")
dofile(scriptDir .. "_tree/library.lua")

Tree.Colors.init()

print("^2[Tree Framework] v1.0.0 - BeamMP Plugin System^r")

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
    
    local pluginName = scriptBasePath:match("([^/\\]+)[/\\]*$") or "unknown"
    local loadedPlugins = Tree.Loader.getLoadedPlugins()
    
    loadedPlugins[pluginName] = {
        info = {
            name = pluginName,
            path = scriptBasePath,
            manifest = fullManifestPath
        },
        manifest = manifest,
        filesLoaded = 0
    }
    
    local filesLoaded = Tree.Loader.loadFromManifest(manifest, scriptBasePath)
    
    if filesLoaded > 0 then
        loadedPlugins[pluginName].filesLoaded = filesLoaded
        
        print("^2[Tree Framework] Ready! " .. filesLoaded .. " files loaded^7")
        
        if Tree.OnScriptLoaded then
            Tree.OnScriptLoaded(manifest)
        end
        
        return true
    else
        loadedPlugins[pluginName] = nil
        print("^3[Tree Framework] Warning: No files were loaded^7")
        return false
    end
end

function Tree.GetInfo()
    return {
        version = Tree.Version,
        author = Tree.Author,
        loadedFiles = Tree.Loader.getLoadedFiles(),
        loadedPlugins = Tree.Loader.getLoadedPlugins()
    }
end

function Tree.LoadScript(scriptPath)
    local manifestPath = scriptPath .. "/manifest.lua"
    return Tree.Init(manifestPath)
end

function Tree.Debug(...)
    local args = {...}
    local message = "^5[Tree Debug]^r "
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

Tree.OnScriptLoaded = nil
Wait = MP.Sleep

print("^2[Tree Framework] Scanning for plugins...^7")

local parentDir = Tree.Utils.getParentDirectory(scriptDir)
if parentDir then
    Tree.Loader.loadAllPlugins(parentDir)
else
    print("^1[Tree Framework] Could not determine parent directory for plugin scanning^7")
end

_G.Tree = Tree
Tree = Tree or {}
Tree.Loader = {}

local loadedFiles = {}
local loadedPlugins = {}

function Tree.Loader.expandPattern(pattern, basePath)
    basePath = basePath or "."
    
    pattern = "files/" .. pattern
    
    return Tree.Utils.glob(pattern, basePath)
end

function Tree.Loader.loadFile(filepath)
    local normalizedPath = filepath:gsub("\\", "/")
    
    if loadedFiles[normalizedPath] then
        print("^3[Tree Framework] File already loaded: " .. normalizedPath .. "^7")
        return true
    end
    
    local file = io.open(filepath, "r")
    if not file then
        print("^1[Tree Framework] Could not open file: " .. filepath .. "^7")
        return false
    end
    
    local content = file:read("*all")
    file:close()
    
    if not content or content == "" then
        print("^3[Tree Framework] Empty file: " .. filepath .. "^7")
        return true
    end
    
    local chunk, error = load(content, "@" .. filepath)
    if not chunk then
        print("^1[Tree Framework] Syntax error in " .. filepath .. ": " .. tostring(error) .. "^7")
        return false
    end
    
    local success, result = pcall(chunk)
    if not success then
        print("^1[Tree Framework] Runtime error in " .. filepath .. ": " .. tostring(result) .. "^7")
        return false
    end
    
    loadedFiles[normalizedPath] = true
    return true
end

function Tree.Loader.loadFiles(patterns, basePath)
    basePath = basePath or "."
    
    if type(patterns) == "string" then
        patterns = {patterns}
    end
    
    local allFiles = {}
    
    for _, pattern in ipairs(patterns) do
        local files = Tree.Loader.expandPattern(pattern, basePath)
        for _, file in ipairs(files) do
            table.insert(allFiles, file)
        end
    end
    
    local uniqueFiles = {}
    local seen = {}
    for _, file in ipairs(allFiles) do
        if not seen[file] then
            seen[file] = true
            table.insert(uniqueFiles, file)
        end
    end
    table.sort(uniqueFiles)
    
    local loadedCount = 0
    for _, file in ipairs(uniqueFiles) do
        if Tree.Loader.loadFile(file) then
            loadedCount = loadedCount + 1
        end
    end
    
    return loadedCount
end

function Tree.Loader.loadFromManifest(manifest, scriptPath)
    local basePath = scriptPath or Tree.Utils.getScriptDirectory() or "."
    
    local totalLoaded = 0
    
    if manifest.server_scripts then
        totalLoaded = totalLoaded + Tree.Loader.loadFiles(manifest.server_scripts, basePath)
    end
    return totalLoaded
end

function Tree.Loader.getLoadedFiles()
    return loadedFiles
end

function Tree.Loader.getLoadedPlugins()
    return loadedPlugins
end

function Tree.Loader.loadPlugin(pluginInfo)
    if not pluginInfo or not pluginInfo.manifest then
        print("^1[Tree Framework] Invalid plugin info^7")
        return false
    end
    
    if loadedPlugins[pluginInfo.name] then
        print("^3[Tree Framework] Plugin already loaded: " .. pluginInfo.name .. "^7")
        return true
    end
    
    local manifest = Tree.Manifest.parse(pluginInfo.manifest)
    if not manifest then
        print("^1[Tree Framework] Failed to parse manifest for plugin: " .. pluginInfo.name .. "^7")
        return false
    end
    
    local info = {}
    if manifest.description then table.insert(info, manifest.description) end
    if manifest.author then table.insert(info, "by " .. manifest.author) end
    if manifest.version then table.insert(info, "v" .. manifest.version) end
    
    local pluginLabel = pluginInfo.name
    if #info > 0 then
        pluginLabel = pluginLabel .. " (" .. table.concat(info, " ") .. ")"
    end
    
    print("^6[Tree Framework] Loading plugin: " .. pluginLabel .. "^7")
    
    local filesLoaded = Tree.Loader.loadFromManifest(manifest, pluginInfo.path .. "/")
    
    if filesLoaded > 0 then
        loadedPlugins[pluginInfo.name] = {
            info = pluginInfo,
            manifest = manifest,
            filesLoaded = filesLoaded
        }
        
        print("^2[Tree Framework] Plugin loaded: " .. pluginInfo.name .. " (" .. filesLoaded .. " files)^7")
        return true
    else
        print("^3[Tree Framework] Warning: No files loaded for plugin: " .. pluginInfo.name .. "^7")
        return false
    end
end

function Tree.Loader.loadAllPlugins(baseDir)
    local plugins = Tree.Utils.scanForPlugins(baseDir)
    local totalLoaded = 0
    local totalFiles = 0
    
    if #plugins == 0 then
        print("^3[Tree Framework] No plugins found in: " .. tostring(baseDir) .. "^7")
        return 0
    end
    
    print("^2[Tree Framework] Found " .. #plugins .. " plugin(s) to load^7")
    
    for _, plugin in ipairs(plugins) do
        if Tree.Loader.loadPlugin(plugin) then
            totalLoaded = totalLoaded + 1
            local pluginData = loadedPlugins[plugin.name]
            if pluginData then
                totalFiles = totalFiles + pluginData.filesLoaded
            end
        end
    end
    
    if totalLoaded > 0 then
        print("^2[Tree Framework] Plugin system ready! " .. totalLoaded .. " plugin(s) loaded (" .. totalFiles .. " files total)^7")
    end
    
    return totalLoaded
end


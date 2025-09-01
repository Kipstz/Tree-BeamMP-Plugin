Tree = Tree or {}
Tree.Loader = {}

local loadedFiles = {}

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


Tree = Tree or {}
Tree.Utils = {}

function Tree.Utils.getScriptDirectory()
    local info = debug.getinfo(2, "S")
    if info and info.source then
        local path = info.source:sub(2)
        return path:match("(.*/)")
    end
    return "./"
end

function Tree.Utils.resolvePath(basePath, relativePath)
    if not basePath or not relativePath then
        return relativePath or basePath or "./"
    end
    
    if relativePath:match("^[A-Za-z]:") or relativePath:match("^/") then
        return relativePath
    end
    
    basePath = basePath:gsub("\\", "/"):gsub("/$", "")
    relativePath = relativePath:gsub("\\", "/")
    
    return basePath .. "/" .. relativePath
end

function Tree.Utils.fileExists(path)
    if FS and FS.Exists then
        return FS.Exists(path) and FS.IsFile(path)
    else
        local file = io.open(path, "r")
        if file then
            file:close()
            return true
        end
        return false
    end
end

function Tree.Utils.glob(pattern, basePath)
    basePath = basePath or "."
    local files = {}
    
    if not pattern:match("[*?]") then
        local fullPath = Tree.Utils.resolvePath(basePath, pattern)
        if Tree.Utils.fileExists(fullPath) then
            table.insert(files, fullPath)
        end
        return files
    end
    
    local function scanDir(dir, filePattern, recursive)
        local dirFiles = FS.ListFiles(dir)
        if dirFiles then
            for _, fileName in ipairs(dirFiles) do
                if fileName:match("%.lua$") then
                    local fullPath = dir .. "/" .. fileName
                    
                    if filePattern == "*.lua" then
                        table.insert(files, fullPath)
                    else
                        local pattern_regex = filePattern:gsub("%*", ".*"):gsub("%%", "%%%%")
                        if fileName:match(pattern_regex) then
                            table.insert(files, fullPath)
                        end
                    end
                end
            end
        end
        
        if recursive then
            local subDirs = FS.ListDirectories(dir)
            if subDirs then
                for _, subDir in ipairs(subDirs) do
                    local fullSubDir = dir .. "/" .. subDir
                    scanDir(fullSubDir, filePattern, recursive)
                end
            end
        end
    end
    
    local dir, filePattern = pattern:match("^(.+)/([^/]+)$")
    if not dir then
        dir = basePath
        filePattern = pattern
    else
        dir = Tree.Utils.resolvePath(basePath, dir)
    end
    
    local recursive = pattern:match("%*%*/") ~= nil
    
    scanDir(dir, filePattern, recursive)
    
    table.sort(files)
    
    return files
end

function Tree.Utils.printTable(t, indent)
    indent = indent or 0
    local spacing = string.rep("  ", indent)
    
    if type(t) ~= "table" then
        print(spacing .. tostring(t))
        return
    end
    
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(spacing .. tostring(k) .. ":")
            Tree.Utils.printTable(v, indent + 1)
        else
            print(spacing .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

function Tree.Utils.copyTable(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = Tree.Utils.copyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function Tree.Utils.tableLength(t)
    if not t or type(t) ~= "table" then
        return 0
    end
    
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function Tree.Utils.getParentDirectory(path)
    if not path then return nil end
    
    path = path:gsub("\\", "/"):gsub("/$", "")
    local parent = path:match("(.+)/[^/]+$")
    if not parent then
        return nil
    end
    return parent
end

function Tree.Utils.scanForPlugins(baseDir)
    if not baseDir then
        return {}
    end
    
    local plugins = {}
    local directories = FS.ListDirectories(baseDir)
    
    if directories and type(directories) == "table" and #directories > 0 then
        for _, pluginName in ipairs(directories) do
            local pluginPath = baseDir .. "/" .. pluginName
            local manifestPath = pluginPath .. "/manifest.lua"
            
            if FS.Exists(manifestPath) and FS.IsFile(manifestPath) then
                table.insert(plugins, {
                    name = pluginName,
                    path = pluginPath,
                    manifest = manifestPath
                })
            end
        end
    end
    
    return plugins
end

function Tree.Utils.getCallingPlugin()
    local loadedPlugins = Tree.Loader.getLoadedPlugins()
    
    for level = 2, 10 do
        local info = debug.getinfo(level, "S")
        if not info or not info.source then
            break
        end
        
        local source = info.source
        if source:sub(1, 1) == "@" then
            source = source:sub(2):gsub("\\", "/")
            
            for pluginName, pluginData in pairs(loadedPlugins) do
                local pluginPath = pluginData.info.path:gsub("\\", "/")
                if source:find(pluginPath, 1, true) == 1 then
                    return pluginName, pluginPath
                end
            end
        end
    end
    
    return nil, nil
end
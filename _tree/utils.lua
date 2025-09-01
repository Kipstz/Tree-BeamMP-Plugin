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
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
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
        local windowsDir = dir:gsub("/", "\\")
        local tempFile = "tree_temp_" .. os.time() .. "_" .. math.random(1000, 9999) .. ".txt"
        
        local command
        if recursive then
            command = 'dir /s /b "' .. windowsDir .. '\\*.lua" > ' .. tempFile .. ' 2>nul'
        else
            command = 'dir /b "' .. windowsDir .. '\\*.lua" > ' .. tempFile .. ' 2>nul'
        end
        
        os.execute(command)
        
        local file = io.open(tempFile, "r")
        if not file then
            pcall(os.remove, tempFile)
            return
        end
        
        local result = file:read("*a")
        file:close()
        pcall(os.remove, tempFile)
        
        for line in result:gmatch("[^\r\n]+") do
            if line:match("%.lua$") then
                local normalizedPath = line:gsub("\\", "/")
                
                if not recursive and not line:match("^[A-Za-z]:") then
                    normalizedPath = dir .. "/" .. line
                end
                
                if filePattern == "*.lua" then
                    table.insert(files, normalizedPath)
                else
                    local fileName = normalizedPath:match("([^/]+)$")
                    if fileName and fileName:match(filePattern:gsub("%*", ".*"):gsub("%%", "%%%%")) then
                        table.insert(files, normalizedPath)
                    end
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
    local isWindows = package.config:sub(1,1) == '\\'
    local tempScript, tempOut
    
    if isWindows then
        tempScript = "tree_scan_" .. os.time() .. "_" .. math.random(1000, 9999) .. ".bat"
        tempOut = "tree_output_" .. os.time() .. "_" .. math.random(1000, 9999) .. ".txt"
        
        local windowsDir = baseDir:gsub("/", "\\")
        local batFile = io.open(tempScript, "w")
        if not batFile then
            return plugins
        end
        
        batFile:write('@echo off\n')
        batFile:write('for /d %%i in ("' .. windowsDir .. '\\*") do (\n')
        batFile:write('  if exist "%%i\\manifest.lua" echo %%i\n')
        batFile:write(')\n')
        batFile:close()
        
        os.execute(tempScript .. ' > ' .. tempOut .. ' 2>nul')
    else
        tempScript = "tree_scan_" .. os.time() .. "_" .. math.random(1000, 9999) .. ".sh"
        tempOut = "tree_output_" .. os.time() .. "_" .. math.random(1000, 9999) .. ".txt"
        
        local shFile = io.open(tempScript, "w")
        if not shFile then
            return plugins
        end
        
        shFile:write('#!/bin/bash\n')
        shFile:write('for dir in "' .. baseDir .. '"/*; do\n')
        shFile:write('  if [ -d "$dir" ] && [ -f "$dir/manifest.lua" ]; then\n')
        shFile:write('    echo "$dir"\n')
        shFile:write('  fi\n')
        shFile:write('done\n')
        shFile:close()
        
        os.execute('chmod +x ' .. tempScript)
        os.execute('./' .. tempScript .. ' > ' .. tempOut .. ' 2>/dev/null')
    end
    
    local file = io.open(tempOut, "r")
    if file then
        local result = file:read("*a")
        file:close()
        
        for line in result:gmatch("[^\r\n]+") do
            if line and line ~= "" then
                local normalizedPath = line:gsub("\\", "/")
                local pluginName = normalizedPath:match("([^/]+)$")
                if pluginName then
                    local manifestPath = normalizedPath .. "/manifest.lua"
                    if Tree.Utils.fileExists(manifestPath) then
                        table.insert(plugins, {
                            name = pluginName,
                            path = normalizedPath,
                            manifest = manifestPath
                        })
                    end
                end
            end
        end
    end
    
    pcall(os.remove, tempScript)
    pcall(os.remove, tempOut)
    
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


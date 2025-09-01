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
        
        local command
        if recursive then
            command = 'dir /s /b "' .. windowsDir .. '\\*.lua" 2>nul'
        else
            command = 'dir /b "' .. windowsDir .. '\\*.lua" 2>nul'
        end
        
        local handle = io.popen(command)
        if not handle then return end
        
        local result = handle:read("*a")
        handle:close()
        
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


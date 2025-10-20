---@meta

Tree = Tree or {}

---Native library loading system for the Tree Framework
---@class Tree.Library
Tree.Library = {}

---Load a native library from plugin lib directory or system
---@param libName string Name of the library to load (without extension)
---@param customFunctionNames? string|table Optional custom function name(s) to try loading
---@return any|nil lib The loaded library module, or nil on error
function Tree.LoadLib(libName, customFunctionNames)
    if not libName or type(libName) ~= "string" then
        print("^4[Tree Framework] Error: Invalid library name^r")
        return nil
    end
    
    local isWindows = package.config:sub(1,1) == '\\'
    local extension = isWindows and ".dll" or ".so"
    
    local libPath, baseName = libName:match("^(.+)/([^/]+)$")
    if not libPath then
        libPath = ""
        baseName = libName
    else
        libPath = libPath .. "/"
    end
    
    local fileName = baseName .. extension

    local functionNames = {}

    -- Add custom function names first if provided
    if customFunctionNames then
        if type(customFunctionNames) == "string" then
            table.insert(functionNames, customFunctionNames)
        elseif type(customFunctionNames) == "table" then
            for _, funcName in ipairs(customFunctionNames) do
                if type(funcName) == "string" then
                    table.insert(functionNames, funcName)
                end
            end
        end
    end

    -- Add default function names
    local defaultNames = {
        "luaopen_" .. baseName,
        "luaopen_lib" .. baseName,
        baseName .. "_init",
        "init_" .. baseName,
        "open_" .. baseName
    }

    for _, name in ipairs(defaultNames) do
        table.insert(functionNames, name)
    end
    
    local function tryLoadLib(libPath, source)
        if not Tree.Utils.fileExists(libPath) then
            return nil
        end
        
        for _, funcName in ipairs(functionNames) do
            local success, result = pcall(package.loadlib, libPath, funcName)
            
            if success and result then
                local initSuccess, lib = pcall(result)
                
                if initSuccess then
                    print("^2[Tree Framework] Loaded library: " .. fileName .. " from " .. source .. " (entry: " .. funcName .. ")^r")
                    return lib
                else
                    print("^3[Tree Framework] Function " .. funcName .. " found but init failed: " .. tostring(lib) .. "^r")
                end
            end
        end
        
        return nil
    end
    
    local pluginName, pluginPath = Tree.Utils.getCallingPlugin()

    if pluginName and pluginPath then
        local loadedPlugins = Tree.Loader.getLoadedPlugins()
        local pluginData = loadedPlugins[pluginName]
        local libDir = "lib"
        
        if pluginData and pluginData.manifest and pluginData.manifest.lib_dir then
            libDir = pluginData.manifest.lib_dir
        end
        
        local pluginLibPath = pluginPath .. "/" .. libDir .. "/" .. libPath .. fileName
        local lib = tryLoadLib(pluginLibPath, "plugin " .. pluginName)
        if lib then
            return lib
        end
        print("^3[Tree Framework] Library not found in plugin " .. pluginName .. ": " .. pluginLibPath .. "^r")
    end
    
    local success, result = pcall(require, baseName)
    
    if success then
        print("^2[Tree Framework] Loaded library: " .. baseName .. " via require^r")
        return result
    end
    
    print("^4[Tree Framework] Error: Unable to load library " .. libName .. " (searched plugin libs and system)^r")
    return nil
end

---Get a list of all loaded libraries
---@return table libraries Array of loaded library names
function Tree.Library.getLoadedLibraries()
    local loaded = {}
    for name, _ in pairs(package.loaded) do
        if not name:match("^_") then
            table.insert(loaded, name)
        end
    end
    return loaded
end
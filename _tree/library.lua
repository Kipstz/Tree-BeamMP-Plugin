Tree = Tree or {}
Tree.Library = {}

function Tree.LoadLib(libName)
    if not libName or type(libName) ~= "string" then
        print("^4[Tree Framework] Error: Invalid library name^r")
        return nil
    end
    
    local isWindows = package.config:sub(1,1) == '\\'
    local extension = isWindows and ".dll" or ".so"
    local fileName = libName .. extension
    
    local functionNames = {
        "luaopen_" .. libName,
        "luaopen_lib" .. libName,
        libName .. "_init",
        "init_" .. libName,
        "open_" .. libName
    }
    
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
        local pluginLibPath = pluginPath .. "/lib/" .. fileName
        local lib = tryLoadLib(pluginLibPath, "plugin " .. pluginName)
        if lib then
            return lib
        end
        print("^3[Tree Framework] Library not found in plugin " .. pluginName .. ": " .. pluginLibPath .. "^r")
    end
    
    local success, result = pcall(require, libName)
    
    if success then
        print("^2[Tree Framework] Loaded library: " .. libName .. " via require^r")
        return result
    end
    
    print("^4[Tree Framework] Error: Unable to load library " .. libName .. " (searched plugin libs and system)^r")
    return nil
end

function Tree.Library.getLoadedLibraries()
    local loaded = {}
    for name, _ in pairs(package.loaded) do
        if not name:match("^_") then
            table.insert(loaded, name)
        end
    end
    return loaded
end
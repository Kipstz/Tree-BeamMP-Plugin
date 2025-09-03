---@meta

Tree = Tree or {}

---Plugin loading system for the Tree Framework
---@class Tree.Loader
Tree.Loader = {}

local loadedFiles = {}
local loadedPlugins = {}

---Expand a file pattern using glob matching within the plugin's files directory
---@param pattern string File pattern to expand (e.g., "*.lua", "modules/*.lua")
---@param basePath string? Base path for the plugin (default: ".")
---@param manifest table? Plugin manifest containing files_dir setting
---@return table files Array of matching file paths
function Tree.Loader.expandPattern(pattern, basePath, manifest)
    basePath = basePath or "."
    manifest = manifest or {}
    
    local filesDir = manifest.files_dir or "files"
    pattern = filesDir .. "/" .. pattern
    
    return Tree.Utils.glob(pattern, basePath)
end

---Load a single Lua file with optional print prefix from manifest
---@param filepath string Path to the Lua file to load
---@param manifest table? Plugin manifest for print prefix configuration
---@return boolean success True if file was loaded successfully
function Tree.Loader.loadFile(filepath, manifest)
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
    
    local env = _G
    if manifest and manifest.print_prefix and manifest.print_prefix ~= "" then
        env = setmetatable({}, {__index = _G})
        local originalPrint = print
        env.print = function(...)
            local args = {...}
            local message = ""
            for i, arg in ipairs(args) do
                message = message .. tostring(arg)
                if i < #args then
                    message = message .. "\t"
                end
            end
            originalPrint(manifest.print_prefix .. message)
        end
    end
    
    local chunk, error = load(content, "@" .. filepath, "t", env)
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

---Load multiple files matching the given patterns
---@param patterns string|table Pattern or array of patterns to match
---@param basePath string? Base path for pattern matching (default: ".")
---@param manifest table? Plugin manifest for configuration
---@return number loadedCount Number of files successfully loaded
function Tree.Loader.loadFiles(patterns, basePath, manifest)
    basePath = basePath or "."
    manifest = manifest or {}
    
    if type(patterns) == "string" then
        patterns = {patterns}
    end
    
    local allFiles = {}
    
    for _, pattern in ipairs(patterns) do
        local files = Tree.Loader.expandPattern(pattern, basePath, manifest)
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
    
    local loadedCount = 0
    for _, file in ipairs(uniqueFiles) do
        if Tree.Loader.loadFile(file, manifest) then
            loadedCount = loadedCount + 1
        end
    end
    
    return loadedCount
end

---Load files from a parsed manifest
---@param manifest table Parsed manifest containing server_scripts
---@param scriptPath string? Base path for the plugin scripts
---@return number totalLoaded Total number of files loaded
function Tree.Loader.loadFromManifest(manifest, scriptPath)
    local basePath = scriptPath or Tree.Utils.getScriptDirectory() or "."
    
    local totalLoaded = 0
    
    if manifest.server_scripts then
        totalLoaded = totalLoaded + Tree.Loader.loadFiles(manifest.server_scripts, basePath, manifest)
    end
    return totalLoaded
end

---Get the registry of loaded files
---@return table loadedFiles Registry of loaded file paths
function Tree.Loader.getLoadedFiles()
    return loadedFiles
end

---Get the registry of loaded plugins
---@return table loadedPlugins Registry of loaded plugin data
function Tree.Loader.getLoadedPlugins()
    return loadedPlugins
end

---Load a single plugin from plugin info
---@param pluginInfo table Plugin info with name, path, and manifest fields
---@return boolean success True if plugin was loaded successfully
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
    
    loadedPlugins[pluginInfo.name] = {
        info = pluginInfo,
        manifest = manifest,
        filesLoaded = 0
    }
    
    local filesLoaded = Tree.Loader.loadFromManifest(manifest, pluginInfo.path .. "/")
    
    if filesLoaded > 0 then
        loadedPlugins[pluginInfo.name].filesLoaded = filesLoaded
        
        print("^2[Tree Framework] Plugin loaded: " .. pluginInfo.name .. " (" .. filesLoaded .. " files)^7")
        return true
    else
        loadedPlugins[pluginInfo.name] = nil
        print("^3[Tree Framework] Warning: No files loaded for plugin: " .. pluginInfo.name .. "^7")
        return false
    end
end

---Discover and load all plugins in a directory
---@param baseDir string Base directory to scan for plugins
---@return number totalLoaded Number of plugins successfully loaded
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


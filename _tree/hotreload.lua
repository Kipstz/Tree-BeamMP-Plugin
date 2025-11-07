---@meta HotReload

---@class HotReload
Tree.HotReload = {}

-- Registry to track file timestamps/hashes for plugins with hot reload enabled
local watchedPlugins = {}
local watchTimer = nil
local CHECK_INTERVAL = 5000 -- 5 seconds

---@class WatchedPlugin
---@field name string
---@field path string
---@field manifest table
---@field manifestPath string
---@field files table<string, string> -- filepath -> hash/timestamp

---Computes a simple hash of file content
---@param filepath string
---@return string|nil hash
local function computeFileHash(filepath)
    local file = io.open(filepath, "rb")
    if not file then
        return nil
    end

    local content = file:read("*all")
    file:close()

    if not content then
        return nil
    end

    -- Simple hash: combine file size with first/last bytes
    local hash = tostring(#content)
    if #content > 0 then
        hash = hash .. "_" .. string.byte(content, 1)
    end
    if #content > 1 then
        hash = hash .. "_" .. string.byte(content, #content)
    end
    -- Add middle section for better detection
    if #content > 100 then
        local mid = math.floor(#content / 2)
        hash = hash .. "_" .. string.byte(content, mid)
    end

    return hash
end

---Gets the current state (hash) of a file
---@param filepath string
---@return string|nil
local function getFileState(filepath)
    -- Normalize path
    filepath = filepath:gsub("\\", "/")

    -- Try to use file system timestamp if available (future-proof)
    if FS and FS.GetLastModified then
        local timestamp = FS.GetLastModified(filepath)
        if timestamp then
            return tostring(timestamp)
        end
    end

    -- Fallback to content hash
    return computeFileHash(filepath)
end

---Checks if any files in a watched plugin have changed
---@param watchedPlugin WatchedPlugin
---@return boolean changed
---@return table|nil changedFiles
local function checkPluginFiles(watchedPlugin)
    local changed = false
    local changedFiles = {}

    for filepath, oldHash in pairs(watchedPlugin.files) do
        local currentHash = getFileState(filepath)

        if currentHash and currentHash ~= oldHash then
            changed = true
            table.insert(changedFiles, filepath)
            print(string.format("^6[HotReload]^r Detected change in: ^3%s^r", filepath))
        elseif not currentHash then
            -- File might have been deleted
            print(string.format("^1[HotReload]^r File no longer accessible: ^3%s^r", filepath))
        end
    end

    return changed, changedFiles
end

---Reloads a plugin by unloading and reloading it
---@param watchedPlugin WatchedPlugin
local function reloadPlugin(watchedPlugin)
    print(string.format("^2[HotReload]^r Reloading plugin: ^3%s^r", watchedPlugin.name))

    -- Step 1: Unload the plugin
    local success = Tree.Loader.unloadPlugin(watchedPlugin.name)

    if not success then
        print(string.format("^1[HotReload]^r Failed to unload plugin: ^3%s^r", watchedPlugin.name))
        return
    end

    -- Step 2: Reload the plugin
    local pluginInfo = {
        name = watchedPlugin.name,
        path = watchedPlugin.path,
        manifest = watchedPlugin.manifestPath
    }

    local reloadSuccess = Tree.Loader.loadPlugin(pluginInfo, true)

    if reloadSuccess then
        print(string.format("^2[HotReload]^r Successfully reloaded plugin: ^3%s^r", watchedPlugin.name))

        -- Update the watched file hashes
        local loadedPlugin = Tree.Loader.getLoadedPlugin(watchedPlugin.name)
        if loadedPlugin and loadedPlugin.manifest.hot_reload then
            -- Re-register with new file states
            Tree.HotReload.registerPlugin(loadedPlugin)
        end
    else
        print(string.format("^1[HotReload]^r Failed to reload plugin: ^3%s^r", watchedPlugin.name))
    end
end

---Main watch loop that checks all watched plugins
local function watchLoop()
    for pluginName, watchedPlugin in pairs(watchedPlugins) do
        local changed, changedFiles = checkPluginFiles(watchedPlugin)

        if changed then
            reloadPlugin(watchedPlugin)
        end
    end
end

---Registers a plugin for hot reload watching
---@param pluginInfo table Plugin info from loader
function Tree.HotReload.registerPlugin(pluginInfo)
    if not pluginInfo.manifest.hot_reload then
        return
    end

    -- Get manifest path from the original plugin info
    local manifestPath = pluginInfo.info and pluginInfo.info.manifest
    if not manifestPath then
        -- Fallback: construct path from plugin path
        manifestPath = pluginInfo.path .. "/manifest.lua"
    end

    -- Normalize path (backslash to forward slash)
    manifestPath = manifestPath:gsub("\\", "/")

    local watchedPlugin = {
        name = pluginInfo.name,
        path = pluginInfo.path,
        manifest = pluginInfo.manifest,
        manifestPath = manifestPath,
        files = {}
    }

    -- Get all files loaded by this plugin
    local loadedFiles = pluginInfo.loadedFiles or {}

    for _, filepath in ipairs(loadedFiles) do
        local fileState = getFileState(filepath)
        if fileState then
            watchedPlugin.files[filepath] = fileState
        end
    end

    watchedPlugins[pluginInfo.name] = watchedPlugin

    print(string.format("^6[HotReload]^r Watching plugin: ^3%s^r (^2%d^r files)",
        pluginInfo.name, Tree.Utils.tableLength(watchedPlugin.files)))
end

---Unregisters a plugin from hot reload watching
---@param pluginName string
function Tree.HotReload.unregisterPlugin(pluginName)
    if watchedPlugins[pluginName] then
        watchedPlugins[pluginName] = nil
        print(string.format("^6[HotReload]^r Stopped watching plugin: ^3%s^r", pluginName))
    end
end

---Initializes the hot reload system
function Tree.HotReload.init()
    if watchTimer then
        print("^3[HotReload]^r Hot reload system already initialized")
        return
    end

    -- Create a recurring timer that checks every 10 seconds
    CreateThread(function()
        while true do
            Wait(CHECK_INTERVAL)

            -- Only run if there are plugins being watched
            if Tree.Utils.tableLength(watchedPlugins) > 0 then
                local success, err = pcall(watchLoop)
                if not success then
                    print(string.format("^1[HotReload]^r Error in watch loop: %s^r", tostring(err)))
                end
            end
        end
    end)

    print("^2[HotReload]^r Hot reload system initialized (checking every 10 seconds)")
end

---Gets information about watched plugins
---@return table
function Tree.HotReload.getWatchedPlugins()
    local info = {}
    for name, plugin in pairs(watchedPlugins) do
        info[name] = {
            name = plugin.name,
            path = plugin.path,
            fileCount = Tree.Utils.tableLength(plugin.files)
        }
    end
    return info
end

---Manually triggers a check for all watched plugins
function Tree.HotReload.checkNow()
    print("^6[HotReload]^r Manually checking for changes...")
    watchLoop()
end

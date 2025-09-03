---@meta

Tree = Tree or {}

---Manifest parsing system for the Tree Framework
---@class Tree.Manifest
Tree.Manifest = {}

local currentManifest = {}

---Parse a manifest.lua file in a sandboxed environment
---@param manifestPath string Path to the manifest.lua file
---@return table|nil manifest Parsed manifest table or nil on error
function Tree.Manifest.parse(manifestPath)
    local file = io.open(manifestPath, "r")
    if not file then
        print("^1[Tree Framework] Could not open manifest: " .. manifestPath .. "^7")
        return nil
    end
    
    local content = file:read("*all")
    file:close()
    
    if not content or content == "" then
        print("^1[Tree Framework] Empty manifest: " .. manifestPath .. "^7")
        return nil
    end
    
    local manifestEnv = setmetatable({}, {
        __newindex = function(t, k, v)
            currentManifest[k] = v
        end,
        __index = _G
    })
    
    currentManifest = {}
    
    local chunk, error = load(content, "@" .. manifestPath, "t", manifestEnv)
    if not chunk then
        print("^1[Tree Framework] Syntax error in manifest " .. manifestPath .. ": " .. tostring(error) .. "^7")
        return nil
    end
    
    local success, result = pcall(chunk)
    if not success then
        print("^1[Tree Framework] Runtime error in manifest " .. manifestPath .. ": " .. tostring(result) .. "^7")
        return nil
    end
    
    if not currentManifest.server_scripts then
        print("^3[Tree Framework] Warning: No server_scripts specified in manifest^7")
    end
    
    currentManifest.files_dir = currentManifest.files_dir or "files"
    currentManifest.lib_dir = currentManifest.lib_dir or "lib"
    currentManifest.print_prefix = currentManifest.print_prefix or ""
    
    return currentManifest
end

---Get the currently parsed manifest
---@return table currentManifest The last parsed manifest table
function Tree.Manifest.getCurrent()
    return currentManifest
end



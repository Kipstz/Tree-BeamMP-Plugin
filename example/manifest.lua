author = 'Tree Framework Team'
description = 'Professional example plugin demonstrating Tree Framework features'
version = '1.0.0'

-- Directory configuration
files_dir = 'files'
lib_dir = 'lib'

-- Console output customization
print_prefix = '[Example] '

-- Enable hot reload for development
hot_reload = true

-- Load order: configuration first, then event handlers
server_scripts = {
    "test.lua",      -- Server initialization & configuration
    "test2.lua"      -- Event handlers & player management
}
# Tree Framework

A lightweight BeamMP plugin framework inspired by FiveM's architecture that provides automatic plugin discovery and loading.

## Overview

The Tree Framework is the **core framework** that scans the `Resources/Server/` directory for plugins and loads them automatically. Unlike traditional single-plugin frameworks, Tree manages multiple plugins simultaneously.

## Key Features

- **Plugin Discovery** - Automatically scans parent directory for plugins with `manifest.lua` files
- **Multi-plugin Support** - Load and manage multiple plugins simultaneously
- **FiveM-like Structure** - Familiar manifest-driven development
- **Global Variable Sharing** - Variables shared automatically between files within each plugin
- **Hot Reload System** - Automatically detects file changes and reloads plugins every 5 seconds
- **Enhanced Event System** - Multiple handlers per event with anonymous function support
- **Zero Configuration** - Framework works out-of-the-box

## How It Works

1. BeamMP loads `Tree-BeamMP-Plugin/main.lua` on server start
2. Framework scans `Resources/Server/` for directories containing `manifest.lua`
3. Each discovered plugin is loaded according to its manifest configuration
4. Global `Tree` API becomes available to all plugins

## Framework Structure

```
Tree-BeamMP-Plugin/          # Core framework (this directory)
├── main.lua                # Entry point - initializes framework and scans for plugins
├── _tree/                  # Framework internals
│   ├── loader.lua         # Plugin loading system with glob pattern support
│   ├── manifest.lua       # Manifest parsing in sandboxed environment
│   ├── utils.lua          # Utility functions
│   ├── colors.lua         # BeamMP color code support
│   ├── threads.lua        # Threading utilities
│   ├── library.lua        # Native library loading
│   ├── events.lua         # Enhanced event system
│   └── hotreload.lua      # Hot reload system for development
└── example/               # Example plugin structure for reference
```

## Plugin Development

Create plugins as **separate directories** alongside `Tree-BeamMP-Plugin`:

```
Resources/Server/
├── Tree-BeamMP-Plugin/    # Framework (don't modify)
├── your-plugin/           # Your plugin
│   ├── manifest.lua      # Plugin configuration
│   └── files/            # Your scripts
└── another-plugin/        # Another plugin
    ├── manifest.lua
    └── files/
```

### Plugin Manifest Format

Each plugin needs a `manifest.lua` file:

```lua
author = 'Your Name'
description = 'Professional plugin description'
version = '1.0.0'

-- Directory configuration
files_dir = 'files'      -- Directory containing your scripts (default: 'files')
lib_dir = 'lib'          -- Directory for native libraries (default: 'lib')

-- Console output customization
print_prefix = '[MyPlugin] '  -- Custom prefix for print statements (optional)

-- Enable hot reload for development
hot_reload = true

-- Load scripts in order
server_scripts = {
    "init.lua",
    "config.lua",
    "modules/*.lua"      -- Supports glob patterns
}
```

### Configuration Options

- **`files_dir`** - Directory containing your plugin scripts (default: `'files'`)
- **`prefix`** - Custom prefix for console output (default: plugin directory name)
- **`server_scripts`** - Array of file patterns to load, supports glob patterns like `*.lua`

## Variable Sharing

Global variables are shared automatically between files in the same plugin:

```lua
-- files/config.lua
ServerConfig = {
    name = "My Server",
    maxPlayers = 8,
    version = "1.0.0"
}
local privateKey = "secret"  -- Only accessible in this file

-- files/events.lua
print(ServerConfig.name)     -- Works: "My Server"
print(privateKey)            -- nil (local variables stay private)

-- Modify shared state
ServerConfig.currentPlayers = 5
```

This allows easy data sharing across your plugin files while maintaining encapsulation for local variables.

## Load Order

Files load in the order specified in `server_scripts`. Use this to ensure dependencies load first.

## Color Codes

The framework supports BeamMP color codes in all print statements:

```lua
print("^2Green text^r and ^4red text^r")
print("^lBold^r ^nunderlined^r ^oitalic^r text")
```

**Colors:**
- `^0` black, `^1` blue, `^2` green, `^3` light blue, `^4` red, `^5` pink
- `^6` orange, `^7` grey, `^8` dark grey, `^9` light purple
- `^a` light green, `^b` light blue, `^c` dark orange, `^d` light pink
- `^e` yellow, `^f` white

**Effects:**
- `^l` bold, `^n` underline, `^o` italic, `^m` strike-through
- `^r` reset, `^p` newline

## Enhanced Event System

The Tree Framework extends BeamMP's event system with enhanced functionality:

### Multiple Event Handlers
Register multiple handlers for the same event - all will be executed:

```lua
-- Plugin: AntiCheat
MP.RegisterEvent("onPlayerJoin", function(playerID)
    checkPlayerBan(playerID)
end)

-- Plugin: WelcomeSystem
MP.RegisterEvent("onPlayerJoin", function(playerID)
    sendWelcomeMessage(playerID)
end)

-- Plugin: Analytics
MP.RegisterEvent("onPlayerJoin", function(playerID)
    logPlayerJoin(playerID)
end)

-- All three handlers execute when a player joins!
```

### Anonymous Function Support
Register event handlers using anonymous functions directly:

```lua
-- Traditional named function approach (still works)
function handleServerCommand(cmd, args)
    print("Executing command: " .. cmd)
end
MP.RegisterEvent("onConsoleInput", "handleServerCommand")

-- Modern anonymous function approach (recommended)
MP.RegisterEvent("onChatMessage", function(playerID, playerName, message)
    if message:match("^/help") then
        MP.SendChatMessage(playerID, "Available commands: /help, /info")
    end
end)
```

### How It Works
The framework automatically generates unique handler names internally:
- Anonymous functions: `TreeAnonymous_[EventName]_[Counter]`
- Named functions: `[FunctionName]_Tree_[Counter]`

This prevents naming conflicts and allows multiple handlers per event.

## Hot Reload System

The Tree Framework includes a powerful hot reload system that automatically detects file changes and reloads plugins without server restart.

### Enabling Hot Reload

Add `hot_reload = true` to your plugin's manifest:

```lua
author = 'Your Name'
description = 'Player Management System'
version = '1.0.0'

-- Enable hot reload for rapid development
hot_reload = true

server_scripts = {
    "config.lua",
    "events.lua",
    "commands.lua"
}
```

Now you can modify any file and see changes in ~5 seconds without restarting the server!

### How It Works

1. When `hot_reload = true`, the framework monitors all files loaded by your plugin
2. Every **5 seconds**, the system checks if any files have been modified
3. When changes are detected:
   - Plugin is automatically unloaded
   - All files are reloaded fresh
   - Console shows which files changed and reload status

### Example Output

When you edit a file and save:

```
[HotReload] Watching plugin: player-management (3 files)
[HotReload] Hot reload system initialized (checking every 5 seconds)

[HotReload] Detected change in: Resources/Server/player-management/files/events.lua
[HotReload] Reloading plugin: player-management
[Tree Framework] Unloading plugin: player-management
[Tree Framework] Plugin unloaded: player-management
[Tree Framework] Reloading plugin: player-management (Player Management System v1.0.0)
[PlayerMgmt] Initializing Player Management System...
[PlayerMgmt] Event handlers registered successfully!
[Tree Framework] Plugin loaded: player-management (3 files)
[HotReload] Successfully reloaded plugin: player-management
[HotReload] Watching plugin: player-management (3 files)
```

Your changes are live without server restart!

### Manual Checks

You can manually trigger a check for all watched plugins:

```lua
Tree.HotReload.checkNow()  -- Force immediate check
```

### View Watched Plugins

See which plugins are being watched:

```lua
local watched = Tree.HotReload.getWatchedPlugins()
for name, info in pairs(watched) do
    print(name .. " - watching " .. info.fileCount .. " files")
end
```

### Important Notes

- **Global Variables**: Variables declared globally in your plugin will persist after reload. Use `local` for truly fresh state.
- **Event Handlers**: BeamMP event handlers registered with `MP.RegisterEvent()` may persist. The framework cannot fully clean these between reloads.
- **Check Interval**: Fixed at 5 seconds (configurable in `_tree/hotreload.lua`)
- **File Detection**: Uses content hashing to detect changes (timestamp API pending BeamMP support)

### Limitations

Due to Lua's nature, hot reload has some limitations:

- **Global State**: Global variables and event handlers may persist across reloads
- **Native Libraries**: Loaded native libraries (`.dll`/`.so`) cannot be unloaded
- **Memory**: Old code remains in memory; server restart recommended periodically

For complete cleanup, restart the server. Hot reload is best for rapid development iteration.

## Native Libraries

Place `.dll` (Windows) or `.so` (Linux) files in the `lib/` directory of your plugin and load them:

```lua
-- Load JSON library for data serialization
local json = Tree.LoadLib("json")
if json then
    -- Serialize player data
    local playerData = {
        id = 123,
        name = "Player1",
        position = {x = 100, y = 50, z = 200}
    }
    local encoded = json.encode(playerData)
    print("Saved: " .. encoded)
end

-- Load custom library with non-standard entry point
local database = Tree.LoadLib("sqlite", "luaopen_lsqlite3")
if database then
    local db = database.open("playerdata.db")
    -- Use database...
end

-- Try multiple entry points (first match wins)
local crypto = Tree.LoadLib("openssl", {"luaopen_openssl", "init_ssl", "ssl_init"})
```

### Custom Function Names

The `Tree.LoadLib` function accepts an optional second parameter to specify custom entry point function names:

- **Single function name (string)**: `Tree.LoadLib("libname", "custom_init")`
- **Multiple function names (table)**: `Tree.LoadLib("libname", {"init_one", "init_two"})`

Custom function names are tried **first**, followed by default naming patterns:
- `luaopen_[libname]`
- `luaopen_lib[libname]`
- `[libname]_init`
- `init_[libname]`
- `open_[libname]`

This allows loading libraries with non-standard entry points without modifying the framework.

**⚠️ Windows Note:** Native library loading is currently not working on Windows due to BeamMP's Lua environment limitations. Waiting for a future BeamMP patch to resolve this issue. Linux support may vary.

## Framework API

The Tree Framework provides a global `Tree` API available to all plugins:

### Core API
- `Tree.Debug(...)` - Debug logging with table support and color formatting
- `Tree.GetInfo()` - Framework version and loaded plugin information
- `Tree.LoadLib(name, customFunctionNames?)` - Load native library from lib/ directory with optional custom entry point function names

### Hot Reload API
- `Tree.HotReload.checkNow()` - Manually trigger an immediate check for file changes
- `Tree.HotReload.getWatchedPlugins()` - Get information about all watched plugins
- `Tree.HotReload.registerPlugin(pluginInfo)` - Manually register a plugin for hot reload watching
- `Tree.HotReload.unregisterPlugin(pluginName)` - Stop watching a specific plugin

### Threading API
- `CreateThread(function)` - Create an asynchronous thread (global function)
- `SetTimeout(milliseconds, function)` - Execute function after delay (global function)
- `Wait(milliseconds)` - Sleep/pause execution (alias for `MP.Sleep`)

## Example Plugin Usage

The framework includes an `example/` plugin to demonstrate usage. You can also find a standalone `example/` plugin in the parent directory.

To create your own plugin:

1. Create a new directory alongside `Tree-BeamMP-Plugin`
2. Add a `manifest.lua` file with your plugin configuration
3. Create a `files/` directory for your scripts
4. Framework will automatically discover and load your plugin on server restart

## Plugin Loading Process

1. Framework scans `Resources/Server/` for directories with `manifest.lua`
2. Each plugin's manifest is parsed in a sandboxed environment
3. Plugin's `files_dir` is determined (default: `'files'`)
4. Files are loaded from the files directory according to `server_scripts` order using glob pattern matching
5. Global variables within each plugin are shared between its files
6. Each plugin maintains isolated loading state with optional custom print prefix

## Print Prefixes

Each plugin can have a custom prefix for console output:

```lua
-- In manifest.lua
prefix = 'MyPlugin'
```

When not specified, the framework uses the plugin directory name as the prefix. This helps identify which plugin is generating console output in multi-plugin environments.

## License

Licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
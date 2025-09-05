# Tree Framework

A lightweight BeamMP plugin framework inspired by FiveM's architecture that provides automatic plugin discovery and loading.

## Overview

The Tree Framework is the **core framework** that scans the `Resources/Server/` directory for plugins and loads them automatically. Unlike traditional single-plugin frameworks, Tree manages multiple plugins simultaneously.

## Key Features

- **Plugin Discovery** - Automatically scans parent directory for plugins with `manifest.lua` files
- **Multi-plugin Support** - Load and manage multiple plugins simultaneously  
- **FiveM-like Structure** - Familiar manifest-driven development
- **Global Variable Sharing** - Variables shared automatically between files within each plugin
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
│   └── library.lua        # Native library loading
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
description = 'Your Plugin Description'
version = '1.0.0'

-- Optional: Custom print prefix (defaults to plugin directory name)
files_dir = 'files'  -- Directory containing your scripts (default: 'files')
prefix = 'MyPlugin'  -- Custom prefix for print statements (optional)

server_scripts = {
    "init.lua",
    "modules/*.lua"  -- Supports glob patterns
}
```

### Configuration Options

- **`files_dir`** - Directory containing your plugin scripts (default: `'files'`)
- **`prefix`** - Custom prefix for console output (default: plugin directory name)
- **`server_scripts`** - Array of file patterns to load, supports glob patterns like `*.lua`

## Variable Sharing

Variables are shared automatically between files without require():

```lua
-- files/init.lua
playerCount = 0
local secret = "private"

-- files/modules/player.lua  
print(playerCount)  -- Works
print(secret)       -- nil (local variables stay private)
```

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
You can now register multiple handlers for the same event:

```lua
-- All three handlers will be called when onConsoleInput is triggered
MP.RegisterEvent("onConsoleInput", function()
    print("First handler")
end)

MP.RegisterEvent("onConsoleInput", function()
    print("Second handler")
end)

MP.RegisterEvent("onConsoleInput", function()
    print("Third handler")
end)
```

### Anonymous Function Support
Register event handlers using anonymous functions directly:

```lua
-- Traditional named function approach (still works)
function MyHandler()
    print("Named function handler")
end
MP.RegisterEvent("MyCoolCustomEvent", "MyHandler")

-- New anonymous function approach
MP.RegisterEvent("MyCoolCustomEvent", function()
    print("Anonymous function handler")
end)
```

### How It Works
The framework automatically generates unique handler names internally:
- Anonymous functions: `TreeAnonymous_[EventName]_[Counter]`
- Named functions: `[FunctionName]_Tree_[Counter]`

This prevents naming conflicts and allows multiple handlers per event.

## Native Libraries

Place `.dll` (Windows) or `.so` (Linux) files in the `lib/` directory and load them:

```lua
-- Load json.dll on Windows or json.so on Linux
local json = Tree.LoadLib("json")
if json then
    local data = json.encode({hello = "world"})
end
```

**⚠️ Windows Note:** Native library loading is currently not working on Windows due to BeamMP's Lua environment limitations. Waiting for a future BeamMP patch to resolve this issue. Linux support may vary.

## Framework API

The Tree Framework provides a global `Tree` API available to all plugins:

- `Tree.Debug(...)` - Debug logging with table support and color formatting
- `Tree.GetInfo()` - Framework version and loaded plugin information
- `Tree.LoadLib(name)` - Load native library from lib/ directory

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
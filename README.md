# Tree Framework

A lightweight BeamMP plugin framework inspired by FiveM's architecture.

## Features

- **FiveM-like structure** with manifest-driven file loading
- **No require() needed** - automatic global Tree variable sharing
- **Clean organization** with dedicated files directory
- **Minimal overhead** - every line serves a purpose

## Quick Start

1. Place the framework in your BeamMP server's `Resources/Server/` directory
2. Edit `manifest.lua` with your project details
3. Add your scripts to the `files/` directory
4. BeamMP will load everything automatically

## Structure

```
Tree-BeamMP-Plugin/
├── main.lua              # Framework entry point
├── manifest.lua          # Project configuration
├── _tree/                 # Framework internals
└── files/                 # Your scripts go here
    ├── init.lua
    └── modules/
        └── player.lua
```

## Manifest Format

```lua
author = 'Your Name'
description = 'Your BeamMP Project'
version = '1.0.0'

server_scripts = {
    "init.lua",
    "modules/*.lua"
}
```

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

## API

- `Tree.Debug(...)` - Debug logging with table support
- `Tree.GetInfo()` - Framework version and loaded files info
- `Tree.LoadLib(name)` - Load native library from lib/ directory

## Complete Example

A complete example plugin is provided to demonstrate framework usage. To test it:

1. **Copy the ExamplePlugin folder** (located next to Tree-BeamMP-Plugin) to your `Resources/Server/` directory
2. **Restart your BeamMP server** - the Tree Framework will automatically load the plugin
3. **Watch the console** for colorized demonstrations

The example plugin demonstrates:
- ✅ **Global vs Local Variables** - How variables are shared between files
- 🎨 **All BeamMP Color Codes** - Complete demonstration of 16 colors and effects
- 👥 **Player Simulation** - Connections/disconnections with colored counters
- 🐛 **Testing & Debug** - Functions to test variable sharing

```bash
# Example structure:
ExamplePlugin/
├── manifest.lua           # Configuration
└── files/
    ├── init.lua          # Variables + basic colors
    └── modules/
        ├── player.lua    # Variable tests + player management
        └── debug.lua     # Complete tests + simulation
```

**Expected Output:** The plugin automatically displays colorized tests showing that global variables are shared between files but local variables are not, plus a complete demonstration of all available colors.

## License

Licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
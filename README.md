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

## API

- `Tree.Debug(...)` - Debug logging with table support
- `Tree.GetInfo()` - Framework version and loaded files info

## License

Licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
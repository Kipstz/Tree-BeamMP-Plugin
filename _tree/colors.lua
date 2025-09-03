---@meta

Tree = Tree or {}

---Color code support for BeamMP console output
---@class Tree.Colors
Tree.Colors = {}

local originalPrint = print

---BeamMP color code to ANSI escape sequence mapping
local colors = {
    ["^r"] = "\27[0m",     -- reset
    ["^p"] = "\n",         -- newline
    ["^n"] = "\27[4m",     -- underline
    ["^l"] = "\27[1m",     -- bold
    ["^m"] = "\27[9m",     -- strike-through
    ["^o"] = "\27[3m",     -- italic
    ["^0"] = "\27[30m",    -- black
    ["^1"] = "\27[34m",    -- blue
    ["^2"] = "\27[32m",    -- green
    ["^3"] = "\27[96m",    -- light blue
    ["^4"] = "\27[31m",    -- red
    ["^5"] = "\27[95m",    -- pink
    ["^6"] = "\27[33m",    -- orange
    ["^7"] = "\27[37m",    -- grey
    ["^8"] = "\27[90m",    -- dark grey
    ["^9"] = "\27[35m",    -- light purple
    ["^a"] = "\27[92m",    -- light green
    ["^b"] = "\27[94m",    -- light blue
    ["^c"] = "\27[91m",    -- dark orange
    ["^d"] = "\27[93m",    -- light pinks
    ["^e"] = "\27[93m",    -- yellow
    ["^f"] = "\27[97m"     -- white
}

---Initialize color code support by overriding the global print function
function Tree.Colors.init()
    print = function(...)
        local args = {...}
        for i, arg in ipairs(args) do
            if type(arg) == "string" then
                for code, ansi in pairs(colors) do
                    arg = arg:gsub("%"..code, ansi)
                end
                arg = arg .. "\27[0m"
                args[i] = arg
            end
        end
        originalPrint(table.unpack(args))
    end
end
-- Server Configuration
local serverName = "BeamMP Example Server"
local maxPlayers = 8

-- Shared variables (accessible from other files)
PlayerCount = 0
ServerStartTime = os.time()

-- Local variables (private to this file)
local welcomeMessage = "^2Welcome to " .. serverName .. "!^r"

-- Initialize server
print("^6[Server]^r Initializing " .. serverName .. "...")
print("^6[Server]^r Max players: ^2" .. maxPlayers .. "^r")

-- Example of threading
CreateThread(function()
    Wait(1000)
    print("^2[Server]^r Server initialization complete!")
end)
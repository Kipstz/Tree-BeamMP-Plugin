-- Access shared variables from test.lua
print("^6[Events]^r Current player count: ^2" .. PlayerCount .. "^r")
print("^6[Events]^r Server uptime: ^2" .. os.difftime(os.time(), ServerStartTime) .. "s^r")

-- Player event handlers using enhanced event system
MP.RegisterEvent("onPlayerJoin", function(playerID)
    PlayerCount = PlayerCount + 1
    local playerName = MP.GetPlayerName(playerID) or "Unknown"
    print(string.format("^2[Join]^r %s connected (^2%d^r/^28^r players)", playerName, PlayerCount))
end)

MP.RegisterEvent("onPlayerDisconnect", function(playerID)
    PlayerCount = PlayerCount - 1
    local playerName = MP.GetPlayerName(playerID) or "Unknown"
    print(string.format("^4[Leave]^r %s disconnected (^2%d^r/^28^r players)", playerName, PlayerCount))
end)

-- Multiple handlers for the same event (enhanced event system feature)
MP.RegisterEvent("onChatMessage", function(playerID, playerName, message)
    print(string.format("^3[Chat]^r %s: %s", playerName, message))
end)

-- Example of delayed execution
SetTimeout(2000, function()
    print("^6[Events]^r Event handlers registered successfully!")
end)

-- Example: Show color codes
print("^6[Info]^r Framework supports ^2colors^r, ^4styles^r, and ^l^6formatting^r!")
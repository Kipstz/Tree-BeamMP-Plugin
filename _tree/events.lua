---@meta

-- Store original MP.RegisterEvent
local OriginalRegisterEvent = MP and MP.RegisterEvent

-- Counter for unique handler names
local handlerCounter = 0

-- Override MP.RegisterEvent to allow duplicates and anonymous functions
function MP.RegisterEvent(eventName, handlerNameOrFunc)
    if not OriginalRegisterEvent then
        return
    end
    
    -- Generate a unique name every time
    handlerCounter = handlerCounter + 1
    
    local handlerFunc
    local uniqueName
    
    -- Check if it's a function (anonymous) or string (named function)
    if type(handlerNameOrFunc) == "function" then
        -- Anonymous function
        handlerFunc = handlerNameOrFunc
        uniqueName = "TreeAnonymous_" .. eventName .. "_" .. handlerCounter
    elseif type(handlerNameOrFunc) == "string" then
        -- Named function
        handlerFunc = _G[handlerNameOrFunc]
        if not handlerFunc then
            return
        end
        uniqueName = handlerNameOrFunc .. "_Tree_" .. handlerCounter
    else
        return
    end
    
    -- Create the function with unique name
    _G[uniqueName] = handlerFunc
    
    -- Register with the unique name
    OriginalRegisterEvent(eventName, uniqueName)
end
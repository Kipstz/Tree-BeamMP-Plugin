Tree = Tree or {}
Tree.Threads = {}

local threadId = 0
local threads = {}

function CreateThread(func)
    if type(func) ~= "function" then
        print("^1[Tree Framework] Error: CreateThread expects a function^r")
        return
    end
    
    threadId = threadId + 1
    local id = "__thread_" .. threadId
    local handlerName = "__thread_handler_" .. threadId
    
    _G[handlerName] = function()
        func()
        MP.CancelEventTimer(id)
        _G[handlerName] = nil
        threads[id] = nil
    end
    
    threads[id] = _G[handlerName]
    
    MP.RegisterEvent(id, handlerName)
    MP.CreateEventTimer(id, 100)
    
    return threadId
end

function Tree.Threads.getThreads()
    return threads
end

function Tree.Threads.getThreadCount()
    local count = 0
    for _ in pairs(threads) do
        count = count + 1
    end
    return count
end

function SetTimeout(milliseconds, func)
    if type(milliseconds) ~= "number" or milliseconds < 0 then
        print("^1[Tree Framework] Error: SetTimeout expects a positive number for milliseconds^r")
        return
    end
    
    if type(func) ~= "function" then
        print("^1[Tree Framework] Error: SetTimeout expects a function^r")
        return
    end
    
    return CreateThread(function()
        Wait(milliseconds)
        func()
    end)
end

Tree.SetTimeout = SetTimeout
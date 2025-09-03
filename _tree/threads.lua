---@meta

Tree = Tree or {}

---Threading utilities for the Tree Framework
---@class Tree.Threads
Tree.Threads = {}

local threadId = 0
local threads = {}

---Create a new thread that executes a function asynchronously
---@param func function The function to execute in the thread
---@return number threadId The ID of the created thread
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

---Get the registry of active threads
---@return table threads Registry of active thread handlers
function Tree.Threads.getThreads()
    return threads
end

---Get the number of active threads
---@return number count Number of active threads
function Tree.Threads.getThreadCount()
    local count = 0
    for _ in pairs(threads) do
        count = count + 1
    end
    return count
end

---Execute a function after a specified delay
---@param milliseconds number Delay in milliseconds before execution
---@param func function The function to execute after the delay
---@return number|nil threadId The ID of the timeout thread, or nil on error
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
require("utils/utils")

local wakeListeners = {}
local sleepListeners = {}

local function notifyListeners(listeners, eventType)
    for _, listener in ipairs(listeners) do
        listener(eventType)
    end
end

function isScreenLocked()
    -- `not not` casts to boolean (this returns nil if the screen is not locked)
    return not not hs.caffeinate.sessionProperties()["CGSSessionScreenIsLocked"]
end

-- https://github.com/Hammerspoon/hammerspoon/blob/45fa3561a5c8fcbba3ebcef7aff25ed296e49fe9/extensions/caffeinate/libcaffeinate_watcher.m#L76
watcher = hs.caffeinate.watcher.new(function(eventType)
    local eventName = ""
    local isWakeEvent = false
    local isSleepEvent = false

    if eventType == hs.caffeinate.watcher.screensDidUnlock then
        eventName = "Screen Unlocked"
        isWakeEvent = true
    elseif eventType == hs.caffeinate.watcher.screensDidWake then
        eventName = "Screen Woke"
        isWakeEvent = false
    elseif eventType == hs.caffeinate.watcher.systemDidWake then
        eventName = "System Woke"
        isWakeEvent = false
    elseif eventType == hs.caffeinate.watcher.sessionDidBecomeActive then
        eventName = "Session Became Active"
        isWakeEvent = false
    elseif eventType == hs.caffeinate.watcher.screensDidLock then
        eventName = "Screen Locked"
        isSleepEvent = true
    elseif eventType == hs.caffeinate.watcher.screensDidSleep then
        eventName = "Screen Slept"
        isSleepEvent = false
    elseif eventType == hs.caffeinate.watcher.systemWillSleep then
        eventName = "System Will Sleep"
        isSleepEvent = true
    elseif eventType == hs.caffeinate.watcher.sessionDidResignActive then
        eventName = "Session Resigned Active"
        isSleepEvent = false
    end

    if eventName ~= "" then
        log("Caffeinate event: " .. eventName .. ". isWakeEvent: " .. tostring(isWakeEvent) .. ". isSleepEvent: " ..
                tostring(isSleepEvent))
        if isWakeEvent then
            notifyListeners(wakeListeners, eventType)
        elseif isSleepEvent then
            notifyListeners(sleepListeners, eventType)
        end
    end
end)

watcher:start()

function addWakeWatcher(listener)
    table.insert(wakeListeners, listener)
end

function addSleepWatcher(listener)
    table.insert(sleepListeners, listener)
end

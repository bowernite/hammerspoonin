require("utils/utils")

local wakeListeners = {}

local function notifyListeners(eventType)
    for _, listener in ipairs(wakeListeners) do listener(eventType) end
end

-- https://github.com/Hammerspoon/hammerspoon/blob/45fa3561a5c8fcbba3ebcef7aff25ed296e49fe9/extensions/caffeinate/libcaffeinate_watcher.m#L76
watcher = hs.caffeinate.watcher.new(function(eventType)
    local eventName = ""
    if eventType == hs.caffeinate.watcher.screensDidUnlock then
        eventName = "Screen Unlocked"
    elseif eventType == hs.caffeinate.watcher.screensDidWake then
        eventName = "Screen Woke"
    elseif eventType == hs.caffeinate.watcher.systemDidWake then
        eventName = "System Woke"
    elseif eventType == hs.caffeinate.watcher.sessionDidBecomeActive then
        eventName = "Session Became Active"
    end

    if eventName ~= "" then
        log("Caffeinate event: " .. eventName)
        notifyListeners(eventType)
    end
end)

watcher:start()

function addWakeWatcher(listener) table.insert(wakeListeners, listener) end


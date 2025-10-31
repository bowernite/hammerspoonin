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
            if _G.dailyTaskWakeHandlers then
                for _, handler in ipairs(_G.dailyTaskWakeHandlers) do
                    handler()
                end
            end
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

-- Restart the system with different window reopening options
function restartSystem(options)
    options = options or {}
    
    if options.reopenWindows == false then
        -- Restart without reopening windows
        log("Restarting system without reopening windows")
        
        -- First set the preferences to not reopen windows
        hs.execute([[defaults write com.apple.loginwindow TALLogoutSavesState -bool FALSE]])
        hs.execute([[defaults write com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool FALSE]])
        
        -- Then execute the restart command in the background
        hs.execute([[osascript -e 'tell application "System Events" to restart' &> /dev/null &]])
    else
        -- Standard restart with default behavior (will reopen windows)
        log("Restarting system with default behavior (will reopen windows)")
        
        -- First set the preferences to reopen windows
        hs.execute([[defaults write com.apple.loginwindow TALLogoutSavesState -bool TRUE]])
        hs.execute([[defaults write com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool TRUE]])
        
        -- Then restart
        hs.caffeinate.restartSystem()
    end
    
    return true
end

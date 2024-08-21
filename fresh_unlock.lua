require("utils/utils")
require("utils/caffeinate")
require("utils/app_utils")

local function handleSleep()
    logAction("Fresh unlock on sleep")
    hideAllAppsManual()
end

local function handleWake()
    logAction("Fresh unlock on wake")
    hs.timer.doAfter(0.1, function()
        hideAllAppsManual()
    end)
end

local ONE_MINUTE = 60
local throttledSleepHandler = throttle(handleSleep, ONE_MINUTE)
local throttledWakeHandler = throttle(handleWake, ONE_MINUTE)

addSleepWatcher(throttledSleepHandler)
addWakeWatcher(throttledWakeHandler)

-- Function to sleep display and hide apps
local function sleepDisplayAndHideApps()
    throttledSleepHandler()
    logAction("Sleeping display")
    hs.caffeinate.systemSleep()
end

-- Function to hide apps and lock display
local function hideAppsAndLockDisplay()
    throttledSleepHandler()
    logAction("Locking display")
    hs.caffeinate.lockScreen()
end

hs.hotkey.bind({"cmd", "ctrl"}, "w", sleepDisplayAndHideApps)
hs.hotkey.bind({"cmd", "ctrl"}, "q", hideAppsAndLockDisplay)

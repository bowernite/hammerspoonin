require("utils/utils")
require("utils/caffeinate")
require("utils/app_utils")

local lastHideTime = 0
local ONE_MINUTE = 60

local function throttledHideAllApps()
    local currentTime = os.time()
    if currentTime - lastHideTime >= ONE_MINUTE then
        hideAllApps()
        lastHideTime = currentTime
    end
end

addSleepWatcher(throttledHideAllApps)
addWakeWatcher(function() hs.timer.doAfter(0.1, throttledHideAllApps) end)

-- Function to sleep display and hide apps
-- local function sleepDisplayAndHideApps()
--     hideAllApps()
--     logAction("Sleeping display")
--     hs.caffeinate.systemSleep()
-- end

-- -- Function to hide apps and lock display
-- local function hideAppsAndLockDisplay()
--     hideAllApps()
--     logAction("Locking display")
--     hs.caffeinate.lockScreen()
-- end

-- hs.hotkey.bind({"cmd", "ctrl"}, "w", sleepDisplayAndHideApps)
-- hs.hotkey.bind({"cmd", "ctrl"}, "q", hideAppsAndLockDisplay)

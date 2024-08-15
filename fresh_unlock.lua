require("utils/utils")
require("utils/caffeinate")
require("utils/app_utils")

addSleepWatcher(hideAllApps)
addWakeWatcher(
    function() hs.timer.doAfter(0.1, function() hideAllApps() end) end)

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

require("utils/utils")

hs.application.runningApplications()

-- Function to hide all apps
local function hideAllApps()
    log("Hiding all apps")
    local allApps = hs.application.runningApplications()
    for _, app in ipairs(allApps) do app:hide() end
end

-- Function to sleep display and hide apps
local function sleepDisplayAndHideApps()
    hideAllApps()

    log("Sleeping display")
    hs.caffeinate.systemSleep()
end

-- Function to hide apps and lock display
local function hideAppsAndLockDisplay()
    hideAllApps()
    log("Locking display")
    hs.caffeinate.lockScreen()
end

-- Set up hotkey to sleep display and hide apps
hs.hotkey.bind({"cmd", "ctrl"}, "w", sleepDisplayAndHideApps)

-- Set up hotkey to hide apps and lock display
hs.hotkey.bind({"cmd", "ctrl"}, "q", hideAppsAndLockDisplay)

-- addWakeWatcher(hideAllApps)

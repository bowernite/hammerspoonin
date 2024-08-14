require("utils/utils")
require("utils/caffeinate")

hs.application.runningApplications()

-- Function to hide all visible apps
local function hideAllApps()
    local createdNewFinderWindow = false

    -- Create a new Finder window if it doesn't already exist
    logAction("Creating a new Finder window")
    local finderApp = hs.application.get("Finder")
    if not finderApp then
        hs.application.launchOrFocus("Finder")
        createdNewFinderWindow = true
    elseif #finderApp:allWindows() == 0 then
        finderApp:selectMenuItem({"File", "New Finder Window"})
        createdNewFinderWindow = true
    end

    logAction("Hiding all visible apps")
    local visibleApps =
        hs.window.filter.new():setAppFilter("", {visible = true}):getWindows()
    for _, window in ipairs(visibleApps) do
        local app = window:application()

        if app then
            logAction("Hiding app: " .. app:name())
            app:hide()
        end
    end
    -- Hide Hammerspoon
    local hammerspoonApp = hs.application.get("Hammerspoon")
    if hammerspoonApp then
        logAction("Hiding Hammerspoon")
        hammerspoonApp:hide()
    end

    -- Close the Finder window if we created one
    -- if createdNewFinderWindow then
    --     logAction("Closing the Finder window")
    --     finderApp = hs.application.get("Finder")
    --     if finderApp then
    --         local finderWindows = finderApp:allWindows()
    --         if #finderWindows > 0 then finderWindows[1]:close() end
    --     end
    -- end
end

addSleepWatcher(hideAllApps)

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

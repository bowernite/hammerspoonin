require("utils/app_utils")
require("utils/log")
require("boot")
require("utils/utils")

local function resetApps()
    log("Initiating app reset sequence")

    killAppsInDock()

    defaultAppState()
    hs.timer.doAfter(2, function()
        startEssentialApps()
    end)

    closeAllFinderWindows()

    hs.alert.show("Reset apps")
end

local function resetAppsEveryMorning()
    local resetTask = createDailyTask("04:00", function()
        log("Resetting apps after first wake past 4 AM")
        hs.alert.show("Doing morning reset...")
        resetApps()
    end)

    addWakeWatcher(function()
        resetTask()
    end)
end

resetAppsEveryMorning()

hs.hotkey.bind({"cmd", "alt"}, "K", function()
    resetApps()
end)

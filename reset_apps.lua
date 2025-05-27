require("utils/app_utils")
require("utils/log")
require("boot")
require("utils/utils")

local function resetApps()
    log("Initiating app reset sequence")

    killInessentialApps()

    closeAllFinderWindows()

    hs.alert.show("Reset apps")
end

function resetAppsEveryMorning()
    local function resetAppsTask()
        log("Resetting apps after first wake past 4 AM")
        hs.alert.show("Doing morning reset...", 10)
        hs.notify.show("Doing morning reset...", "Resetting apps", "")
        resetApps()

        hs.timer.doAfter(2, function()
            defaultAppState()
        end)

        log("Reset apps complete; returning true")
        return true
    end

    local resetTask = createDailyTask("04:00", resetAppsTask, "Reset apps")

    addWakeWatcher(function()
        resetTask()
    end)
end

hs.hotkey.bind({"cmd", "alt"}, "r", function()
    resetApps()
end)

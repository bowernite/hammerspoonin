require("utils/app_utils")
require("boot")

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
    local hasResetToday = false

    local function resetState()
        log("Reset state triggered")
        hasResetToday = false
    end

    hs.timer.doAt("03:59", "1d", resetState)

    addWakeWatcher(function()
        local currentTime = os.date("*t")
        log("Checking if apps should be reset", {
            hasResetToday = hasResetToday,
            currentTime = currentTime
        })
        if not hasResetToday and currentTime.hour >= 4 then
            log("Resetting apps after first wake past 4 AM")
            hs.alert.show("Doing morning reset...")
            resetApps()
            hasResetToday = true
        end
    end)
end

resetAppsEveryMorning()

hs.hotkey.bind({"cmd", "alt"}, "K", function()
    resetApps()
end)

require("utils/app_utils")
require("utils/log")
require("boot")
require("utils/utils")

function resetApps()
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

    createDailyTask("04:00", resetAppsTask, "Reset apps")
end

-- This doesn't work. Instead, use `hs -c "resetApps()"` from the command line.
-- Register URL handler for resetting apps
-- Usage:
--   From command line: open "resetApps://"
--   From Lua: hs.urlevent.openURL("resetApps://")
-- hs.urlevent.bind("resetApps", function(eventName, params)
--     log("Received resetApps URL event")
--     resetApps()
-- end)
-- Register the URL scheme
-- hs.urlevent.setDefaultHandler("resetApps")


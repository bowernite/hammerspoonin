require("utils/utils")
require("utils/log")
require("utils/caffeinate")

-- Daily restart task between 4am and 12pm
local function restartComputer()
    log("Checking if computer should restart")

    if isWithinTimeWindow("4:00AM", "12:00PM") then
        logAction("Daily restart initiated - restarting computer")
        hs.alert.show("Restarting computer for daily maintenance...", 5)
        hs.timer.doAfter(5, function()
            hs.caffeinate.restartSystem()
        end)
        return true
    else
        log("Outside restart time window, skipping restart")
        return false
    end
end

local dailyRestartTask = createDailyTask("04:00", restartComputer, "Daily computer restart")
addWakeWatcher(function()
    hs.timer.doAfter(3, function()
        dailyRestartTask()
    end)
end)

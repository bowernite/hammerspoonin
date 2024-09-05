require("utils/utils")

local function isWeekend()
    local dayOfWeek = os.date("*t").wday
    return dayOfWeek == 1 or dayOfWeek == 7 -- Sunday is 1, Saturday is 7
end

local function getRestartTime()
    return isWeekend() and "22:30" or "21:10"
end

local function scheduleRestart()
    log("Scheduling restart")
  
    local restartTime = getRestartTime()
    local hour, minute = restartTime:match("(%d+):(%d+)")

    -- Schedule 10-minute warning
    hs.timer.doAt(hour .. ":" .. string.format("%02d", minute - 10), "00", function()
        if not hs.caffeinate.isScreenLocked() then
            logAction("Screen is not locked, sending notification")
            hs.notify.new({
                title = "Computer Restart",
                informativeText = "Computer will restart in 10 minutes"
            }):send()
        end
    end)

    -- Schedule 5-minute warning
    hs.timer.doAt(hour .. ":" .. string.format("%02d", minute - 5), "00", function()
        if not hs.caffeinate.isScreenLocked() then
            logAction("Screen is not locked, sending notification")
            hs.notify.new({
                title = "Computer Restart",
                informativeText = "Computer will restart in 5 minutes"
            }):send()
        end
    end)

    -- Schedule restart
    hs.timer.doAt(restartTime, "00", function()
        log("Nightly restart fired, checking if screen is locked")
        if not hs.caffeinate.isScreenLocked() then
            logAction("Screen is not locked; restarting")
            hs.execute("shutdown -r now")
        end
    end)
end

-- Run the scheduler daily
hs.timer.doEvery(24 * 60 * 60, scheduleRestart)

-- Initial run
scheduleRestart()

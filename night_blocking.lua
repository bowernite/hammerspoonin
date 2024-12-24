require("utils/utils")
require("utils/caffeinate")

local function isWeekendNight()
    local dayOfWeek = os.date("*t").wday
    return dayOfWeek == 6 or dayOfWeek == 7 -- Friday is 6, Saturday is 7
end

local function getRestartTime()
    return isWeekendNight() and "22:30" or "21:10"
end

-- Returns true if the current time is within an hour after the restart time
local function isWithinRestartTimeWindow()
    local restartTime = getRestartTime()
    local restartHour, restartMinute = restartTime:match("(%d+):(%d+)")
    local restartMinutes = tonumber(restartHour) * 60 + tonumber(restartMinute)

    local currentTimeInfo = getCurrentTimeInfo()
    local currentMinutes = currentTimeInfo.hour * 60 + currentTimeInfo.minute

    local timeDifference = (currentMinutes - restartMinutes + 1440) % 1440 -- Ensure positive difference

    log("Checking to see if night_blocking action fired within restart time window", {
        restartTime = restartTime,
        restartMinutes = restartMinutes,
        currentTime = currentTimeInfo.hour .. ":" .. currentTimeInfo.minute,
        currentMinutes = currentMinutes,
        timeDifference = timeDifference
    })

    return timeDifference <= 60 -- Within 60 minutes after restart time
end

function showWarning(timeRemaining)
    if isWithinRestartTimeWindow() then
        hs.alert.show("Computer will restart in " .. tostring(timeRemaining) .. " minutes", 5)
    end
end

local warningTimers = {}
local restartTimer = nil
local dailyScheduleTimer = nil

local function scheduleRestart()
    log("Scheduling restart")

    local restartTime = getRestartTime()
    log("Restart time: " .. restartTime)

    -- Schedule warnings
    local warningTimes = {10, 5, 3, 1}
    local hour, minute = restartTime:match("(%d+):(%d+)")
    for _, warningTime in ipairs(warningTimes) do
        log("Scheduling warning for " .. warningTime .. " minutes before restart")
        warningTimers[warningTime] = hs.timer.doAt(hour .. ":" .. string.format("%02d", tonumber(minute) - warningTime), function()
            -- if not isScreenLocked() then
            logAction("Screen is not locked, sending notification")
            showWarning(warningTime)
            -- end
        end)
    end

    -- Schedule restart
    restartTimer = hs.timer.doAt(restartTime, function()
        log("Nightly restart fired, checking if screen is locked")
        -- if not isScreenLocked() then
        log("Screen is not locked...")
        if not isWithinRestartTimeWindow() then
            log("Not within restart time window, skipping")
            return
        end

        logAction(
            "Brett has been a bad boy... Restarting his computer to keep him honest and keep that melatonin highhhhhh")
        hs.caffeinate.restartSystem()
        -- end
    end)
end

-- Run the scheduler daily
dailyScheduleTimer = hs.timer.doEvery(24 * 60 * 60, scheduleRestart)

-- Initial run
scheduleRestart()

-- hs.caffeinate.restartSystem()

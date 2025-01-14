require("utils/log")

function isProcessRunning(processName)
    local command = "pgrep " .. processName
    local output = hs.execute(command)
    return output ~= ""
end

function killProcess(processName)
    if isProcessRunning(processName) then
        log("💀 " .. processName .. " is running; killing")
        hs.execute("pkill -f '" .. processName .. "'")
    end
end

function getCurrentTimeInfo()
    local currentTime = os.time()
    local currentDate = os.date("*t", currentTime)
    local currentHour = currentDate.hour
    local currentMinute = currentDate.min
    return {
        time = currentTime,
        hour = currentHour,
        minute = currentMinute
    }
end

function parseTime(timeString)
    local hour, minute, period = timeString:match("(%d+):?(%d*)%s*([AaPp]?[Mm]?)")
    hour = tonumber(hour)
    minute = tonumber(minute) or 0

    if period then
        if period:lower() == "pm" and hour ~= 12 then
            hour = hour + 12
        elseif period:lower() == "am" and hour == 12 then
            hour = 0
        end
    end

    return hour * 60 + minute
end

function isWithinTimeWindow(startTime, endTime)
    local timeInfo = getCurrentTimeInfo()
    local currentMinutes = timeInfo.hour * 60 + timeInfo.minute
    local startMinutes = parseTime(startTime)
    local endMinutes = parseTime(endTime)

    log(string.format("Time window check: Start=%s (%d), End=%s (%d), Current=%02d:%02d (%d)", startTime, startMinutes,
        endTime, endMinutes, timeInfo.hour, timeInfo.minute, currentMinutes))
    if startMinutes < endMinutes then
        return currentMinutes >= startMinutes and currentMinutes <= endMinutes
    else
        return currentMinutes >= startMinutes or currentMinutes <= endMinutes
    end
end

function isNighttime()
    return isWithinTimeWindow("5pm", "5am")
end

function poll(fn, intervalInSeconds, maxAttempts, onMaxAttemptsReached)
    maxAttempts = maxAttempts or 3
    local attempts = 0
    local timer

    local function executeAndSchedule()
        if attempts < maxAttempts then
            if fn() then
                if timer then
                    timer:stop()
                end
                return
            end
            attempts = attempts + 1
            timer = hs.timer.doAfter(intervalInSeconds, executeAndSchedule)
        else
            if timer then
                timer:stop()
            end
            if onMaxAttemptsReached then
                onMaxAttemptsReached()
            end
        end
    end

    executeAndSchedule()
end

-- Throttle a function to run at most once per cooldown period
-- @param cooldownPeriod Number of seconds between allowed function calls
function throttle(func, cooldownPeriod)
    local lastCallTime = 0
    return function()
        local currentTime = os.time()
        if currentTime - lastCallTime >= cooldownPeriod then
            func()
            lastCallTime = currentTime
        end
    end
end

-- Initialize global table for timers if it doesn't exist. Timers are stored in this table to prevent garbage collection.
_G.dailyTaskTimers = _G.dailyTaskTimers or {}

function createDailyTask(resetTime, taskFunction, taskName)
    local hasRunToday = false
    local resetTimer = nil

    local function resetState()
        log("Reset state triggered")
        hasRunToday = false
    end

    resetTimer = hs.timer.doAt(resetTime, "1d", resetState)
    table.insert(_G.dailyTaskTimers, resetTimer)

    return function()
        local currentTime = os.date("*t")
        local resetHour = tonumber(resetTime:match("(%d+):"))
        log("Checking if daily task should run", {
            hasRunToday = hasRunToday,
            currentTime = string.format("%02d:%02d", currentTime.hour, currentTime.min),
            resetHour = resetHour,
            taskName = taskName
        })
        if not hasRunToday and currentTime.hour >= resetHour then
            log("Attempting to run daily task")
            local result = taskFunction()
            log("Daily task result", {
                result = tostring(result)
            })
            if result then
                hasRunToday = true
                log("Daily task ran successfully (" .. taskName .. ")")
                hs.notify.show("Daily task ran successfully", taskName, "")
            end
        end
    end
end

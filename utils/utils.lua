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

    log(string.format("Time window check: Start=%s (%d), End=%s (%d), Current=%02d:%02d (%d)", 
        startTime, startMinutes, endTime, endMinutes,
        timeInfo.hour, timeInfo.minute, currentMinutes))
    if startMinutes < endMinutes then
        return currentMinutes >= startMinutes and currentMinutes <= endMinutes
    else
        return currentMinutes >= startMinutes or currentMinutes <= endMinutes
    end
end

function isNighttime()
    return isWithinTimeWindow("7pm", "5am")
end

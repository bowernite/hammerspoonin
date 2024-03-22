function isProcessRunning(processName)
    local command = "pgrep " .. processName
    local output = hs.execute(command)
    return output ~= ""
end

function killProcess(processName)
    log("🔆 Checking if " .. processName .. " is running")
    if isProcessRunning(processName) then
        log("🔆 " .. processName .. " is running; killing")
        hs.execute("pkill -f '" .. processName .. "'")
    else
        log("🔆 " .. processName .. " not running")
    end
end

function isNighttime()
    local nighttimeStartTime = 19 * 60 * 60 -- 7pm in seconds
    local nighttimeEndTime = 5 * 60 * 60 -- 5am in seconds

    local currentTime = os.time()
    local currentHour = os.date("*t", currentTime).hour
    local currentSeconds = currentHour * 60 * 60 +
                               os.date("*t", currentTime).min * 60 +
                               os.date("*t", currentTime).sec

    return currentSeconds >= nighttimeStartTime or currentSeconds <=
               nighttimeEndTime
end

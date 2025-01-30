function logToFile(message, filename)
    -- Ensure logs directory exists
    os.execute("mkdir -p logs")

    filename = filename or "hammerspoon.log"

    -- Try to open file in append mode first
    local logFile = io.open("logs/" .. filename, "a")
    if not logFile then
        -- If that fails, try to create the file
        logFile = io.open("logs/" .. filename, "w")
    end

    if logFile then
        local month = os.date("%m"):gsub("^0", "")
        local day = os.date("%d"):gsub("^0", "")
        local hour = os.date("%I"):gsub("^0", "")
        local min = os.date("%M")
        local sec = os.date("%S")
        local ampm = os.date("%p"):lower()
        local timestamp = string.format("[%s/%s %s:%s:%s%s]", month, day, hour, min, sec, ampm)
        logFile:write(string.format("%s %s\n", timestamp, message))
        logFile:close()
    end
end

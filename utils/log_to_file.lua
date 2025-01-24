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
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        logFile:write(string.format("[%s] %s\n", timestamp, message))
        logFile:close()
    end
end

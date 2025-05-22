-- Log cleanup utilities for Hammerspoon
-- Handles automatic and manual cleanup of log files older than 24 hours
local RETENTION_HOURS = 24

-- Function to parse timestamp from log line and return time in seconds since epoch
local function parseLogTimestamp(timestampStr)
    -- Extract components from format [month/day hour:min:secampm]
    local month, day, hour, min, sec, ampm = timestampStr:match("%[(%d+)/(%d+) (%d+):(%d+):(%d+)([ap]m)%]")

    if not month then
        return nil
    end

    -- Convert to 24-hour format
    hour = tonumber(hour)
    if ampm == "pm" and hour ~= 12 then
        hour = hour + 12
    elseif ampm == "am" and hour == 12 then
        hour = 0
    end

    -- Get current year (since logs don't include year)
    local currentYear = tonumber(os.date("%Y"))

    -- Create time table
    local timeTable = {
        year = currentYear,
        month = tonumber(month),
        day = tonumber(day),
        hour = hour,
        min = tonumber(min),
        sec = tonumber(sec)
    }

    return os.time(timeTable)
end

-- Function to clean up a single log file by removing entries older than specified hours
local function cleanupSingleFile(filename)
    local filepath = "logs/" .. filename
    local file = io.open(filepath, "r")
    if not file then
        return false, 0
    end

    local lines = {}
    local currentTime = os.time()
    local cutoffTime = currentTime - (RETENTION_HOURS * 60 * 60)
    local removedLines = 0

    -- Read all lines and filter out old ones
    for line in file:lines() do
        local timestampMatch = line:match("^(%[%d+/%d+ %d+:%d+:%d+[ap]m%])")
        if timestampMatch then
            local logTime = parseLogTimestamp(timestampMatch)
            if logTime and logTime >= cutoffTime then
                table.insert(lines, line)
            else
                removedLines = removedLines + 1
            end
        else
            -- Keep non-timestamped lines if we have recent timestamped lines
            if #lines > 0 then
                table.insert(lines, line)
            else
                removedLines = removedLines + 1
            end
        end
    end
    file:close()

    -- Write back the filtered lines
    file = io.open(filepath, "w")
    if file then
        for _, line in ipairs(lines) do
            file:write(line .. "\n")
        end
        file:close()
        return true, removedLines
    end

    return false, 0
end

-- Function to clean up all log files in the logs directory
function cleanupAllLogFiles()
    local handle = io.popen("find logs -name '*.log' -type f 2>/dev/null")
    if not handle then
        return 0, 0
    end

    local cleanedFiles = 0
    local totalRemoved = 0

    for filepath in handle:lines() do
        local filename = filepath:match("logs/(.+)")
        if filename then
            local success, removedLines = cleanupSingleFile(filename)
            if success then
                cleanedFiles = cleanedFiles + 1
                totalRemoved = totalRemoved + removedLines
            end
        end
    end
    handle:close()

    return cleanedFiles, totalRemoved
end

-- Function to clean up a specific log file
function cleanupLogFile(filename)
    return cleanupSingleFile(filename)
end

-- Function to get cleanup statistics without actually cleaning
function getCleanupStats()
    local handle = io.popen("find logs -name '*.log' -type f 2>/dev/null")
    if not handle then
        return 0, 0, 0
    end

    local totalFiles = 0
    local totalOldLines = 0
    local totalLines = 0
    local currentTime = os.time()
    local cutoffTime = currentTime - (RETENTION_HOURS * 60 * 60)

    for filepath in handle:lines() do
        local filename = filepath:match("logs/(.+)")
        if filename then
            local file = io.open("logs/" .. filename, "r")
            if file then
                totalFiles = totalFiles + 1
                for line in file:lines() do
                    totalLines = totalLines + 1
                    local timestampMatch = line:match("^(%[%d+/%d+ %d+:%d+:%d+[ap]m%])")
                    if timestampMatch then
                        local logTime = parseLogTimestamp(timestampMatch)
                        if logTime and logTime < cutoffTime then
                            totalOldLines = totalOldLines + 1
                        end
                    else
                        -- Count continuation lines as old if we haven't seen recent timestamped lines
                        totalOldLines = totalOldLines + 1
                    end
                end
                file:close()
            end
        end
    end
    handle:close()

    return totalFiles, totalOldLines, totalLines
end

-- Function to manually clean up all log files and provide feedback
function cleanupLogs()
    local cleanedFiles, totalRemoved = cleanupAllLogFiles()

    -- Use print since we don't want to depend on the log module here
    print("🧹 Cleaned up log files older than 24 hours - Files processed: " .. cleanedFiles .. ", Lines removed: " ..
              totalRemoved)
    return cleanedFiles, totalRemoved
end

-- Function to show cleanup statistics without actually cleaning
function showCleanupStats()
    local totalFiles, oldLines, totalLines = getCleanupStats()
    local percentSavings = totalLines > 0 and (oldLines / totalLines * 100) or 0

    print("🧹 Log cleanup statistics - Files: " .. totalFiles .. ", Total lines: " .. totalLines .. ", Old lines: " ..
              oldLines .. ", Potential savings: " .. string.format("%.1f%%", percentSavings))
    return totalFiles, oldLines, totalLines
end

-- Make functions available globally
_G.cleanupAllLogFiles = cleanupAllLogFiles
_G.cleanupLogFile = cleanupLogFile
_G.getCleanupStats = getCleanupStats
_G.cleanupLogs = cleanupLogs
_G.showCleanupStats = showCleanupStats

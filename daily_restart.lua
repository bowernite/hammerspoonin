require("utils/utils")
require("utils/log")
require("utils/caffeinate")

-- Set up persistence directory
local function setupPersistenceDir()
    -- Use a local persistence directory in the repository
    local persistence_dir = "persistence"
    
    -- Ensure the directory exists - using pcall for error handling
    local success, err = pcall(function() 
        return hs.fs.mkdir(persistence_dir) 
    end)
    
    -- Check if directory exists or was created successfully
    if (not success or not err) and not hs.fs.attributes(persistence_dir) then
        logError("Failed to create persistence directory: " .. (type(err) == "string" and err or "unknown error"))
        -- Fallback to Hammerspoon config directory
        persistence_dir = hs.configdir .. "/persistence"
        log("Using fallback directory for persistence: " .. persistence_dir)
        
        -- Try to create the fallback directory
        success, err = pcall(function() return hs.fs.mkdir(persistence_dir) end)
        if (not success or not err) and not hs.fs.attributes(persistence_dir) then
            logError("Failed to create fallback persistence directory: " .. (type(err) == "string" and err or "unknown error"))
            -- Ultimate fallback to temp directory
            persistence_dir = os.getenv("TMPDIR") or "/tmp"
            log("Using temporary directory for persistence: " .. persistence_dir)
        end
    else
        log("Using persistence directory: " .. persistence_dir)
    end
    
    return persistence_dir
end

-- Set up persistence - using local variables
local persistence_dir = setupPersistenceDir()
local restart_log_file = persistence_dir .. "/restart_log.json"
log("Using restart log file: " .. restart_log_file)

-- Function to check if restart already occurred today
local function hasRestartedToday()
    -- Check if restart log file exists
    if not hs.fs.attributes(restart_log_file) then
        log("No restart log file found")
        return false
    end
    
    -- Read restart log file using protected call
    local success, file = pcall(function() return io.open(restart_log_file, "r") end)
    if not success or not file then
        log("Failed to open restart log file: " .. (type(file) == "string" and file or "unknown error"))
        return false
    end
    
    -- Read file contents with error handling
    local content = file:read("*all")
    file:close()
    
    if not content or content == "" then
        log("Restart log file is empty")
        return false
    end
    
    local success, data = pcall(function() return hs.json.decode(content) end)
    if not success or not data then
        log("Failed to parse restart log file: " .. (type(data) == "string" and data or "unknown error"))
        return false
    end
    
    -- Check if data has the expected format
    if type(data) ~= "table" or type(data.lastRestartDate) ~= "string" then
        log("Invalid data format in restart log file")
        return false
    end
    
    -- Check if last restart date is today
    local today = os.date("%Y-%m-%d")
    if data.lastRestartDate == today then
        log("Already restarted today: " .. today)
        return true
    end
    
    return false
end

-- Function to record today's restart
local function recordRestart()
    local today = os.date("%Y-%m-%d")
    local data = {lastRestartDate = today}
    
    -- Use protected call for file operations
    local success, file = pcall(function() return io.open(restart_log_file, "w") end)
    if not success or not file then
        logError("Failed to write restart log file: " .. (type(file) == "string" and file or "unknown error"))
        return false
    end
    
    -- Encode data with error handling
    local success, encoded = pcall(function() return hs.json.encode(data) end)
    if not success or not encoded then
        logError("Failed to encode restart data: " .. (type(encoded) == "string" and encoded or "unknown error"))
        file:close()
        return false
    end
    
    file:write(encoded)
    file:close()
    log("Recorded restart for today: " .. today)
    return true
end

-- Daily restart task between 4am and 12pm
local function restartComputer()
    log("Checking if computer should restart")

    -- Check if we already restarted today
    if hasRestartedToday() then
        log("Already performed daily restart today, skipping")
        return false
    end
    
    -- Only restart if within specified time window (4am to 12pm)
    if isWithinTimeWindow("4:00AM", "10:00PM") then
        logAction("Daily restart initiated - restarting computer")
        
        -- Record the restart before actually restarting
        if not recordRestart() then
            logError("Failed to record restart, continuing anyway")
        end
        
        -- Show alert and schedule restart
        hs.alert.show("Restarting computer for daily maintenance...", 5)
        hs.timer.doAfter(5, function()
            -- Use our new restart utility with reopenWindows set to false
            restartSystem({reopenWindows = false})
        end)
        return true
    else
        log("Outside restart time window, skipping restart")
        return false
    end
end

-- Create the daily task with error handling
local dailyRestartTask = createDailyTask("04:00", restartComputer, "Daily computer restart")

-- Add wake watcher with protected execution
local wakeWatcherID = addWakeWatcher(function()
    hs.timer.doAfter(3, function()
        local success, result = pcall(dailyRestartTask)
        if not success then
            logError("Error running daily restart task: " .. tostring(result))
        end
    end)
end)

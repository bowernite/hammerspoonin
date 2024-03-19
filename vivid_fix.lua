require("log_utils")

local function isProcessRunning(processName)
    local command = "pgrep " .. processName
    local output = hs.execute(command)
    return output ~= ""
end

local function restartVividApp()
    log("Checking if Vivid app is running")
    if not isProcessRunning("Vivid") then
        log("Vivid app not running")
    else
        log("Vivid app is running; killing")
      
        hs.execute("pkill -f 'Vivid'")
        -- Wait for the app to fully terminate before attempting to restart
        hs.timer.usleep(500000) -- 0.5 seconds
    end
    
    log("Starting Vivid App")
    hs.application.open("/Applications/Vivid.app")
end

-- Screen watcher to detect screen changes
local screenWatcher = hs.screen.watcher.newWithActiveScreen(function(
    activeChanged)
    if not activeChanged then
        -- A screen was disconnected
        -- Introduce a delay before restarting to prevent a loop
        hs.timer.doAfter(1, function() restartVividApp() end)
    end
end)

screenWatcher:start()

-- Delay initial restart to prevent potential loop at startup
hs.timer.doAfter(1, function() restartVividApp() end)

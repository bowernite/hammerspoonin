require("log_utils")

local function isProcessRunning(processName)
    local command = "pgrep " .. processName
    local output = hs.execute(command)
    return output ~= ""
end

local function killProcess(processName)
    log("🔆 Checking if " .. processName .. " is running")
    if isProcessRunning(processName) then
        log("🔆 " .. processName .. " is running; killing")
        hs.execute("pkill -f '" .. processName .. "'")
        -- Wait for the app to fully terminate before attempting to restart
        hs.timer.usleep(500000) -- 0.5 seconds
    else
        log("🔆 " .. processName .. " not running")
    end
end

local function restartVividApp()
    killProcess("Vivid")

    log("🔆 Starting Vivid App")
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

local function ensureFluxRunning()
    local fluxStartTime = 19 * 60 * 60 -- 7pm in seconds
    local fluxEndTime = 5 * 60 * 60 -- 5am in seconds

    local currentTime = os.time()
    local currentHour = os.date("*t", currentTime).hour
    local currentSeconds = currentHour * 60 * 60 +
                               os.date("*t", currentTime).min * 60 +
                               os.date("*t", currentTime).sec

    -- Check if current time is within the Flux running period
    if (currentSeconds >= fluxStartTime or currentSeconds <= fluxEndTime) then
        if not isProcessRunning("Flux") then
            log(
                "🔆🕯️ Flux is not running during its allowed time; starting Flux")
            hs.execute("open -a Flux")
        else
            log("🔆🕯️ Flux is already running as expected")
        end
    else
        if isProcessRunning("Flux") then
            log(
                "🔆🕯️ Flux is running outside its allowed time; killing Flux")
            killProcess("Flux")
            -- Restart Vivid app whenever we kill Flux
            restartVividApp()
        else
            log(
                "🔆🕯️ Flux is not running outside its allowed time, as expected")
        end
    end
end

-- Check Flux status every minute to ensure it's running or killed as per the schedule
fluxTimer = hs.timer.doEvery(60, ensureFluxRunning)
ensureFluxRunning()


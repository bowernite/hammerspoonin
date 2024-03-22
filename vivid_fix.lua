require("log_utils")
require("utils")

local function restartVividApp()
    killProcess("Vivid")

    -- Wait for the app to fully terminate before attempting to restart
    hs.timer.usleep(500000) -- 0.5 seconds

    log("🔆 Starting Vivid App")
    hs.application.open("Vivid")
end

local function startFluxOrVivid()
    if isNighttime() then
        if not isProcessRunning("Flux") then
            log(
                "🔆🕯️ Flux is not running during its allowed time; starting Flux")
            hs.execute("open -a Flux")
        else
            log("🔆🕯️ Flux is already running as expected")
        end

        killProcess("Vivid")
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

-- Screen watcher to detect screen changes and prevent potential loop by limiting restarts
local lastRestart = os.time()
local screenWatcher = hs.screen.watcher.newWithActiveScreen(function(
    activeChanged)
    if not activeChanged and os.difftime(os.time(), lastRestart) > 5 then
        -- A screen was disconnected and it's been more than 5 seconds since the last restart
        lastRestart = os.time() -- Update the last restart time
        -- Introduce a delay before restarting to prevent a loop
        hs.timer.doAfter(1, function()
            if not isNighttime() then restartVividApp() end
        end)
    end
end)

screenWatcher:start()

-- Delay initial restart to prevent potential loop at startup
hs.timer.doAfter(1,
                 function() if not isNighttime() then restartVividApp() end end)

-- Check Flux status every minute to ensure it's running or killed as per the schedule
fluxTimer = hs.timer.doEvery(60, startFluxOrVivid)
startFluxOrVivid()


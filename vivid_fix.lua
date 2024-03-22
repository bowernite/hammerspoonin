require("log_utils")
require("utils")

local function killAndRestartApp(appName, delayBeforeRestart)
    killProcess(appName)

    -- Wait for the app to fully terminate before attempting to restart
    hs.timer.usleep(delayBeforeRestart)

    log("🔆 Starting " .. appName)
    hs.application.open(appName)
end

local function handleFluxState()
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
            killAndRestartApp("Vivid", 500000) -- Restart Vivid app whenever we kill Flux
        else
            log(
                "🔆🕯️ Flux is not running outside its allowed time, as expected")
        end
    end
end

local function restartVividIfNotNighttime()
    if not isNighttime() then killAndRestartApp("Vivid", 500000) end
end

-- Screen watcher to detect screen changes and prevent potential loop by limiting restarts
local lastRestart = os.time()
local screenWatcher = hs.screen.watcher.newWithActiveScreen(function(
    activeChanged)
    if not activeChanged and os.difftime(os.time(), lastRestart) > 5 then
        lastRestart = os.time() -- Update the last restart time
        hs.timer.doAfter(1, restartVividIfNotNighttime)
    end
end)

screenWatcher:start()

-- Delay initial restart to prevent potential loop at startup
hs.timer.doAfter(1, restartVividIfNotNighttime)

-- Check Flux status every minute to ensure it's running or killed as per the schedule
fluxTimer = hs.timer.doEvery(600, handleFluxState)
handleFluxState()


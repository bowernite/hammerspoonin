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
        end
        killProcess("Vivid")
    else
        if isProcessRunning("Flux") then
            log(
                "🔆🕯️ Flux is running outside its allowed time; killing Flux")
            killProcess("Flux")
            killAndRestartApp("Vivid", 500000) -- Restart Vivid app whenever we kill Flux
        end
    end
end

local function restartVividIfNotNighttime()
    if not isNighttime() then killAndRestartApp("Vivid", 500000) end
end

-- Screen watcher to restart Vivid when a monitor is disconnected
local screenWatcher = hs.screen.watcher.new(function()
    local screenCount = #hs.screen.allScreens()
    if screenCount < previousScreenCount then
        log("🔆 Monitor disconnected; preparing to restart Vivid.")
        hs.timer.doAfter(5, function() restartVividIfNotNighttime() end)
    end
    previousScreenCount = screenCount
end)
previousScreenCount = #hs.screen.allScreens()

screenWatcher:start()

-- Delay initial restart to prevent potential loop at startup
-- hs.timer.doAfter(1, function()
--     log(
--         "🔆 Initiating delayed restart of Vivid to prevent potential loop at startup")
--     restartVividIfNotNighttime()
-- end)

-- Check Flux status every minute to ensure it's running or killed as per the schedule
fluxTimer = hs.timer.doEvery(600, handleFluxState)
handleFluxState()


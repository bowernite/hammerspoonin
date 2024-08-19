require("utils/log")
require("utils/utils")
require("utils/caffeinate")

-- Parameters:
--   appName (string): The name of the application to restart.
--   delayBeforeRestart (number): The delay before restarting the application, in milliseconds (1 second = 1,000 milliseconds).
local function killAndRestartApp(appName, delayBeforeRestart)
    delayBeforeRestart = delayBeforeRestart or 500 -- Default to 500 milliseconds if not specified
    killProcess(appName)

    -- Wait for the app to fully terminate before attempting to restart
    hs.timer.usleep(delayBeforeRestart * 1000) -- Convert milliseconds to microseconds

    log("🔆 Starting " .. appName)
    hs.application.open(appName)
end

hs.urlevent.bind("killAndRestartApp", function(eventName, params)
    killAndRestartApp(params["appName"], tonumber(params["delayBeforeRestart"]))
end)

local function handleFluxState()
    log("Handle flux state")
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
            killAndRestartApp("Vivid") -- Restart Vivid app whenever we kill Flux
        end
    end
end

local function restartVividIfNotNighttime()
    if not isNighttime() then killAndRestartApp("Vivid") end
end

-- Screen watcher to restart Vivid when switching to built-in display
local BUILTIN_DISPLAY_NAME = "Built-in Retina Display"

local function isPrimaryDisplayBuiltIn()
    local primaryDisplay = hs.screen.primaryScreen()
    log("Checking if primary display is built-in",
        {primaryDisplay = primaryDisplay})
    return primaryDisplay and primaryDisplay:name() == BUILTIN_DISPLAY_NAME
end

local wasPrimaryDisplayBuiltIn = isPrimaryDisplayBuiltIn()

local function handlePowerSourceChange()
    local isPrimaryBuiltIn = isPrimaryDisplayBuiltIn()
    log("Power source changed; checking to see if we need to restart Vivid.", {
        isPrimaryBuiltIn = isPrimaryBuiltIn,
        wasPrimaryDisplayBuiltIn = wasPrimaryDisplayBuiltIn
    })

    if isPrimaryBuiltIn and not wasPrimaryDisplayBuiltIn then
        log("🔆 Switched to built-in display; preparing to restart Vivid.")
        hs.timer.doAfter(2, function() restartVividIfNotNighttime() end)
    end

    wasPrimaryDisplayBuiltIn = isPrimaryBuiltIn
end

powerWatcher = hs.battery.watcher.new(function()
    if not hs.battery.powerSource() == "Battery Power" then
        handlePowerSourceChange()
    end
end)

powerWatcher:start()

log("Screen watcher started",
    {isPrimaryDisplayBuiltIn = wasPrimaryDisplayBuiltIn})

handleFluxState()
-- Check Flux status every minute to ensure it's running or killed as per the schedule
fluxTimer = hs.timer.doEvery(600, handleFluxState)
addWakeWatcher(handleFluxState)

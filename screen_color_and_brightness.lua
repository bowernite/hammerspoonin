require("utils/log")
require("utils/utils")
require("utils/caffeinate")
require("utils/screen_utils")

local eventtap = hs.eventtap

--   delayBeforeRestart (number): The delay before restarting the application, in milliseconds (1 second = 1,000 milliseconds).
local function killAndRestartApp(appName, delayBeforeRestart)
    delayBeforeRestart = delayBeforeRestart or 500 -- Default to 500 milliseconds if not specified
    killProcess(appName)

    -- Wait for the app to fully terminate before attempting to restart
    hs.timer.usleep(delayBeforeRestart * 1000) -- Convert milliseconds to microseconds

    log("Starting " .. appName)
    hs.application.open(appName)
end

hs.urlevent.bind("killAndRestartApp", function(eventName, params)
    killAndRestartApp(params["appName"], tonumber(params["delayBeforeRestart"]))
end)

local function handleFluxState()
    log("Handle flux state")
    if isNighttime() then
        if not isProcessRunning("Flux") then
            log("🕯️ Flux is not running during its allowed time; starting Flux")
            hs.execute("open -a Flux")
        end
        killProcess("Vivid")
    else
        if isProcessRunning("Flux") then
            log("🕯️ Flux is running outside its allowed time; killing Flux")
            killProcess("Flux")
            killAndRestartApp("Vivid") -- Restart Vivid app whenever we kill Flux
        end
    end
end

local function restartVividIfNotNighttime()
    if not isNighttime() then
        killAndRestartApp("Vivid")
    end
end

local wasPrimaryDisplayBuiltIn = isPrimaryDisplayBuiltIn()

local function handlePowerSourceChange()
    local isPrimaryBuiltIn = isPrimaryDisplayBuiltIn()
    log("Power source changed; checking to see if we need to restart Vivid.", {
        isPrimaryBuiltIn = isPrimaryBuiltIn,
        wasPrimaryDisplayBuiltIn = wasPrimaryDisplayBuiltIn
    })

    if isPrimaryBuiltIn and not wasPrimaryDisplayBuiltIn then
        log("Switched to built-in display; preparing to restart Vivid.")
        hs.timer.doAfter(2, function()
            restartVividIfNotNighttime()
        end)
    end

    wasPrimaryDisplayBuiltIn = isPrimaryBuiltIn
end

powerWatcher = hs.battery.watcher.new(function()
    if not hs.battery.powerSource() == "Battery Power" then
        handlePowerSourceChange()
    end
end)

powerWatcher:start()

log("Screen watcher started", {
    isPrimaryDisplayBuiltIn = wasPrimaryDisplayBuiltIn
})

handleFluxState()
restartVividIfNotNighttime()

-- Check Flux status every minute to ensure it's running or killed as per the schedule
FLUX_CHECK_TIMER = hs.timer.doEvery(60, handleFluxState)
addWakeWatcher(handleFluxState)

local function maxOutBrightness()
    log("Screen unlocked; checking to see if we need to max out brightness", {
        isNighttime = isNighttime(),
        isPrimaryDisplayBuiltIn = isPrimaryDisplayBuiltIn()
    })
    if not isNighttime() and not isPrimaryDisplayBuiltIn() then
        logAction("Screen unlocked during daytime; maxing out brightness")
        for _, screen in ipairs(hs.screen.allScreens()) do
            -- Doesn't work on external monitor. Maybe because of MonitorControl / that it's not an Apple display, so it doesn't support native brightness?
            -- https://github.com/Hammerspoon/hammerspoon/issues/2342
            -- screen:setBrightness(1)

            for i = 1, 16 do -- Assuming 16 steps is enough to reach max brightness
                hs.eventtap.event.newSystemKeyEvent("BRIGHTNESS_UP", true):post()
                hs.eventtap.event.newSystemKeyEvent("BRIGHTNESS_UP", false):post()
            end

            -- Return true to indicate that the task has been completed, so we don't need to run it again today
            return true
        end
    end

    return false
end

local maxOutBrightnessTask = createDailyTask("05:00", maxOutBrightness, "Max out brightness (external monitor)")

addWakeWatcher(function()
    -- temp: see if this fixes an issue where this doesn't work properly
    hs.timer.doAfter(3, function()
        maxOutBrightnessTask()
    end)
end)

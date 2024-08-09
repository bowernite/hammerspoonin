--[[
    morning_space.lua

    A Hammerspoon module that encourages mindful mornings by temporarily
    limiting computer access between 6:30 AM and 9:30 AM.

    Features:
    - Blocks input for a set delay (default 90 seconds)
    - Offers shutdown option
    - Test mode for debugging (activate with Cmd+Alt+T)

    Components:
    - Delay timers and time windows
    - Screen overlay and input blockers
    - Message display and shutdown functionality

    Note: Requires appropriate Hammerspoon permissions.
]] --
require("utils")
require("log_utils")

local morningDelay = 10 -- 1.5 minutes in seconds
local testModeDelay = 10 -- 10 seconds for test mode
local startTime = "6:30AM"
local endTime = "9:30AM"
local lastDelayTime = 0 -- Time of the last delay application
local isTestMode = false -- Flag to enable test mode
local activeOverlay = nil
local activeKeyboardBlocker = nil
local activeMouseTimer = nil
local activeDelayMessage = nil

-- Define test mode key combo
local testModeKeyCombo = {mods = {"cmd", "alt"}, key = "t"}

local function showDelayMessage()
    log("Showing delay message")
    local message = hs.alert.show("🌅 Good morning! Have some space 😌",
                                  hs.screen.mainScreen(), 150)
    activeDelayMessage = message
    return message
end

local function removeDelayMessage()
    log("Removing delay message")
    if activeDelayMessage then
        hs.alert.closeSpecific(activeDelayMessage)
        activeDelayMessage = nil
    end
end

local function offerShutdown()
    log("Offering shutdown option")
    local result = hs.dialog.blockAlert("Morning Routine",
                                        "Would you like to shut down instead of waiting?",
                                        "Shut Down", "Wait")
    if result == "Shut Down" then
        if not isTestMode then
            log("User chose to shut down")
            hs.caffeinate.shutdownSystem()
        else
            log("Test Mode: Simulating shutdown")
            hs.alert.show("Test Mode: System would shut down here")
        end
    else
        log("User chose to wait")
    end
end

local function createFullScreenOverlay()
    log("Creating full screen overlay")
    local canvas = hs.canvas.new(hs.screen.mainScreen():fullFrame())
    canvas:appendElements({
        type = "rectangle",
        action = "fill",
        fillColor = {red = 0, green = 0, blue = 0, alpha = 0.8}
    })
    canvas:show()
    return canvas
end

local function clearActiveBlocking()
    log("Clearing active blocking")
    if activeOverlay then
        activeOverlay:delete()
        activeOverlay = nil
    end
    if activeKeyboardBlocker then
        activeKeyboardBlocker:stop()
        activeKeyboardBlocker = nil
    end
    if activeMouseTimer then
        activeMouseTimer:stop()
        activeMouseTimer = nil
    end
    removeDelayMessage()
    if isTestMode then
        isTestMode = false
        log("Test Mode: Disabled")
        hs.alert.show("Test Mode: Disabled")
    end
end

local function applyMorningDelay()
    log("Applying morning delay")

    local currentTimeInfo = getCurrentTimeInfo()
    local currentTime = currentTimeInfo.time

    local timeSinceLastDelay = currentTime - lastDelayTime
    local delay = isTestMode and testModeDelay or morningDelay

    local isWithinTimeWindow = isWithinTimeWindow(startTime, endTime)
    local isEnoughTimeSinceLastDelay = timeSinceLastDelay >= 5400
    local shouldApplyDelay = isWithinTimeWindow and isEnoughTimeSinceLastDelay
    if shouldApplyDelay or isTestMode then
        log("Delay conditions met, applying delay")
        local message = showDelayMessage()
        -- offerShutdown()

        activeOverlay = createFullScreenOverlay()
        activeKeyboardBlocker = hs.eventtap.new({
            hs.eventtap.event.types.keyDown
        }, function(event)
            local flags = event:getFlags()
            local keyCode = event:getKeyCode()

            -- Allow the test mode key combo to pass through
            if flags:containExactly(testModeKeyCombo.mods) and keyCode ==
                hs.keycodes.map[testModeKeyCombo.key] then
                log("Test mode key combo detected, allowing input")
                return false
            end

            -- Block all other keyboard input
            log("Blocking keyboard input")
            return true
        end)
        activeKeyboardBlocker:start()

        hs.timer.doAfter(delay, function()
            log("Delay timer finished, clearing blocking")
            clearActiveBlocking()
        end)

        -- Move mouse to center every second
        activeMouseTimer = hs.timer.doEvery(1, function()
            local screen = hs.screen.mainScreen()
            local center = hs.geometry.rectMidPoint(screen:fullFrame())
            hs.mouse.absolutePosition(center)
        end)

        lastDelayTime = currentTime
    else
        log("Delay conditions not met, skipping delay")
    end
end

hs.caffeinate.watcher.new(function(eventType)
    log("Morning Space: Caffeinate watcher event: " .. eventType)
    if eventType == hs.caffeinate.watcher.screensDidUnlock or eventType ==
        hs.caffeinate.watcher.screensDidWake then
        log("Screen unlocked or system woke, applying morning delay")
        applyMorningDelay()
    end
end):start()

-- Function to toggle test mode
local function toggleTestMode()
    if isTestMode then
        log("Disabling test mode")
        clearActiveBlocking()
    else
        log("Enabling test mode")
        isTestMode = true
        hs.alert.show("Test Mode: Enabled")
        applyMorningDelay()
    end
end

-- Bind a hotkey to toggle test mode using the defined key combo
hs.hotkey.bind(testModeKeyCombo.mods, testModeKeyCombo.key, toggleTestMode)

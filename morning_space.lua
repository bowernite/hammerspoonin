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
local morningDelay = 90 -- 1.5 minutes in seconds
local testModeDelay = 10 -- 10 seconds for test mode
local startTime = 6.5 * 3600 -- 6:30 AM in seconds
local endTime = 9.5 * 3600 -- 9:30 AM in seconds
local lastDelayTime = 0 -- Time of the last delay application
local isTestMode = false -- Flag to enable test mode
local activeOverlay = nil
local activeKeyboardBlocker = nil
local activeMouseTimer = nil
local activeDelayMessage = nil

-- Define test mode key combo
local testModeKeyCombo = {mods = {"cmd", "alt"}, key = "t"}

local function showDelayMessage()
    print("Showing delay message")
    local message = hs.alert.show("🌅 Good morning! Have some space 😌",
                                  hs.screen.mainScreen(), 150)
    activeDelayMessage = message
    return message
end

local function removeDelayMessage()
    print("Removing delay message")
    if activeDelayMessage then
        hs.alert.closeSpecific(activeDelayMessage)
        activeDelayMessage = nil
    end
end

local function offerShutdown()
    print("Offering shutdown option")
    local result = hs.dialog.blockAlert("Morning Routine",
                                        "Would you like to shut down instead of waiting?",
                                        "Shut Down", "Wait")
    if result == "Shut Down" then
        if not isTestMode then
            print("User chose to shut down")
            hs.caffeinate.shutdownSystem()
        else
            print("Test Mode: Simulating shutdown")
            hs.alert.show("Test Mode: System would shut down here")
        end
    else
        print("User chose to wait")
    end
end

local function createFullScreenOverlay()
    print("Creating full screen overlay")
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
    print("Clearing active blocking")
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
        print("Test Mode: Disabled")
        hs.alert.show("Test Mode: Disabled")
    end
end

local function applyMorningDelay()
    print("Applying morning delay")
    local currentTime = os.time()
    print("Current time: " .. tostring(currentTime))
    
    -- Get the current date and time in the local time zone
    local currentDate = os.date("*t")
    local secondsSinceMidnight = currentDate.hour * 3600 + currentDate.min * 60 + currentDate.sec
    print("Seconds since midnight: " .. tostring(secondsSinceMidnight))

    local timeSinceLastDelay = currentTime - lastDelayTime
    local delay = isTestMode and testModeDelay or morningDelay

    local isWithinTimeWindow = secondsSinceMidnight >= startTime and
                                   secondsSinceMidnight <= endTime
    local isEnoughTimeSinceLastDelay = timeSinceLastDelay >= 5400
    local shouldApplyDelay = isWithinTimeWindow and isEnoughTimeSinceLastDelay
    print("isWithinTimeWindow: " .. tostring(isWithinTimeWindow))
    print("isEnoughTimeSinceLastDelay: " .. tostring(isEnoughTimeSinceLastDelay))
    print("shouldApplyDelay: " .. tostring(shouldApplyDelay))
    if shouldApplyDelay or isTestMode then
        print("Delay conditions met, applying delay")
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
                print("Test mode key combo detected, allowing input")
                return false
            end

            -- Block all other keyboard input
            print("Blocking keyboard input")
            return true
        end)
        activeKeyboardBlocker:start()

        hs.timer.doAfter(delay, function() 
            print("Delay timer finished, clearing blocking")
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
        print("Delay conditions not met, skipping delay")
    end
end

hs.caffeinate.watcher.new(function(eventType)
    if eventType == hs.caffeinate.watcher.screensDidUnlock or
       eventType == hs.caffeinate.watcher.screensDidWake or
       eventType == hs.caffeinate.watcher.systemDidWake then
        print("Screen unlocked or system woke, applying morning delay")
        applyMorningDelay()
    end
end):start()

-- Function to toggle test mode
local function toggleTestMode()
    if isTestMode then
        print("Disabling test mode")
        clearActiveBlocking()
    else
        print("Enabling test mode")
        isTestMode = true
        hs.alert.show("Test Mode: Enabled")
        applyMorningDelay()
    end
end

-- Bind a hotkey to toggle test mode using the defined key combo
hs.hotkey.bind(testModeKeyCombo.mods, testModeKeyCombo.key, toggleTestMode)

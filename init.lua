hs.console.clearConsole()

-- Utility function to format screen dimensions
local function formatScreenDimensions(screen)
    local screenFrame = screen:frame()
    return string.format("%s (Dimensions: w=%d, h=%d)", screen:name(), screenFrame.w, screenFrame.h)
end

-- Utility function to format window dimensions and coordinates
local function formatWindowDimensions(window)
    local windowFrame = window:frame()
    return string.format("%s (Dimensions: w=%d, h=%d, Coordinates: x=%d, y=%d)", window:application():name(), windowFrame.w, windowFrame.h, windowFrame.x, windowFrame.y)
end

-- Modified Emoji log function
function emojiLog(message, oldScreen, currentScreen, window)
    if window and window:application():name() ~= "Clock" then
        return
    end
    local logMessage = "\n🔍 " .. message
    if oldScreen then
        logMessage = logMessage .. " | Old Screen: " .. formatScreenDimensions(oldScreen)
    end
    if currentScreen then
        logMessage = logMessage .. " | Current Screen: " .. formatScreenDimensions(currentScreen)
    end
    if window then
        logMessage = logMessage .. " | " .. formatWindowDimensions(window)
    end
    hs.console.printStyledtext(logMessage)
end

-- Global variables to keep track of window and screen information
windowScreenMap = {}
screenDimensions = {}
centeredWindows = {} -- Dictionary to keep track of centered windows

-- Function to check if a window is centered on its screen
function isWindowCentered(window)
    local windowFrame = window:frame()
    local screenFrame = window:screen():frame()
    -- Adjusting the window's coordinates relative to its current screen
    local windowCenter = {x = windowFrame.x - screenFrame.x + windowFrame.w / 2, y = windowFrame.y - screenFrame.y + windowFrame.h / 2}
    local screenCenter = {x = screenFrame.w / 2, y = screenFrame.h / 2}
    local isCentered = math.abs(windowCenter.x - screenCenter.x) < 1 and math.abs(windowCenter.y - screenCenter.y) < 1
    emojiLog("Window Centered Check: " .. tostring(isCentered), nil, window:screen(), window)
    return isCentered
end

-- Function to update window screen map, screen dimensions, and centered windows
function updateWindowScreenMapAndCenteredWindows()
    local allWindows = hs.window.allWindows()
    for _, window in ipairs(allWindows) do
        local windowID, screenID = window:id(), window:screen():id()
        windowScreenMap[windowID] = screenID
        -- Update screen dimensions
        local screenFrame = window:screen():frame()
        screenDimensions[screenID] = {w = screenFrame.w, h = screenFrame.h}
        -- Update centered windows
        centeredWindows[windowID] = isWindowCentered(window)
    end
end

-- Abstraction for finding the full screen object for the last screen a window was on
local function findOldScreen(windowID)
    local previousScreenID = windowScreenMap[windowID]
    local oldScreen = hs.screen.find(previousScreenID)
    if oldScreen then
        emojiLog("Old screen found", oldScreen, nil, window)
    else
        emojiLog("Old screen not found", nil, nil, window)
    end
    return oldScreen
end

-- Abstraction for updating windowScreenMap for a specific window
local function updateWindowScreenMap(windowID, currentScreenID)
    emojiLog("Updating windowScreenMap for windowID: " .. tostring(windowID) .. " | New Screen ID: " .. tostring(currentScreenID), nil, nil, nil)
    windowScreenMap[windowID] = currentScreenID
end

-- Function to maximize window if moved to a new screen and was maximized
function maximizeWindowOnNewScreen(window)
    local windowID, currentScreenID = window:id(), window:screen():id()
    local oldScreen = findOldScreen(windowID)
    
    if currentScreenID ~= windowScreenMap[windowID] then
        local newScreen = hs.screen.find(currentScreenID)
        emojiLog(window:application():name() .. " - " .. window:title() .. " moved", oldScreen, newScreen, window)
        
        local wasMaximized = screenDimensions[windowScreenMap[windowID]] and window:frame().w == screenDimensions[windowScreenMap[windowID]].w and window:frame().h == screenDimensions[windowScreenMap[windowID]].h
        if wasMaximized then
            emojiLog("Was Maximized ✅")
            window:maximize(0) -- Pass 0 to disable animation
            return
        end
        
        -- Check if the window was centered using the centeredWindows dictionary
        if centeredWindows[windowID] then
            emojiLog("Was Centered✅")
            window:centerOnScreen(currentScreen, false, 0) -- Center on the new screen without animation
            centeredWindows[windowID] = true
        end
    end
    -- Update the window's screen ID in the map and check if it's centered
    updateWindowScreenMap(windowID, currentScreenID)
    centeredWindows[windowID] = isWindowCentered(window)
end

-- Watch for window events
windowWatcher = hs.window.filter.new(nil)
windowWatcher:subscribe(hs.window.filter.windowCreated, function(window)
    emojiLog("Window created", nil, window:screen(), window)
    updateWindowScreenMapAndCenteredWindows()
    maximizeWindowOnNewScreen(window)
end)
windowWatcher:subscribe(hs.window.filter.windowMoved, function(window)
    emojiLog("Window moved", nil, window:screen(), window)

    local windowID = window:id()
    local oldScreen = findOldScreen(windowID)
    emojiLog("Window moved", oldScreen, window:screen(), window)
    maximizeWindowOnNewScreen(window)

    -- Update windowScreenMap when a window moves
    updateWindowScreenMap(windowID, window:screen():id())
end)

-- Initialize
updateWindowScreenMapAndCenteredWindows()
emojiLog("Hammerspoon initialized and window screen map updated")

-----------------------------------------------------------------------------------------------
-- Check Ethernet and Toggle Wifi
-----------------------------------------------------------------------------------------------

function networkChangedCallback()
    local ethernetInterface = "en6" -- Change to your Ethernet interface identifier
    local wifiInterface = "en0" -- Change to your WiFi interface identifier
    local ethernetActive = hs.network.interfaceDetails(ethernetInterface) and hs.network.interfaceDetails(ethernetInterface).IPv4
    local wifiPower = hs.wifi.interfaceDetails(wifiInterface) and hs.wifi.interfaceDetails(wifiInterface).power

    emojiLog("🌐 Network Status: Ethernet Interface - " .. ethernetInterface .. ", WiFi Interface - " .. wifiInterface)
    emojiLog("🌐 Network Status: Ethernet Active - " .. tostring(ethernetActive) .. ", WiFi Power - " .. tostring(wifiPower))

    if ethernetActive and wifiPower then
        -- Ethernet is connected and WiFi is on, turn off WiFi
        hs.wifi.setPower(false, wifiInterface)
        hs.notify.new({title="🌐 Network Status", informativeText="🔌 Ethernet connected. 📶 WiFi turned off."}):send()
        emojiLog("🌐 Network Status: 🔌 Ethernet connected. 📶 WiFi turned off.")
    elseif not ethernetActive and not wifiPower then
        -- Ethernet is disconnected and WiFi is off, turn on WiFi
        hs.wifi.setPower(true, wifiInterface)
        hs.notify.new({title="🌐 Network Status", informativeText="🔌 Ethernet disconnected. 📶 WiFi turned on."}):send()
        emojiLog("🌐 Network Status: 🔌 Ethernet disconnected. 📶 WiFi turned on.")
    end
end

wifiWatcher = hs.network.reachability.internet():setCallback(networkChangedCallback):start()

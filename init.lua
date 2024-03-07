hs.console.clearConsole()

-- Modified Emoji log function
function emojiLog(message, screen, window)
    if window and window:application():name() ~= "Clock" then
        return
    end
    local logMessage = "\n🔍 " .. message
    if screen then
        local screenName = screen:name()
        local screenFrame = screen:frame()
        logMessage = logMessage .. string.format(" | Screen: %s (Dimensions: w=%d, h=%d)", screenName, screenFrame.w, screenFrame.h)
    end
    if window then
        local appName = window:application():name()
        local windowFrame = window:frame()
        logMessage = logMessage .. string.format(" | %s (Dimensions: w=%d, h=%d, Coordinates: x=%d, y=%d)", appName, windowFrame.w, windowFrame.h, windowFrame.x, windowFrame.y)
    end
    hs.console.printStyledtext(logMessage)
end

-- Global variables to keep track of window and screen information
windowScreenMap = {}
screenDimensions = {}

-- Function to update window screen map and screen dimensions
function updateWindowScreenMap()
    local allWindows = hs.window.allWindows()
    for _, window in ipairs(allWindows) do
        local windowID = window:id()
        local screen = window:screen()
        local screenID = screen:id()
        windowScreenMap[windowID] = screenID
        -- Update screen dimensions
        local screenFrame = screen:frame()
        screenDimensions[screenID] = {w = screenFrame.w, h = screenFrame.h}
    end
end

-- Function to maximize window if moved to a new screen and was maximized
function maximizeWindowOnNewScreen(window)
    local windowID = window:id()
    local currentScreen = window:screen()
    local currentScreenID = currentScreen:id()
    local previousScreenID = windowScreenMap[windowID]
    
    if currentScreenID ~= previousScreenID then
        local windowName = window:title()
        local appName = window:application():name()
        local oldScreenName = hs.screen.find(previousScreenID) and hs.screen.find(previousScreenID):name() or "unknown"
        local newScreenName = hs.screen.find(currentScreenID) and hs.screen.find(currentScreenID):name() or "unknown"
        emojiLog(appName .. " - " .. windowName .. " moved from " .. oldScreenName .. " to " .. newScreenName, currentScreen, window)
        local wasMaximized = screenDimensions[previousScreenID] and window:frame().w == screenDimensions[previousScreenID].w and window:frame().h == screenDimensions[previousScreenID].h
        emojiLog("Was Maximized: " .. tostring(wasMaximized), nil, window)
        if wasMaximized then
            emojiLog(appName .. " - " .. windowName .. " was maximized on the previous screen, maximizing on the new screen", currentScreen, window)
            window:maximize()
        end
    end
    -- Update the window's screen ID in the map
    windowScreenMap[windowID] = currentScreenID
end

-- Watch for window events
windowWatcher = hs.window.filter.new(nil)
windowWatcher:subscribe(hs.window.filter.windowCreated, function(window)
    local screen = window:screen()
    emojiLog("Window created", screen, window)
    updateWindowScreenMap()
    maximizeWindowOnNewScreen(window)
end)
windowWatcher:subscribe(hs.window.filter.windowMoved, function(window)
    local screen = window:screen()
    emojiLog("Window moved", screen, window)
    maximizeWindowOnNewScreen(window)
end)

-- Initialize
updateWindowScreenMap()
emojiLog("Hammerspoon initialized and window screen map updated")

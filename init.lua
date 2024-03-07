hs.console.clearConsole()

-- Modified Emoji log function
function emojiLog(message, oldScreen, currentScreen, window)
    if window and window:application():name() ~= "Clock" then
        return
    end
    local logMessage = "\n🔍 " .. message
    if oldScreen then
        local oldScreenName = oldScreen:name()
        local oldScreenFrame = oldScreen:frame()
        logMessage = logMessage .. string.format(" | Old Screen: %s (Dimensions: w=%d, h=%d)", oldScreenName, oldScreenFrame.w, oldScreenFrame.h)
    end
    if currentScreen then
        local currentScreenName = currentScreen:name()
        local currentScreenFrame = currentScreen:frame()
        logMessage = logMessage .. string.format(" | Current Screen: %s (Dimensions: w=%d, h=%d)", currentScreenName, currentScreenFrame.w, currentScreenFrame.h)
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
centeredWindows = {} -- Dictionary to keep track of centered windows

-- Function to check if a window is centered on its screen
function isWindowCentered(window)
    local windowFrame = window:frame()
    local screenFrame = window:screen():frame()
    -- Adjusting the window's coordinates relative to its current screen
    local windowCenterX = windowFrame.x - screenFrame.x + (windowFrame.w / 2)
    local windowCenterY = windowFrame.y - screenFrame.y + (windowFrame.h / 2)
    local screenCenterX = screenFrame.w / 2
    local screenCenterY = screenFrame.h / 2
    local isCenteredHorizontally = math.abs(windowCenterX - screenCenterX) < 1
    local isCenteredVertically = math.abs(windowCenterY - screenCenterY) < 1
    emojiLog("Window Centered Check: Horizontal -> " .. tostring(isCenteredHorizontally) .. ", Vertical -> " .. tostring(isCenteredVertically), nil, window:screen(), window)
    return isCenteredHorizontally and isCenteredVertically
end

-- Function to update window screen map, screen dimensions, and centered windows
function updateWindowScreenMapAndCenteredWindows()
    local allWindows = hs.window.allWindows()
    for _, window in ipairs(allWindows) do
        local windowID = window:id()
        local screen = window:screen()
        local screenID = screen:id()
        windowScreenMap[windowID] = screenID
        -- Update screen dimensions
        local screenFrame = screen:frame()
        screenDimensions[screenID] = {w = screenFrame.w, h = screenFrame.h}
        -- Update centered windows
        centeredWindows[windowID] = isWindowCentered(window)
    end
end

-- Function to maximize window if moved to a new screen and was maximized
function maximizeWindowOnNewScreen(window)
    local windowID = window:id()
    local currentScreen = window:screen()
    local currentScreenID = currentScreen:id()
    local previousScreenID = windowScreenMap[windowID]
    local oldScreen = hs.screen.find(previousScreenID)
    local newScreen = hs.screen.find(currentScreenID)
    
    if currentScreenID ~= previousScreenID then
        local windowName = window:title()
        local appName = window:application():name()
        local oldScreenName = oldScreen and oldScreen:name() or "unknown"
        local newScreenName = newScreen and newScreen:name() or "unknown"
        emojiLog(appName .. " - " .. windowName .. " moved from " .. oldScreenName .. " to " .. newScreenName, oldScreen, newScreen, window)
        local wasMaximized = screenDimensions[previousScreenID] and window:frame().w == screenDimensions[previousScreenID].w and window:frame().h == screenDimensions[previousScreenID].h
        emojiLog("Was Maximized: " .. tostring(wasMaximized), oldScreen, newScreen, window)
        if wasMaximized then
            emojiLog(appName .. " - " .. windowName .. " was maximized on the previous screen, maximizing on the new screen", oldScreen, newScreen, window)
            window:maximize(0) -- Pass 0 to disable animation
        end
        
        -- Check if the window was centered using the centeredWindows dictionary
        local wasCentered = centeredWindows[windowID]
        emojiLog("Was Centered: " .. tostring(wasCentered), oldScreen, newScreen, window)
        
        if wasCentered then
            emojiLog(appName .. " - " .. windowName .. " was centered on the previous screen, centering on the new screen", oldScreen, newScreen, window)
            local screenFrame = currentScreen:fullFrame()
            local menuBarHeight = currentScreen:frame().y - screenFrame.y
            window:setFrame({
                x = screenFrame.x + (screenFrame.w - window:frame().w) / 2,
                y = screenFrame.y + menuBarHeight + (screenFrame.h - menuBarHeight - window:frame().h) / 2,
                w = window:frame().w,
                h = window:frame().h
            }, 0) -- Pass 0 to disable animation
            centeredWindows[windowID] = true
        end
    end
    -- Update the window's screen ID in the map and check if it's centered
    windowScreenMap[windowID] = currentScreenID
    centeredWindows[windowID] = isWindowCentered(window)
end

-- Watch for window events
windowWatcher = hs.window.filter.new(nil)
windowWatcher:subscribe(hs.window.filter.windowCreated, function(window)
    local screen = window:screen()
    emojiLog("Window created", nil, screen, window)
    updateWindowScreenMapAndCenteredWindows()
    maximizeWindowOnNewScreen(window)
end)
windowWatcher:subscribe(hs.window.filter.windowMoved, function(window)
    local screen = window:screen()
    emojiLog("Window moved", nil, screen, window)
    maximizeWindowOnNewScreen(window)
end)

-- Initialize
updateWindowScreenMapAndCenteredWindows()
emojiLog("Hammerspoon initialized and window screen map updated")

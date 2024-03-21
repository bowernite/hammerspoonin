require("log_utils")
require("windows/window_utils")

hs.window.animationDuration = 0

BLACKLIST_RULES = {{app = "Alfred", window = "Alfred"}, {app = "Vivid"}}

-- Function to check if a window is blacklisted
function isWindowBlacklisted(window)
    local appName = window:application():name()
    local windowName = window:title()

    if not isMainWindow(window) then
        log("Not a main window: ", {window})
        return true
    end

    for _, rule in ipairs(BLACKLIST_RULES) do
        if appName == rule.app and
            (not rule.window or windowName == rule.window) then
            return true
        end
    end
    return false
end

windowScreenMap = {}
centeredWindows = {} -- Dictionary to keep track of centered windows
maximizedWindows = {} -- Dictionary to keep track of maximized windows

function updateWindowScreenMap(window)
    if isWindowBlacklisted(window) then return end

    local windowID = window:id()
    local screenID = window:screen():id()
    windowScreenMap[windowID] = screenID
end

-- Function to check if a window is centered on its screen
function isWindowCentered(window)
    if isWindowBlacklisted(window) then return end

    local windowFrame = window:frame()
    local screenFrame = window:screen():frame()
    -- Adjusting the window's coordinates relative to its current screen
    local windowCenter = {
        x = windowFrame.x - screenFrame.x + windowFrame.w / 2,
        y = windowFrame.y - screenFrame.y + windowFrame.h / 2
    }
    local screenCenter = {x = screenFrame.w / 2, y = screenFrame.h / 2}
    local isCentered = math.abs(windowCenter.x - screenCenter.x) < 1 and
                           math.abs(windowCenter.y - screenCenter.y) < 1
    log("Window Centered Check: ",
        {window, screen = window:screen(), isCentered})
    return isCentered
end

-- Function to update window screen map, screen dimensions, centered and maximized windows
function initWindowStates()
    local allWindows = hs.window.allWindows()
    for _, window in ipairs(allWindows) do
        if isWindowBlacklisted(window) then return end

        updateWindowScreenMap(window)

        -- Update centered windows
        centeredWindows[window:id()] = isWindowCentered(window)

        -- Update maximized windows
        local screenFrame = window:screen():frame()
        maximizedWindows[window:id()] = isWindowMaximized(window)
    end
end

function maximizeWindow(window)
    if isWindowBlacklisted(window) then
        log("Exiting due to blacklisted window", {window})
        return
    end

    log("Maximizing window", {window})

    window:setTopLeft({x = 0, y = 0})
    hs.timer.doAfter(0.25, function() window:maximize() end)

    local checkMaximized = function()
        local maximized = window:isFullScreen() or
                              (window:frame().w == window:screen():frame().w and
                                  window:frame().h == window:screen():frame().h)
        if maximized then
            log("Window is maximized as expected", {window})
            return true -- Stop the timer if the window is maximized
        else
            log("Window is not maximized as expected, correcting", {window})
            window:maximize()
        end
    end

    local timer
    timer = hs.timer.doEvery(1, function()
        if checkMaximized() then timer:stop() end
    end)

    hs.timer.doAfter(10, function() timer:stop() end) -- Stop checking after 10 seconds

    maximizedWindows[window:id()] = true
end

function centerWindowOnNewScreen(window)
    if isWindowBlacklisted(window) then
        log("Exiting due to blacklisted window", {window})
        return
    end

    log("Centering window", {window})
    window:centerOnScreen(currentScreen, false, 0) -- Center on the new screen without animation
    centeredWindows[window:id()] = true
end

-- Function to maximize window if moved to a new screen and was maximized
function maximizeWindowOnNewScreenIfNecessary(window)
    local appName = window:application():name()
    local windowName = window:title()
    if isWindowBlacklisted(window) then
        log("Exiting due to blacklisted window", {window})
        return
    end

    local windowID, currentScreenID = window:id(), window:screen():id()

    local oldScreenID = windowScreenMap[windowID]
    log("Checking to see if window moved", {
        oldScreenID = oldScreenID,
        currentScreenID = currentScreenID,
        window = window
    })
    local windowIsOnNewScreenOrInitialScreen = currentScreenID ~= oldScreenID
    if windowIsOnNewScreenOrInitialScreen then
        log("Window is on a new screen or initial screen")
        local newScreen = hs.screen.find(currentScreenID)

        if maximizedWindows[windowID] then
            log("Was Maximized ✅")
            maximizeWindow(window)
            return
        end

        -- Just center all windows when they move screens
        -- This will have to change if/when we start to do fancy proportional stuff, like with split windows and whatnot
        local windowMovedScreens = oldScreenID ~= nil
        if windowMovedScreens then
            log("Window moved screens; centering window", {window})
            window:centerOnScreen(currentScreen, false, 0) -- Center on the new screen without animation
            centeredWindows[windowID] = true
        end
    end

    -- Update the window's screen ID in the map and check if it's centered
    centeredWindows[windowID] = isWindowCentered(window)
end

-- Watch for window events
windowWatcher = hs.window.filter.new(nil)

windowWatcher:subscribe(hs.window.filter.windowCreated, function(window)
    log("Window created", {window, screen = window:screen()})
    maximizeWindowOnNewScreenIfNecessary(window)

    -- Maximize windows for specific apps
    -- WIP
    -- local app = window:application():name()
    -- if app == "Google Chrome" or app == "Notion Calendar" or app == "kitty" or
    --     app == "Trello" then
    --     if window:title() ~= "" then
    --         if app == "superwhisper" then
    --             window:centerOnScreen(nil, true, 0)
    --         else
    --             maximizeWindow(window)
    --         end
    --     else
    --         log("Skipped maximizing due to empty window title", {app})
    --     end
    -- end

    updateWindowScreenMap(window)
end)

windowWatcher:subscribe(hs.window.filter.windowMoved, function(window)
    local windowID = window:id()
    log("Window moved", {window, screen = window:screen()})
    maximizeWindowOnNewScreenIfNecessary(window)

    updateWindowScreenMap(window)

    maximizedWindows[windowID] = isWindowMaximized(window)
end)

-- Initialize
initWindowStates()


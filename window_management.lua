require("log_utils")

hs.window.animationDuration = 0

windowScreenMap = {}
centeredWindows = {} -- Dictionary to keep track of centered windows
maximizedWindows = {} -- Dictionary to keep track of maximized windows

function updateWindowScreenMap(windowID, screenID)
    windowScreenMap[windowID] = screenID
end

-- Function to check if a window is centered on its screen
function isWindowCentered(window)
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
        local windowID = window:id()

        updateWindowScreenMap(windowID, window:screen():id())

        -- Update centered windows
        centeredWindows[windowID] = isWindowCentered(window)

        -- Update maximized windows
        local screenFrame = window:screen():frame()
        maximizedWindows[windowID] = window:isFullScreen() or
                                         (window:frame().w == screenFrame.w and
                                             window:frame().h == screenFrame.h)
    end
end

function maximizeWindow(window)
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

    local timer = hs.timer.doEvery(1, function()
        if checkMaximized() then
            timer:stop()
        end
    end)

    hs.timer.doAfter(10, function() timer:stop() end) -- Stop checking after 10 seconds

    maximizedWindows[window:id()] = true
end

function centerWindowOnNewScreen(window)
    log("Centering window", {window})
    window:centerOnScreen(currentScreen, false, 0) -- Center on the new screen without animation
    centeredWindows[windowID] = true
end

-- Function to maximize window if moved to a new screen and was maximized
function maximizeWindowOnNewScreenIfNecessary(window)
    local appName = window:application():name()
    local windowName = window:title()
    if appName == 'Alfred' and windowName == 'Alfred' then
        log("Exiting due to Alfred window", {window})
        return
    end

    local windowID, currentScreenID = window:id(), window:screen():id()

    if currentScreenID ~= windowScreenMap[windowID] then
        local newScreen = hs.screen.find(currentScreenID)

        if maximizedWindows[windowID] then
            log("Was Maximized ✅")
            maximizeWindow(window)
            return
        end

        -- Just center all windows when they move screens
        -- This will have to change if/when we start to do fancy proportional stuff, like with split windows and whatnot
        local appName = window:application():name()
        if appName ~= 'Remotasks' and appName ~= 'Remotasks Helper' then
            log("Centering window", {window})
            window:centerOnScreen(currentScreen, false, 0) -- Center on the new screen without animation
            centeredWindows[windowID] = true
        end

        -- Check if the window was centered using the centeredWindows dictionary
        -- if centeredWindows[windowID] then
        --     log("Was Centered✅")
        --     window:centerOnScreen(currentScreen, false, 0) -- Center on the new screen without animation
        --     centeredWindows[windowID] = true
        -- end
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
    local app = window:application():name()
    if app == "Google Chrome" or app == "Notion Calendar" or app == "kitty" or
        app == "Trello" then
        if window:title() ~= "" then
            if app == "superwhisper" then
                window:centerOnScreen(nil, true, 0)
            else
                maximizeWindow(window)
            end
        else
            log("Skipped maximizing due to empty window title", {app})
        end
    end

    updateWindowScreenMap(window:id(), window:screen():id())
end)

windowWatcher:subscribe(hs.window.filter.windowMoved, function(window)
    local windowID = window:id()
    log("Window moved", {window, screen = window:screen()})
    maximizeWindowOnNewScreenIfNecessary(window)

    updateWindowScreenMap(window:id(), window:screen():id())
end)

-- Initialize
initWindowStates()


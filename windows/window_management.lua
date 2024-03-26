require("log_utils")
require("windows/window_utils")

hs.window.animationDuration = 0

BLACKLIST_RULES = {
    {app = "Alfred", window = "Alfred"}, {app = "Vivid"}, {app = "Remotasks"},
    {app = "Remotasks Helper"}, {app = "Calculator"},
    {app = "Captive Network Assistant"}, {window = "Software Update"},
    {app = "Security Agent"}
}

-- Function to check if a window is blacklisted
function isWindowBlacklisted(window)
    local appName = window:application():name()
    local windowName = window:title()

    if not isMainWindow(window) then
        -- log("Not a main window: ", {window})
        return true
    end

    for _, rule in ipairs(BLACKLIST_RULES) do
        if (not rule.app or appName == rule.app) and
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

-- Function to update window screen map, screen dimensions, centered and maximized windows
function initWindowStates()
    local allWindows = hs.window.allWindows()
    for _, window in ipairs(allWindows) do
        if not isWindowBlacklisted(window) then
            updateWindowScreenMap(window)

            -- Update centered windows
            centeredWindows[window:id()] = isWindowCentered(window)

            -- Update maximized windows
            maximizedWindows[window:id()] = isWindowMaximized(window)
        end
    end
end

function adjustWindowIfNecessary(window)
    local appName = window:application():name()
    local windowName = window:title()
    if isWindowBlacklisted(window) then
        log("Exiting due to blacklisted window", {window})
        return
    end

    local windowID, currentScreenID = window:id(), window:screen():id()

    local oldScreenID = windowScreenMap[windowID]
    log("Checking to see if window moved screens", {
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
            centerWindow(window)
        end
    end

    -- Update the window's screen ID in the map and check if it's centered
    centeredWindows[windowID] = isWindowCentered(window)
end

-- Watch for window events
windowWatcher = hs.window.filter.new(nil)

function setDefaultWindowSize(window)
    local appName = window:application():name()
    local defaultSizes = {
        ["Finder"] = {w = 800, h = 600},
        ["Notes"] = {w = 1000, h = 1000},
        ["System Settings"] = {w = 800, h = 600},
        ["Reminders"] = {w = 700, h = 600},
        ["Clock"] = {w = 650, h = 670},
        ["Bear"] = {w = 1000, h = 1000},
        ["Messages"] = {w = 1000, h = 800},
        ["Contacts"] = {w = 700, h = 700}
    }

    -- log("App Name: " .. appName)
    if defaultSizes[appName] then
        log("Default size found for app")
        local size = defaultSizes[appName]
        window:setSize(size)
        centerWindow(window)
    else
        if not maximizeWindow(window) then centerWindow(window) end
    end
end

windowWatcher:subscribe(hs.window.filter.windowCreated, function(window)
    if isWindowBlacklisted(window) then return end

    log("Window created", {window, screen = window:screen()})

    updateWindowScreenMap(window)

    setDefaultWindowSize(window)

    -- adjustWindowIfNecessary(window)

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
end)

windowWatcher:subscribe(hs.window.filter.windowMoved, function(window)
    if isWindowBlacklisted(window) then return end

    log("Window moved", {window, screen = window:screen()})

    updateWindowScreenMap(window)

    adjustWindowIfNecessary(window)

    local windowID = window:id()
    maximizedWindows[windowID] = isWindowMaximized(window)
end)

-- Initialize
initWindowStates()


require("utils/log")
require("windows/window_utils")
require("windows/default_window_sizes")
require("windows/window_blacklist")
require("utils/caffeinate")

windowScreenMap = {}
centeredWindows = {}
maximizedWindows = {}

local function updateWindowScreenMap(window)
    if isWindowBlacklisted(window) then
        return
    end

    local windowID = window:id()
    local screenID = window:screen():id()
    windowScreenMap[windowID] = screenID
end

-- Function to update window screen map, screen dimensions, centered and maximized windows
local function initWindowStates()
    log("Initializing window states")
    local allWindows = hs.window.allWindows()
    for _, window in ipairs(allWindows) do
        if not isWindowBlacklisted(window) then
            -- Not sure why we were doing this, but experimenting with turning it off to reduce load on load
            -- Maybe for on boot?
            -- setDefaultWindowSize(window)

            updateWindowScreenMap(window)

            -- Update centered windows
            centeredWindows[window:id()] = isWindowCentered(window)

            -- Update maximized windows
            maximizedWindows[window:id()] = isWindowMaximized(window)
        end
    end
end

local function adjustWindowIfNecessary(window)
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
            log("Was maximized on old screen; maximizing on new screen")
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

local function handleWindowEvent(window, eventType)
    if isWindowBlacklisted(window) then
        return
    end

    log("Window event:" .. eventType .. "; adjusting window if necessary", {
        window = window,
        screen = window:screen()
    })

    if eventType == "created" then
        setDefaultWindowSize(window)
    else
        adjustWindowIfNecessary(window)
    end

    updateWindowScreenMap(window)

    local windowID = window:id()
    maximizedWindows[windowID] = isWindowMaximized(window)
end

-- https://www.hammerspoon.org/docs/hs.window.filter.html
windowWatcher = hs.window.filter.new(nil)
windowWatcher:subscribe(hs.window.filter.windowCreated, function(window)
    handleWindowEvent(window, "created")
end)
-- windowWatcher:subscribe(hs.window.filter.windowMoved, function(window)
--     handleWindowEvent(window, "moved")
-- end)
-- 1/27/25: Chrome: opening a bookmark via Alfred doesn't trigger a `created` event, so we need to use `focused`, or `onScreen`, or `visible`
-- windowWatcher:subscribe(hs.window.filter.windowFocused, function(window)
--     handleWindowEvent(window, "focused")
-- end)
-- 9/4/24: Trying to fix bug where focus event doesn't fire on first focus (but does fire on subsequent focus)
-- TODO: Remove / isolate these if it's fixed, or remove if the wake watcher handles this
-- windowOnScreen fires only when a window becomes physically visible on the current screen,
-- while windowVisible fires for any window that becomes "visible" across all spaces/screens.
-- Guess: Since we don't use Mission Control spaces, windowOnScreen is more precise and efficient.
-- windowWatcher:subscribe(hs.window.filter.windowOnScreen, function(window)
--     handleWindowEvent(window, "onScreen")
-- end)
-- windowWatcher:subscribe(hs.window.filter.windowVisible, function(window)
--     handleWindowEvent(window, "visible")
-- end)

function adjustAllWindows()
    local allWindows = hs.window.allWindows()
    for _, window in ipairs(allWindows) do
        adjustWindowIfNecessary(window)
    end
end

-- "Creates a new screen-watcher that is also called when the active screen changes." (in addition to "when a change in the screen layout occurs")
-- https://www.hammerspoon.org/docs/hs.screen.watcher.html#newWithActiveScreen
-- 1/27/25: Doesn't seem to work when: Built-in -> sleep for a while -> wake when lid is closed + external monitor is connected
-- hs.screen.watcher.newWithActiveScreen(function()
--     log("newWithActiveScreen watcher called; adjusting windows", {
--         primaryScreen = hs.screen.primaryScreen(),
--         mainScreen = hs.screen.mainScreen()
--     })
--     hs.timer.doAfter(4, function()
--         logAction("Adjusting windows after 8 second delay (newWithActiveScreen watcher)")
--         adjustAllWindows()
--     end)
-- end):start()

addWakeWatcher(function()
    logAction("wake watcher called; adjusting windows", {
        primaryScreen = hs.screen.primaryScreen(),
        mainScreen = hs.screen.mainScreen()
    })
    hs.timer.doAfter(1, function()
        adjustAllWindows()
    end)
end)

initWindowStates()


require("utils/log")
require("windows/window_utils")
require("utils/caffeinate")

BLACKLIST_RULES = {{
    app = "Archive Utility"
}, {
    app = "iPhone Mirroring"
}, {
    app = "Alfred",
    window = "Alfred"
}, {
    app = "Vivid"
}, {
    app = "Remotasks"
}, {
    app = "Remotasks Helper"
}, {
    app = "Calculator"
}, {
    app = "Captive Network Assistant"
}, {
    window = "Software Update"
}, {
    app = "Security Agent"
}, {
    app = "Homerow"
}, {
    app = "superwhisper"
}, {
    window = "Untitled"
}, {
    app = "coreautha"
}, {
    app = "Google Chrome",
    window = "PayPal - Google Chrome - Brett"
}}

-- Function to check if a window is blacklisted
function isWindowBlacklisted(window)
    if not window or not window:application() then
        return true
    end
    local appName = window:application():name()
    local windowName = window:title()
    -- Chrome apps like Notion and Trello for some reason don't have a window name
    if not appName or appName == "" or (not windowName or windowName == "") and appName ~= "Notion" and appName ~=
        "Trello" then
        return true
    end

    if not isMainWindow(window) then
        return true
    end

    for _, rule in ipairs(BLACKLIST_RULES) do
        if (not rule.app or appName == rule.app) and (not rule.window or windowName == rule.window) then
            return true
        end
    end
    return false
end

windowScreenMap = {}
centeredWindows = {} -- Dictionary to keep track of centered windows
maximizedWindows = {} -- Dictionary to keep track of maximized windows

function updateWindowScreenMap(window)
    if isWindowBlacklisted(window) then
        return
    end

    local windowID = window:id()
    local screenID = window:screen():id()
    windowScreenMap[windowID] = screenID
end

-- Function to update window screen map, screen dimensions, centered and maximized windows
function initWindowStates()
    local allWindows = hs.window.allWindows()
    for _, window in ipairs(allWindows) do
        if not isWindowBlacklisted(window) then
            setDefaultWindowSize(window)

            updateWindowScreenMap(window)

            -- Update centered windows
            centeredWindows[window:id()] = isWindowCentered(window)

            -- Update maximized windows
            maximizedWindows[window:id()] = isWindowMaximized(window)
        end
    end
end

function adjustWindowIfNecessary(window)
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

function setDefaultRemotasksWindowSizes(window)
    local screenFrame = window:screen():frame()
    local screenWidth = screenFrame.w
    local screenHeight = screenFrame.h
    local minRemotasksWidth = 900
    local remotasksWidth, helperWidth
    local menuBarHeight = hs.screen.primaryScreen():frame().y

    if screenWidth / 2 > minRemotasksWidth then
        remotasksWidth = screenWidth / 2
    else
        remotasksWidth = minRemotasksWidth
    end

    helperWidth = screenWidth - remotasksWidth

    if appName == "Remotasks" then
        window:setFrame({
            x = 0,
            y = menuBarHeight,
            w = remotasksWidth,
            h = screenHeight - menuBarHeight
        })
    elseif appName == "Remotasks Helper" then
        window:setFrame({
            x = remotasksWidth,
            y = menuBarHeight,
            w = helperWidth,
            h = screenHeight - menuBarHeight
        })
    end
end

function setDefaultWindowSize(window)
    local appName = window:application():name()
    local defaultSizes = {
        ["Finder"] = {
            w = 800,
            h = 600
        },
        ["Notes"] = {
            w = 1000,
            h = 1000
        },
        ["System Settings"] = {
            w = 800,
            h = 600
        },
        ["Reminders"] = {
            w = 700,
            h = 600
        },
        ["Clock"] = {
            w = 650,
            h = 670
        },
        ["Messages"] = {
            w = 1000,
            h = 800
        },
        ["Contacts"] = {
            w = 700,
            h = 700
        },
        ["Cold Turkey Blocker"] = {
            w = 1000,
            h = 1000
        }
    }

    local centerOnlyApps = {
        ["Preview"] = true
    }

    -- log("App Name: " .. appName)
    if defaultSizes[appName] then
        log("Default size found for app")
        local size = defaultSizes[appName]
        window:setSize(size)
        centerWindow(window)
    elseif appName == "Remotasks" or appName == "Remotasks Helper" then
        setDefaultRemotasksWindowSizes(window)
    elseif centerOnlyApps[appName] then
        centerWindow(window)
    else
        if not maximizeWindow(window) then
            centerWindow(window)
        end
    end
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
end

-- https://www.hammerspoon.org/docs/hs.window.filter.html
windowWatcher = hs.window.filter.new(nil)
windowWatcher:subscribe(hs.window.filter.windowCreated, function(window)
    handleWindowEvent(window, "created")
end)
windowWatcher:subscribe(hs.window.filter.windowMoved, function(window)
    handleWindowEvent(window, "moved")
end)
windowWatcher:subscribe(hs.window.filter.windowFocused, function(window)
    handleWindowEvent(window, "focused")
end)
-- 9/4/24: Trying to fix bug where focus event doesn't fire on first focus (but does fire on subsequent focus)
-- TODO: Remove / isolate these if it's fixed, or remove if the wake watcher handles this
windowWatcher:subscribe(hs.window.filter.windowOnScreen, function(window)
    handleWindowEvent(window, "onScreen")
end)
windowWatcher:subscribe(hs.window.filter.windowVisible, function(window)
    handleWindowEvent(window, "visible")
end)

hs.screen.watcher.newWithActiveScreen(function()
    log("newWithActiveScreen watcher called; adjusting windows", {
        primaryScreen = hs.screen.primaryScreen(),
        mainScreen = hs.screen.mainScreen()
    })
    hs.timer.doAfter(8, function()
        local allWindows = hs.window.allWindows()
        for _, window in ipairs(allWindows) do
            if window:screen() == hs.screen.primaryScreen() then
                adjustWindowIfNecessary(window)
            end
        end
    end)
end):start()

addWakeWatcher(function()
    logAction("wake watcher called; adjusting windows", {
        primaryScreen = hs.screen.primaryScreen(),
        mainScreen = hs.screen.mainScreen()
    })
    hs.timer.doAfter(1, function()
        local allWindows = hs.window.allWindows()
        for _, window in ipairs(allWindows) do
            if window:screen() == hs.screen.primaryScreen() then
                adjustWindowIfNecessary(window)
            end
        end
    end)
end)

-- Initialize
initWindowStates()


-------------------------------------------------------
-- Window Management Module
--
-- Handles window positioning, sizing, and screen changes
-- Usage: local windowManager = require('modules.window.manager')
-------------------------------------------------------

local log = require('utils.log')
local windowUtils = require('modules.window.utils')
local defaultSizes = require('modules.window.default_sizes')
local blacklist = require('modules.window.blacklist')
local screenUtils = require('utils.screen_utils')

local M = {}

-- Private state
local windowScreenMap = {}
local centeredWindows = {}
local maximizedWindows = {}
local windowWatcher = nil
local screenWatcher = nil
local wakeWatcher = nil

-- Private functions
local function updateWindowScreenMap(window)
    if blacklist.isBlacklisted(window) then
        return
    end

    local windowID = window:id()
    local screenID = window:screen():id()
    windowScreenMap[windowID] = screenID
end

local function adjustWindowIfNecessary(window)
    if blacklist.isBlacklisted(window) then
        log("Exiting due to blacklisted window", {window})
        return
    end

    local windowID, currentScreenID = window:id(), window:screen():id()
    local oldScreenID = windowScreenMap[windowID]
    
    log("Checking if window moved screens", {
        oldScreenID = oldScreenID,
        currentScreenID = currentScreenID,
        window = window
    })
    
    local windowIsOnNewScreenOrInitialScreen = currentScreenID ~= oldScreenID
    if windowIsOnNewScreenOrInitialScreen then
        log("Window is on a new screen or initial screen")

        if maximizedWindows[windowID] then
            log("Was maximized on old screen; maximizing on new screen")
            windowUtils.maximize(window)
            return
        end

        local windowMovedScreens = oldScreenID ~= nil
        if windowMovedScreens then
            log("Window moved screens; centering window", {window})
            windowUtils.center(window)
        end
    end

    -- Handle windows sized for built-in display
    local frame = window:frame()
    local windowIsSizeOfBuiltinDisplay = (frame.w >= 1715 and frame.w <= 1740) and (frame.h >= 1075 and frame.h <= 1085)
    if windowIsSizeOfBuiltinDisplay and not screenUtils.isPrimaryDisplayBuiltIn() then
        log("Window is dimensions of MacBook built-in screen; maximizing", {
            window = window,
            frame = frame
        })
        windowUtils.maximize(window)
        return
    end

    -- Update centered state
    centeredWindows[windowID] = windowUtils.isCentered(window)
end

local function handleWindowEvent(window, eventType)
    if blacklist.isBlacklisted(window) then
        return
    end

    log("Window event: " .. eventType .. "; adjusting window if necessary", {
        window = window,
        screen = window:screen()
    })

    if eventType == "created" then
        defaultSizes.apply(window)
    else
        adjustWindowIfNecessary(window)
    end

    updateWindowScreenMap(window)
    maximizedWindows[window:id()] = windowUtils.isMaximized(window)
end

-- Public API
function M.start()
    if windowWatcher then
        log("Window manager already started")
        return
    end
    
    -- Initialize window states
    local allWindows = hs.window.allWindows()
    for _, window in ipairs(allWindows) do
        if not blacklist.isBlacklisted(window) then
            updateWindowScreenMap(window)
            centeredWindows[window:id()] = windowUtils.isCentered(window)
            maximizedWindows[window:id()] = windowUtils.isMaximized(window)
        end
    end

    -- Set up window watcher
    windowWatcher = hs.window.filter.new(nil)
    
    windowWatcher:subscribe(hs.window.filter.windowCreated, function(window)
        handleWindowEvent(window, "created")
    end)
    
    windowWatcher:subscribe(hs.window.filter.windowFocused, function(window)
        handleWindowEvent(window, "focused")
    end)
    
    windowWatcher:subscribe(hs.window.filter.windowVisible, function(window)
        handleWindowEvent(window, "visible")
    end)
    
    log("Window manager started")
end

function M.stop()
    if windowWatcher then
        windowWatcher:unsubscribeAll()
        windowWatcher = nil
    end
    if screenWatcher then
        screenWatcher:stop()
        screenWatcher = nil
    end
    log("Window manager stopped")
end

function M.adjustAllWindows()
    local allWindows = hs.window.allWindows()
    for _, window in ipairs(allWindows) do
        adjustWindowIfNecessary(window)
    end
end

function M.getWindowScreenMap()
    return windowScreenMap
end

return M
-------------------------------------------------------
-- Default Window Sizes Module
--
-- Handles setting default window sizes for specific applications
-- Usage: local defaultSizes = require('modules.window.default_sizes')
-------------------------------------------------------

local log = require('utils.log')
local windowUtils = require('modules.window.utils')

local M = {}

-- Private state
local defaultSizes = {
    ["Google Chrome"] = {w = 1200, h = 800},
    ["Arc"] = {w = 1200, h = 800},
    ["Cursor"] = {w = 1400, h = 900},
    ["Slack"] = {w = 1000, h = 700},
    ["Messages"] = {w = 800, h = 600},
    ["Notion"] = {w = 1300, h = 850},
    ["Trello"] = {w = 1200, h = 800},
}

-- Private functions
local function getDefaultSize(appName)
    return defaultSizes[appName]
end

-- Public API
function M.apply(window)
    if not window then return false end
    
    local app = window:application()
    if not app then return false end
    
    local appName = app:name()
    local size = getDefaultSize(appName)
    
    if not size then
        log("No default size configured for app", {app = appName})
        return false
    end
    
    local screen = window:screen()
    local screenFrame = screen:frame()
    
    -- Center the window with the default size
    local frame = {
        x = screenFrame.x + (screenFrame.w - size.w) / 2,
        y = screenFrame.y + (screenFrame.h - size.h) / 2,
        w = size.w,
        h = size.h
    }
    
    windowUtils.setFrame(window, frame)
    log("Applied default size", {app = appName, size = size})
    return true
end

function M.setDefaultSize(appName, width, height)
    defaultSizes[appName] = {w = width, h = height}
    log("Set default size for app", {app = appName, width = width, height = height})
end

function M.getDefaultSize(appName)
    return getDefaultSize(appName)
end

function M.removeDefaultSize(appName)
    defaultSizes[appName] = nil
    log("Removed default size for app", {app = appName})
end

function M.getAllDefaultSizes()
    return defaultSizes
end

return M
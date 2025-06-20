-------------------------------------------------------
-- Window Blacklist Module
--
-- Manages which windows should be ignored by window management
-- Usage: local blacklist = require('modules.window.blacklist')
-------------------------------------------------------

local log = require('utils.log')

local M = {}

-- Private state
local blacklistedApps = {
    "Finder",
    "System Preferences",
    "System Settings",
    "Activity Monitor",
    "Console",
    "Terminal",
    "Raycast",
    "Alfred",
    "Spotlight",
}

local blacklistedWindowTitles = {
    "Desktop",
    "Dock",
    "Menubar",
}

-- Private functions
local function isAppBlacklisted(window)
    local app = window:application()
    if not app then return false end
    
    local appName = app:name()
    for _, blacklistedApp in ipairs(blacklistedApps) do
        if appName == blacklistedApp then
            return true
        end
    end
    return false
end

local function isTitleBlacklisted(window)
    local title = window:title()
    if not title then return false end
    
    for _, blacklistedTitle in ipairs(blacklistedWindowTitles) do
        if title:find(blacklistedTitle) then
            return true
        end
    end
    return false
end

-- Public API
function M.isBlacklisted(window)
    if not window then return true end
    
    return isAppBlacklisted(window) or isTitleBlacklisted(window)
end

function M.addApp(appName)
    table.insert(blacklistedApps, appName)
    log("Added app to blacklist", {app = appName})
end

function M.removeApp(appName)
    for i, app in ipairs(blacklistedApps) do
        if app == appName then
            table.remove(blacklistedApps, i)
            log("Removed app from blacklist", {app = appName})
            return true
        end
    end
    return false
end

function M.addWindowTitle(title)
    table.insert(blacklistedWindowTitles, title)
    log("Added window title to blacklist", {title = title})
end

function M.getBlacklistedApps()
    return blacklistedApps
end

function M.getBlacklistedTitles()
    return blacklistedWindowTitles
end

return M
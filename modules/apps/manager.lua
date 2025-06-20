-------------------------------------------------------
-- App Management Module
--
-- Handles application startup, management, and cleanup
-- Usage: local appManager = require('modules.apps.manager')
-------------------------------------------------------

local log = require('utils.log')
local appUtils = require('utils.app_utils')

local M = {}

-- Private state
local essentialApps = {
    "Messages", "Cursor", "Slack", "Notion Calendar", "kitty", 
    "Reminders", "Obsidian", "Vivid", "Google Chrome", "Notion", 
    "Trello", "Hammerspoon", "Arc"
}

-- Private functions
local function startApp(appName)
    if not hs.application.get(appName) then
        hs.timer.doAfter(0.1, function()
            log.logAction("Starting app: " .. appName)
            hs.application.open(appName, 0, true)
            log.logAction("App is done starting; hiding: " .. appName)
            if appUtils.hideAppWhenAvailable then
                appUtils.hideAppWhenAvailable(appName)
            end
        end)
    else
        log.log("App already running; not starting: " .. appName)
    end
end

local function minimizeCursorWindows()
    local cursor = hs.application.get("Cursor")
    if cursor then
        local windows = cursor:allWindows()
        for _, window in ipairs(windows) do
            window:minimize()
        end
    else
        local minimizeExecuted = false
        local iterations = 0

        local timer
        timer = hs.timer.doEvery(2, function()
            log.log("Minimizing cursor windows check")
            iterations = iterations + 1
            if not minimizeExecuted and hs.application.get("Cursor") then
                log.logAction("Minimizing cursor windows")
                local cursorApp = hs.application.get("Cursor")
                if cursorApp then
                    local cursorWindows = cursorApp:allWindows()
                    for _, window in ipairs(cursorWindows) do
                        window:minimize()
                    end
                end
                minimizeExecuted = true
                timer:stop()
                return
            end
            
            if iterations >= 30 or minimizeExecuted then
                timer:stop()
            end
        end)
    end
end

-- Public API
function M.setEssentialApps(apps)
    essentialApps = apps
    log.log("Updated essential apps list", apps)
end

function M.getEssentialApps()
    return essentialApps
end

function M.killInessentialApps()
    log.logAction("Killing inessential apps")
    if appUtils.killAppsInDock then
        appUtils.killAppsInDock(essentialApps)
    end
end

function M.startEssentialApps()
    log.logAction("Starting essential apps")
    
    for i, appName in ipairs(essentialApps) do
        hs.timer.doAfter((i - 1) * 0.25, function()
            startApp(appName)
        end)
    end
end

function M.openDefaultRepos()
    log.logAction("Opening default repos")
    hs.execute("cursor ~/src/dotfiles")
    hs.execute("cursor ~/src/hammerspoon")
end

function M.runDefaultAppState()
    hs.timer.doAfter(0, function()
        M.startEssentialApps()
        hs.timer.doAfter(1, function()
            M.openDefaultRepos()
            hs.timer.doAfter(1, function()
                minimizeCursorWindows()
            end)
        end)
    end)

    hs.timer.doAfter(10, function()
        if appUtils.hideAllApps then
            appUtils.hideAllApps()
        end
    end)
end

function M.hideAllApps()
    if appUtils.hideAllApps then
        appUtils.hideAllApps()
    else
        log.logWarning("hideAllApps function not available")
    end
end

return M
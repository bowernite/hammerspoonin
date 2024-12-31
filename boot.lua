require("utils/app_utils")
require("utils/log")

-- General things we want to do when macOS boots
local output, status = hs.execute("colima start --ssh-agent --dns 8.8.8.8", true)
if not status then
    hs.alert.show("Failed to start Colima: " .. output)
end

local essentialApps = {"Messages", "Cursor", "Slack", "Notion Calendar", "kitty", "Reminders", "Obsidian", "Vivid",
                       "Google Chrome", "Notion", "Trello", "Hammerspoon"}

function killInessentialApps()
    logAction("Killing inessential apps")
    killAppsInDock(essentialApps)
end

function startEssentialApps()
    logAction("Starting essential apps")
    local startApp = function(appName)
        if not hs.application.get(appName) then
            hs.timer.doAfter(0.1, function()
                logAction("Starting app: " .. appName)
                hs.application.open(appName, 0, true)
                logAction("App is done starting; hiding: " .. appName)
                hideAppWhenAvailable(appName)
            end)
        else
            log("App already running; not starting: " .. appName)
        end
    end

    for i, appName in ipairs(essentialApps) do
        hs.timer.doAfter((i - 1) * 0.25, function()
            startApp(appName)
        end)
    end
end

function openDefaultRepos()
    logAction("Opening default repos")
    hs.execute("cursor ~/src/dotfiles")
    hs.execute("cursor ~/src/hammerspoon")
end

function minimizeCursorWindows()
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
        poll(function()
            log("Minimizing cursor windows check")
            if not minimizeExecuted and hs.application.get("Cursor") then
                logAction("Minimizing cursor windows")
                local cursorApp = hs.application.get("Cursor")
                if cursorApp then
                    local cursorWindows = cursorApp:allWindows()
                    for _, window in ipairs(cursorWindows) do
                        window:minimize()
                    end
                end
                minimizeExecuted = true
                return true -- Stop polling
            end
            return false -- Continue polling
        end, 2, 30)

        timer:start()
    end
end

function defaultAppState()
    hs.timer.doAfter(0, function()
        startEssentialApps()
        hs.timer.doAfter(1, function()
            openDefaultRepos()
            hs.timer.doAfter(1, function()
                minimizeCursorWindows()
            end)
        end)
    end)

    hs.timer.doAfter(10, function()
        hideAllApps()
    end)
end

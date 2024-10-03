require("utils/log")

local eventtap = hs.eventtap

function closeAllFinderWindows()
    logAction("Closing all Finder windows")
    local finder = hs.application.get("Finder")
    if finder then
        local windows = finder:allWindows()
        for i, window in ipairs(windows) do
            log("Finder window " .. i .. ": " .. window:title())
            window:close()
        end
    end
end

-- Function to hide all visible apps
function hideAllApps()
    logAction("Hiding all apps, via Finder + Hide Others")
    local finderApp = hs.application.open("Finder")
    if finderApp then
        finderApp:activate()
    else
        log("Failed to open Finder")
    end
    -- Hide all other applications
    hs.timer.usleep(250000)  -- Sleep for 0.25 seconds (250,000 microseconds)
    hs.eventtap.keyStroke({"cmd", "alt"}, "h")
    hs.timer.usleep(500000)
    closeAllFinderWindows()

    -- local createdNewFinderWindow = false

    -- logAction("Hiding all visible apps")
    -- local visibleApps = hs.window.filter.new():setAppFilter("", {
    --     visible = true
    -- }):getWindows()
    -- for _, window in ipairs(visibleApps) do
    --     local app = window:application()

    --     if app then
    --         logAction("Hiding app: " .. app:name())
    --         app:hide()
    --     end
    -- end
    -- -- Hide Hammerspoon
    -- local hammerspoonApp = hs.application.get("Hammerspoon")
    -- if hammerspoonApp then
    --     logAction("Hiding Hammerspoon")
    --     hammerspoonApp:hide()
    -- end
end

function hideAllAppsManual()
    -- logAction("Hiding all apps manually")
    -- for i = 1, 15 do
    --     hs.eventtap.keyStroke({"cmd"}, "h")
    --     hs.timer.usleep(100) -- Sleep for 100ms between keystrokes
    -- end
end

function killAppsInDock()
    local appsToNotKill = {"Hammerspoon", "Finder", "kitty"}
    local appsInDock = hs.fnutils.filter(hs.application.runningApplications(), function(app)
        return app:kind() == 1
    end)
    local appNamesInDock = hs.fnutils.map(appsInDock, function(app)
        return app:name()
    end)
    log("Killing apps in dock: " .. table.concat(appNamesInDock, ", "))
    for _, app in ipairs(appsInDock) do
        local appName = app:name()
        if not hs.fnutils.contains(appsToNotKill, appName) then
            logAction("Killing app: " .. appName)
            app:kill()
        end
    end
end

function hideAppWhenAvailable(appName)
    poll(function()
        local app = hs.application.get(appName)
        if app then
            logAction("Hiding app: " .. appName)
            app:hide()
            return true
        end
        return false
    end, 2, 30, function()
        logWarning("Failed to hide " .. appName .. " after 30 attempts")
    end)
end


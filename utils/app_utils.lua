-- Function to hide all visible apps
function hideAllApps()
    local createdNewFinderWindow = false

    logAction("Hiding all visible apps")
    local visibleApps =
        hs.window.filter.new():setAppFilter("", {visible = true}):getWindows()
    for _, window in ipairs(visibleApps) do
        local app = window:application()

        if app then
            logAction("Hiding app: " .. app:name())
            app:hide()
        end
    end
    -- Hide Hammerspoon
    local hammerspoonApp = hs.application.get("Hammerspoon")
    if hammerspoonApp then
        logAction("Hiding Hammerspoon")
        hammerspoonApp:hide()
    end
end

function killAppsInDock()
    local appsToNotKill = {"Hammerspoon", "Finder", "kitty"}
    local appsInDock = hs.fnutils.filter(hs.application.runningApplications(),
                                         function(app) return app:kind() == 1 end)
    local appNamesInDock = hs.fnutils.map(appsInDock,
                                          function(app) return app:name() end)
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


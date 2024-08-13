local essentialApps = {
    "Messages", "Cursor", "Slack", "Notion Calendar", "kitty", "Reminders",
    "Bear", "Vivid", "Google Chrome", "Notion", "Trello", "Hammerspoon"
}
local appsToNotKill = {"Hammerspoon", "Finder"}

-- local backgroundApps = {
--     "Flux", "superwhisper", "Alfred", "Alfred 5", "Karabiner-Elements",
--     "Rectangle", "Amphetamine", "Homerow", "MonitorControl", "Hammerspoon",
--     "Finder", "CleanShot X", "Online", "Keysmith"
-- }

local function killAppsInDock()
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

local function hideAppWhenAvailable(appName)
    local iterations = 0
    local maxIterations = 30
    local timer

    timer = hs.timer.new(2, function()
        local app = hs.application.get(appName)
        if app then
            logAction("Hiding app: " .. appName)
            app:hide()
            timer:stop()
        elseif iterations >= maxIterations then
            logWarning("Failed to hide " .. appName .. " after " ..
                           maxIterations .. " iterations")
            timer:stop()
        end
        iterations = iterations + 1
    end)

    timer:start()
end

local function startEssentialApps(essentialApps)
    logAction("Starting essential apps")
    local startApp = function(appName)
        hs.timer.doAfter(0.1, function()
            logAction("Starting app: " .. appName)
            hs.application.open(appName, 0, true)
            logAction("App is done starting; hiding: " .. appName)
            hideAppWhenAvailable(appName)
        end)
    end

    for _, appName in ipairs(essentialApps) do
        if not hs.fnutils.contains(appsToNotKill, appName) then
            startApp(appName)
        end
    end
end

local function closeAllFinderWindows()
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

local function openDefaultRepos()
    logAction("Opening default repos")
    hs.execute("cursor ~/src/dotfiles")
    hs.execute("cursor ~/src/hammerspoon")
end

local function minimizeCursorWindows()
    local cursor = hs.application.get("Cursor")
    if cursor then
        local windows = cursor:allWindows()
        for _, window in ipairs(windows) do window:minimize() end
    else
        local minimizeExecuted = false
        local iterations = 0

        local timer
        timer = hs.timer.new(2, function()
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
                timer:stop()
            elseif iterations >= 30 then
                log("Failed to minimize cursor windows after 30 iterations")
                timer:stop()
            end
            iterations = iterations + 1
        end)

        timer:start()
    end
end

local function openNewFinderWindow()
    logAction("Opening new Finder window")
    local finder = hs.application.get("Finder")
    if finder then
        finder:selectMenuItem({"File", "New Finder Window"})
    else
        hs.application.open("Finder")
    end
end

local function resetApps(restartApps)
    log("Initiating app reset sequence")

    killAppsInDock()

    if restartApps then startEssentialApps(essentialApps) end

    openDefaultRepos()
    minimizeCursorWindows()

    -- openNewFinderWindow()
    -- local oneSecondInMicroseconds = 1000000
    -- hs.timer.usleep(oneSecondInMicroseconds)
    -- for _, appName in ipairs(essentialApps) do hideAppWhenAvailable(appName) end
    closeAllFinderWindows()

    hs.alert.show("Reset apps")
end

local function resetAppsEveryMorning()
    local hasResetToday = false

    local function resetState()
        log("Reset state triggered")
        hasResetToday = false
    end

    hs.timer.doAt("03:59", "1d", resetState)

    addWakeWatcher(function()
        local currentTime = os.date("*t")
        log("Checking if apps should be reset",
            {hasResetToday = hasResetToday, currentTime = currentTime})
        if not hasResetToday and currentTime.hour >= 4 then
            log("Resetting apps after first wake past 4 AM")
            resetApps(true)
            hasResetToday = true
        end
    end)
end

resetAppsEveryMorning()

hs.hotkey.bind({"cmd", "alt"}, "K", function() resetApps(true) end)

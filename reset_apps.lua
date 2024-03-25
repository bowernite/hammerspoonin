local function resetApps(restartApps)
    log("🔄 Initiating app reset sequence")
    local essentialApps = {
        "Messages", "Cursor", "Slack", "Notion Calendar", "kitty", "Reminders",
        "Bear", "Vivid", "Remotasks", "Remotasks Helper", "Google Chrome",
        "Notion", "Trello"
    }

    local backgroundApps = {
        "Flux", "superwhisper", "Alfred", "Alfred 5", "Karabiner-Elements",
        "Rectangle", "Amphetamine", "Homerow", "Monitor Control", "Hammerspoon",
        "Finder", "CleanShot X", "Online"
    }

    -- Need to refine this, ie flux / Vivid conflicts
    -- for _, appName in ipairs(backgroundApps) do
    --     local app = hs.application.get(appName)
    --     if not app or not app:isRunning() then
    --         hs.application.launchOrFocus(appName)
    --         log(appName .. " started as it was not running.")
    --     end
    -- end

    local runningApps = hs.application.runningApplications()
    for i, app in ipairs(runningApps) do
        local appName = app:name()
        if not hs.fnutils.contains(essentialApps, appName) and
            not hs.fnutils.contains(backgroundApps, appName) and
            not appName:find("Bartender") and not appName:find("Fantastical") then
            app:kill()
        end
    end

    if restartApps then
        local restartApp = function(appName)
            local app = hs.application.get(appName)
            if app then
                app:kill9() -- Forcefully stops the app
                hs.timer.doAfter(0.1,
                                 function() -- Wait a bit for the app to fully terminate
                    hs.application.open(appName, 10, true) -- Restart the app without activating it
                end)
            end
        end

        for _, appName in ipairs(essentialApps) do
            hs.timer.doAfter(0, function() restartApp(appName) end) -- Execute app restarts in parallel
        end
    end

    -- Hide all windows after restarting essential apps
    local allApps = hs.application.runningApplications()
    for _, app in ipairs(allApps) do
        local windows = app:allWindows()
        for _, window in ipairs(windows) do
            window:minimize() -- Minimize each window
        end
    end

    local finder = hs.application.get("Finder")
    if finder then
        local windows = finder:allWindows()
        for _, window in ipairs(windows) do window:close() end
    end

    hs.alert.show("🔄 Reset apps")
end

local function resetAppsEveryMorning()
    local hasResetToday = false

    local function resetState()
        log("🔄 Reset state triggered")
        hasResetToday = false
    end

    hs.timer.doAt("03:59", "1d", resetState)

    local wakeWatcher = hs.caffeinate.watcher.new(function(event)
        log("🔄 Wake event detected: " .. event)
        if event == hs.caffeinate.watcher.systemDidWake and not hasResetToday then
            local currentTime = os.date("*t")
            log("🔄 Current time: " .. currentTime.hour)
            if currentTime.hour >= 4 then
                log("🔄 Resetting apps after first wake past 4 AM")
                resetApps(true)
                hasResetToday = true
            end
        end
    end)
    wakeWatcher:start()
end

-- resetAppsEveryMorning()

hs.hotkey.bind({"cmd", "alt"}, "K", function() resetApps(false) end)

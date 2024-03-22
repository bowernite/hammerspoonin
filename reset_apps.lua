local function resetApps()
    log("🔄 Initiating app reset sequence")
    local essentialApps = {
        "Messages", "Cursor", "Slack", "Notion Calendar", "kitty", "Reminders",
        "Bear", "Vivid", "Flux", "Remotasks", "Remotasks Helper",
        "superwhisper", "Alfred", "Alfred 5", "Karabiner-Elements", "Rectangle",
        "Amphetamine", "Homerow", "Monitor Control", "Hammerspoon", "Finder",
        "Google Chrome", "Notion", "Trello"
    }

    local runningApps = hs.application.runningApplications()
    for i, app in ipairs(runningApps) do
        local appName = app:name()
        local appPath = app:path()
        if not hs.fnutils.contains(essentialApps, appName) and
            not appName:find("Bartender") and not appName:find("Fantastical") then
            app:kill()
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
                resetApps()
                hasResetToday = true
            end
        end
    end)
    wakeWatcher:start()
end

resetAppsEveryMorning()

hs.hotkey.bind({"cmd", "alt"}, "K", resetApps)

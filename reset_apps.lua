hs.hotkey.bind({"cmd", "alt"}, "K", function()
    log("Initiating app reset sequence")
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

    hs.alert.show("Reset apps")
end)

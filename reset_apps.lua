require("utils/app_utils")

local essentialApps = {
    "Messages", "Cursor", "Slack", "Notion Calendar", "kitty", "Reminders",
    "Bear", "Vivid", "Google Chrome", "Notion", "Trello", "Hammerspoon"
}

-- local backgroundApps = {
--     "Flux", "superwhisper", "Alfred", "Alfred 5", "Karabiner-Elements",
--     "Rectangle", "Amphetamine", "Homerow", "MonitorControl", "Hammerspoon",
--     "Finder", "CleanShot X", "Online", "Keysmith"
-- }

local function startEssentialApps(essentialApps)
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

    for _, appName in ipairs(essentialApps) do startApp(appName) end
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

local function resetApps(restartApps)
    log("Initiating app reset sequence")

    killAppsInDock()

    if restartApps then startEssentialApps(essentialApps) end

    openDefaultRepos()
    minimizeCursorWindows()

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
            hs.alert.show("Doing morning reset...")
            resetApps(true)
            hasResetToday = true
        end
    end)
end

resetAppsEveryMorning()

hs.hotkey.bind({"cmd", "alt"}, "K", function() resetApps(true) end)

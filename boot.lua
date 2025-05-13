require("utils/app_utils")
require("utils/log")

-- General things we want to do when macOS boots

local network = require("utils/network")

-- Set up persistence for tracking actual system boots
local BOOT_STATE_KEY = "last_system_boot_time"
local UPTIME_THRESHOLD = 300 -- 5 minutes in seconds

-- Function for other modules to check if system booted recently
function wasRecentSystemBoot(timeWindowSeconds)
    local lastBootTime = hs.settings.get(BOOT_STATE_KEY)
    if not lastBootTime then return false end
    
    timeWindowSeconds = timeWindowSeconds or 150 -- Default 2.5 minutes
    return (os.time() - lastBootTime) < timeWindowSeconds
end

-- Function to determine if this is an actual system boot or just a Hammerspoon restart
function isActualSystemBoot()
    -- Get the real system uptime in seconds using the system uptime command
    local uptimeOutput, status = hs.execute("uptime")
    local systemUptimeSeconds = 0
    
    if status then
        log("Uptime output: " .. uptimeOutput)
        
        -- macOS uptime format is typically: " HH:MM:SS  up   H:MM,  N users,  load average: X.XX, Y.YY, Z.ZZ"
        -- or for longer times: " HH:MM:SS  up N days,  H:MM,  N users,  load average: X.XX, Y.YY, Z.ZZ"
        
        -- Extract the uptime portion
        local upPart = uptimeOutput:match("up%s+(.-),%s+%d+%s+users")
        if upPart then
            log("Uptime part: " .. upPart)
            
            -- Handle days if present
            local days = upPart:match("(%d+)%s+days?")
            local timeStr = upPart:match("(%d+:%d+)$")
            
            local hours, minutes = 0, 0
            if timeStr then
                hours, minutes = timeStr:match("(%d+):(%d+)")
            end
            
            -- Convert all to seconds
            systemUptimeSeconds = (days and tonumber(days) * 86400 or 0) + 
                                 (hours and tonumber(hours) * 3600 or 0) + 
                                 (minutes and tonumber(minutes) * 60 or 0)
            
            log("Parsed uptime: " .. tostring(systemUptimeSeconds) .. " seconds", {
                days = days,
                hours = hours,
                minutes = minutes,
                timeStr = timeStr
            })
        else
            log("Failed to parse uptime output")
        end
    end
    
    -- Get the last recorded boot time from settings
    local lastBootTime = hs.settings.get(BOOT_STATE_KEY)
    local currentTime = os.time()
    
    -- Consider this a system boot if:
    -- 1. System uptime is low (less than threshold), indicating recent boot
    -- 2. AND either we don't have a previous boot time or the current time minus uptime
    --    is significantly different from the last boot time
    if systemUptimeSeconds < UPTIME_THRESHOLD then
        local estimatedBootTime = currentTime - systemUptimeSeconds
        
        -- If we don't have a last boot time or the boot times are different (allowing for some margin)
        if not lastBootTime or math.abs(estimatedBootTime - lastBootTime) > 60 then
            -- Save the estimated boot time
            hs.settings.set(BOOT_STATE_KEY, estimatedBootTime)
            log("Detected actual system boot", {
                systemUptime = systemUptimeSeconds,
                estimatedBootTime = os.date("%Y-%m-%d %H:%M:%S", estimatedBootTime)
            })
            return true
        end
    end
    
    log("Not an actual system boot, just a Hammerspoon restart/reload", {
        systemUptime = systemUptimeSeconds,
        lastBootTime = lastBootTime and os.date("%Y-%m-%d %H:%M:%S", lastBootTime) or "none"
    })
    return false
end

local function startColima()
    local output, status = hs.execute("colima start --ssh-agent --dns 8.8.8.8", true)
    if not status then
        -- Check for the specific "vz driver is running but host agent is not" error
        if output:match("vz driver is running but host agent is not") then
            log("Detected Colima in inconsistent state, attempting to fix...")
            -- Try to stop Colima first (force if needed) and then restart
            hs.execute("colima stop --force", true)
            -- Try starting again after force stop
            output, status = hs.execute("colima start --ssh-agent --dns 8.8.8.8", true)
            if not status then
                logError("Failed to start Colima after recovery attempt", {
                    output = output,
                    status = status
                }, output)
            else
                log("Successfully started Colima after recovery")
            end
        else
            logError("Failed to start Colima", {
                output = output,
                status = status
            }, output)
        end
    else
        log("Successfully started Colima")
    end
end

local essentialApps = {"Messages", "Cursor", "Slack", "Notion Calendar", "kitty", "Reminders", "Obsidian", "Vivid",
                       "Google Chrome", "Notion", "Trello", "Hammerspoon", "Arc"}

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
        timer = hs.timer.doEvery(2, function()
            log("Minimizing cursor windows check")
            iterations = iterations + 1
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
                return
            end
            
            if iterations >= 30 or minimizeExecuted then
                timer:stop()
            end
        end)
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

-- Store the time Hammerspoon was last reloaded
hs.settings.set("hs_last_reload", hs.timer.secondsSinceEpoch())

-- Only run boot startup sequence if this is an actual system boot
if isActualSystemBoot() then
    logAction("Running boot startup sequence")
    startColima()
    
    -- Show alert and schedule hiding all windows after delay
    local HIDE_WINDOWS_DELAY = 10 -- Wait 10 seconds before hiding windows, so we know the default window size is set first
    hs.alert.show("System booted - windows will be hidden in " .. HIDE_WINDOWS_DELAY .. " seconds", HIDE_WINDOWS_DELAY)
    
    -- Schedule hiding all windows after delay
    log("Scheduling hideAllApps in " .. HIDE_WINDOWS_DELAY .. " seconds")
    HIDE_WINDOWS_ON_BOOT_TIMER = hs.timer.doAfter(HIDE_WINDOWS_DELAY, function()
        logAction(HIDE_WINDOWS_DELAY .. " seconds elapsed after boot - hiding all windows")
        hs.alert.show("Hiding all windows now...", 3)
        hideAllApps()
    end)
else
    log("Skipping boot sequence - not an actual system boot")
end

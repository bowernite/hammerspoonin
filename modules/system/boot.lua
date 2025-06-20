-------------------------------------------------------
-- System Boot Module
--
-- Handles system boot detection and initialization tasks
-- Usage: local boot = require('modules.system.boot')
-------------------------------------------------------

local log = require('utils.log')
local appUtils = require('utils.app_utils')
local network = require('utils.network')

local M = {}

-- Private state
local BOOT_STATE_KEY = "last_system_boot_time"
local UPTIME_THRESHOLD = 300 -- 5 minutes in seconds

-- Private functions
local function getSystemUptime()
    local uptimeOutput, status = hs.execute("uptime")
    local systemUptimeSeconds = 0
    
    if status then
        log("Uptime output: " .. uptimeOutput)
        
        local upPart = uptimeOutput:match("up%s+(.-),%s+%d+%s+users")
        if upPart then
            log("Uptime part: " .. upPart)
            
            local days = upPart:match("(%d+)%s+days?")
            local timeStr = upPart:match("(%d+:%d+)$")
            
            local hours, minutes = 0, 0
            if timeStr then
                hours, minutes = timeStr:match("(%d+):(%d+)")
            end
            
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
    
    return systemUptimeSeconds
end

local function startColima()
    local output, status = hs.execute("colima start --ssh-agent --dns 8.8.8.8", true)
    if not status then
        if output:match("vz driver is running but host agent is not") then
            log("Detected Colima in inconsistent state, attempting to fix...")
            hs.execute("colima stop --force", true)
            output, status = hs.execute("colima start --ssh-agent --dns 8.8.8.8", true)
        end
        
        if not status then
            log("Failed to start Colima", {output = output})
        else
            log("Successfully started Colima after recovery")
        end
    else
        log("Successfully started Colima")
    end
end

-- Public API
function M.wasRecentSystemBoot(timeWindowSeconds)
    local lastBootTime = hs.settings.get(BOOT_STATE_KEY)
    if not lastBootTime then return false end
    
    timeWindowSeconds = timeWindowSeconds or 150 -- Default 2.5 minutes
    return (os.time() - lastBootTime) < timeWindowSeconds
end

function M.isActualSystemBoot()
    local systemUptimeSeconds = getSystemUptime()
    local lastBootTime = hs.settings.get(BOOT_STATE_KEY)
    local currentTime = os.time()
    
    if systemUptimeSeconds < UPTIME_THRESHOLD then
        local estimatedBootTime = currentTime - systemUptimeSeconds
        
        if not lastBootTime or math.abs(estimatedBootTime - lastBootTime) > 60 then
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

function M.runBootSequence()
    if not M.isActualSystemBoot() then
        log("Skipping boot sequence - not an actual system boot")
        return false
    end
    
    log("Running boot startup sequence")
    
    -- Start Colima
    startColima()
    
    -- Show alert and schedule actions
    local HIDE_WINDOWS_DELAY = 10
    hs.alert.show("System booted - windows will be hidden in " .. HIDE_WINDOWS_DELAY .. " seconds", HIDE_WINDOWS_DELAY)
    
    hs.timer.doAfter(HIDE_WINDOWS_DELAY, function()
        log(HIDE_WINDOWS_DELAY .. " seconds elapsed after boot - hiding all windows")
        hs.alert.show("Hiding all windows now...", 3)
        if appUtils.hideAllApps then
            appUtils.hideAllApps()
        end
    end)
    
    return true
end

function M.recordReload()
    hs.settings.set("hs_last_reload", hs.timer.secondsSinceEpoch())
end

return M
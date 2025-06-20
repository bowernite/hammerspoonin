require("utils/log")
require("utils/caffeinate")

local network = require("utils/network")

-- Network configuration constants
local HOME_WIFI_SSID = "Brett and Mary"
local HOTSPOT_SSID = "Brett’s iPhone"
local HOTSPOT_PASSWORD = "puppies123"

--- Check available networks and auto-connect to hotspot if needed
local function checkAndConnectToHotspot()
    logAction("Checking available networks for auto-hotspot connection")

    hs.wifi.backgroundScan(function(networks)
        if type(networks) == "string" then
            logWarning("Network scan failed: " .. networks)
            return
        end
        log("Available networks: " .. hs.inspect(networks))

        local homeWifiAvailable = false
        local hotspotAvailable = false

        -- Check what networks are available
        for _, network in ipairs(networks) do
            if network.ssid == HOME_WIFI_SSID then
                homeWifiAvailable = true
            elseif network.ssid == HOTSPOT_SSID then
                hotspotAvailable = true
            end
        end

        log("Network scan results:")
        log(HOME_WIFI_SSID .. ": " .. (homeWifiAvailable and "available" or "not available"))
        log(HOTSPOT_SSID .. ": " .. (hotspotAvailable and "available" or "not available"))

        -- Connect to hotspot only if home wifi is not available but hotspot is
        if not homeWifiAvailable and hotspotAvailable then
            logAction("Home WiFi not available but hotspot is - connecting to " .. HOTSPOT_SSID)
            network.connectToNetwork(HOTSPOT_SSID, HOTSPOT_PASSWORD, function(success, message)
                if success then
                    logAction("Successfully connected to hotspot: " .. message)
                else
                    logWarning("Failed to connect to hotspot: " .. message)
                end
            end)
        elseif homeWifiAvailable then
            log("Home WiFi is available - no need to connect to hotspot")
        elseif not hotspotAvailable then
            log("Neither home WiFi nor hotspot are available")
        end
    end)
end

--- Initialize the auto-hotspot system
local function init()
    logAction("Initializing auto-hotspot connection on wake")

    -- Add wake watcher to check networks when system wakes up
    addWakeWatcher(function(eventType)
        -- Wait a few seconds after wake to let WiFi stabilize
        hs.timer.doAfter(2, function()
            checkAndConnectToHotspot()
        end)
    end)

    log("Auto-hotspot system initialized")
end

-- Initialize when this module is loaded
init()

return {
    checkAndConnectToHotspot = checkAndConnectToHotspot,
    init = init
}

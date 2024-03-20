require("log_utils")

-----------------------------------------------------------------------------------------------
-- Toggle Wifi based on Ethernet status and Screen Lock status
-----------------------------------------------------------------------------------------------
function updateWifiEnabled(screenLocked)
    local ethernetInterface = "en6" -- Change to your Ethernet interface identifier
    local wifiInterface = "en0" -- Change to your WiFi interface identifier
    local ethernetActive = hs.network.interfaceDetails(ethernetInterface) and
                               hs.network.interfaceDetails(ethernetInterface)
                                   .IPv4
    local wifiPower = hs.wifi.interfaceDetails(wifiInterface) and
                          hs.wifi.interfaceDetails(wifiInterface).power

    log("🌐 Network Status: Ethernet Interface - " .. ethernetInterface ..
            ", WiFi Interface - " .. wifiInterface)
    log("🌐 Network Status: Ethernet Active - " .. tostring(ethernetActive) ..
            ", WiFi Power - " .. tostring(wifiPower))

    -- If screenLocked parameter is not provided, determine screen lock status
    if screenLocked == nil then
        screenLocked = hs.caffeinate.get("displayIdle")
    end
    log("🔒 Screen Locked Status: " .. tostring(screenLocked))

    if ethernetActive and not screenLocked then
        -- Ethernet is connected and screen is unlocked, turn off WiFi
        if wifiPower then
            hs.wifi.setPower(false, wifiInterface)
            log(
                "🔓 Screen Unlocked & Ethernet Connected: 📶 WiFi turned off.")
        end
    else
        -- At all other times, ensure WiFi is on for connectivity
        if not wifiPower then
            hs.wifi.setPower(true, wifiInterface)
            log("📶 WiFi turned on for connectivity.")
        end
    end
end

-- Execute the callback once at Hammerspoon startup to ensure correct network status
updateWifiEnabled()

-- Watch for network changes
wifiWatcher = hs.network.reachability.internet():setCallback(function(event)
    updateWifiEnabled()
end):start()

-- Watch for screen lock/unlock events
screenWatcher = hs.caffeinate.watcher.new(function(event)
    local screenLocked = nil
    if event == hs.caffeinate.watcher.screensDidLock then
        screenLocked = true
    elseif event == hs.caffeinate.watcher.screensDidUnlock then
        screenLocked = false
    end
    if screenLocked ~= nil then updateWifiEnabled(screenLocked) end
end):start()

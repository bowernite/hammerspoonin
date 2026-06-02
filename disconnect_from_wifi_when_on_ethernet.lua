require("utils/log")

-----------------------------------------------------------------------------------------------
-- Toggle Wifi based on Ethernet status and Screen Lock status
-----------------------------------------------------------------------------------------------
local ethernetInterface = "en6" -- Change to your Ethernet interface identifier
local wifiInterface = "en0" -- Change to your WiFi interface identifier

local function isEthernetActive(interface)
    local interfaceDetails = hs.network.interfaceDetails(interface)
    return interfaceDetails and interfaceDetails.IPv4 ~= nil
end

local function isWifiPowered(interface)
    local wifiDetails = hs.wifi.interfaceDetails(interface)
    return wifiDetails and wifiDetails.power
end

local function logNetworkStatus(ethernetActive, wifiPower)
    log("🌐 Network Status: Ethernet Interface - " .. ethernetInterface ..
            ", WiFi Interface - " .. wifiInterface)
    log("🌐 Network Status: Ethernet Active - " .. tostring(ethernetActive) ..
            ", WiFi Power - " .. tostring(wifiPower))
end

local function logScreenLockStatus(screenLocked)
    log("🔒 Screen Locked Status: " .. tostring(screenLocked))
    log("🕒 Timestamp: " .. os.date("%c"))
end

local function toggleWifiBasedOnEthernetAndScreenLock(screenLocked)
    local ethernetActive = isEthernetActive(ethernetInterface)
    local wifiPower = isWifiPowered(wifiInterface)

    logNetworkStatus(ethernetActive, wifiPower)

    if screenLocked == nil then
        screenLocked = hs.caffeinate.get("displayIdle")
    end
    logScreenLockStatus(screenLocked)

    log("🕒 Timestamp: " .. os.date("%c"))
    if ethernetActive and not screenLocked and wifiPower then
        hs.wifi.setPower(false, wifiInterface)
        logAction("🔓 Screen Unlocked & Ethernet Connected: 📶 WiFi turned off.")
    elseif not ethernetActive or screenLocked and not wifiPower then
        hs.wifi.setPower(true, wifiInterface)
        logAction("📶 WiFi turned on for connectivity.")
    end
end

-- Execute the callback once at Hammerspoon startup to ensure correct network status
toggleWifiBasedOnEthernetAndScreenLock()

-- Watch for network changes
wifiWatcher = hs.network.reachability.internet():setCallback(function(event)
    toggleWifiBasedOnEthernetAndScreenLock()
end):start()

-- Watch for screen lock/unlock events
screenWatcher = hs.caffeinate.watcher.new(function(event)
    local screenLocked = event == hs.caffeinate.watcher.screensDidLock
    toggleWifiBasedOnEthernetAndScreenLock(screenLocked)
end):start()


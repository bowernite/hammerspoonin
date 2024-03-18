-----------------------------------------------------------------------------------------------
-- Check Ethernet and Toggle Wifi
-----------------------------------------------------------------------------------------------
function networkChangedCallback()
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

    if ethernetActive and wifiPower then
        -- Ethernet is connected and WiFi is on, turn off WiFi
        hs.wifi.setPower(false, wifiInterface)
        hs.notify.new({
            title = "🌐 Network Status",
            informativeText = "🔌 Ethernet connected. 📶 WiFi turned off."
        }):send()
        log(
            "🌐 Network Status: 🔌 Ethernet connected. 📶 WiFi turned off.")
    elseif not ethernetActive and not wifiPower then
        -- Ethernet is disconnected and WiFi is off, turn on WiFi
        hs.wifi.setPower(true, wifiInterface)
        hs.notify.new({
            title = "🌐 Network Status",
            informativeText = "🔌 Ethernet disconnected. 📶 WiFi turned on."
        }):send()
        log(
            "🌐 Network Status: 🔌 Ethernet disconnected. 📶 WiFi turned on.")
    end
end

-- Execute the callback once at Hammerspoon startup to ensure correct network status
networkChangedCallback()

wifiWatcher = hs.network.reachability.internet():setCallback(
                  networkChangedCallback):start()

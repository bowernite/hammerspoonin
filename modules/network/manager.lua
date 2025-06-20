-------------------------------------------------------
-- Network Management Module
--
-- Handles WiFi, Ethernet, and network connection management
-- Usage: local networkManager = require('modules.network.manager')
-------------------------------------------------------

local log = require('utils.log')
local network = require('utils.network')

local M = {}

-- Private state
local wifiWatcher = nil
local ethernetWatcher = nil

-- Private functions
local function handleNetworkChange()
    log.log("Network configuration changed")
    
    -- Logic from disconnect_from_wifi_when_on_ethernet.lua would go here
    if M.isEthernetConnected() and M.isWiFiConnected() then
        log.logAction("Ethernet connected, disconnecting WiFi")
        M.disconnectWiFi()
    end
end

-- Public API
function M.start()
    if wifiWatcher then
        log.log("Network manager already started")
        return
    end
    
    -- Set up network watchers
    wifiWatcher = hs.wifi.watcher.new(handleNetworkChange)
    wifiWatcher:start()
    
    log.log("Network manager started")
end

function M.stop()
    if wifiWatcher then
        wifiWatcher:stop()
        wifiWatcher = nil
    end
    if ethernetWatcher then
        ethernetWatcher:stop()
        ethernetWatcher = nil
    end
    log.log("Network manager stopped")
end

function M.isWiFiConnected()
    local interface = hs.wifi.currentNetwork()
    return interface ~= nil
end

function M.isEthernetConnected()
    -- Check if ethernet is connected
    local interfaces = hs.network.interfaceDetails()
    for name, details in pairs(interfaces) do
        if name:match("^en%d+$") and details.Link and details.Link.Active then
            return true
        end
    end
    return false
end

function M.disconnectWiFi()
    local currentNetwork = hs.wifi.currentNetwork()
    if currentNetwork then
        hs.wifi.disassociate()
        log.logAction("Disconnected from WiFi: " .. currentNetwork)
        return true
    end
    return false
end

function M.getCurrentWiFiNetwork()
    return hs.wifi.currentNetwork()
end

function M.getNetworkInterfaces()
    return hs.network.interfaceDetails()
end

return M
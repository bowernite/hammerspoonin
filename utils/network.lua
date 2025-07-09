require("utils/log")

local function runCommand(command)
    return io.popen(command)
end

--- Check if internet is available by pinging Google
local function hasInternetConnection()
    local pingCmd = "ping -c 1 -W 3 google.com 2>/dev/null >/dev/null && echo 'connected' || echo 'disconnected'"
    local output = runCommand(pingCmd)
    local result = output:read("*all")
    output:close()

    return result:match("connected") ~= nil
end

--- Check if command output indicates a connectivity error
---
--- Parameters:
---  * output - String, command output to analyze
---
--- Returns:
---  * Boolean, true if the output indicates a connectivity/network error
local function isConnectivityError(output)
    if not output then
        return false
    end
    
    local connectivityPatterns = {
        "Failed to connect",
        "Connection timeout",
        "Network is unreachable",
        "Could not resolve host",
        "No route to host",
        "Connection refused",
        "curl:.*Connection timed out",
        "curl:.*Could not resolve host",
        "getaddrinfo.*nodename nor servname provided",
        "Failed to download resource",
        "Error: No such file or directory"
    }
    
    for _, pattern in ipairs(connectivityPatterns) do
        if output:match(pattern) then
            return true
        end
    end
    
    return false
end

--- Connect to any WiFi network (async)
---
--- Parameters:
---  * ssid - String, network SSID
---  * password - String, network password
---  * callback - Optional function called with (success, message) when complete
---  * interface - Optional string, WiFi interface name (defaults to "en0")
local function connectToNetwork(ssid, password, callback, interface)
    interface = interface or "en0"

    -- Make callback optional
    local function finalCallback(success, message)
        if callback and type(callback) == "function" then
            callback(success, message)
        else
            if success then
                logAction("Connection completed: " .. message)
            else
                logWarning("Connection failed: " .. message)
            end
        end
    end

    logAction("Attempting to connect to network: " .. ssid)

    function attemptConnection()
        log("Attempting to connect to '" .. ssid .. "'")
        local success = hs.wifi.associate(ssid, password, interface)

        if success then
            -- Verify connection after a short delay
            hs.timer.doAfter(3, function()
                local currentNetwork = hs.wifi.currentNetwork(interface)
                if currentNetwork == ssid then
                    finalCallback(true, "Connected successfully to '" .. ssid .. "'")
                else
                    finalCallback(false, "Connection failed - connected to '" .. (currentNetwork or "none") ..
                        "' instead of '" .. ssid .. "'")
                end
            end)
        else
            finalCallback(false, "Failed to associate with network '" .. ssid .. "'")
        end
    end

    -- Check if WiFi is powered on, turn it on if needed
    if not hs.wifi.interfaceDetails(interface).power then
        logAction("Turning on WiFi interface")
        if not hs.wifi.setPower(true, interface) then
            finalCallback(false, "Failed to power on WiFi interface")
            return
        end

        -- Wait for WiFi to initialize then try connection
        hs.timer.doAfter(2, function()
            attemptConnection()
        end)
    else
        attemptConnection()
    end
end

return {
    hasInternetConnection = hasInternetConnection,
    connectToNetwork = connectToNetwork,
    isConnectivityError = isConnectivityError
}

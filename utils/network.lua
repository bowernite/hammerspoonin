local function runCommand(command)
    return io.popen(command)
end

local function hasInternetConnection()
    local pingCmd = "ping -c 1 -W 3 google.com 2>/dev/null >/dev/null && echo 'connected' || echo 'disconnected'"
    local output = runCommand(pingCmd)
    local result = output:read("*all")
    output:close()
    
    return result:match("connected") ~= nil
end

local function isConnectivityError(result)
    return result:match("Could not resolve host") ~= nil or 
           result:match("Failed to connect") ~= nil or
           result:match("Operation timed out") ~= nil or
           result:match("No route to host") ~= nil
end

return {
    hasInternetConnection = hasInternetConnection,
    isConnectivityError = isConnectivityError
}
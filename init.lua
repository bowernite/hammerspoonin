hs.console.clearConsole()

-- Utility function to format screen dimensions
local function formatScreenForLog(screen)
    local screenFrame = screen:frame()
    return string.format("%s (Dimensions: w=%d, h=%d)", screen:name(),
                         screenFrame.w, screenFrame.h)
end

-- Utility function to format window dimensions and coordinates
local function formatWindowForLog(window)
    local windowFrame = window:frame()
    return string.format(
               "%s - %s (Dimensions: w=%d, h=%d, Coordinates: x=%d, y=%d)",
               window:application():name(), window:title(), windowFrame.w,
               windowFrame.h, windowFrame.x, windowFrame.y)
end

function log(message, details)
    local logMessage = "\n🔍 " .. message
    if details then
        for key, value in pairs(details) do
            if type(value) == "userdata" and value:frame() then
                if type(value.isScreen) == "function" and value:isScreen() then
                    logMessage = logMessage .. " | " .. key .. ": " ..
                                     formatScreenForLog(value)
                elseif type(value.isWindow) == "function" and value:isWindow() then
                    logMessage = logMessage .. " | " .. key .. ": " ..
                                     formatWindowForLog(value)
                end
            else
                logMessage = logMessage .. " | " .. key .. ": " ..
                                 tostring(value)
            end
        end
    end
    hs.console.printStyledtext(logMessage)
end

windowScreenMap = {}
centeredWindows = {} -- Dictionary to keep track of centered windows
maximizedWindows = {} -- Dictionary to keep track of maximized windows

function updateWindowScreenMap(windowID, screenID)
    windowScreenMap[windowID] = screenID
end

-- Function to check if a window is centered on its screen
function isWindowCentered(window)
    local windowFrame = window:frame()
    local screenFrame = window:screen():frame()
    -- Adjusting the window's coordinates relative to its current screen
    local windowCenter = {
        x = windowFrame.x - screenFrame.x + windowFrame.w / 2,
        y = windowFrame.y - screenFrame.y + windowFrame.h / 2
    }
    local screenCenter = {x = screenFrame.w / 2, y = screenFrame.h / 2}
    local isCentered = math.abs(windowCenter.x - screenCenter.x) < 1 and
                           math.abs(windowCenter.y - screenCenter.y) < 1
    log("Window Centered Check: ",
        {window, screen = window:screen(), isCentered})
    return isCentered
end

-- Function to update window screen map, screen dimensions, centered and maximized windows
function updateWindowStatus()
    local allWindows = hs.window.allWindows()
    for _, window in ipairs(allWindows) do
        local windowID = window:id()

        -- Update centered windows
        centeredWindows[windowID] = isWindowCentered(window)

        -- Update maximized windows
        local screenFrame = window:screen():frame()
        maximizedWindows[windowID] = window:isFullScreen() or
                                         (window:frame().w == screenFrame.w and
                                             window:frame().h == screenFrame.h)
    end
end

function maximizeWindow(window)
    log("Maximizing window", {window})

    local screenFrame = window:screen():frame()
    window:setFrame(screenFrame)
    maximizedWindows[window:id()] = true
end

function centerWindowOnNewScreen(window)
    log("Centering window", {window})
    window:centerOnScreen(currentScreen, false, 0) -- Center on the new screen without animation
    centeredWindows[windowID] = true
end

-- Function to maximize window if moved to a new screen and was maximized
function maximizeWindowOnNewScreenIfNecessary(window)
    local appName = window:application():name()
    local windowName = window:title()
    if appName == 'Alfred' and windowName == 'Alfred' then
        log("Exiting due to Alfred window", {window})
        return
    end
    
    local windowID, currentScreenID = window:id(), window:screen():id()

    if currentScreenID ~= windowScreenMap[windowID] then
        local newScreen = hs.screen.find(currentScreenID)

        if maximizedWindows[windowID] then
            log("Was Maximized ✅")
            maximizeWindow(window)
            return
        end
        
        -- Just center all windows when they move screens
        -- This will have to change if/when we start to do fancy proportional stuff, like with split windows and whatnot
        local appName = window:application():name()
        if appName ~= 'Remotasks' and appName ~= 'Remotasks Helper' then
            log("Centering window", {window})
            window:centerOnScreen(currentScreen, false, 0) -- Center on the new screen without animation
            centeredWindows[windowID] = true
        end

        -- Check if the window was centered using the centeredWindows dictionary
        -- if centeredWindows[windowID] then
        --     log("Was Centered✅")
        --     window:centerOnScreen(currentScreen, false, 0) -- Center on the new screen without animation
        --     centeredWindows[windowID] = true
        -- end
    end

    -- Update the window's screen ID in the map and check if it's centered
    centeredWindows[windowID] = isWindowCentered(window)
end

-- Watch for window events
windowWatcher = hs.window.filter.new(nil)

windowWatcher:subscribe(hs.window.filter.windowCreated, function(window)
    log("Window created", {window, screen = window:screen()})
    maximizeWindowOnNewScreenIfNecessary(window)

    updateWindowScreenMap(window:id(), window:screen():id())

    -- Maximize windows for specific apps
    -- WIP
    local app = window:application():name()
    if app == "Google Chrome" or app == "Notion Calendar" or app == "kitty" or
        app == "Trello" then
        if window:title() ~= "" then
            if app == "superwhisper" then
                window:centerOnScreen(nil, true, 0)
            else
                maximizeWindow(window)
            end
        else
            log("Skipped maximizing due to empty window title", {app})
        end
    end
end)

windowWatcher:subscribe(hs.window.filter.windowMoved, function(window)
    local windowID = window:id()
    log("Window moved", {window, screen = window:screen()})
    maximizeWindowOnNewScreenIfNecessary(window)

    updateWindowScreenMap(window:id(), window:screen():id())
end)

-- Initialize
updateWindowStatus()
log("Hammerspoon initialized and window screen map updated")

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

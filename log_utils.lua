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

                    if value:title() == "" then return end
                end
            else
                logMessage = logMessage .. " | " .. key .. ": " ..
                                 tostring(value)
            end
        end
    end
    hs.console.printStyledtext(logMessage)
end

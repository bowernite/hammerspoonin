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

-- Utility function to format details for log
local function formatDetailsForLog(details)
    local logMessage = ""
    for key, value in pairs(details) do
        if type(value) == "userdata" and value:frame() then
            if type(value.isScreen) == "function" and value:isScreen() then
                logMessage = logMessage .. " " ..
                                 (type(key) == "number" and "" or (key .. ": ")) ..
                                 formatScreenForLog(value)
            elseif type(value.isWindow) == "function" and value:isWindow() then
                logMessage = logMessage .. " " ..
                                 (type(key) == "number" and "" or (key .. ": ")) ..
                                 formatWindowForLog(value)

                if value:title() == "" then return logMessage end
            end
        else
            logMessage = logMessage ..
                             (type(key) == "number" and "" or (key .. ": ")) ..
                             tostring(value)
        end
    end
    return logMessage
end

-- Generate a deterministic random color based on the first 12 characters of the message
local function generateColorFromMessage(message)
    local hash = 0
    for i = 1, math.min(12, #message) do
        hash = (hash * 31 + message:byte(i)) % 0xFFFFFF
    end
    return {
        red = ((hash & 0xFF0000) >> 16) / 255,
        green = ((hash & 0x00FF00) >> 8) / 255,
        blue = (hash & 0x0000FF) / 255
    }
end

-- Ensure the color has enough contrast with the white background
local function ensureContrast(color)
    local function luminance(r, g, b)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    end

    local function adjustColor(color)
        local lum = luminance(color.red, color.green, color.blue)
        if lum > 0.6 then
            -- If the color is too light, darken it more aggressively
            return {
                red = color.red * 0.5,
                green = color.green * 0.5,
                blue = color.blue * 0.5
            }
        elseif lum < 0.3 then
            -- If the color is too dark, lighten it more aggressively
            return {
                red = color.red + (1 - color.red) * 0.5,
                green = color.green + (1 - color.green) * 0.5,
                blue = color.blue + (1 - color.blue) * 0.5
            }
        end
        return color
    end

    local adjustedColor = adjustColor(color)
    -- Adjust the color until it has enough contrast
    local lum = luminance(adjustedColor.red, adjustedColor.green,
                          adjustedColor.blue)
    -- while lum <= 0.3 or lum >= 0.7 do
    adjustedColor = adjustColor(adjustedColor)
    lum = luminance(adjustedColor.red, adjustedColor.green, adjustedColor.blue)
    -- end
    return adjustedColor
end

-- Mapping of filenames to emojis
local fileEmojis = {
    ["window_utils.lua"] = "🪟",
    ["window_management.lua"] = "🪟",
    ["log_utils.lua"] = "📘",
    ["utils.lua"] = "🔧",
    ["boot.lua"] = "🚀",
    ["init.lua"] = "🔄",
    ["vivid_fix.lua"] = "💡",
    ["morning_space.lua"] = "🌅",
    ["reset_apps.lua"] = "🔄",
    ["disconnect_from_wifi_when_on_ethernet.lua"] = "📶"
}

function log(message, details)
    local time = os.date("%I:%M %p"):gsub("^0", ""):gsub(" ", ""):lower()

    -- Get the filename of the calling script
    local filename = debug.getinfo(2, "S").source:match("^.+/(.+)$")
    local emoji = fileEmojis[filename] or "🔍"

    local logMessage = "[" .. time .. "] " .. emoji .. " " .. message
    if details then
        logMessage = logMessage .. "\n\t" .. formatDetailsForLog(details) ..
                         "\n"
    end

    local color = ensureContrast(generateColorFromMessage(message))
    hs.console.printStyledtext(hs.styledtext.new(logMessage, {
        color = color,
        font = {name = "Menlo", size = 18}
    }))
end

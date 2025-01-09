-- Utility function to format screen dimensions
local function formatScreenForLog(screen)
    if not screen then
        return "(none)"
    end
    local screenFrame = screen:frame()
    return string.format("%s (Dimensions: w=%d, h=%d)", screen:name(), screenFrame.w, screenFrame.h)
end

-- Utility function to format window dimensions and coordinates
local function formatWindowForLog(window)
    if not window then
        return "(null window)"
    end
    local windowFrame = window:frame()
    local app = window:application()
    local appName = app and app:name() or "Unknown app name"
    return string.format("%s (app) - %s (window) (Dimensions: w=%d, h=%d, Coordinates: x=%d, y=%d)", appName,
        window:title(), windowFrame.w, windowFrame.h, windowFrame.x, windowFrame.y)
end

-- Utility function to format details for log
local function formatDetailsForLog(details)
    if type(details) ~= "table" then
        return tostring(details) .. "\n"
    end

    local logMessage = ""
    for key, value in pairs(details) do
        local keyLabel = type(key) == "number" and "" or (key .. ": ")
        logMessage = logMessage .. "\t"

        if type(value) == "userdata" and value and value.frame and value:frame() then
            if type(value.isScreen) == "function" and value:isScreen() then
                logMessage = logMessage .. keyLabel .. formatScreenForLog(value)
            elseif type(value.isWindow) == "function" and value:isWindow() then
                logMessage = logMessage .. keyLabel .. formatWindowForLog(value)
            else
                logMessage = logMessage .. keyLabel .. (value ~= nil and tostring(value) or "(none)")
            end
            logMessage = logMessage .. " (type:" .. type(value) .. ")"
        elseif type(value) == "table" then
            logMessage = logMessage .. keyLabel .. "\n"
            logMessage = logMessage .. formatDetailsForLog(value)
        else
            logMessage = logMessage .. keyLabel .. (value ~= nil and tostring(value) or "(none)")
        end
        logMessage = logMessage .. "\n"
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

-- Ensure the color has enough contrast with the given background
local function ensureContrast(color, isBlackBackground)
    local function luminance(r, g, b)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    end

    local function adjustColor(color, isBlackBackground)
        local lum = luminance(color.red, color.green, color.blue)
        if isBlackBackground then
            if lum < 0.5 then
                -- If the color is too dark for a black background, lighten it
                return {
                    red = color.red + (1 - color.red) * 0.5,
                    green = color.green + (1 - color.green) * 0.5,
                    blue = color.blue + (1 - color.blue) * 0.5
                }
            end
        else
            if lum > 0.6 then
                -- If the color is too light for a white background, darken it
                return {
                    red = color.red * 0.5,
                    green = color.green * 0.5,
                    blue = color.blue * 0.5
                }
            elseif lum < 0.3 then
                -- If the color is too dark for a white background, lighten it
                return {
                    red = color.red + (1 - color.red) * 0.5,
                    green = color.green + (1 - color.green) * 0.5,
                    blue = color.blue + (1 - color.blue) * 0.5
                }
            end
        end
        return color
    end

    local adjustedColor = adjustColor(color, isBlackBackground)
    local lum = luminance(adjustedColor.red, adjustedColor.green, adjustedColor.blue)

    -- Adjust further if needed
    if isBlackBackground and lum < 0.4 then
        adjustedColor = adjustColor(adjustedColor, isBlackBackground)
    elseif not isBlackBackground and (lum < 0.3 or lum > 0.7) then
        adjustedColor = adjustColor(adjustedColor, isBlackBackground)
    end

    return adjustedColor
end

-- Mapping of filenames to emojis
local fileEmojis = {
    ["window_utils.lua"] = "🪟",
    ["window_management.lua"] = "🪟",
    ["log.lua"] = "📘",
    ["utils.lua"] = "🔧",
    ["boot.lua"] = "🚀",
    ["init.lua"] = "🔄",
    ["screen_color_and_brightness.lua"] = "🔆",
    ["morning_space.lua"] = "🌅",
    ["reset_apps.lua"] = "🔄",
    ["disconnect_from_wifi_when_on_ethernet.lua"] = "📶",
    ["caffeinate.lua"] = "☕",
    ["app_utils.lua"] = "📱",
    ["fresh_unlock.lua"] = "🔓",
    ["night_blocking.lua"] = "🌙",
    ["audio_devices.lua"] = "🎧"
}

local lastLogTime = os.time()

-- Convenience logger function, with lots of useful functionality
function log(message, details, styleOptions, level)
    -- Add newlines every 30 minutes, to visualize the time elapsed between logs
    local currentTime = os.time()
    local timeDiff = currentTime - lastLogTime
    local thirtyMinutes = 1800 -- 30 minutes in seconds
    local numNewLines = math.min(20, math.floor(timeDiff / thirtyMinutes))
    local newLines = string.rep("•\n\n\n\n", numNewLines)

    local time = os.date("%I:%M:%S %p"):gsub("^0", ""):gsub(" ", ""):lower()

    -- Get the filename of the calling script
    local stackLevel = level or 2
    local filename = debug.getinfo(stackLevel, "S").source:match("^.+/(.+)$")
    local emoji = fileEmojis[filename] or "🔍"

    local logMessage = newLines .. "[" .. time .. "] " .. emoji .. " " .. message
    if details then
        logMessage = logMessage .. "\n" .. formatDetailsForLog(details)
    end

    local isBlackBackground =
        styleOptions and styleOptions.backgroundColor and styleOptions.backgroundColor.red == 0 and
            styleOptions.backgroundColor.green == 0 and styleOptions.backgroundColor.blue == 0

    local color = ensureContrast(generateColorFromMessage(message), isBlackBackground)

    local defaultStyle = {
        color = color,
        font = {
            name = "Menlo",
            size = 18
        }
    }

    -- Merge defaultStyle with styleOptions
    local finalStyle = {}
    for k, v in pairs(defaultStyle) do
        finalStyle[k] = v
    end
    if styleOptions then
        for k, v in pairs(styleOptions) do
            finalStyle[k] = v
        end
    end

    hs.console.printStyledtext(hs.styledtext.new(logMessage, finalStyle))

    lastLogTime = currentTime
end

-- Logger function for when we're going to do a concrete action (e.g. maximize a window, kill an app, etc.)
function logAction(message, details)
    log(message, details, {
        backgroundColor = {
            red = 0,
            green = 0,
            blue = 0
        }
    }, 3)
end

-- Logger function for errors
function logError(message, details)
    log(message, details, {
        color = {
            red = 1,
            green = 0,
            blue = 0
        },
        backgroundColor = {
            red = 0.2,
            green = 0,
            blue = 0
        }
    }, 3)
    hs.notify.show("❌ Hammerspoon error", "", details)
end

-- Logger function for warnings
function logWarning(message, details)
    log(message, details, {
        color = {
            red = 1,
            green = 1,
            blue = 0
        },
        backgroundColor = {
            red = 0.2,
            green = 0.2,
            blue = 0
        }
    }, 3)
end

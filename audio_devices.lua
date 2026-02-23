-------------------------------------------------------
-- audio_devices.lua
--
-- Manages audio devices
-- - Prioritized list of input devices
-------------------------------------------------------
require("utils/log")

-- List of input devices, in priority order
-- De-duplicated and added MacBook Pro Microphone as last fallback
local preferredInputDevices = {
    -- "Wave Link Stream",            -- Only if Elgato USB present
    "Elgato Wave:3",
    "C922 Pro Stream Webcam",
    "Brett's AirPods",
    "MacBook Pro Microphone"       -- Always last fallback
}

local function normalizeDeviceName(name)
    if not name then
        return ""
    end

    -- Normalize common punctuation differences (straight vs smart quotes)
    -- and compare case-insensitively so minor renames don't break matching.
    local normalized = name
        :gsub("[’']", "") -- strip both straight and curly apostrophes
        :lower()

    return normalized
end

local function setInputDevice(dev)
    log("Ensuring input device is set to:", dev:name())
    local currentInputDevice = hs.audiodevice.defaultInputDevice()
    if currentInputDevice:name() == dev:name() then
        log("Device already default:", dev:name())
        return
    end
    
    -- Add guard: only set if device is input device (removed online() check as it doesn't exist)
    if dev:isInputDevice() then
        dev:setDefaultInputDevice()
        logAction("Switched input to:", dev:name())
    else
        logWarning("Cannot set input device - device not available:", dev:name())
    end
end

-- Check for actual Elgato USB hardware presence instead of audio device name matching
local function hasElgatoDevice()
    local usbDevices = hs.usb.attachedDevices()
    for _, device in ipairs(usbDevices) do
        -- Check for Elgato vendor ID (0x0FD9) or Wave product names
        if device.vendorID == 0x0FD9 or 
           (device.productName and device.productName:match("Wave")) then
            log("Found Elgato USB device:", device.productName or "Unknown")
            return true
        end
    end
    return false
end

local function shouldConsiderDevice(deviceName)
    -- Short-circuit Wave Link Stream if no Elgato hardware present
    if deviceName == "Wave Link Stream" then
        return hasElgatoDevice()
    end
    return true
end

local function ensurePrioritizedInputDevice()
    local audioDevices = hs.audiodevice.allInputDevices()
    log("Ensuring input device is set by priority", {
        audioDevices = audioDevices,
        currentInputDevice = hs.audiodevice.defaultInputDevice()
    })

    for _, deviceName in ipairs(preferredInputDevices) do
        if shouldConsiderDevice(deviceName) then
            local targetName = normalizeDeviceName(deviceName)

            -- Match against the actual list of input devices we just fetched,
            -- using normalized names so small naming differences don't break priority.
            for _, dev in ipairs(audioDevices) do
                if normalizeDeviceName(dev:name()) == targetName then
                    setInputDevice(dev)
                    return
                end
            end
        end
    end

    -- Structured logging for debugging when no preferred device found
    logWarning("No preferred input device found; input device was not changed")
    log("Available audio devices:", hs.json.encode(audioDevices))
end

-- Watch for changes in audio devices
-- Debounce so we wait for macOS's event storm to settle before enforcing preference
local audioDebounceTimer = nil
local AUDIO_DEBOUNCE_SECONDS = 0.5

AUDIO_WATCHER = hs.audiodevice.watcher
AUDIO_WATCHER.setCallback(function(event)
    log("audioDeviceCallback", event)
    if event == "dev#" or event == "dIn " then
        if audioDebounceTimer then
            audioDebounceTimer:stop()
        end
        audioDebounceTimer = hs.timer.doAfter(AUDIO_DEBOUNCE_SECONDS, function()
            log("audioDeviceCallback (debounced); setting default input device")
            ensurePrioritizedInputDevice()
        end)
    end
end)
AUDIO_WATCHER.start()

-- Watch for USB device changes (specifically for Elgato devices)
-- Fixed: USB watcher callback receives one table parameter, not separate device and event
USB_WATCHER = hs.usb.watcher.new(function(data)
    log("USB device event:", {eventType = data.eventType, vendorID = data.vendorID, productName = data.productName})
    -- Check if this is an Elgato device (guard against nil productName)
    if data.vendorID == 0x0FD9 or 
       (data.productName and data.productName:match("Wave")) then
        log("Elgato USB device change detected, updating input device")
        ensurePrioritizedInputDevice()
    end
end)
USB_WATCHER:start()

-- Optional: Safety timer disabled to avoid overriding manual user choices
-- AUDIO_SAFETY_TIMER = hs.timer.doEvery(10, function()
--     pcall(ensurePrioritizedInputDevice)
-- end)

-- Ensure proper device is set on initial load
ensurePrioritizedInputDevice()

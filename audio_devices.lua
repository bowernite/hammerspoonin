-------------------------------------------------------
-- audio_devices.lua
--
-- Manages audio devices
-- - Prioritized list of input devices
-------------------------------------------------------
require("utils/log")

-- List of input devices, in priority order
-- Do *not* modify the names in this list / the apostrophes
local preferredInputDevices = {"C922 Pro Stream Webcam", "Brett's AirPods", "Brett's AirPods Pro",
                               "Brett’s AirPods Pro", "Brett’s AirPods"}

local function setInputDevice(dev)
    log("Ensuring input device is set to:", dev:name())
    local currentInputDevice = hs.audiodevice.defaultInputDevice()
    if currentInputDevice:name() == dev:name() then
        log("Device already default:", dev:name())
        return
    end
    dev:setDefaultInputDevice()
    logAction("Switched input to:", dev:name())
end

local function useBuiltinIfInOffice()
    local audioDevices = hs.audiodevice.allInputDevices()
    local webcamConnected = false
    local builtInAvailable = false
    local builtInDevice = nil

    for _, dev in ipairs(audioDevices) do
        if dev:name() == "C922 Pro Stream Webcam" then
            webcamConnected = true
        end
        if dev:transportType() == "Built-in" and dev:jackConnected() then
            builtInAvailable = true
            builtInDevice = dev
        end
    end

    log("Checking if webcam is connected and built-in is available", {
        webcamConnected = webcamConnected,
        builtInAvailable = builtInAvailable,
        builtInDevice = builtInDevice
    })

    -- TODO: Doesn't work yet, can't get a watcher to fire when built-in availability changes
    -- TODO: Also, builtinAvailable is always false still. jackConnected doesn't seem to work as we're trying to use it 
    -- if builtInStatus.webcamConnected and builtInStatus.builtInAvailable and builtInStatus.builtInDevice then
    --     setInputDevice(builtInStatus.builtInDevice)
    --     return true
    -- end

    return false
end

local function ensurePrioritizedInputDevice()
    local audioDevices = hs.audiodevice.allInputDevices()
    log("Ensuring input device is set by priority", {
        audioDevices = audioDevices,
        currentInputDevice = hs.audiodevice.defaultInputDevice()
    })

    local switchedToBuiltIn = useBuiltinIfInOffice()
    if switchedToBuiltIn then
        return
    end

    for _, deviceName in ipairs(preferredInputDevices) do
        for _, dev in ipairs(audioDevices) do
            if dev:name() == deviceName then
                setInputDevice(dev)
                return
            end
        end
    end

    logWarning("No preferred input device found; input device was not changed")
end

-- Watch for changes in audio devices
local watcher = hs.audiodevice.watcher
watcher.setCallback(function(event)
    log("audioDeviceCallback", event)
    local deviceListChangedEvent = "dev#"
    if event == "dev#" then
        log("audioDeviceCallback; setting default input device")
        ensurePrioritizedInputDevice()
    end
end)
watcher.start()

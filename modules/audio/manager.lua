-------------------------------------------------------
-- Audio Device Manager Module
--
-- Manages audio device priorities and switching
-- Usage: local audio = require('modules.audio.manager')
-------------------------------------------------------

local log = require('utils.log')

local M = {}

-- Private state
local preferredInputDevices = {
    "Wave Link Stream", -- Elgato Wave:3 output (after effects)
    "Brett's AirPods",
    "Brett's AirPods Pro",
}

local watcher = nil

-- Private functions
local function setInputDevice(dev)
    log("Ensuring input device is set to:", dev:name())
    local currentInputDevice = hs.audiodevice.defaultInputDevice()
    if currentInputDevice:name() == dev:name() then
        log("Device already default:", dev:name())
        return
    end
    dev:setDefaultInputDevice()
    log("Switched input to:", dev:name())
end

local function hasElgatoDevice(audioDevices)
    for _, dev in ipairs(audioDevices) do
        if string.lower(dev:name()):find("elgato") then
            return true
        end
    end
    return false
end

local function shouldConsiderDevice(deviceName, audioDevices)
    if deviceName == "Wave Link Stream" then
        return hasElgatoDevice(audioDevices)
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
        if shouldConsiderDevice(deviceName, audioDevices) then
            for _, dev in ipairs(audioDevices) do
                if dev:name() == deviceName then
                    setInputDevice(dev)
                    return
                end
            end
        end
    end

    log("No preferred input device found; input device was not changed")
end

-- Public API
function M.start()
    if watcher then
        log("Audio watcher already started")
        return
    end
    
    watcher = hs.audiodevice.watcher
    watcher.setCallback(function(event)
        log("Audio device callback", event)
        if event == "dev#" then
            log("Device list changed; setting default input device")
            ensurePrioritizedInputDevice()
        end
    end)
    watcher.start()
    log("Audio device watcher started")
end

function M.stop()
    if watcher then
        watcher.stop()
        watcher = nil
        log("Audio device watcher stopped")
    end
end

function M.setPreferredDevices(devices)
    preferredInputDevices = devices
    log("Updated preferred input devices", devices)
end

function M.getCurrentDevice()
    return hs.audiodevice.defaultInputDevice()
end

return M
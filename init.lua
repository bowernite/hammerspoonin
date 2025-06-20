-------------------------------------------------------
-- Hammerspoon Configuration
-- 
-- Main initialization file following proper Lua module patterns
-- Coordinates all modules and handles startup sequence
-------------------------------------------------------

-- Clear console and set up basic configuration
hs.console.clearConsole()
hs.console.consoleFont({
    name = "Menlo",
    size = 18
})

-- Install CLI if needed
hs.ipc.cliInstall()

-- Load utility modules first (these provide global functions for backward compatibility)
local log = require('utils.log')

-- Load all main modules
local audioManager = require('modules.audio.manager')
local windowManager = require('modules.window.manager')
local appManager = require('modules.apps.manager')
local bootManager = require('modules.system.boot')
local networkManager = require('modules.network.manager')
local screenManager = require('modules.system.screen')

-- Load legacy modules that haven't been converted yet
require("screen_color_and_brightness")
require("homebrew_autoupdate")
require("forced_breaks")
require("hammerspoon_console_auto_dark_mode")

-- Store managers globally for access from other modules
_G.HammerspoonManagers = {
    audio = audioManager,
    window = windowManager,
    apps = appManager,
    boot = bootManager,
    network = networkManager,
    screen = screenManager
}

-- Initialize all modules
local function initializeModules()
    log.log("Initializing Hammerspoon modules...")
    
    -- Start core functionality
    audioManager.start()
    windowManager.start()
    networkManager.start()
    screenManager.start()
    
    log.log("All modules initialized successfully")
end

-- Handle system boot sequence
local function handleBootSequence()
    bootManager.recordReload()
    
    if bootManager.runBootSequence() then
        log.logAction("Boot sequence completed")
    else
        log.log("Skipped boot sequence - regular reload")
    end
end

-- Main initialization
local function main()
    log.log("Starting Hammerspoon configuration...")
    
    -- Initialize modules
    initializeModules()
    
    -- Handle boot sequence
    handleBootSequence()
    
    -- Load work-specific configuration if it exists
    local workConfig = "work/work"
    local workConfigPath = hs.fs.pathToAbsolute(workConfig .. ".lua")
    if workConfigPath then
        log.log("Loading work configuration")
        require(workConfig)
    end
    
    log.log("Hammerspoon configuration loaded successfully")
end

-- Run main initialization
main()

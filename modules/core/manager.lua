-------------------------------------------------------
-- Core Manager Module
--
-- Coordinates all other modules and handles the main lifecycle
-- Usage: local coreManager = require('modules.core.manager')
-------------------------------------------------------

local log = require('utils.log')
local config = require('config.modules')

local M = {}

-- Private state
local activeModules = {}
local isInitialized = false

-- Module registry - maps module names to their require paths
local moduleRegistry = {
    audio = 'modules.audio.manager',
    window = 'modules.window.manager',
    apps = 'modules.apps.manager',
    boot = 'modules.system.boot',
    network = 'modules.network.manager',
    screen = 'modules.system.screen',
}

-- Private functions
local function loadModule(moduleName)
    if not config.modules[moduleName] then
        log.log("Module disabled in config: " .. moduleName)
        return nil
    end
    
    local requirePath = moduleRegistry[moduleName]
    if not requirePath then
        log.logError("Unknown module: " .. moduleName)
        return nil
    end
    
    local success, module = pcall(require, requirePath)
    if not success then
        log.logError("Failed to load module: " .. moduleName, {error = module})
        return nil
    end
    
    log.log("Loaded module: " .. moduleName)
    return module
end

-- Public API
function M.initialize()
    if isInitialized then
        log.logWarning("Core manager already initialized")
        return false
    end
    
    log.log("Initializing core manager...")
    
    -- Load all enabled modules
    for moduleName, _ in pairs(moduleRegistry) do
        local module = loadModule(moduleName)
        if module then
            activeModules[moduleName] = module
        end
    end
    
    -- Initialize all loaded modules
    for moduleName, module in pairs(activeModules) do
        if module.start then
            local success, err = pcall(module.start)
            if not success then
                log.logError("Failed to start module: " .. moduleName, {error = err})
            else
                log.log("Started module: " .. moduleName)
            end
        end
    end
    
    isInitialized = true
    log.log("Core manager initialization complete")
    return true
end

function M.shutdown()
    if not isInitialized then
        log.logWarning("Core manager not initialized")
        return false
    end
    
    log.log("Shutting down core manager...")
    
    -- Stop all modules
    for moduleName, module in pairs(activeModules) do
        if module.stop then
            local success, err = pcall(module.stop)
            if not success then
                log.logError("Failed to stop module: " .. moduleName, {error = err})
            else
                log.log("Stopped module: " .. moduleName)
            end
        end
    end
    
    activeModules = {}
    isInitialized = false
    log.log("Core manager shutdown complete")
    return true
end

function M.reload()
    log.log("Reloading core manager...")
    M.shutdown()
    -- Force reload of all modules
    for moduleName, requirePath in pairs(moduleRegistry) do
        package.loaded[requirePath] = nil
    end
    package.loaded['config.modules'] = nil
    config = require('config.modules')
    return M.initialize()
end

function M.getModule(moduleName)
    return activeModules[moduleName]
end

function M.getActiveModules()
    return activeModules
end

function M.isModuleActive(moduleName)
    return activeModules[moduleName] ~= nil
end

function M.getStatus()
    return {
        initialized = isInitialized,
        activeModules = activeModules,
        moduleCount = #activeModules
    }
end

return M
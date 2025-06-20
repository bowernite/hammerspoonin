# Hammerspoon Configuration

A modular, well-organized Hammerspoon configuration following Lua best practices.

## 🏗️ Architecture

This configuration follows a modular architecture with proper separation of concerns:

```
├── init.lua                    # Main entry point
├── config/
│   └── modules.lua            # Module configuration
├── modules/
│   ├── audio/
│   │   └── manager.lua        # Audio device management
│   ├── window/
│   │   ├── manager.lua        # Window management coordinator
│   │   ├── utils.lua          # Window utilities
│   │   ├── blacklist.lua      # Window blacklist management
│   │   └── default_sizes.lua  # Default window sizes
│   ├── system/
│   │   ├── boot.lua           # Boot detection and initialization
│   │   └── screen.lua         # Screen management
│   ├── network/
│   │   └── manager.lua        # Network management
│   ├── apps/
│   │   └── manager.lua        # Application management
│   └── core/
│       └── manager.lua        # Core module coordinator
└── utils/                     # Utility modules
    ├── log.lua                # Logging system
    ├── app_utils.lua          # App utilities
    ├── dark_mode.lua          # Dark mode detection
    └── ...                    # Other utilities
```

## 🚀 Key Features

### Proper Module System
- Each module follows Lua conventions with explicit exports
- Clean separation between public and private APIs
- Consistent error handling and logging

### Configuration Management
- Centralized configuration in `config/modules.lua`
- Easy to enable/disable modules
- Module-specific settings in one place

### Lifecycle Management
- Proper startup and shutdown sequences
- Clean module initialization and cleanup
- Graceful error handling

### Backward Compatibility
- Global functions maintained for existing code
- Gradual migration path for legacy modules

## 🎯 Module Overview

### Audio Manager (`modules/audio/manager.lua`)
- Manages audio device priorities
- Automatic switching based on availability
- Elgato Wave:3 integration

### Window Manager (`modules/window/manager.lua`)
- Intelligent window positioning
- Screen change detection
- Application-specific default sizes
- Window blacklisting

### App Manager (`modules/apps/manager.lua`)
- Essential app management
- Startup sequences
- Repository opening automation

### Boot Manager (`modules/system/boot.lua`)
- System boot detection
- Initialization sequences
- Colima Docker management

### Network Manager (`modules/network/manager.lua`)
- WiFi/Ethernet management
- Automatic WiFi disconnect when Ethernet connects

## 📖 Usage

### Basic Usage
The configuration loads automatically when Hammerspoon starts. All modules are initialized based on settings in `config/modules.lua`.

### Accessing Modules
```lua
-- Access managers globally
local audioManager = _G.HammerspoonManagers.audio
local windowManager = _G.HammerspoonManagers.window

-- Or require directly
local audioManager = require('modules.audio.manager')
```

### Configuration
Edit `config/modules.lua` to:
- Enable/disable modules
- Configure module-specific settings
- Adjust behavior parameters

### Creating New Modules
Follow the established pattern:

```lua
-------------------------------------------------------
-- Your Module Name
--
-- Description of what this module does
-- Usage: local yourModule = require('modules.category.your_module')
-------------------------------------------------------

local log = require('utils.log')

local M = {}

-- Private state
local someState = {}

-- Private functions
local function privateFunction()
    -- Implementation
end

-- Public API
function M.start()
    -- Module initialization
    log.log("Your module started")
end

function M.stop()
    -- Module cleanup
    log.log("Your module stopped")
end

function M.yourPublicFunction()
    -- Public functionality
end

return M
```

## 🔧 Configuration Options

### Module Control
```lua
-- In config/modules.lua
M.modules = {
    audio = true,        -- Enable audio management
    window = true,       -- Enable window management
    apps = true,         -- Enable app management
    boot = true,         -- Enable boot detection
    network = true,      -- Enable network management
    screen = true,       -- Enable screen management
}
```

### Module-Specific Settings
```lua
-- Audio settings
M.audio = {
    preferredInputDevices = {
        "Wave Link Stream",
        "Brett's AirPods",
        "Brett's AirPods Pro",
    }
}

-- Window settings
M.window = {
    blacklistedApps = {"Finder", "Terminal"},
    defaultSizes = {
        ["Google Chrome"] = {w = 1200, h = 800},
        ["Cursor"] = {w = 1400, h = 900},
    }
}
```

## 🧠 Design Principles

### 1. Separation of Concerns
Each module has a single, well-defined responsibility.

### 2. Explicit Dependencies
All dependencies are clearly stated through `require()` calls.

### 3. Consistent API
All modules follow the same lifecycle pattern (`start()`, `stop()`).

### 4. Error Resilience
Modules handle errors gracefully and don't crash the entire system.

### 5. Configurable
Behavior can be customized without modifying module code.

## 🔄 Migration from Legacy Code

### Before (Anti-patterns)
```lua
-- Global variables
windowScreenMap = {}

-- Side effects on require
require("some_module") -- Starts watchers immediately

-- Inconsistent patterns
function globalFunction() -- No module structure
end
```

### After (Best Practices)
```lua
-- Module structure
local M = {}

-- Private state
local windowScreenMap = {}

-- Explicit initialization
function M.start()
    -- Start watchers here
end

-- Clean exports
return M
```

## 🐛 Troubleshooting

### Module Not Loading
1. Check `config/modules.lua` - ensure module is enabled
2. Verify module path in `moduleRegistry`
3. Check for syntax errors in module file

### Functions Not Available
1. Ensure module is started: `_G.HammerspoonManagers.moduleName.start()`
2. Check if function is properly exported in module
3. Verify proper require path

### Performance Issues
1. Check log output for errors
2. Verify modules are properly stopped on reload
3. Look for resource leaks (timers, watchers not cleaned up)

## 📝 Logging

The logging system provides structured, colorized output:

```lua
local log = require('utils.log')

log.log("Basic message", {details = "value"})
log.logAction("Action taken", {window = window})
log.logError("Error message", {error = err})
log.logWarning("Warning message")
```

## 🚀 Future Improvements

1. **Convert remaining legacy modules** to new pattern
2. **Add unit tests** for critical functionality  
3. **Create module templates** for faster development
4. **Add configuration validation** to prevent errors
5. **Implement hot-reloading** for development

## 🤝 Contributing

When adding new functionality:
1. Follow the established module pattern
2. Add proper error handling and logging
3. Update `config/modules.lua` with new settings
4. Document your changes in this README
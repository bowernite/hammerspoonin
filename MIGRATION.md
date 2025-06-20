# Migration Guide

This guide helps you transition from the old Hammerspoon configuration to the new modular system.

## 🔄 What Changed

### Before: Mixed Patterns
- Some modules used global functions
- Some had side effects on `require()`
- Inconsistent error handling
- No central configuration
- Hard to test and maintain

### After: Consistent Module System
- All modules return a table with explicit API
- Initialization is separate from module loading
- Centralized configuration
- Proper error handling and logging
- Clear lifecycle management

## 📁 File Changes

### Old Structure → New Structure

| Old File | New Location | Status |
|----------|--------------|---------|
| `audio_devices.lua` | `modules/audio/manager.lua` | ✅ Converted |
| `windows/window_management.lua` | `modules/window/manager.lua` | ✅ Converted |
| `windows/window_utils.lua` | `modules/window/utils.lua` | ✅ Converted |
| `windows/window_blacklist.lua` | `modules/window/blacklist.lua` | ✅ Converted |
| `windows/default_window_sizes.lua` | `modules/window/default_sizes.lua` | ✅ Converted |
| `boot.lua` | `modules/system/boot.lua` | ✅ Converted |
| `disconnect_from_wifi_when_on_ethernet.lua` | `modules/network/manager.lua` | ✅ Converted |
| `utils/utils.lua` | `modules/apps/manager.lua` | ✅ Partially converted |
| `screen_color_and_brightness.lua` | `modules/system/screen.lua` | 🔄 Partially converted |
| `homebrew_autoupdate.lua` | - | 🔄 Legacy (to be converted) |
| `forced_breaks.lua` | - | 🔄 Legacy (to be converted) |
| `night_blocking.lua` | - | ❌ Disabled |
| `daily_restart.lua` | - | ❌ Disabled |
| `morning_space.lua` | - | ❌ Disabled |
| `fresh_unlock.lua` | - | ❌ Disabled |

## 🔧 API Changes

### Audio Management

#### Before:
```lua
require("audio_devices")
-- Functions became global automatically
```

#### After:
```lua
local audioManager = require('modules.audio.manager')
audioManager.start() -- Explicit initialization
audioManager.setPreferredDevices({"Device 1", "Device 2"})
```

### Window Management

#### Before:
```lua
require("windows/window_management")
-- Global variables: windowScreenMap, centeredWindows, maximizedWindows
-- Global functions: adjustAllWindows(), etc.
```

#### After:
```lua
local windowManager = require('modules.window.manager')
windowManager.start() -- Explicit initialization
windowManager.adjustAllWindows()
local screenMap = windowManager.getWindowScreenMap()
```

### Boot Management

#### Before:
```lua
require("boot")
-- Global functions: wasRecentSystemBoot(), isActualSystemBoot(), etc.
```

#### After:
```lua
local bootManager = require('modules.system.boot')
local wasRecentBoot = bootManager.wasRecentSystemBoot()
local isActualBoot = bootManager.isActualSystemBoot()
bootManager.runBootSequence()
```

### App Management

#### Before:
```lua
require("boot") -- for app functions
-- Global functions: killInessentialApps(), startEssentialApps(), etc.
```

#### After:
```lua
local appManager = require('modules.apps.manager')
appManager.killInessentialApps()
appManager.startEssentialApps()
appManager.runDefaultAppState()
```

## ⚙️ Configuration Migration

### Before: Hardcoded Values
```lua
-- In audio_devices.lua
local preferredInputDevices = {
    "Wave Link Stream",
    "Brett's AirPods",
    "Brett's AirPods Pro",
}

-- In boot.lua
local essentialApps = {"Messages", "Cursor", "Slack", ...}
```

### After: Centralized Configuration
```lua
-- In config/modules.lua
M.audio = {
    preferredInputDevices = {
        "Wave Link Stream",
        "Brett's AirPods",
        "Brett's AirPods Pro",
    }
}

M.apps = {
    essentialApps = {"Messages", "Cursor", "Slack", ...}
}
```

## 🚦 Migration Steps

### Step 1: Backup Your Current Configuration
```bash
cp -r ~/.hammerspoon ~/.hammerspoon.backup
```

### Step 2: Update Your init.lua
Replace your current `init.lua` with the new modular version that properly initializes all modules.

### Step 3: Update Module References
If you have custom code that calls the old global functions:

#### Old:
```lua
-- These were global functions
log("message")
logAction("action")
adjustAllWindows()
wasRecentSystemBoot()
```

#### New:
```lua
-- Access through proper modules
local log = require('utils.log')
log.log("message")
log.logAction("action")

local windowManager = _G.HammerspoonManagers.window
windowManager.adjustAllWindows()

local bootManager = _G.HammerspoonManagers.boot
bootManager.wasRecentSystemBoot()
```

### Step 4: Update Configuration
Move your hardcoded settings to `config/modules.lua`:

```lua
-- Instead of editing module files directly, configure them:
local config = require('config.modules')
config.audio.preferredInputDevices = {"Your Device"}
config.apps.essentialApps = {"Your Apps"}
```

### Step 5: Test Your Configuration
1. Reload Hammerspoon: `⌘+⌥+⌃+R`
2. Check the console for any errors
3. Verify all functionality works as expected

## 🔧 Troubleshooting Migration Issues

### Issue: "Module not found" errors
**Solution:** Check the require paths in your custom code and update them to the new module locations.

### Issue: Global functions not available
**Solution:** The functions are now methods on module objects. Access them through the proper module:
```lua
-- Old: adjustAllWindows()
-- New: _G.HammerspoonManagers.window.adjustAllWindows()
```

### Issue: Configuration not taking effect
**Solution:** Ensure you're modifying `config/modules.lua` rather than hardcoded values in module files.

### Issue: Watchers not starting
**Solution:** Make sure modules are properly started. The new system requires explicit initialization:
```lua
local audioManager = require('modules.audio.manager')
audioManager.start() -- This starts the watchers
```

## 🧪 Testing Your Migration

### 1. Audio Device Switching
- Connect/disconnect audio devices
- Verify automatic switching works
- Check console logs for proper operation

### 2. Window Management
- Open new windows
- Switch between screens
- Verify windows are positioned correctly

### 3. Boot Detection
- Restart your system
- Verify boot sequence runs only on actual boots
- Check that apps are started/hidden properly

### 4. Network Management
- Connect/disconnect Ethernet
- Verify WiFi disconnects when Ethernet connects

## 🔮 Future Migration

### Remaining Legacy Modules
These modules still need to be converted to the new pattern:

1. **homebrew_autoupdate.lua** → Convert to `modules/system/homebrew.lua`
2. **forced_breaks.lua** → Convert to `modules/wellness/breaks.lua`
3. **screen_color_and_brightness.lua** → Complete `modules/system/screen.lua`

### How to Convert Legacy Modules

1. **Create new module file** in appropriate directory
2. **Wrap functionality** in proper module structure
3. **Add to module registry** in `modules/core/manager.lua`
4. **Add configuration** to `config/modules.lua`
5. **Test thoroughly** before removing old file

## 📞 Getting Help

If you encounter issues during migration:

1. **Check the logs** - Look for error messages in the Hammerspoon console
2. **Verify file paths** - Ensure all require paths are correct
3. **Test incrementally** - Enable modules one at a time to isolate issues
4. **Backup and restore** - Keep your working configuration as backup

## ✅ Migration Checklist

- [ ] Backup current configuration
- [ ] Update init.lua to new version
- [ ] Update any custom module references
- [ ] Move configuration to config/modules.lua
- [ ] Test audio device switching
- [ ] Test window management
- [ ] Test boot sequence
- [ ] Test network management
- [ ] Verify all timers and watchers work properly
- [ ] Check for any error messages in console
- [ ] Update any external scripts that depend on Hammerspoon
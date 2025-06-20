-------------------------------------------------------
-- Module Configuration
--
-- Central configuration for all Hammerspoon modules
-- Usage: local config = require('config.modules')
-------------------------------------------------------

local M = {}

-- Module enable/disable flags
M.modules = {
    audio = true,
    window = true,
    apps = true,
    boot = true,
    network = true,
    screen = true,
    
    -- Legacy modules (to be converted)
    homebrew_autoupdate = true,
    forced_breaks = true,
    hammerspoon_console = true,
    night_blocking = false,  -- Disabled as noted in original
    daily_restart = false,   -- Disabled as noted in original
    morning_space = false,   -- Disabled as noted in original
    fresh_unlock = false,    -- Disabled as noted in original
}

-- Audio module configuration
M.audio = {
    preferredInputDevices = {
        "Wave Link Stream", -- Elgato Wave:3 output (after effects)
        "Brett's AirPods",
        "Brett's AirPods Pro",
    }
}

-- Window module configuration
M.window = {
    blacklistedApps = {
        "Finder",
        "System Preferences",
        "System Settings",
        "Activity Monitor",
        "Console",
        "Terminal",
        "Raycast",
        "Alfred",
        "Spotlight",
    },
    defaultSizes = {
        ["Google Chrome"] = {w = 1200, h = 800},
        ["Arc"] = {w = 1200, h = 800},
        ["Cursor"] = {w = 1400, h = 900},
        ["Slack"] = {w = 1000, h = 700},
        ["Messages"] = {w = 800, h = 600},
        ["Notion"] = {w = 1300, h = 850},
        ["Trello"] = {w = 1200, h = 800},
    }
}

-- App module configuration
M.apps = {
    essentialApps = {
        "Messages", "Cursor", "Slack", "Notion Calendar", "kitty", 
        "Reminders", "Obsidian", "Vivid", "Google Chrome", "Notion", 
        "Trello", "Hammerspoon", "Arc"
    },
    defaultRepos = {
        "~/src/dotfiles",
        "~/src/hammerspoon"
    }
}

-- Boot module configuration
M.boot = {
    hideWindowsDelay = 10, -- seconds
    uptimeThreshold = 300, -- 5 minutes
}

-- Network module configuration
M.network = {
    autoDisconnectWifi = true, -- Disconnect WiFi when Ethernet is connected
}

-- Screen module configuration
M.screen = {
    autoBrightness = true,
    autoColorAdjustment = true,
}

return M
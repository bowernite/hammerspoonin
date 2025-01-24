require("windows/window_utils")
require("utils/log")

local DEFAULT_SIZES = {
    ["Finder"] = {
        w = 800,
        h = 600
    },
    ["Notes"] = {
        w = 1000,
        h = 1000
    },
    ["System Settings"] = {
        w = 800,
        h = 600
    },
    ["Reminders"] = {
        w = 700,
        h = 600
    },
    ["Clock"] = {
        w = 650,
        h = 670
    },
    ["Messages"] = {
        w = 1000,
        h = 800
    },
    ["Contacts"] = {
        w = 700,
        h = 700
    },
    ["Cold Turkey Blocker"] = {
        w = 1000,
        h = 1000
    }
}

function setDefaultWindowSize(window)
    local appName = window:application():name()

    local centerOnlyApps = {
        ["Preview"] = true
    }

    if DEFAULT_SIZES[appName] then
        log("Default size found for app")
        local size = DEFAULT_SIZES[appName]
        window:setSize(size)
        centerWindow(window)
    elseif centerOnlyApps[appName] then
        centerWindow(window)
    else
        if not maximizeWindow(window) then
            centerWindow(window)
        end
    end
end

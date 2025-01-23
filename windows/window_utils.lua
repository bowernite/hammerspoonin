require("utils/log")

hs.window.animationDuration = 0

function isMainWindow(window)
    local role = window:role()
    local subrole = window:subrole()

    local isStandard = window:isStandard()
    -- log("isMainWindow check: Window properties:", {
    --     role = role,
    --     subrole = subrole,
    --     window = window,
    --     isStandard = isStandard,
    --     isMaximizable = window:isMaximizable(),
    --     isVisible = window:isVisible()
    -- })

    if not window:isMaximizable() then
        return false
    end

    -- When main windows are hidden, for some reason they seem to have the role AXDialog.
    local isHiddenMainWindow = not window:isVisible() and role == "AXWindow" and subrole == "AXDialog"
    if isHiddenMainWindow then
        return true
    end

    -- Main windows usually have the role 'AXWindow' and might have a subrole like 'AXStandardWindow'.
    -- These values can vary, so you might need to adjust them based on the behavior of specific apps.
    return (role == "AXWindow" and (subrole == "AXStandardWindow" or subrole == ""))
end

function isWindowTopLeft(window)
    local windowFrame = window:frame()
    local screenFrame = window:screen():frame()
    log("isWindowTopLeft check: ", {
        windowX = windowFrame.x,
        windowY = windowFrame.y,
        screenX = screenFrame.x,
        screenY = screenFrame.y
    })
    return windowFrame.x == screenFrame.x and windowFrame.y == screenFrame.y
end

function isWindowMaximized(window)
    return window:isFullScreen() or
               (window:frame().w == window:screen():frame().w and window:frame().h == window:screen():frame().h)
end

-- Function to check if a window is centered on its screen
function isWindowCentered(window)
    local windowFrame = window:frame()
    local screenFrame = window:screen():frame()
    -- Adjusting the window's coordinates relative to its current screen
    local windowCenter = {
        x = windowFrame.x - screenFrame.x + windowFrame.w / 2,
        y = windowFrame.y - screenFrame.y + windowFrame.h / 2
    }
    local screenCenter = {
        x = screenFrame.w / 2,
        y = screenFrame.h / 2
    }
    local isCentered = math.abs(windowCenter.x - screenCenter.x) < 1 and math.abs(windowCenter.y - screenCenter.y) < 1

    -- log("Window Centered Check: ",
    -- {window, screen = window:screen(), isCentered})
    return isCentered
end

function isMaximizable(window)
    local windowName = window:title()
    if not windowName then
        return false
    end
    if windowName:match("^Updating%s") then
        return false
    end
    if windowName:lower():match("settings") then
        return false
    end

    log("isMaximizable check: ", {
        isMaximizeable = window:isMaximizable()
    })

    return window:isMaximizable()
end

function isMaximized(window)
    return window:isFullScreen() or
               (window:frame().w == window:screen():frame().w and window:frame().h == window:screen():frame().h)
end

-- Maximizes the given window. Returns true if the window was maximized, false if it was not.
function maximizeWindow(window)
    if isMaximized(window) then
        -- log("Window is already maximized", {
        --     window = window
        -- })
        return true
    end

    if not isMaximizable(window) then
        log("Window is not maximizable; centering instead", {window})
        centerWindow(window)
        return false
    end

    maximizeWindowManually(window)

    local delay = 0.3
    hs.timer.doAfter(delay, function()
        maximizeWindowManually(window)
        hs.timer.doAfter(delay, function()
            maximizeWindowManually(window)
        end)
    end)

    maximizedWindows[window:id()] = true

    return true
end

function maximizeWindowManually(window)
    if isWindowMaximized(window) then
        return
    end

    if not isWindowTopLeft(window) then
        logAction("Maximize Window: Window is not at top left; putting there first", {window})
        local screen = window:screen()
        local frame = screen:frame()
        window:setTopLeft({
            x = 0,
            y = 0
        })
    else
        logAction("Maximize Window: Window is at top left; maximizing", {window})
        window:maximize()
    end
end

function centerWindow(window)
    if not window then
        logWarning("No window provided for centering")
        return
    end

    if isWindowCentered(window) then
        return
    end

    local windowID = window:id()
    logAction("Centering window", {window})
    window:centerOnScreen(nil, false, 0) -- Center on the current screen with animation
end

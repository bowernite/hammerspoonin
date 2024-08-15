require("utils/log")

function isMainWindow(window)
    local role = window:role()
    local subrole = window:subrole()

    -- log("isMainWindow check: Role - " .. role .. ", Subrole - " .. subrole)

    -- Main windows usually have the role 'AXWindow' and might have a subrole like 'AXStandardWindow'.
    -- These values can vary, so you might need to adjust them based on the behavior of specific apps.
    return role == "AXWindow" and
               (subrole == "AXStandardWindow" or subrole == "")
end

function isWindowMaximized(window)
    return window:isFullScreen() or
               (window:frame().w == window:screen():frame().w and
                   window:frame().h == window:screen():frame().h)
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
    local screenCenter = {x = screenFrame.w / 2, y = screenFrame.h / 2}
    local isCentered = math.abs(windowCenter.x - screenCenter.x) < 1 and
                           math.abs(windowCenter.y - screenCenter.y) < 1
    -- log("Window Centered Check: ",
    --     {window, screen = window:screen(), isCentered})
    return isCentered
end

function isMaximizable(window)
    local windowName = window:title()
    if not windowName then return false end
    if windowName:match("^Updating%s") then return false end
    if windowName:lower():match("settings") then return false end

    return true
end

function isMaximized(window)
    return window:isFullScreen() or
               (window:frame().w == window:screen():frame().w and
                   window:frame().h == window:screen():frame().h)
end

-- Maximizes the given window. Returns true if the window was maximized, false if it was not.
function maximizeWindow(window)
    if isMaximized(window) then return true end

    if not isMaximizable(window) then
        log("Window is not maximizable; centering instead", {window})
        centerWindow(window)
        return false
    end

    logAction("Maximizing window", {window})

    window:setTopLeft({x = 0, y = 0})
    window:maximize()

    poll(function()
        local maximized = window:isFullScreen() or
                              (window:frame().w == window:screen():frame().w and
                                  window:frame().h == window:screen():frame().h)
        if maximized then
            return true
        else
            logAction("(hack) Re-maximizing window, first attempt failed",
                      {window})
            window:setTopLeft({x = 0, y = 0})
            window:maximize()
        end
    end, 0.2, 3, function()
        logWarning("Failed to maximize window after 3 attempts")
    end)

    maximizedWindows[window:id()] = true

    return true
end

function centerWindow(window)
    if not window then
        logWarning("No window provided for centering")
        return
    end

    if isWindowCentered(window) then return end

    local windowID = window:id()
    logAction("Centering window", {window})
    window:centerOnScreen(nil, false, 0) -- Center on the current screen with animation
end

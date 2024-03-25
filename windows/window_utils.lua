require("log_utils")

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
    log("Window Centered Check: ",
        {window, screen = window:screen(), isCentered})
    return isCentered
end

function maximizeWindow(window)
    log("Maximizing window", {window})

    -- if not window.isResizable or not window:isResizable() then
    --     log("Window is not resizable, skipping maximization", {window})
    --     return false
    -- end

    window:maximize()

    window:setTopLeft({x = 0, y = 0})
    hs.timer.doAfter(0.25, function() window:maximize() end)

    local checkMaximized = function()
        local maximized = window:isFullScreen() or
                              (window:frame().w == window:screen():frame().w and
                                  window:frame().h == window:screen():frame().h)
        if maximized then
            log("Window is maximized as expected", {window})
            return true -- Stop the timer if the window is maximized
        else
            log("Window is not maximized as expected, correcting", {window})
            window:maximize()
        end
    end

    local timer
    timer = hs.timer.doEvery(1, function()
        if checkMaximized() then timer:stop() end
    end)

    hs.timer.doAfter(10, function() timer:stop() end) -- Stop checking after 10 seconds

    maximizedWindows[window:id()] = true

    return true
end

function centerWindow(window)
    if not window then
        log("No window provided for centering")
        return
    end

    local windowID = window:id()
    log("Centering window", {window})
    window:centerOnScreen(nil, false, 0) -- Center on the current screen with animation
end

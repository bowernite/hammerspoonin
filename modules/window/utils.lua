-------------------------------------------------------
-- Window Utilities Module
--
-- Provides utility functions for window manipulation
-- Usage: local windowUtils = require('modules.window.utils')
-------------------------------------------------------

local log = require('utils.log')

local M = {}

function M.center(window)
    if not window then return false end
    
    local screen = window:screen()
    local screenFrame = screen:frame()
    local windowFrame = window:frame()
    
    windowFrame.x = screenFrame.x + (screenFrame.w - windowFrame.w) / 2
    windowFrame.y = screenFrame.y + (screenFrame.h - windowFrame.h) / 2
    
    window:setFrame(windowFrame)
    log("Centered window", {window = window})
    return true
end

function M.maximize(window)
    if not window then return false end
    
    window:maximize()
    log("Maximized window", {window = window})
    return true
end

function M.isCentered(window)
    if not window then return false end
    
    local screen = window:screen()
    local screenFrame = screen:frame()
    local windowFrame = window:frame()
    
    local expectedX = screenFrame.x + (screenFrame.w - windowFrame.w) / 2
    local expectedY = screenFrame.y + (screenFrame.h - windowFrame.h) / 2
    
    local tolerance = 5
    return math.abs(windowFrame.x - expectedX) <= tolerance and 
           math.abs(windowFrame.y - expectedY) <= tolerance
end

function M.isMaximized(window)
    if not window then return false end
    
    local screen = window:screen()
    local screenFrame = screen:frame()
    local windowFrame = window:frame()
    
    local tolerance = 10
    return math.abs(windowFrame.w - screenFrame.w) <= tolerance and
           math.abs(windowFrame.h - screenFrame.h) <= tolerance
end

function M.setFrame(window, frame)
    if not window or not frame then return false end
    
    window:setFrame(frame)
    log("Set window frame", {window = window, frame = frame})
    return true
end

function M.getFrame(window)
    if not window then return nil end
    return window:frame()
end

return M
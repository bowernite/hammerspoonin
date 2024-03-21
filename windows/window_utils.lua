function isMainWindow(window)
    local role = window:role()
    local subrole = window:subrole()

    -- log("isMainWindow check: Role - " .. role .. ", Subrole - " .. subrole)

    -- Main windows usually have the role 'AXWindow' and might have a subrole like 'AXStandardWindow'.
    -- These values can vary, so you might need to adjust them based on the behavior of specific apps.
    return role == "AXWindow" and
               (subrole == "AXStandardWindow" or subrole == "")
end

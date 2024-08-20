function isBuiltinDisplay(screen) return
    screen:name():lower():match("built%-in") end

function isPrimaryDisplayBuiltIn()
    local primaryDisplay = hs.screen.primaryScreen()
    log("Checking if primary display is built-in",
        {primaryDisplay = primaryDisplay})
    return isBuiltinDisplay(primaryDisplay)
end

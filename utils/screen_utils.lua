function isBuiltinDisplay(screen) return
    screen:name():lower():match("built%-in") end

-- Checks if the Mac lid is closed (clamshell mode) by querying the I/O Registry.
-- AppleClamshellState is set by the lid sensor: "Yes" when closed, "No" when open.
function isClamshellMode()
    local output = hs.execute("ioreg -r -k AppleClamshellState -d 4 | grep '\"AppleClamshellState\"'")
    return output ~= nil and output:find("Yes") ~= nil
end

function isPrimaryDisplayBuiltIn()
    local primaryDisplay = hs.screen.primaryScreen()
    log("Checking if primary display is built-in",
        {primaryDisplay = primaryDisplay})
    return isBuiltinDisplay(primaryDisplay)
end

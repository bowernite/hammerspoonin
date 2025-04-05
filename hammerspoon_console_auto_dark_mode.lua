-- https://github.com/Hammerspoon/hammerspoon/issues/3725#issuecomment-2545660184
dm = require "utils/dark_mode"
dm.addHandler(function(dm2)
    if dm2 then
        hs.console.darkMode(true)
    else
        hs.console.darkMode(false)
    end
end)

if dm.getDarkMode() then
    hs.console.darkMode(true)
else
    hs.console.darkMode(false)
end

hs.console.clearConsole()
hs.console.consoleFont({
    name = "Menlo",
    size = 18
})

hs.ipc.cliInstall()

-- Preload common modules
local fnutils = hs.fnutils
local styledtext = hs.styledtext
local alert = hs.alert
local fs = hs.fs
local notify = hs.notify
local application = hs.application

require("screen_color_and_brightness")
require("windows/window_management")
require("night_blocking")

------------
-- Annoying things to be enabled while developing
------------
require("reset_apps")
require("fresh_unlock")
-- require("boot")
-- defaultAppState()
-- require("morning_space")

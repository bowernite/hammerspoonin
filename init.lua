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
-- Cold Turkey is fine for now
-- require("night_blocking")

---------------------------
-- WIP / not sure about yet
------------------------------------------------
-- New finder windows annoying
-- Without this, it's just... stupid. On the other hand, when it's on it's still not bulletproof. Still going back and forth...
-- require("windows/window_management")
require("audio_devices")

------------------------------------------------
-- Annoying things to be enabled while developing
------------------------------------------------
-- Do I really need this? It's good in theory, but it _is_ complicating my life
-- require("reset_apps")
-- resetAppsEveryMorning()
-- require("boot")
-- defaultAppState()
-- require("morning_space")

-- Current Finder functionality is buggy -- we can pick this up later
-- require("fresh_unlock")

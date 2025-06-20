hs.console.clearConsole()
hs.console.consoleFont({
    name = "Menlo",
    size = 18
})

hs.ipc.cliInstall()

-- Preload common modules
-- experiment: Delaying 5 seconds, so Hammerspoon is responsive quicker on startup..?
-- hs.timer.doAfter(5, function()
--     local fnutils = hs.fnutils
--     local styledtext = hs.styledtext
--     local alert = hs.alert
--     local fs = hs.fs
--     local notify = hs.notify
--     local application = hs.application
--     local location = hs.location
-- end)

require("screen_color_and_brightness")
require("homebrew_autoupdate")
-- Cold Turkey is fine for now
-- require("night_blocking")
-- New finder windows annoying
-- Without this, it's just... stupid. On the other hand, when it's on it's still not bulletproof. Still going back and forth... As of now, it does still work sometimes, so it's not nothing
require("windows/window_management")
require("audio_devices")

---------------------------
-- WIP / not sure about yet
------------------------------------------------
require("autojoin_hotspot")
require("forced_breaks")
require("hammerspoon_console_auto_dark_mode")
require("work/work")

------------------------------------------------
-- Annoying things to be enabled while developing
------------------------------------------------
require("reset_apps")
-- require("daily_restart")
-- Do I really need this? It's good in theory, but it _is_ complicating my life
-- resetAppsEveryMorning()
require("boot")
-- defaultAppState()
-- require("morning_space")

-- Current Finder functionality is buggy -- we can pick this up later
-- require("fresh_unlock")

hs.console.clearConsole()
hs.console.consoleFont({name = "Menlo", size = 18})

hs.ipc.cliInstall()

require("vivid_fix")
require("reset_apps")
require("boot")
require("morning_space")

-- This is a rabbit hole, and you ain't ready right now
require("windows/window_management")

-- Doesn't seem to help err_network_changed..?
-- require("disconnect_from_wifi_when_on_ethernet")

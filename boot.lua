-- General things we want to do when macOS boots
local output, status = hs.execute("colima start --ssh-agent", true)
if not status then hs.alert.show("Failed to start Colima: " .. output) end


require("utils/caffeinate")
require("utils/log")

local timerScriptPath = "~/src/personal/dotfiles/macos/swiftbar-plugins/countdown_timer.1s.rb"
local defaultTimerArgs = "25m,3m"

function startCountdownTimer(timerArgs)
    logAction("Executing countdown timer script after wake")
    local output, status, type, rc = hs.execute(timerScriptPath .. " " .. timerArgs, true)
    log("Executed countdown timer script", {
        status = status,
        output = output,
        type = type,
        returnCode = rc
    })
    if status then
        log("Countdown timer script executed successfully")
    else
        logError("Failed to execute countdown timer script", {
            output = output,
            type = type,
            returnCode = rc
        })
    end
end

addWakeWatcher(function()
    startCountdownTimer(defaultTimerArgs)
end)

addSleepWatcher(function()
    -- On sleep, turn off the timer, so that we don't get locked out later when we try to unlock
    startCountdownTimer("-1")
end)

-- startDefaultCountdownTimer()

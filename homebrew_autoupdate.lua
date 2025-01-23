require("utils/log")
require("private")

local brewCommand = "/opt/homebrew/bin/brew"
local sudoPassword = getSudoPassword()

local function appendToLog(message)
    -- Ensure logs directory exists
    os.execute("mkdir -p logs")

    -- Try to open file in append mode first
    local logFile = io.open("logs/homebrew_updates.log", "a")
    if not logFile then
        -- If that fails, try to create the file
        logFile = io.open("logs/homebrew_updates.log", "w")
    end

    if logFile then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        logFile:write(string.format("[%s] %s\n", timestamp, message))
        logFile:close()
    end
end

local function runCommand(command)
    return io.popen(command)
end

local function updateHomebrew()
    -- Initial notification
    hs.notify.show("Homebrew Update", "", "Starting Homebrew updates")

    logAction("Running Homebrew update and upgrade")

    -- Update
    hs.notify.show("Homebrew Update", "", "Running brew update...")
    appendToLog("Running: brew update")
    local updateOutput = runCommand(brewCommand .. " update 2>&1")
    local updateResult = updateOutput:read("*all")
    updateOutput:close()
    appendToLog("Output:\n" .. updateResult)
    local updateSuccess = updateResult:match("Already up%-to%-date") ~= nil or updateResult:match("Updated") ~= nil

    if updateSuccess then
        log("Homebrew update completed", {
            updateResult = updateResult
        })
        hs.notify.show("Homebrew Update", "", "Update completed successfully")

        -- Upgrade formulae
        hs.notify.show("Homebrew Update", "", "Running brew upgrade...")
        appendToLog("Running: brew upgrade")
        local upgradeOutput = runCommand(brewCommand .. " upgrade 2>&1")
        local upgradeResult = upgradeOutput:read("*all")
        upgradeOutput:close()
        appendToLog("Output:\n" .. upgradeResult)
        local upgradeSuccess = upgradeResult:match("Error:") == nil

        if upgradeSuccess then
            log("Homebrew formula upgrade completed", {
                upgradeResult = upgradeResult
            })
            hs.notify.show("Homebrew Update", "", "Formula upgrades completed successfully")

            -- Upgrade casks
            hs.notify.show("Homebrew Update", "", "Running cask upgrades...")
            appendToLog("Running: brew upgrade --cask")
            local caskOutput = runCommand(brewCommand .. " upgrade --cask 2>&1")
            local caskResult = caskOutput:read("*all")
            caskOutput:close()
            appendToLog("Output:\n" .. caskResult)
            local caskSuccess = caskResult:match("Error:") == nil

            if caskSuccess then
                log("Homebrew cask upgrade completed", {
                    caskResult = caskResult
                })
                hs.notify.show("Homebrew Update", "", "All updates completed successfully")
            else
                logError("Homebrew cask upgrade failed", {
                    caskResult = caskResult
                })
            end
        else
            logError("Homebrew formula upgrade failed", {
                upgradeResult = upgradeResult
            }, upgradeResult)
        end
    else
        logError("Homebrew update failed", {
            updateResult = updateResult
        }, updateResult)
    end
end

-- Run every hour (3600 seconds)
local ONE_HOUR_IN_SECONDS = 60 * 60
local timer = hs.timer.doEvery(ONE_HOUR_IN_SECONDS, updateHomebrew)
timer:start()

-- While testing, run it immediately
-- updateHomebrew()

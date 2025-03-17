require("utils/log")
require("private")
require("utils/log")

local brewCommand = "/opt/homebrew/bin/brew"
local sudoPassword = getSudoPassword()

local function runCommand(command)
    return io.popen(command)
end

local function executeBrewCommand(command, description)
    -- hs.notify.show("Homebrew Update", "", description)
    log("Running: " .. command)

    local output = runCommand(brewCommand .. " " .. command .. " 2>&1")
    local result = output:read("*all")
    output:close()

    log("Output:\n" .. result)
    return result
end

local function isUpdateSuccessful(result)
    return result:match("Already up%-to%-date") ~= nil or result:match("Updated") ~= nil
end

local function isCommandSuccessful(result)
    return result:match("Error:") == nil
end

local function updateHomebrew()
    -- hs.notify.show("Homebrew Update", "", "Starting Homebrew updates")
    logAction("Running Homebrew update and upgrade")

    -- Update
    local updateResult = executeBrewCommand("update", "Running brew update...")
    if not isUpdateSuccessful(updateResult) then
        logError("Homebrew update failed", {
            updateResult = updateResult
        }, updateResult)
        return
    end

    log("Homebrew update completed", {
        updateResult = updateResult
    })
    -- hs.notify.show("Homebrew Update", "", "Update completed successfully")

    -- Upgrade formulae
    local upgradeResult = executeBrewCommand("upgrade", "Running brew upgrade...")
    if not isCommandSuccessful(upgradeResult) then
        logError("Homebrew formula upgrade failed", {
            upgradeResult = upgradeResult
        }, upgradeResult)
        return
    end

    log("Homebrew formula upgrade completed", {
        upgradeResult = upgradeResult
    })
    -- hs.notify.show("Homebrew Update", "", "Formula upgrades completed successfully")

    -- Upgrade casks
    local caskResult = executeBrewCommand("upgrade --cask", "Running cask upgrades...")
    if not isCommandSuccessful(caskResult) then
        logError("Homebrew cask upgrade failed", {
            caskResult = caskResult
        })
        return
    end

    log("Homebrew cask upgrade completed", {
        caskResult = caskResult
    })
    -- hs.notify.show("Homebrew Update", "", "All updates completed successfully")
end

-- Run every hour (3600 seconds)
local ONE_HOUR_IN_SECONDS = 60 * 60
-- NOTE: Create a timer on the global scope so that it's not garbage collected. Ensure the name is unique, to avoid conflicts.
HOMEBREW_AUTOUPDATE_TIMER = hs.timer.doEvery(ONE_HOUR_IN_SECONDS, updateHomebrew)
HOMEBREW_AUTOUPDATE_TIMER:start()

-- While testing, run it immediately
-- updateHomebrew()

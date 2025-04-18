require("utils/log")
require("private")
require("utils/log")

local brewCommand = "/opt/homebrew/bin/brew"
local askpassPath = os.getenv("HOME") .. "/src/personal/hammerspoon/askpass.sh"

local function runCommand(command)
    return io.popen(command)
end

local function executeBrewCommand(command, description, env)
    log("Running: " .. command)

    local envPrefix = ""
    if env then
        for key, value in pairs(env) do
            envPrefix = envPrefix .. key .. "=" .. value .. " "
        end
    end

    local fullCommand = envPrefix .. brewCommand .. " " .. command .. " 2>&1"
    
    local output = runCommand(fullCommand)
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

    -- Upgrade casks without sudo for brew itself
    -- --greedy lets us update casks that have some flag that says "I'll update myself"
    local caskResult = executeBrewCommand("upgrade --cask --greedy", "Running cask upgrades...", {
        SUDO_ASKPASS = askpassPath
    })
    if not isCommandSuccessful(caskResult) then
        logError("Homebrew cask upgrade failed", {
            caskResult = caskResult
        }, caskResult)
        return
    end

    log("Homebrew cask upgrade completed", {
        caskResult = caskResult
    })
    
    -- Cleanup after updates
    local cleanupResult = executeBrewCommand("cleanup", "Cleaning up...")
    if not isCommandSuccessful(cleanupResult) then
        logError("Homebrew cleanup failed", {
            cleanupResult = cleanupResult
        }, cleanupResult)
        return
    end
    
    log("Homebrew cleanup completed", {
        cleanupResult = cleanupResult
    })
end

-- Run every hour (3600 seconds)
local ONE_HOUR_IN_SECONDS = 60 * 60
-- NOTE: Create a timer on the global scope so that it's not garbage collected. Ensure the name is unique, to avoid conflicts.
HOMEBREW_AUTOUPDATE_TIMER = hs.timer.doEvery(ONE_HOUR_IN_SECONDS, updateHomebrew)
HOMEBREW_AUTOUPDATE_TIMER:start()

-- While testing, run it immediately
updateHomebrew()

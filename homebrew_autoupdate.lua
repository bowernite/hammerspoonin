-- Note: Occasional cask upgrade failures like "App already exists" are typically
-- one-off issues from interrupted upgrades. Manual intervention is preferred over 
-- auto-fixing to avoid masking underlying problems.
require("utils/log")
require("utils/log")
local network = require("utils/network")
local config = require("config")

local brewCommand = "/opt/homebrew/bin/brew"
local askpassPath = os.getenv("HOME") .. "/src/personal/hammerspoon/askpass.sh"

local function extractBrewError(output)
    for line in output:gmatch("[^\r\n]+") do
        if line:match("^Error:") then
            return line:gsub("^Error: ", "")
        end
    end
    return nil
end

-- Runs an arbitrary shell command asynchronously via hs.task (off the main Lua thread) so
-- Hammerspoon stays responsive. `callback` is invoked with the combined stdout/stderr output
-- when the command finishes. Env vars are `export`ed (not just prefixed) so they apply to the
-- WHOLE shell -- important for multi-command pipelines like the cask-upgrade step below, where
-- the env must reach the `brew upgrade` at the end of the pipe, not just the first command.
local function executeShellCommand(shellCommand, description, callback, env)
    log("Running: " .. (description or shellCommand))

    -- Default environment variables for all brew commands
    local defaultEnv = {
        SUDO_ASKPASS = askpassPath,
        HOMEBREW_NO_ENV_HINTS = "1"
    }

    -- Merge default env with provided env
    if env then
        for key, value in pairs(env) do
            defaultEnv[key] = value
        end
    end

    -- Build export statements
    local exports = ""
    for key, value in pairs(defaultEnv) do
        exports = exports .. "export " .. key .. "='" .. value .. "'; "
    end

    -- 2>&1 merges stderr into stdout so the callback receives the full output. Running through
    -- bash inherits Hammerspoon's environment (PATH, etc.).
    local fullCommand = exports .. shellCommand .. " 2>&1"

    local task = hs.task.new("/bin/bash", function(_exitCode, stdOut, _stdErr)
        local result = stdOut or ""
        log("Output:\n" .. result)
        callback(result)
    end, {"-c", fullCommand})

    task:start()
end

-- Convenience wrapper for the common case of running a single `brew <subcommand>`.
local function executeBrewCommand(command, description, callback, env)
    executeShellCommand(brewCommand .. " " .. command, description, callback, env)
end

local function isUpdateSuccessful(result)
    return result:match("Already up%-to%-date") ~= nil or result:match("Updated") ~= nil
end

local function isCommandSuccessful(result)
    return result:match("Error:") == nil
end

local function isSudoPasswordFailure(result)
    return result:match("Sorry, try again") ~= nil
end

-- The steps run sequentially via chained async callbacks: each step only starts
-- once the previous one has finished successfully, preserving the original
-- update -> upgrade -> cask upgrade -> cleanup order and per-step result checks.
function updateHomebrew()
    logAction("Running Homebrew update and upgrade")

    if not network.hasInternetConnection() then
        log("Skipping Homebrew updates - no internet connection")
        return
    end

    local function runCleanup()
        executeBrewCommand("cleanup", "Cleaning up...", function(cleanupResult)
            if not isCommandSuccessful(cleanupResult) then
                if network.isConnectivityError(cleanupResult) then
                    log("Homebrew cleanup skipped due to connectivity issues")
                    return
                end

                logError("Homebrew cleanup failed", {
                    cleanupResult = cleanupResult
                }, extractBrewError(cleanupResult))
                return
            end

            log("Homebrew cleanup completed", {
                cleanupResult = cleanupResult
            })
        end)
    end

    -- Safety net: relaunch any app that brew quit during a cask upgrade. Brew logs
    -- "Quitting application 'bundle.id'..." for each running app it quits and never
    -- relaunches them; a quit line implies the app was running, so relaunching restores the
    -- pre-upgrade state. Runs on failures too -- the quit happens BEFORE the install step,
    -- so a failed upgrade (e.g. non-writable /Applications) otherwise leaves the app dead.
    local function relaunchAppsQuitByBrew(brewOutput)
        for bundleID in brewOutput:gmatch("Quitting application '([^']+)'") do
            logAction("Relaunching app that brew quit during cask upgrade: " .. bundleID)
            hs.application.launchOrFocusByBundleID(bundleID)
        end
    end

    local function caskUpgradeShell()
        local skipCasks = config.skipUpgradeCasks
        if #skipCasks == 0 then
            return brewCommand .. " upgrade --cask --greedy", "Running cask upgrades..."
        end

        -- An unguarded `brew upgrade --cask` with no names upgrades every outdated cask.
        local skipPattern = "^(" .. table.concat(skipCasks, "|") .. ")$"
        local command = "outdated=$(" .. brewCommand .. " outdated --cask --quiet | grep -vxE '" ..
                            skipPattern .. "'); " .. "if [ -n \"$outdated\" ]; then " .. brewCommand ..
                            " upgrade --cask $outdated; " ..
                            "else echo 'No non-skip-listed casks to upgrade'; fi"
        return command, "Running cask upgrades (excluding skip-listed apps)..."
    end

    local function runCaskUpgrade()
        local command, description = caskUpgradeShell()
        executeShellCommand(command, description, function(caskResult)
            relaunchAppsQuitByBrew(caskResult)
            if not isCommandSuccessful(caskResult) then
                if network.isConnectivityError(caskResult) then
                    log("Homebrew cask upgrade skipped due to connectivity issues")
                    return
                end

                if isSudoPasswordFailure(caskResult) then
                    logError("Homebrew cask upgrade failed due to incorrect sudo password", {
                        caskResult = caskResult
                    }, extractBrewError(caskResult))
                    return
                end

                logError("Homebrew cask upgrade failed", {
                    caskResult = caskResult
                }, extractBrewError(caskResult))
                return
            end

            log("Homebrew cask upgrade completed", {
                caskResult = caskResult
            })

            runCleanup()
        end)
    end

    local function runFormulaUpgrade()
        -- --formula scopes this to formulae only. A bare `brew upgrade` also upgrades
        -- outdated casks (quitting their apps). Cask upgrades run in the next step.
        executeBrewCommand("upgrade --formula", "Running brew upgrade...", function(upgradeResult)
            if not isCommandSuccessful(upgradeResult) then
                if network.isConnectivityError(upgradeResult) then
                    log("Homebrew formula upgrade skipped due to connectivity issues")
                    return
                end

                if isSudoPasswordFailure(upgradeResult) then
                    logError("Homebrew upgrade failed due to incorrect sudo password", {
                        upgradeResult = upgradeResult
                    }, extractBrewError(upgradeResult))
                    return
                end

                logError("Homebrew formula upgrade failed", {
                    upgradeResult = upgradeResult
                }, extractBrewError(upgradeResult))
                return
            end

            log("Homebrew formula upgrade completed", {
                upgradeResult = upgradeResult
            })

            runCaskUpgrade()
        end)
    end

    executeBrewCommand("update", "Running brew update...", function(updateResult)
        if not isUpdateSuccessful(updateResult) then
            if network.isConnectivityError(updateResult) then
                log("Homebrew update skipped due to connectivity issues")
                return
            end

            logError("Homebrew update failed", {
                updateResult = updateResult
            }, extractBrewError(updateResult))
            return
        end

        log("Homebrew update completed", {
            updateResult = updateResult
        })

        runFormulaUpgrade()
    end)
end

-- Run every 24 hours (86400 seconds)
local ONE_DAY_IN_SECONDS = 60 * 60 * 24
-- NOTE: Create a timer on the global scope so that it's not garbage collected. Ensure the name is unique, to avoid conflicts.
HOMEBREW_AUTOUPDATE_TIMER = hs.timer.doEvery(ONE_DAY_IN_SECONDS, updateHomebrew)
HOMEBREW_AUTOUPDATE_TIMER:start()

-- Run once on startup. Deferred to the next runloop tick so requiring this
-- module never blocks init.lua: the brew work itself runs off-thread via
-- hs.task, and even the internet pre-check happens after config load completes.
hs.timer.doAfter(0, updateHomebrew)

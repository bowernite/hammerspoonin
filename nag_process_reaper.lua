require("utils/log")

-- Proactive process reaper -- kill nagger *processes* before they can paint anything.
--
-- This is the process-level sibling of windows/window_suppression.lua: that file reacts to
-- nag *windows* once they're on screen (so a brief flash still sneaks through), whereas this
-- file kills the background process that would paint the window in the first place -- no
-- process, no flash. The two are deliberately separate modules so each can be enabled on its
-- own from init.lua: comment this out to stop killing processes but keep auto-closing
-- windows, or vice versa.
--
-- The one current target is Microsoft AutoUpdate's reminder agent -- process "Microsoft
-- Update Assistant", bundle id com.microsoft.autoupdate.fba -- an LSUIElement that launchd
-- keeps around (via LaunchAgent com.microsoft.update.agent) and wakes on a timer to check
-- for updates; when one is pending for a running app it pops the "please quit X to finish
-- updating" nag.
--
-- Killing that agent makes it stay dead for a long time: launchd has no KeepAlive for it, so
-- it only comes back on the agent's ~2h StartInterval or an on-demand XPC request. So
-- proactively reaping it is cheap (one kill buys hours of quiet)
-- and keeps it dead ~all of the time, shrinking the window in which it can paint a nag toward
-- zero. Crucially this does NOT stop updates: the actual download/install is done by a
-- separate privileged root daemon (com.microsoft.autoupdate.helper), which here is MDM-managed
-- to AutomaticDownload. We are only silencing the reminder UI, not the updater.
--
-- We deliberately target ONLY the ".fba" reminder agent, never the main Microsoft AutoUpdate
-- app (com.microsoft.autoupdate2) you might open yourself -- so a manual "Check for Updates"
-- still works. (One caveat: if you leave MAU open updating by hand and it spawns this agent,
-- the reaper will keep killing it. That's rare and harmless -- the root daemon does the real
-- work -- but if you're mid manual-update and it fights you, reload without this file.)
--
-- Matching is by exact bundle id -- the most stable identifier, and exactness matters here:
-- a substring match on "com.microsoft.autoupdate" would also kill the main MAU app.
REAP_BUNDLE_IDS = {"com.microsoft.autoupdate.fba"}

-- A freshly-launched agent has to run its update check before it can paint, so sweeping
-- every few seconds is fast enough to catch a respawn before it nags. It's a no-op lookup
-- while the agent is dead (the common case), so a short interval costs effectively nothing.
local REAP_INTERVAL_SECONDS = 5

local function isReapTarget(bundleID)
    for _, target in ipairs(REAP_BUNDLE_IDS) do
        if bundleID == target then
            return true
        end
    end
    return false
end

-- Exposed globally so it can be triggered manually for testing: `hs -c "reapNagProcesses()"`.
function reapNagProcesses()
    for _, bundleID in ipairs(REAP_BUNDLE_IDS) do
        for _, process in ipairs(hs.application.applicationsForBundleID(bundleID)) do
            logAction("Reaping nag process before it can nag", {process})
            process:kill()
        end
    end
end

-- Layered on purpose; any one layer would mostly do, together they're belt-and-suspenders
-- (plus window_suppression.lua stays as the final net if a nag ever paints anyway):
--
-- (1) Kill it the moment launchd (re)starts it -- earliest possible interception.
nagProcessReaperWatcher = hs.application.watcher.new(function(_, event, app)
    if not app or not isReapTarget(app:bundleID()) then
        return
    end
    if event == hs.application.watcher.launched or event == hs.application.watcher.activated then
        reapNagProcesses()
    end
end)
nagProcessReaperWatcher:start()

-- (2) Short sweep as a safety net for launches the watcher doesn't report (launch events for
-- background LSUIElement agents aren't always delivered). Bare global so it isn't GC'd.
NAG_PROCESS_REAPER_TIMER = hs.timer.doEvery(REAP_INTERVAL_SECONDS, reapNagProcesses)

-- (3) And slay whatever's resident right now, at load.
reapNagProcesses()

require("utils/log")

-- Auto-dismiss nag windows the moment they appear (Microsoft AutoUpdate "a new version
-- of Teams/Outlook is available", etc.). This is the inverse of window_blacklist.lua:
-- the blacklist says "don't *manage* this window", whereas these rules say "actively get
-- this window *out of my face*".
--
-- This is the *reactive* layer -- it acts on windows once they're on screen, so a brief
-- flash can sneak through. Its proactive sibling is nag_process_reaper.lua, which kills
-- known nagger processes before they can paint anything. Each works standalone; enable
-- either or both from init.lua.
--
-- Matching mirrors the blacklist: `app`, `window`, and/or `bundleID` are matched
-- case-insensitively as substrings against the window's application name, title, and
-- bundle identifier respectively. Any fields you specify must ALL match. A rule with only
-- `app` matches any window of that app; only `window` matches by title regardless of app;
-- `bundleID` matches by bundle id (the most stable identifier -- immune to localized /
-- differing display names).
--
-- `action` is what we do to a matching window, and it also picks the starting point of an
-- escalation chain (close -> hide -> minimize). If the window is still hanging around a
-- moment after we act, we escalate to the next step. Values:
--   "close"    -- close just that window (default). Escalates to hide, then minimize.
--   "hide"     -- hide the whole app (like Cmd-H). Escalates to minimize.
--   "minimize" -- minimize the window to the Dock. End of the chain.
--   "quit"     -- quit the whole app. No escalation (already the nuclear option).
SUPPRESS_RULES = {{
    -- The classic top-right "A new version of Teams/Outlook/... is available" nag.
    --
    -- Matched by bundle-id PREFIX on purpose: the reminder that actually pops up is shown
    -- by a nested background agent -- process/app name "Microsoft Update Assistant", bundle
    -- com.microsoft.autoupdate.fba -- NOT the main "Microsoft AutoUpdate" app
    -- (com.microsoft.autoupdate2). Their display names don't share a clean substring
    -- ("AutoUpdate" vs "Update Assistant"), so an app-name rule would miss the actual nag.
    -- The shared, stable handle is the bundle-id prefix "com.microsoft.autoupdate", which
    -- covers both the agent and the main app. Closing the window is the "dismiss" gesture;
    -- escalates to hide -> minimize if a close ever fails to make it go away.
    bundleID = "com.microsoft.autoupdate",
    action = "close"
}, {
    -- Real windows from SoftwareUpdateNotificationManager, if it ever paints one.
    -- Notification Center *banners* from the same process are not hs.window objects --
    -- those are handled by notification_nags.lua.
    bundleID = "com.apple.SoftwareUpdateNotificationManager",
    action = "close"
}}

-- ---------------------------------------------------------------------------------------
-- Candidates considered but intentionally NOT enabled. They're parked here (fully
-- commented out) so the next annoyance is a one-line uncomment away, with the reasoning
-- captured so future-me doesn't have to re-derive it. To enable one, move it up into the
-- SUPPRESS_RULES table above.
--
-- All four apps below are actually installed on this machine. The MDM
-- apps are deliberately left off: unlike Microsoft AutoUpdate, they don't pop up
-- unprompted -- you *launch them yourself* -- so auto-closing would fight the user.
-- ---------------------------------------------------------------------------------------
--
-- OneDrive -- the strongest "maybe". It genuinely throws unprompted upsell / "you're
-- running low on storage" / re-setup nags. The catch is that an app-wide rule is blunt:
-- it would also slam shut the OneDrive *settings* window if you ever open it on purpose.
-- If enabling, consider narrowing with a `window = "..."` title match instead of app-wide.
--   { app = "OneDrive", action = "close" },
--
-- Company Portal (Microsoft Intune MDM). NOT recommended: this is a corporate compliance
-- app you open deliberately to check device status / enroll / remediate. Auto-closing it
-- would interfere with required corporate actions and could hide a compliance prompt you
-- actually need to act on.
--   { app = "Company Portal", action = "close" },
--
-- Self Service (Jamf MDM app store). NOT recommended, same logic as Company Portal: it's
-- a portal you launch intentionally to install mandated/optional software. Auto-closing is
-- counterproductive -- you'd never be able to keep it open long enough to click anything.
--   { app = "Self Service", action = "close" },
--
-- Slack -- deliberately omitted. It's an app you actively use, so an app-wide rule is a
-- non-starter (it'd close your main Slack window). Slack's "please update" prompts are
-- in-app banners inside the existing window, not separate OS windows, so there's nothing
-- for this window-level mechanism to grab onto anyway.
--   -- (no rule -- listed only to record that it was considered and rejected)
--
-- Other nags worth knowing about, but NOT installed on this machine (so nothing to target):
--   * Nudge -- open-source macOS-update nag tool orgs deploy. If it ever shows up, note it
--     is corporate-mandated and may relaunch/ignore close; suppressing it may violate IT
--     policy. It also intentionally won't interrupt calls/full-screen, so it's less
--     intrusive than MAU to begin with.
--   * Zoom / Webex / Docker Desktop / Adobe Creative Cloud / Acrobat updater popups --
--     all common "update available" window nags; add app-name rules if any get installed.

-- Case-insensitive substring test that tolerates a nil haystack.
local function containsCI(haystack, needle)
    return haystack and string.find(string.lower(haystack), string.lower(needle), 1, true) and true or false
end

-- Does a single rule match this window? (every specified field -- app / window / bundleID
-- -- must match)
local function ruleMatchesWindow(rule, window)
    if not window or not window:application() then
        return false
    end
    if not rule.app and not rule.window and not rule.bundleID then
        return false
    end
    local app = window:application()
    local appMatch = not rule.app or containsCI(app:name(), rule.app)
    local windowMatch = not rule.window or containsCI(window:title(), rule.window)
    local bundleMatch = not rule.bundleID or containsCI(app:bundleID(), rule.bundleID)
    return appMatch and windowMatch and bundleMatch and true or false
end

-- Return the first SUPPRESS_RULES entry that matches this window, or nil.
local function matchingRule(window)
    for _, rule in ipairs(SUPPRESS_RULES) do
        if ruleMatchesWindow(rule, window) then
            return rule
        end
    end
    return nil
end

-- Rescan all open windows for one still matching a given rule (window handles go stale
-- after we close/minimize, so we re-query rather than reuse the old handle).
local function firstWindowMatchingRule(rule)
    for _, window in ipairs(hs.window.allWindows()) do
        if ruleMatchesWindow(rule, window) then
            return window
        end
    end
    return nil
end

-- What to try next if the current action didn't make the window go away.
local ESCALATION = {
    close = "hide",
    hide = "minimize"
}

-- How long to wait before checking whether an action worked (and escalating if not).
-- Long enough for the app to actually tear the window down, short enough to feel instant.
local ESCALATION_RECHECK_DELAY_SECONDS = 0.8

-- Timers are parked in a global table so they aren't garbage-collected mid-flight
-- (same pattern used throughout window_management.lua / window_utils.lua).
_G.windowSuppressionTimers = _G.windowSuppressionTimers or {}

local function actOnWindow(window, action)
    local app = window:application()
    if action == "hide" then
        logAction("Suppressing window: hiding app", {window})
        if app then
            app:hide()
        end
    elseif action == "minimize" then
        logAction("Suppressing window: minimizing", {window})
        window:minimize()
    elseif action == "quit" then
        logAction("Suppressing window: quitting app", {window})
        if app then
            app:kill()
        end
    else -- "close"
        logAction("Suppressing window: closing", {window})
        window:close()
    end
end

-- Act on the window, then verify a moment later that it actually went away. If a matching
-- window is still around, escalate to the next action in the chain (close -> hide -> minimize).
local function suppressWithFallback(window, rule, action)
    action = action or rule.action or "close"

    -- Guard: acting on a stale/closed handle would throw; skip if it's already gone.
    local ok = pcall(function()
        actOnWindow(window, action)
    end)
    if not ok then
        return
    end

    local nextAction = ESCALATION[action]
    if not nextAction then
        return
    end

    local timer = hs.timer.doAfter(ESCALATION_RECHECK_DELAY_SECONDS, function()
        local lingering = firstWindowMatchingRule(rule)
        if lingering then
            logWarning("Suppressed window still present after '" .. action .. "'; escalating to '" .. nextAction ..
                           "'", {lingering})
            suppressWithFallback(lingering, rule, nextAction)
        end
    end)
    table.insert(_G.windowSuppressionTimers, timer)
end

-- windowCreated and windowVisible can both fire for the same window in quick succession.
-- Throttle per app name so we don't thrash (a few seconds is plenty to swallow the storm
-- while still re-acting if the app pops the nag again later).
local recentlyActed = {}
local ACT_COOLDOWN_SECONDS = 3

local function maybeSuppress(window)
    local rule = matchingRule(window)
    if not rule then
        return
    end

    local key = window:application():name() or tostring(window:id())
    local now = os.time()
    if recentlyActed[key] and (now - recentlyActed[key]) < ACT_COOLDOWN_SECONDS then
        return
    end
    recentlyActed[key] = now

    suppressWithFallback(window, rule)
end

-- Sweep already-open windows (e.g. a nag was up when Hammerspoon reloaded). Exposed
-- globally so it can be triggered manually for testing: `hs -c "suppressAnnoyingWindows()"`.
function suppressAnnoyingWindows()
    for _, window in ipairs(hs.window.allWindows()) do
        maybeSuppress(window)
    end
end

-- Dedicated window filter (kept separate from window_management's so the two concerns don't
-- entangle). Callbacks are stored globally to prevent garbage collection.
windowSuppressionWatcher = hs.window.filter.new(nil)

windowSuppressionCreatedCallback = function(window)
    maybeSuppress(window)
end
windowSuppressionVisibleCallback = function(window)
    maybeSuppress(window)
end

windowSuppressionWatcher:subscribe(hs.window.filter.windowCreated, windowSuppressionCreatedCallback)
windowSuppressionWatcher:subscribe(hs.window.filter.windowVisible, windowSuppressionVisibleCallback)

suppressAnnoyingWindows()

require("utils/log")
require("windows/window_utils")

-- Auto-dismiss nag windows the moment they appear (Microsoft AutoUpdate "a new version
-- of Teams/Outlook is available", etc.). This is the inverse of window_blacklist.lua:
-- the blacklist says "don't *manage* this window", whereas these rules say "actively get
-- this window *out of my face*".
--
-- Matching mirrors the blacklist: `app` and/or `window` are matched case-insensitively as
-- substrings against the window's application name and title. A rule with only `app`
-- matches any window of that app; only `window` matches by title regardless of app.
--
-- `action` is what we do to a matching window, and it also picks the starting point of an
-- escalation chain (close -> hide -> minimize). If the window is still hanging around a
-- moment after we act, we escalate to the next step. Values:
--   "close"    -- close just that window (default). Escalates to hide, then minimize.
--   "hide"     -- hide the whole app (like Cmd-H). Escalates to minimize.
--   "minimize" -- minimize the window to the Dock. End of the chain.
--   "quit"     -- quit the whole app. No escalation (already the nuclear option).
SUPPRESS_RULES = {{
    -- The classic top-right "An update is available for Microsoft Teams/Outlook/..." nag.
    -- App name (hs.application:name()) and bundle id com.microsoft.autoupdate2.
    app = "Microsoft AutoUpdate",
    action = "close"
}}

-- Does a single rule match this window? (app AND window must match, when specified)
local function ruleMatchesWindow(rule, window)
    if not window or not window:application() then
        return false
    end
    if not rule.app and not rule.window then
        return false
    end
    local appName = window:application():name()
    local windowName = window:title()
    local appMatch = not rule.app or
                         (appName and string.find(string.lower(appName), string.lower(rule.app), 1, true))
    local windowMatch = not rule.window or
                            (windowName and string.find(string.lower(windowName), string.lower(rule.window), 1, true))
    return appMatch and windowMatch and true or false
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

    local timer = hs.timer.doAfter(0.8, function()
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

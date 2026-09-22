require("utils/log")

-- Dismiss nag banners in Notification Center:
--   * macOS system updates (e.g. "A system update is required", "Updates Available", Jamf
--     "Managed Update" / "An update to macOS X.Y has been scheduled")
--   * Background Task Management ("App Background Activity: "watchman" can run in the
--     background"). macOS re-posts it every time a launch agent's binary changes (e.g. each
--     `brew upgrade`), and it has no toggle in System Settings. It's also muted at the source
--     (see muteBackgroundActivityNotifications), so the sweep is just the fallback for it
--
-- This is NOT a copy of nag_process_reaper.lua. Those Microsoft nags are real windows
-- from a user-level agent we can kill. These nags are Notification Center banners from
-- SoftwareUpdateNotificationManager -- hs.window never sees them, and killing SUNM is
-- pointless (SIP-protected LaunchAgent; launchd relaunches it on wake / updatesAvailable).
-- We only Close the banner. softwareupdated / Jamf DDM still download and install.
--
-- Dismiss logic is the Banner Be Gone approach (Alfred workflow we already use):
-- Notification Center's AX tree shifts across minor macOS releases, so we do not chase
-- layout paths. We look for subroles that start with "AXNotificationCenter" (Alert /
-- Banner — not Stack, whose last action is "Clear All") and perform the *last* action --
-- Close, independent of language. After each dismiss the tree mutates, so we rescan.
-- https://github.com/alfredapp/banner-be-gone-workflow
--
-- Unlike Banner Be Gone we do not clear every banner -- only ones whose visible text
-- matches a nag above.

local UPDATE_NAG_NEEDLES = {"system update", "software update", "macos update", "mac os update",
                            "will be installed tonight", "update is required", "updates available",
                            "restart is required to install", "managed update", "update to macos"}
local BACKGROUND_ACTIVITY_NAG_NEEDLES = {"can run in the background", "app background activity",
                                         "background items added"}
local NAG_NEEDLES = hs.fnutils.concat(hs.fnutils.copy(UPDATE_NAG_NEEDLES), BACKGROUND_ACTIVITY_NAG_NEEDLES)

local SUBROLE_PREFIX = "AXNotificationCenter"
local NC_BUNDLE_ID = "com.apple.notificationcenterui"
local SWEEP_INTERVAL_SECONDS = 0.5
local MAX_DISMISS_PER_SWEEP = 8
local MAX_WALK_DEPTH = 12

local BTM_NOTIFICATION_BUNDLE_ID = "com.apple.BTMNotificationAgent"
-- 0x08 = Banners, 0x10 = Alerts, neither = None
local ALERT_STYLE_BITS = 0x18

local function containsNeedle(haystack)
    local lower = string.lower(haystack)
    for _, needle in ipairs(NAG_NEEDLES) do
        if string.find(lower, needle, 1, true) then
            return true
        end
    end
    return false
end

local function collectText(element, depth, parts)
    depth = depth or 0
    parts = parts or {}
    if not element or depth > 4 then
        return parts
    end
    for _, attr in ipairs({"AXTitle", "AXDescription", "AXValue", "AXHelp"}) do
        local value = element:attributeValue(attr)
        if type(value) == "string" and #value > 0 then
            parts[#parts + 1] = value
        end
    end
    local children = element:attributeValue("AXChildren")
    if type(children) == "table" then
        for _, child in ipairs(children) do
            collectText(child, depth + 1, parts)
        end
    end
    return parts
end

local function isDismissableNagGroup(element)
    local subrole = element:attributeValue("AXSubrole")
    if type(subrole) ~= "string" or subrole:sub(1, #SUBROLE_PREFIX) ~= SUBROLE_PREFIX then
        return false
    end
    -- Stacks' last action is "Clear All" and can include unrelated banners (Slack, etc.).
    return not subrole:find("Stack", 1, true)
end

local function firstMatchingNag(root, depth)
    depth = depth or 0
    if not root or depth > MAX_WALK_DEPTH then
        return nil
    end
    if isDismissableNagGroup(root) then
        local text = table.concat(collectText(root), " ")
        if containsNeedle(text) then
            return root, text
        end
    end
    local children = root:attributeValue("AXChildren")
    if type(children) == "table" then
        for _, child in ipairs(children) do
            local nag, text = firstMatchingNag(child, depth + 1)
            if nag then
                return nag, text
            end
        end
    end
    return nil
end

local function notificationCenterApp()
    local apps = hs.application.applicationsForBundleID(NC_BUNDLE_ID)
    return apps and apps[1] or nil
end

-- Exposed globally so it can be triggered manually: `hs -c "dismissNotificationNags()"`.
function dismissNotificationNags()
    local app = notificationCenterApp()
    if not app then
        return
    end
    local appElement = hs.axuielement.applicationElement(app)
    if not appElement then
        return
    end
    local windows = appElement:attributeValue("AXWindows")
    if type(windows) ~= "table" or #windows == 0 then
        return
    end

    for _ = 1, MAX_DISMISS_PER_SWEEP do
        local nag, text
        for _, window in ipairs(windows) do
            nag, text = firstMatchingNag(window)
            if nag then
                break
            end
        end
        if not nag then
            return
        end
        local actions = nag:actionNames()
        if not actions or #actions == 0 then
            return
        end
        logAction("Dismissing nag notification", {text})
        nag:performAction(actions[#actions])
        -- Tree mutates after a Close; re-read windows for the next pass.
        windows = appElement:attributeValue("AXWindows") or {}
    end
end

-- Sets the Background Task Management sender's alert style to None, so its notifications only land in
-- Notification Center's list. Settings hides this sender, so we edit its ncprefs entry directly. Runs on
-- every load because macOS updates (which reboot, reloading us) can reset it
function muteBackgroundActivityNotifications()
    local exportPath = os.tmpname()
    hs.execute(string.format("defaults export com.apple.ncprefs %q", exportPath))
    local apps = (hs.plist.read(exportPath) or {}).apps or {}
    for index, app in ipairs(apps) do
        local isBtmSender = app["bundle-id"] == BTM_NOTIFICATION_BUNDLE_ID
        if isBtmSender and (app.flags & ALERT_STYLE_BITS) ~= 0 then
            local plutilIndex = index - 1
            hs.execute(string.format(
                "plutil -replace apps.%d.flags -integer %d %q && defaults import com.apple.ncprefs %q && killall usernoted",
                plutilIndex, app.flags & ~ALERT_STYLE_BITS, exportPath, exportPath))
            logAction("Muted App Background Activity notifications", {previousFlags = app.flags})
        end
    end
    os.remove(exportPath)
end

NOTIFICATION_NAG_TIMER = hs.timer.doEvery(SWEEP_INTERVAL_SECONDS, dismissNotificationNags)
muteBackgroundActivityNotifications()
dismissNotificationNags()

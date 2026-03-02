# Daily Tasks (`createDailyTask`)

## How it works

`createDailyTask(resetTime, taskFunction, taskName, options)` in `utils.lua` schedules a function to run once per day after a given time. It uses three redundant trigger mechanisms (see the inline comment in `utils.lua` for the summary). All three call `checkAndRunTask`, which is idempotent — it tracks `lastRunDay` so the task only runs once per day.

## Known issues and investigation history

### `hs.timer` is unreliable across sleep/wake

Hammerspoon timers use NSTimer internally, which **pauses when the computer sleeps**. Repeating timers (`doAt`, `doEvery`) won't fire at their scheduled time if the Mac was asleep. This is a documented limitation:
- https://www.hammerspoon.org/docs/hs.timer.html (see caveat at top of page)
- https://github.com/Hammerspoon/hammerspoon/issues/1942
- https://github.com/Hammerspoon/hammerspoon/issues/2416

This is why we don't rely solely on `hs.timer.doAt` for daily scheduling.

### The `_G.dailyTaskWakeHandlers` global table silently broke (Nov 2025)

**Background:** On Oct 31, 2025 (commit `3d285f0`), a `_G.dailyTaskWakeHandlers` global table was added. `createDailyTask` would `table.insert` wake handlers into this global, and `caffeinate.lua` would iterate it on screen unlock events. This worked from Oct 31 through Nov 7.

**The break:** On Nov 7, 2025 (commit `4b86edd`, "fix daily task again..?"), `utils.lua` was reformatted and `createDailyTask` was refactored (changed from `hasRunToday` boolean to `lastRunDay` date tracking). The wake handler registration code was **unchanged** — same `table.insert(_G.dailyTaskWakeHandlers, wakeHandler)` call. Yet starting from the exact moment the config reloaded (12:00:22pm, verified via log timestamps), the daily task wake handlers completely stopped firing.

**Evidence from logs:**
- 11:18am unlock (old code): 11 "Checking if daily task should run" entries per unlock (as expected)
- 12:01pm unlock (new code, ~1 min after reload): zero daily task check entries
- All subsequent unlocks: zero daily task check entries forever after
- Meanwhile, other wake handlers (`wakeListeners` used by flux state, auto-hotspot) fired perfectly on every single unlock

**What we checked:**
- The `_G.dailyTaskWakeHandlers` table initialization code was identical before/after
- The `table.insert` call was identical
- `caffeinate.lua` was not modified in the commit
- No load errors in the logs — cold turkey daily tasks logged "Creating daily task" (proving `createDailyTask` was called), and the Solace backup ran its direct call (proving the module loaded)
- The caffeinate watcher callback accesses `_G.dailyTaskWakeHandlers` at runtime (not captured in closure), so it should see the populated table

**Root cause:** Unknown. Likely a subtle Lua environment / `_G` table scoping issue in Hammerspoon's reload mechanism. The `_G` global table approach is fundamentally fragile — it relies on all modules sharing the same `_G` reference across the watcher callback boundary.

**Fix (Mar 2026):** Switched from `_G.dailyTaskWakeHandlers` to `addWakeWatcher()`, which uses a local table (`wakeListeners`) inside `caffeinate.lua`. This is the same mechanism that reliably fires flux state and auto-hotspot handlers, and avoids the `_G` table entirely. Also added a periodic `doEvery(2h)` fallback timer and an initial `checkAndRunTask()` call on setup.

### Timer garbage collection

Timers must be stored in a reachable variable or Lua's GC will collect them (https://github.com/Hammerspoon/hammerspoon/issues/2416). This is why `_G.dailyTaskTimers` exists — it holds references to all timer objects to prevent GC.

require("utils/log")
require("utils/utils")

local COLD_TURKEY =
  "/Applications/Cold Turkey Blocker.app/Contents/MacOS/Cold Turkey Blocker"

local BLOCKS = {"Blocked 🔒", "Email and LinkedIn Messages", "Friction",
                "Friction (soft)", "Home", "Messages", "Morning Space ☀️",
                "Scrolling 🤳🏼", "Work", "Work (end of day)"}

local function buildStartCommand(blockName)
  local flags = "-as-is"
  local args = " -start " .. blockName .. " " .. flags
  return COLD_TURKEY .. " " .. args .. " 2>&1"
end

function startColdTurkeyBlock(blockName)
  log("Starting Cold Turkey Blocker " .. blockName .. " block")
  local command = buildStartCommand(blockName)
  local output, status, type, rc = hs.execute(command, true)

  if status then
    logAction("Successfully started Cold Turkey Blocker " .. blockName ..
                " block")
    return true
  else
    -- hs.execute sometimes returns rc=127 (command not found) with empty output
    -- even though the command actually succeeds (Cold Turkey block starts)
    if rc == 127 and output == "" then
      logAction("Started Cold Turkey Blocker " .. blockName .. " block")
      return true
    else
      logError("Failed to start Cold Turkey Blocker " .. blockName .. " block",
        {
          output = output,
          status = status,
          type = type,
          returnCode = rc
        })
      return false
    end
  end
end

-- Create daily tasks for all blocks
for _, blockName in ipairs(BLOCKS) do
  local taskName = "Start Cold Turkey Blocker " .. blockName
  local taskFunction = function()
    return startColdTurkeyBlock(blockName)
  end
  log("Creating daily task for " .. taskName)
  createDailyTask("05:00", taskFunction, taskName)
end

log("Cold Turkey daily blocker automation loaded")

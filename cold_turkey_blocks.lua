require("utils/log")
require("utils/utils")

local BLOCKS = {
    Messages = "Messages",
    Work = "Work"
}

local function startColdTurkeyBlock(blockName)
    log("Starting Cold Turkey Blocker " .. blockName .. " block")
    local command = "/Applications/Cold\\ Turkey\\ Blocker.app/Contents/MacOS/Cold\\ Turkey\\ Blocker -start " ..
                        blockName
    local output, status = hs.execute(command)

    if status then
        logAction("Successfully started Cold Turkey Blocker " .. blockName .. " block")
        return true
    else
        logError("Failed to start Cold Turkey Blocker " .. blockName .. " block", {
            output = output,
            status = status
        })
        return false
    end
end

-- Create daily tasks for all blocks
local coldTurkeyTasks = {}
for blockKey, blockName in pairs(BLOCKS) do
    local taskName = "Start Cold Turkey Blocker " .. blockName
    local taskFunction = function()
        return startColdTurkeyBlock(blockName)
    end
    log("Creating daily task for " .. taskName)
    coldTurkeyTasks[blockKey] = createDailyTask("05:00", taskFunction, taskName)
end

log("Cold Turkey daily blocker automation loaded")

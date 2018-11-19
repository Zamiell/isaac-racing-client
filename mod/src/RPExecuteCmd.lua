local RPExecuteCmd = {}

-- Includes
local RPGlobals            = require("src/rpglobals")
local RPFastTravel         = require("src/rpfasttravel")
local RPSpeedrun           = require("src/rpspeedrun")
local RPSpeedrunPostUpdate = require("src/rpspeedrunpostupdate")
local RPSeededFloors       = require("src/rpseededfloors")

-- ModCallbacks.MC_EXECUTE_CMD (22)
function RPExecuteCmd:Main(cmd, params)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local room = game:GetRoom()
  local roomFrameCount = room:GetFrameCount()
  local isaacFrameCount = Isaac.GetFrameCount()

  local debugString = "MC_EXECUTE_CMD - " .. tostring(cmd)
  if params ~= "" then
    debugString = debugString .. " " .. tostring(params)
  end
  Isaac.DebugString(debugString)

  if cmd == "charnum" then
    if params == "" then
      return
    end
    RPSpeedrun.charNum = tonumber(params)

  elseif cmd == "getframe" then
    -- Used for debugging
    Isaac.DebugString("Isaac frame count is at: " .. tostring(isaacFrameCount))
    Isaac.DebugString("Game frame count is at: " .. tostring(gameFrameCount))
    Isaac.DebugString("Room frame count is at: " .. tostring(roomFrameCount))

  elseif cmd == "level" then
    -- Used to go to the proper floor and stage
    -- (always assumed a seeded race)
    if params == "" then
      return
    end
    local stage = tonumber(params)
    local stageType = RPFastTravel:DetermineStageType(stage)
    if stage == 10 or stage == 11 then
      stageType = 1
    end

    local command = "stage " .. stage
    if stageType == 1 then
      command = command .. "a"
    elseif stageType == 2 then
      command = command .. "b"
    end

    RPSeededFloors:Before(stage)
    RPGlobals:ExecuteCommand(command)
    RPSeededFloors:After()

  elseif cmd == "next" then
    -- Used to go to the next character in a multi-character speedrun
    RPSpeedrunPostUpdate:CheckCheckpoint(true)

  elseif cmd == "previous" then
    -- Used to go to the previous character in a multi-character speedrun
    if RPSpeedrun.charNum == 1 then
      return
    end
    RPSpeedrun.charNum = RPSpeedrun.charNum - 2
    RPSpeedrunPostUpdate:CheckCheckpoint(true)
  end
end

return RPExecuteCmd

local ExecuteCmd = {}

-- Includes
local g                  = require("src/globals")
local FastTravel         = require("src/fasttravel")
local Speedrun           = require("src/speedrun")
local SpeedrunPostUpdate = require("src/speedrunpostupdate")
local SeededFloors       = require("src/seededfloors")

-- ModCallbacks.MC_EXECUTE_CMD (22)
function ExecuteCmd:Main(cmd, params)
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
    Speedrun.charNum = tonumber(params)

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
    local stageType = FastTravel:DetermineStageType(stage)
    if stage == 10 or stage == 11 then
      stageType = 1
    end

    local command = "stage " .. stage
    if stageType == 1 then
      command = command .. "a"
    elseif stageType == 2 then
      command = command .. "b"
    end

    SeededFloors:Before(stage)
    g:ExecuteCommand(command)
    SeededFloors:After()

  elseif cmd == "next" then
    -- Used to go to the next character in a multi-character speedrun
    SpeedrunPostUpdate:CheckCheckpoint(true)

  elseif cmd == "previous" then
    -- Used to go to the previous character in a multi-character speedrun
    if Speedrun.charNum == 1 then
      return
    end
    Speedrun.charNum = Speedrun.charNum - 2
    SpeedrunPostUpdate:CheckCheckpoint(true)
  end
end

return ExecuteCmd

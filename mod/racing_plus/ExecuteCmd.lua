local ExecuteCmd = {}

-- Includes
local g                  = require("racing_plus/globals")
local FastTravel         = require("racing_plus/fasttravel")
local Speedrun           = require("racing_plus/speedrun")
local SpeedrunPostUpdate = require("racing_plus/speedrunpostupdate")
local SeededFloors       = require("racing_plus/seededfloors")

-- ModCallbacks.MC_EXECUTE_CMD (22)
function ExecuteCmd:Main(cmd, params)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local roomFrameCount = g.r:GetFrameCount()
  local isaacFrameCount = Isaac.GetFrameCount()

  local debugString = "MC_EXECUTE_CMD - " .. tostring(cmd)
  if params ~= "" then
    debugString = debugString .. " " .. tostring(params)
  end
  Isaac.DebugString(debugString)

  if cmd == "char" then
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

  elseif cmd == "list" then
    -- Used to print out all of the entities in the room
    Isaac.DebugString("Entities in the room:")
    for i, entity in ipairs(Isaac.GetRoomEntities()) do
      Isaac.DebugString(tostring(i) .. " - " .. tostring(entity.Type) .. "." .. tostring(entity.Variant) .. "." ..
                        tostring(entity.SubType))
    end

  elseif cmd == "s" then
    if params == "" then
      return
    end
    local stage = tonumber(params)
    if stage < 1 or stage > 12 then
      return
    end
    g:ExecuteCommand("stage " .. stage)

  elseif cmd == "speed" then
    for i = 1, 3 do
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_BELT, 0, false) -- 28
    end
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_LORD_OF_THE_PIT, 0, false) -- 82

  elseif cmd == "boss" then
    g.run.bossCommand = true
    g.p:UseCard(Card.CARD_EMPEROR) -- 5
    g.run.bossCommand = false

  elseif cmd == "shop" then
    g.p:UseCard(Card.CARD_HERMIT) -- 10

  elseif cmd == "treasure" then
    g.p:UseCard(Card.CARD_STARS) -- 18

  elseif cmd == "devil" then
    g.p:UseCard(Card.CARD_JOKER) -- 31

  elseif cmd == "cc" then
    g.run.chaosCardTears = not g.run.chaosCardTears
  end
end

return ExecuteCmd

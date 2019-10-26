local ExecuteCmd = {}

-- Includes
local g                  = require("racing_plus/globals")
local FastTravel         = require("racing_plus/fasttravel")
local Schoolbag          = require("racing_plus/schoolbag")
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

  if cmd == "boss" then
    g.run.bossCommand = true
    g.p:UseCard(Card.CARD_EMPEROR) -- 5
    g.run.bossCommand = false

  elseif cmd == "cc" then
    g.run.chaosCardTears = not g.run.chaosCardTears
    local string
    if g.run.chaosCardTears then
      string = "Enabled"
    else
      string = "Disabled"
    end
    string = string .. " chaos card tears."
    Isaac.ConsoleOutput(string)

  elseif cmd == "char" then
    if params == "" then
      return
    end
    Speedrun.charNum = tonumber(params)

  elseif cmd == "damage" then
    g.run.debugDamage = true
    g.p:AddCacheFlags(CacheFlag.CACHE_ALL) -- 0xFFFFFFFF
    g.p:EvaluateItems()

  elseif cmd == "devil" then
    g.p:UseCard(Card.CARD_JOKER) -- 31

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

  elseif cmd == "list" then
    -- Used to print out all of the entities in the room
    Isaac.DebugString("Entities in the room:")
    for i, entity in ipairs(Isaac.GetRoomEntities()) do
      Isaac.DebugString(tostring(i) .. " - " .. tostring(entity.Type) .. "." .. tostring(entity.Variant) .. "." ..
                        tostring(entity.SubType))
    end

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

  elseif cmd == "s" then
    if params == "" then
      return
    end
    local stage = tonumber(params)
    if stage < 1 or stage > 12 then
      return
    end
    g:ExecuteCommand("stage " .. stage)

  elseif cmd == "sc" then
    if params == "" then
      return
    end
    local item = tonumber(params)
    if item < 0 then
      return
    end
    Schoolbag:Put(item, "max")

  elseif cmd == "speed" then
    g.run.debugSpeed = true
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_LORD_OF_THE_PIT, 0, false) -- 82
    -- (since we added Lord of the Pit, it will update the speed stat)

  elseif cmd == "shop" then
    g.p:UseCard(Card.CARD_HERMIT) -- 10

  elseif cmd == "tears" then
    g.run.debugTears = true
    g.p:AddCacheFlags(CacheFlag.CACHE_FIREDELAY) -- 2
    g.p:EvaluateItems()

  elseif cmd == "trapdoor" then
    g.p:UseActiveItem(CollectibleType.COLLECTIBLE_WE_NEED_GO_DEEPER, true, false, false, false) -- 84

  elseif cmd == "treasure" then
    g.p:UseCard(Card.CARD_STARS) -- 18

  else
    Isaac.DebugString("Unknown command.")
  end
end

return ExecuteCmd

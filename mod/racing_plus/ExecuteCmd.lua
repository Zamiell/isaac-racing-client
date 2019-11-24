local ExecuteCmd = {}

-- Includes
local g                  = require("racing_plus/globals")
local FastTravel         = require("racing_plus/fasttravel")
local Schoolbag          = require("racing_plus/schoolbag")
local Speedrun           = require("racing_plus/speedrun")
local SpeedrunPostUpdate = require("racing_plus/speedrunpostupdate")
local SeededFloors       = require("racing_plus/seededfloors")

ExecuteCmd.functions = {}

-- ModCallbacks.MC_EXECUTE_CMD (22)
function ExecuteCmd:Main(cmd, params)
  local debugString = "MC_EXECUTE_CMD - " .. tostring(cmd)
  if params ~= "" then
    debugString = debugString .. " " .. tostring(params)
  end
  Isaac.DebugString(debugString)

  local executeCmdFunc = ExecuteCmd.functions[cmd]
  if executeCmdFunc ~= nil then
    executeCmdFunc(params)
  else
    Isaac.DebugString("Unknown command.")
  end
end

ExecuteCmd.functions["boss"] = function(params)
  g.run.bossCommand = true
  g.p:UseCard(Card.CARD_EMPEROR) -- 5
  g.run.bossCommand = false
end

ExecuteCmd.functions["bm"] = function(params)
  g.run.naturalTeleport = true -- Mark that this is not a Cursed Eye teleport
  g.l.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
  g.g:StartRoomTransition(GridRooms.ROOM_BLACK_MARKET_IDX, -- 6
                          Direction.NO_DIRECTION, g.RoomTransition.TRANSITION_TELEPORT) -- -1, 3
end

ExecuteCmd.functions["cc"] = function(params)
  g.run.chaosCardTears = not g.run.chaosCardTears
  local string
  if g.run.chaosCardTears then
    string = "Enabled"
  else
    string = "Disabled"
  end
  string = string .. " chaos card tears."
  Isaac.ConsoleOutput(string)
end

ExecuteCmd.functions["char"] = function(params)
  if params == "" then
    Isaac.DebugString("You must specify a character number.")
  end
  Speedrun.charNum = tonumber(params)
end

ExecuteCmd.functions["damage"] = function(params)
  g.run.debugDamage = true
  g.p:AddCacheFlags(CacheFlag.CACHE_ALL) -- 0xFFFFFFFF
  g.p:EvaluateItems()
end

ExecuteCmd.functions["devil"] = function(params)
  g.p:UseCard(Card.CARD_JOKER) -- 31
end

ExecuteCmd.functions["getframe"] = function(params)
  -- Used for debugging
  Isaac.DebugString("Isaac frame count is at: " .. tostring(Isaac.GetFrameCount()))
  Isaac.DebugString("Game frame count is at: " .. tostring(g.g:GetFrameCount()))
  Isaac.DebugString("Room frame count is at: " .. tostring(g.r:GetFrameCount()))
end

ExecuteCmd.functions["level"] = function(params)
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
end

ExecuteCmd.functions["list"] = function(params)
  -- Used to print out all of the entities in the room
  Isaac.DebugString("Entities in the room:")
  for i, entity in ipairs(Isaac.GetRoomEntities()) do
    Isaac.DebugString(tostring(i) .. " - " .. tostring(entity.Type) .. "." .. tostring(entity.Variant) .. "." ..
                      tostring(entity.SubType))
  end
end

ExecuteCmd.functions["next"] = function(params)
  -- Used to go to the next character in a multi-character speedrun
  SpeedrunPostUpdate:CheckCheckpoint(true)
end

ExecuteCmd.functions["playerpos"] = function(params)
  Isaac.DebugString("Player position: " .. tostring(g.p.Position.X) .. ", " .. tostring(g.p.Position.Y))
end

ExecuteCmd.functions["previous"] = function(params)
  -- Used to go to the previous character in a multi-character speedrun
  if Speedrun.charNum == 1 then
    return
  end
  Speedrun.charNum = Speedrun.charNum - 2
  SpeedrunPostUpdate:CheckCheckpoint(true)
end

ExecuteCmd.functions["s"] = function(params)
  if params == "" then
    Isaac.DebugString("You must specify a stage number.")
    return
  end
  local stage = tonumber(params)
  if stage < 1 or stage > 12 then
    return
  end
  g:ExecuteCommand("stage " .. stage)
end

ExecuteCmd.functions["schoolbag"] = function(params)
  if params == "" then
    Isaac.DebugString("You must specify a Schoolbag item.")
    return
  end
  local item = tonumber(params)
  if item < 0 then
    return
  end
  Schoolbag:Put(item, "max")
end

ExecuteCmd.functions["speed"] = function(params)
  g.run.debugSpeed = true
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_LORD_OF_THE_PIT, 0, false) -- 82
  -- (since we added Lord of the Pit, it will update the speed stat)
end

ExecuteCmd.functions["shop"] = function(params)
  g.p:UseCard(Card.CARD_HERMIT) -- 10
end

ExecuteCmd.functions["tears"] = function(params)
  g.run.debugTears = true
  g.p:AddCacheFlags(CacheFlag.CACHE_FIREDELAY) -- 2
  g.p:EvaluateItems()
end

ExecuteCmd.functions["trapdoor"] = function(params)
  g.p:UseActiveItem(CollectibleType.COLLECTIBLE_WE_NEED_GO_DEEPER, true, false, false, false) -- 84
end

ExecuteCmd.functions["treasure"] = function(params)
  g.p:UseCard(Card.CARD_STARS) -- 18
end

return ExecuteCmd

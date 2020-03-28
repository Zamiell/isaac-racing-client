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
    Isaac.ConsoleOutput("Unknown command.")
  end
end

--
-- Command functions
--

ExecuteCmd.functions["angel"] = function(params)
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_EUCHARIST) then -- 499
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_EUCHARIST, 0, false) -- 499
  end
  g.p:UseCard(Card.CARD_JOKER) -- 31
end

ExecuteCmd.functions["blackmarket"] = function(params)
  ExecuteCmd:BlackMarket()
end

function ExecuteCmd:BlackMarket()
  g.run.naturalTeleport = true -- Mark that this is not a Cursed Eye teleport
  g.run.usedTeleport = true -- Mark to potentially reposition the player (if they appear at a non-existent entrance)
  g.l.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
  g.g:StartRoomTransition(GridRooms.ROOM_BLACK_MARKET_IDX, -- 6
                          Direction.NO_DIRECTION, g.RoomTransition.TRANSITION_TELEPORT) -- -1, 3
end

ExecuteCmd.functions["boss"] = function(params)
  g.run.bossCommand = true
  g.p:UseCard(Card.CARD_EMPEROR) -- 5
  g.run.bossCommand = false
end

ExecuteCmd.functions["bossrush"] = function(params)
  local wave = 15
  g.run.bossRush.currentWave = wave
  Isaac.ConsoleOutput("Set the Boss Rush current wave to: " .. tostring(wave))
end

ExecuteCmd.functions["bm"] = function(params)
  ExecuteCmd:BlackMarket()
end

ExecuteCmd.functions["card"] = function(params)
  if params == "" then
    Isaac.ConsoleOutput("You must specify a card name.")
    return
  end

  local num = tonumber(params)
  if num ~= nil then
    -- Validate the card ID
    if num < 1 or
       num >= Card.NUM_CARDS then

      Isaac.ConsoleOutput("That is an invalid card ID.")
      return
    end

    -- They entered a number instead of a name, so just give the card corresponding to this number
    Isaac.ExecuteCommand("g k" .. tostring(num))
    Isaac.ConsoleOutput("Gave card #" .. tostring(num) .. ".")
    return
  end

  local cardMap = {}
  cardMap["fool"] = 1
  cardMap["magician"] = 2
  cardMap["magi"] = 2
  cardMap["high priestess"] = 3
  cardMap["highpriestess"] = 3
  cardMap["priestess"] = 3
  cardMap["priest"] = 3
  cardMap["empress"] = 4
  cardMap["emperor"] = 5
  cardMap["emp"] = 5
  cardMap["hierophant"] = 6
  cardMap["hiero"] = 6
  cardMap["lovers"] = 7
  cardMap["chariot"] = 8
  cardMap["justice"] = 9
  cardMap["hermit"] = 10
  cardMap["wheel of fortune"] = 11
  cardMap["wheeloffortune"] = 11
  cardMap["wheel"] = 11
  cardMap["fortune"] = 11
  cardMap["strength"] = 12
  cardMap["hanged man"] = 13
  cardMap["hangedman"] = 13
  cardMap["hanged"] = 13
  cardMap["death"] = 14
  cardMap["temperance"] = 15
  cardMap["devil"] = 16
  cardMap["tower"] = 17
  cardMap["stars"] = 18
  cardMap["moon"] = 19
  cardMap["sun"] = 20
  cardMap["judgement"] = 21
  cardMap["judge"] = 21
  cardMap["world"] = 22
  cardMap["2 of clubs"] = 23
  cardMap["2ofclubs"] = 23
  cardMap["2clubs"] = 23
  cardMap["2 of diamonds"] = 24
  cardMap["2ofdiamonds"] = 24
  cardMap["2diamonds"] = 24
  cardMap["2 of spades"] = 25
  cardMap["2ofspades"] = 25
  cardMap["2spades"] = 25
  cardMap["2 of hearts"] = 26
  cardMap["2ofhearts"] = 26
  cardMap["2hearts"] = 26
  cardMap["ace of clubs"] = 27
  cardMap["aceofclubs"] = 27
  cardMap["aceclubs"] = 27
  cardMap["ace of diamonds"] = 28
  cardMap["aceofdiamonds"] = 28
  cardMap["acediamonds"] = 28
  cardMap["ace of spades"] = 29
  cardMap["aceofspades"] = 29
  cardMap["acespades"] = 29
  cardMap["ace of hearts"] = 30
  cardMap["aceofhearts"] = 30
  cardMap["acehearts"] = 30
  cardMap["joker"] = 31
  cardMap["hagalaz"] = 32
  cardMap["destruction"] = 32
  cardMap["jera"] = 33
  cardMap["abundance"] = 33
  cardMap["ehwaz"] = 34
  cardMap["passage"] = 34
  cardMap["dagaz"] = 35
  cardMap["purity"] = 35
  cardMap["ansuz"] = 36
  cardMap["vision"] = 36
  cardMap["perthro"] = 37
  cardMap["change"] = 37
  cardMap["berkano"] = 38
  cardMap["companionship"] = 38
  cardMap["algiz"] = 39
  cardMap["resistance"] = 39
  cardMap["shield"] = 39
  cardMap["blank"] = 40
  cardMap["black"] = 41
  cardMap["chaos"] = 42
  cardMap["credit"] = 43
  cardMap["rules"] = 44
  cardMap["against humanity"] = 45
  cardMap["againsthumanity"] = 45
  cardMap["humanity"] = 45
  cardMap["suicide king"] = 46
  cardMap["suicideking"] = 46
  cardMap["suicide"] = 46
  cardMap["get out of jail free"] = 47
  cardMap["getoutofjailfree"] = 47
  cardMap["get out of jail"] = 47
  cardMap["getoutofjail"] = 47
  cardMap["get out"] = 47
  cardMap["getout"] = 47
  cardMap["jail"] = 47
  cardMap["?"] = 48
  cardMap["dice shard"] = 49
  cardMap["diceshard"] = 49
  cardMap["dice"] = 49
  cardMap["shard"] = 49
  cardMap["emergency contact"] = 50
  cardMap["emergencycontact"] = 50
  cardMap["emergency"] = 50
  cardMap["contact"] = 50
  cardMap["holy"] = 51
  cardMap["huge growth"] = 52
  cardMap["hugegrowth"] = 52
  cardMap["growth"] = 52
  cardMap["ancient recall"] = 53
  cardMap["ancientrecall"] = 53
  cardMap["ancient"] = 53
  cardMap["recall"] = 53
  cardMap["era walk"] = 54
  cardMap["erawalk"] = 54
  cardMap["era"] = 54
  cardMap["walk"] = 54

  local giveCardNum = 0
  for word, cardNum in pairs(cardMap) do
    if params == word then
      giveCardNum = cardNum
      break
    end
  end

  if giveCardNum == 0 then
    Isaac.ConsoleOutput("Unknown card.")
    return
  end
  Isaac.ExecuteCommand("g k" .. tostring(giveCardNum))
  Isaac.ConsoleOutput("Gave card #" .. tostring(giveCardNum) .. ".")
end

ExecuteCmd.functions["cards"] = function(params)
  local cardNum = 1
  for y = 0, 6 do
    for x = 0, 12 do
      if cardNum < Card.NUM_CARDS then
        local pos = g:GridToPos(x, y)
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, cardNum, pos, g.zeroVector, nil) -- 5.300
        cardNum = cardNum + 1
      end
    end
  end
end

ExecuteCmd.functions["cc"] = function(params)
  ExecuteCmd:ChaosCardTears()
end

function ExecuteCmd:ChaosCardTears()
  g.run.debugChaosCard = not g.run.debugChaosCard
  local string
  if g.run.debugChaosCard then
    string = "Enabled"
  else
    string = "Disabled"
  end
  string = string .. " Chaos Card tears."
  Isaac.ConsoleOutput(string)
end

ExecuteCmd.functions["chaos"] = function(params)
  ExecuteCmd:ChaosCardTears()
end

ExecuteCmd.functions["char"] = function(params)
  if params == "" then
    Isaac.ConsoleOutput("You must specify a character number.")
  end

  local num = ExecuteCmd:ValidateNumber(params)
  if num == nil then
    return
  end

  Speedrun.charNum = num
end

ExecuteCmd.functions["commands"] = function(params)
  ExecuteCmd:Commands()
end

function ExecuteCmd:Commands()
  -- Compile a list of the commands and sort them
  local commands = {}
  for commandName, _ in pairs(ExecuteCmd.functions) do
    commands[#commands + 1] = commandName
  end
  table.sort(commands)

  Isaac.ConsoleOutput("List of Racing+ custom commands:\n")
  for _, commandName in ipairs(commands) do
    Isaac.ConsoleOutput(commandName .. " ")
  end
end

ExecuteCmd.functions["damage"] = function(params)
  g.run.debugDamage = not g.run.debugDamage
  g.p:AddCacheFlags(CacheFlag.CACHE_ALL) -- 0xFFFFFFFF
  g.p:EvaluateItems()
end

ExecuteCmd.functions["db"] = function(params)
  ExecuteCmd:Debug()
end

function ExecuteCmd:Debug()
  Isaac.ExecuteCommand("debug 3")
  Isaac.ExecuteCommand("debug 8")
  Isaac.ExecuteCommand("debug 10")
  Isaac.ExecuteCommand("damage")
  Isaac.ExecuteCommand("speed")
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_XRAY_VISION) then -- 76
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_XRAY_VISION, 0, false) -- 76
  end
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_MIND) then -- 333
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_MIND, 0, false) -- 333
  end
  g.p:AddCoins(99)
  g.p:AddBombs(99)
  g.p:AddKeys(99)
  Isaac.ConsoleOutput("Added \"debug 3\", \"debug 8\", \"debug 10\", \"damage\", \"speed\", " ..
                      "X-Ray Vision, The Mind, 99 coins, 99 bombs, and 99 keys.")
end

ExecuteCmd.functions["dd"] = function(params)
  g.p:UseCard(Card.CARD_JOKER) -- 31
end

ExecuteCmd.functions["debug"] = function(params)
  ExecuteCmd:Debug()
end

ExecuteCmd.functions["devil"] = function(params)
  g.p:UseCard(Card.CARD_JOKER) -- 31
end

ExecuteCmd.functions["doors"] = function(params)
  -- Print out all the doors in the room
  for i = 0, 7 do
    local door = g.r:GetDoor(i)
    if door ~= nil then
      Isaac.ConsoleOutput("Door " .. tostring(i) .. " - " ..
                          "(" .. tostring(door.Position.X) .. ", " .. tostring(door.Position.Y) .. ")\n")
    end
  end
end

ExecuteCmd.functions["error"] = function(params)
  ExecuteCmd:IAMERROR()
end

function ExecuteCmd:IAMERROR()
  g.run.naturalTeleport = true -- Mark that this is not a Cursed Eye teleport
  g.run.usedTeleport = true -- Mark to potentially reposition the player (if they appear at a non-existent entrance)
  g.l.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
  g.g:StartRoomTransition(GridRooms.ROOM_ERROR_IDX, -- 2
                          Direction.NO_DIRECTION, g.RoomTransition.TRANSITION_TELEPORT) -- -1, 3
end

ExecuteCmd.functions["getframe"] = function(params)
  -- Used for debugging
  Isaac.ConsoleOutput("Isaac frame count is at: " .. tostring(Isaac.GetFrameCount()))
  Isaac.ConsoleOutput("Game frame count is at: " .. tostring(g.g:GetFrameCount()))
  Isaac.ConsoleOutput("Room frame count is at: " .. tostring(g.r:GetFrameCount()))
end

ExecuteCmd.functions["getroom"] = function(params)
  Isaac.ConsoleOutput("Room index is: " .. g.l:GetCurrentRoomIndex())
end

ExecuteCmd.functions["help"] = function(params)
  ExecuteCmd:Commands()
end

ExecuteCmd.functions["iamerror"] = function(params)
  ExecuteCmd:IAMERROR()
end

ExecuteCmd.functions["level"] = function(params)
  -- Used to go to the proper floor and stage
  -- (always assume a seeded race)
  if params == "" then
    Isaac.ConsoleOutput("You must specify a level number.")
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
    local debugString = tostring(i) .. " - " .. tostring(entity.Type) .. "." .. tostring(entity.Variant) .. "." ..
                        tostring(entity.SubType)
    local npc = entity:ToNPC()
    if npc ~= nil then
      debugString = debugString .. "." .. npc.State
    end
    debugString = debugString .. " (InitSeed: " .. tostring(entity.InitSeed) .. ")"
    Isaac.DebugString(debugString)
  end
  Isaac.ConsoleOutput("Logged the entities in the room to the \"log.txt\" file.")
end

ExecuteCmd.functions["next"] = function(params)
  -- Used to go to the next character in a multi-character speedrun
  SpeedrunPostUpdate:CheckCheckpointTouched(true)
end

ExecuteCmd.functions["pills"] = function(params)
  local pillNum = 1
  for y = 0, 6 do
    for x = 0, 12 do
      if pillNum < PillColor.NUM_PILLS then
        local pos = g:GridToPos(x, y)
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, pillNum, pos, g.zeroVector, nil) -- 5.70
        pillNum = pillNum + 1
      end
    end
  end
end

ExecuteCmd.functions["pos"] = function(params)
  Isaac.ConsoleOutput("Player position: " .. tostring(g.p.Position.X) .. ", " .. tostring(g.p.Position.Y))
end

ExecuteCmd.functions["previous"] = function(params)
  -- Used to go to the previous character in a multi-character speedrun
  if Speedrun.charNum == 1 then
    return
  end
  Speedrun.charNum = Speedrun.charNum - 2
  SpeedrunPostUpdate:CheckCheckpointTouched(true)
end

ExecuteCmd.functions["removeall"] = function(params)
  -- Copied from the "SeededDeath:DebuffOn()" function
  for i = 1, g:GetTotalItemCount() do
    local numItems = g.p:GetCollectibleNum(i)
    if numItems > 0 and
       g.p:HasCollectible(i) then

      -- Checking both "GetCollectibleNum()" and "HasCollectible()" prevents bugs such as Lilith having 1 Incubus
      for j = 1, numItems do
        g.p:RemoveCollectible(i)
        local debugString = "Removing collectible " .. tostring(i)
        if i == CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM then
          debugString = debugString .. " (Schoolbag)"
        end
        Isaac.DebugString(debugString)
        g.p:TryRemoveCollectibleCostume(i, false)
      end
    end
  end
end

-- "s" is a crash-safe wrapper for the vanilla "stage" command
ExecuteCmd.functions["s"] = function(params)
  if params == "" then
    Isaac.ConsoleOutput("You must specify a stage number.")
    return
  end

  local finalCharacter = string.sub(params, -1)
  local stageNum
  local stageType
  if finalCharacter == "a" or
     finalCharacter == "b" then

    -- e.g. "s 11a" for going to The Chest
    stageNum = string.sub(1, #params - 1)
    stageType = finalCharacter
  else
    -- e.g. "s 11" for going to the Dark Room
    stageNum = params
    stageType = ""
  end
  local stage = ExecuteCmd:ValidateNumber(stageNum)
  if stage == nil then
    return
  end

  if stage < 1 or stage > 12 then
    Isaac.ConsoleOutput("Invalid stage number; must be between 1 and 12.")
    return
  end

  g:ExecuteCommand("stage " .. stage .. stageType)
end

ExecuteCmd.functions["sb"] = function(params)
  ExecuteCmd:Schoolbag(params)
end

ExecuteCmd.functions["schoolbag"] = function(params)
  ExecuteCmd:Schoolbag(params)
end

function ExecuteCmd:Schoolbag(params)
  if params == "" then
    Isaac.ConsoleOutput("You must specify a Schoolbag item.")
    return
  end

  local item = ExecuteCmd:ValidateNumber(params)
  if item == nil then
    return
  end

  local totalItems = g:GetTotalItemCount()
  if item < 0 or item > g:GetTotalItemCount() then
    Isaac.ConsoleOutput("Invalid item number; must be between 0 and " .. tostring(totalItems) .. ".")
    return
  end

  Schoolbag:Put(item, "max")
end

ExecuteCmd.functions["shop"] = function(params)
  g.p:UseCard(Card.CARD_HERMIT) -- 10
end

ExecuteCmd.functions["spam"] = function(params)
  g.run.spamButtons = not g.run.spamButtons
end

ExecuteCmd.functions["speed"] = function(params)
  g.run.debugSpeed = true
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_LORD_OF_THE_PIT) then -- 82
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_LORD_OF_THE_PIT, 0, false) -- 82
  end
  g.p:AddCacheFlags(CacheFlag.CACHE_SPEED) -- 16
  g.p:EvaluateItems()
end

ExecuteCmd.functions["tears"] = function(params)
  g.run.debugTears = not g.run.debugTears
  g.p:AddCacheFlags(CacheFlag.CACHE_FIREDELAY) -- 2
  g.p:EvaluateItems()
end

ExecuteCmd.functions["teleport"] = function(params)
  if params == "" then
    Isaac.ConsoleOutput("You must specify a room index number.")
    return
  end

  local roomIndex = ExecuteCmd:ValidateNumber(params)
  if roomIndex == nil then
    return
  end

  g.l.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
  g.l:ChangeRoom(roomIndex)
end

ExecuteCmd.functions["trapdoor"] = function(params)
  g.p:UseActiveItem(CollectibleType.COLLECTIBLE_WE_NEED_GO_DEEPER, true, false, false, false) -- 84
end

ExecuteCmd.functions["treasure"] = function(params)
  g.p:UseCard(Card.CARD_STARS) -- 18
end

--
-- Subroutines
--

function ExecuteCmd:ValidateNumber(params)
  local num = tonumber(params)
  if num == nil then
    Isaac.ConsoleOutput("You must specify a number.")
  end
  return num
end

return ExecuteCmd

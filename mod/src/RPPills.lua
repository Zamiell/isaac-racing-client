local RPPills = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")
local RPItems   = require("src/rpitems")

--
-- Pill functions
--

function RPPills:HealthUp()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  RPGlobals.run.keeper.usedHealthUpPill = true
  player:AddCacheFlags(CacheFlag.CACHE_RANGE) -- 8
  player:EvaluateItems()
  -- We check to see if we are Keeper, have Greed's Gullet, and are at maximum hearts inside this function
end

function RPPills:Telepills()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local rooms = level:GetRooms()

  -- It is not possible to teleport to I AM ERROR rooms and Black Markets on The Chest / Dark Room
  local insertErrorRoom = false
  local insertBlackMarket = false
  if stage ~= 11 then
    insertErrorRoom = true

    -- There is a 2% chance have a Black Market inserted into the list of possibilities (according to blcd)
    RPGlobals.RNGCounter.Telepills = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.Telepills)
    math.randomseed(RPGlobals.RNGCounter.Telepills)
    local blackMarketRoll = math.random(1, 100) -- Item room, secret room, super secret room, I AM ERROR room
    if blackMarketRoll <= 2 then
      insertBlackMarket = true
    end
  end

  -- Find the indexes for all of the room possibilities
  local roomIndexes = {}
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local gridIndex = rooms:Get(i).SafeGridIndex
    -- We need to use SafeGridIndex instead of GridIndex because we will crash when teleporting to L rooms otherwise
    roomIndexes[#roomIndexes + 1] = gridIndex
  end
  if insertErrorRoom then
    roomIndexes[#roomIndexes + 1] = GridRooms.ROOM_ERROR_IDX -- -2
  end
  if insertBlackMarket then
    roomIndexes[#roomIndexes + 1] = GridRooms.ROOM_BLACK_MARKET_IDX -- -6
  end

  -- Get a random room index
  RPGlobals.RNGCounter.Telepills = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.Telepills)
  math.randomseed(RPGlobals.RNGCounter.Telepills)
  local gridIndex = roomIndexes[math.random(1, #roomIndexes)]

  -- Teleport
  RPGlobals.run.naturalTeleport = true -- Mark that this is not a Cursed Eye teleport
  level.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
  game:StartRoomTransition(gridIndex, Direction.NO_DIRECTION, RPGlobals.RoomTransition.TRANSITION_TELEPORT)
  Isaac.DebugString("Telepills to room: " .. tostring(gridIndex))

  -- We don't want to display the "use" animation, we just want to instantly teleport
  -- Pills are hard coded to queue the "use" animation, so stop it on the next frame
  RPGlobals.run.usedTelepills = true
end

function RPPills:Gulp()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- This will write to the log which trinket we are gulping
  RPItems:Smelter()

  -- Do the actual gulping effect
  player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, false, false, false, false) -- 479
end

return RPPills

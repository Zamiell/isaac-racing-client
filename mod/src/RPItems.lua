local RPItems = {}

--
-- Includes
--

local RPGlobals   = require("src/rpglobals")
local RPSchoolbag = require("src/rpschoolbag")

--
-- Collectible item functions
--

-- Will get called for all items
function RPItems:Main()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local activeItem = player:GetActiveItem()
  local activeCharge = player:GetActiveCharge()
  local batteryCharge = player:GetBatteryCharge()

  -- Fix The Battery + 9 Volt synergy (1/2)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and -- 63
     player:HasCollectible(CollectibleType.COLLECTIBLE_NINE_VOLT) and -- 116
     RPGlobals:GetActiveCollectibleMaxCharges(activeItem) >= 2 and
     activeCharge == RPGlobals:GetActiveCollectibleMaxCharges(activeItem) and
     batteryCharge == RPGlobals:GetActiveCollectibleMaxCharges(activeItem) then

    RPGlobals.run.giveExtraCharge = true
  end

  -- Fix the Schoolbag + Butter! bug
  if player:HasTrinket(TrinketType.TRINKET_BUTTER) then
    RPGlobals.run.usedButter = true
    -- We will check this variable later in the PostUpdate callback (the "RPSchoolbag:CheckSecondItem()" function)
  end
end

--
-- Existing items
--

function RPItems:Teleport()
  -- This callback is used naturally by Broken Remote
  -- This callback is manually called for Cursed Eye

  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local rooms = level:GetRooms()

  -- Get a random room index
  RPGlobals.RNGCounter.Teleport = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.Teleport)
  math.randomseed(RPGlobals.RNGCounter.Teleport)
  local roomNum = math.random(0, rooms.Size - 1)
  local gridIndex = rooms:Get(roomNum).SafeGridIndex
  -- We need to use SafeGridIndex instead of GridIndex because we will crash when teleporting to L rooms otherwise

  -- Teleport
  RPGlobals.run.naturalTeleport = true -- Mark that this is not a Cursed Eye teleport
  level.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
  game:StartRoomTransition(gridIndex, Direction.NO_DIRECTION, RPGlobals.RoomTransition.TRANSITION_TELEPORT)
  Isaac.DebugString("Teleport! / Broken Remote / Cursed Eye to room: " .. tostring(gridIndex))

  -- This will override the existing Teleport! / Broken Remote effect because
  -- we have already locked in a room transition
end

function RPItems:BlankCard()
  local game = Game()
  local player = game:GetPlayer(0)
  local card = player:GetCard(0)
  if card == Card.CARD_FOOL or -- 1
     card == Card.CARD_EMPEROR or -- 5
     card == Card.CARD_HERMIT or -- 10
     card == Card.CARD_STARS or -- 18
     card == Card.CARD_MOON  then -- 19

    -- We don't want to display the "use" animation, we just want to instantly teleport
    -- Blank Card is hard coded to queue the "use" animation, so stop it on the next frame
    RPGlobals.run.usedTelepills = true
  end
end

function RPItems:Undefined()
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

    -- There is a 1% chance have a Black Market inserted into the list of possibilities (according to blcd)
    RPGlobals.RNGCounter.Undefined = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.Undefined)
    math.randomseed(RPGlobals.RNGCounter.Undefined)
    local blackMarketRoll = math.random(1, 100) -- Item room, secret room, super secret room, I AM ERROR room
    if blackMarketRoll <= 1 then
      insertBlackMarket = true
    end
  end

  -- Find the indexes for all of the room possibilities
  local roomIndexes = {}
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local roomType = rooms:Get(i).Data.Type
    if roomType == RoomType.ROOM_TREASURE or -- 4
       roomType == RoomType.ROOM_SECRET or -- 7
       roomType == RoomType.ROOM_SUPERSECRET then -- 8

      roomIndexes[#roomIndexes + 1] = rooms:Get(i).SafeGridIndex
      -- We need to use SafeGridIndex instead of GridIndex because we will crash when teleporting to L rooms otherwise
    end
  end
  if insertErrorRoom then
    roomIndexes[#roomIndexes + 1] = GridRooms.ROOM_ERROR_IDX -- -2
  end
  if insertBlackMarket then
    roomIndexes[#roomIndexes + 1] = GridRooms.ROOM_BLACK_MARKET_IDX -- -6
  end

  -- Get a random index
  RPGlobals.RNGCounter.Undefined = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.Undefined)
  math.randomseed(RPGlobals.RNGCounter.Undefined)
  local gridIndex = roomIndexes[math.random(1, #roomIndexes)]

  -- Teleport
  RPGlobals.run.naturalTeleport = true -- Mark that this is not a Cursed Eye teleport
  level.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
  game:StartRoomTransition(gridIndex, Direction.NO_DIRECTION, RPGlobals.RoomTransition.TRANSITION_TELEPORT)
  Isaac.DebugString("Undefined to room: " .. tostring(gridIndex))

  -- This will override the existing Undefined effect because we have already locked in a room transition
end

function RPItems:GlowingHourGlass()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- Reset the Schoolbag
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) then
    Isaac.DebugString("Rewinding the Schoolbag item.")
    RPGlobals.run.schoolbag.item = RPGlobals.run.schoolbag.lastRoomItem
    RPGlobals.run.schoolbag.nextRoomCharge = true
    -- If we don't wait until the next room is entered, the slot 1 charge will just apply to the Glowing Hour Glass
    -- and not the item that was in the Schoolbag
    RPGlobals.run.schoolbag.charges = RPGlobals.run.schoolbag.lastRoomSlot2Charges
    if RPGlobals.run.schoolbag.item == CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS then
       RPGlobals.run.schoolbag.charges = 0 -- Prevent using the Glowing Hour Glass over and over
    end
    RPSchoolbag.sprites.item = nil
  end
end

function RPItems:Void()
  -- We need to delay item replacement after using a Void (in case the player has consumed a D6)
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  RPGlobals.run.itemReplacementDelay = gameFrameCount + 5 -- Stall for 5 frames
end

--
-- Custom items
--

function RPItems:BookOfSin()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- The Book of Sin has an equal chance to spawn a heart, coin, bomb, key, battery, pill, or card/rune.
  RPGlobals.RNGCounter.BookOfSin = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.BookOfSin)
  math.randomseed(RPGlobals.RNGCounter.BookOfSin)
  local bookPickupType = math.random(1, 7)
  RPGlobals.RNGCounter.BookOfSin = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.BookOfSin)

  local pos = player.Position
  local vel = Vector(0, 0)

  -- If heart
  if bookPickupType == 1 then
    -- Random Heart - 5.10.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, pos, vel,
               player, 0, RPGlobals.RNGCounter.BookOfSin)

  -- If coin
  elseif bookPickupType == 2 then
    -- Random Coin - 5.20.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, pos, vel, player, 0, RPGlobals.RNGCounter.BookOfSin)

  -- If bomb
  elseif bookPickupType == 3 then
    -- Random Bomb - 5.40.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, pos, vel, player, 0, RPGlobals.RNGCounter.BookOfSin)

  -- If key
  elseif bookPickupType == 4 then
    -- Random Key - 5.30.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, pos, vel, player, 0, RPGlobals.RNGCounter.BookOfSin)

  -- If battery
  elseif bookPickupType == 5 then
    -- Lil' Battery - 5.90.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, pos, vel,
               player, 0, RPGlobals.RNGCounter.BookOfSin)

  -- If pill
  elseif bookPickupType == 6 then
    -- Random Pill - 5.70.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, pos, vel, player, 0, RPGlobals.RNGCounter.BookOfSin)

  -- If card/rune
  elseif bookPickupType == 7 then
    -- Random Card - 5.300.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, pos, vel,
               player, 0, RPGlobals.RNGCounter.RuneBag)
  end

  -- By returning true, it will play the animation where Isaac holds the Book of Sin over his head
  return true
end

function RPItems:CrystalBall()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local player = game:GetPlayer(0)

  -- Show the map
  level:ShowMap() -- This is the same as the World/Sun card effect

  -- Decide whether we are dropping a soul heart or a card
  RPGlobals.RNGCounter.CrystalBall = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.CrystalBall)
  math.randomseed(RPGlobals.RNGCounter.CrystalBall)
  local cardChance = math.random(1, 10)
  local spawnCard = false
  if player:HasTrinket(TrinketType.TRINKET_DAEMONS_TAIL) then -- 22
    if cardChance <= 9 then -- 90% chance with Daemon's Tail
      spawnCard = true
    end
  else
    if cardChance <= 5 then -- 50% chance normally
      spawnCard = true
    end
  end

  local pos = player.Position
  local vel = Vector(0, 0)
  if spawnCard then
    -- Random Card - 5.300.0
    RPGlobals.RNGCounter.CrystalBall = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.CrystalBall)
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, pos, vel,
               player, 0, RPGlobals.RNGCounter.CrystalBall)
  else
    -- Heart (soul) - 5.10.3
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, pos, vel, player, 3, 0)
  end

  -- By returning true, it will play the animation where Isaac holds the Book of Sin over his head
  return true
end

function RPItems:Smelter()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local trinket1 = player:GetTrinket(0) -- This will be 0 if there is no trinket
  local trinket2 = player:GetTrinket(1) -- This will be 0 if there is no trinket

  if trinket1 ~= 0 then
    -- Send a message to the item tracker to add this trinket
    Isaac.DebugString("Gulping trinket " .. trinket1)
  end

  if trinket2 ~= 0 then
    -- Send a message to the item tracker to add this trinket
    Isaac.DebugString("Gulping trinket " .. trinket2)
  end

  -- Do the real Smelter effect
  player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, false, false, false, false) -- 479

  -- Display the "use" animation
  return true
end

return RPItems

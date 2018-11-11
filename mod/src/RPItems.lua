local RPItems = {}

-- Includes
local RPGlobals   = require("src/rpglobals")
local RPSchoolbag = require("src/rpschoolbag")

--
-- Pre-use collectible item functions
-- ModCallbacks.MC_PRE_USE_ITEM (23)
--

-- This callback is used naturally by Ehwaz (Passage) runes
function RPItems:WeNeedToGoDeeper() -- 84
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local player = game:GetPlayer(0)

  -- Prevent the racers from "cheating" by using the shovel on Womb 2 in the "Everything" race goal
  if RPGlobals.race.goal == "Everything" and
     stage == 8 then

    -- Signal that what they did was illegal
    player:AnimateSad()

    -- By returning true, it will cancel the original effect
    return true
  end
end

function RPItems:BookOfSin() -- 97
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)

  -- The Book of Sin has an equal chance to spawn a heart, coin, bomb, key, battery, pill, or card/rune
  RPGlobals.RNGCounter.BookOfSin = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.BookOfSin)
  math.randomseed(RPGlobals.RNGCounter.BookOfSin)
  local bookPickupType = math.random(1, 7)
  RPGlobals.RNGCounter.BookOfSin = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.BookOfSin)

  local pos = room:FindFreePickupSpawnPosition(player.Position, 0, true)
  local vel = Vector(0, 0)

  if bookPickupType == 1 then
    -- Random Heart - 5.10.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, pos, vel,
               player, 0, RPGlobals.RNGCounter.BookOfSin)

  elseif bookPickupType == 2 then
    -- Random Coin - 5.20.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, pos, vel, player, 0, RPGlobals.RNGCounter.BookOfSin)

  elseif bookPickupType == 3 then
    -- Random Bomb - 5.40.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, pos, vel, player, 0, RPGlobals.RNGCounter.BookOfSin)

  elseif bookPickupType == 4 then
    -- Random Key - 5.30.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, pos, vel, player, 0, RPGlobals.RNGCounter.BookOfSin)

  elseif bookPickupType == 5 then
    -- Lil' Battery - 5.90.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, pos, vel,
               player, 0, RPGlobals.RNGCounter.BookOfSin)

  elseif bookPickupType == 6 then
    -- Random Pill - 5.70.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, pos, vel, player, 0, RPGlobals.RNGCounter.BookOfSin)

  elseif bookPickupType == 7 then
    -- Random Card/Rune - 5.300.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, pos, vel,
               player, 0, RPGlobals.RNGCounter.BookOfSin)
  end

  -- When we return from the function below, no animation will play, so we have to explitily perform one
  player:AnimateCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_SIN, "UseItem", "PlayerPickup") -- 97

  -- By returning true, it will cancel the original effect
  return true
end

function RPItems:GlowingHourGlass() -- 422
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomDesc = level:GetCurrentRoomDesc()
  local roomVariant = roomDesc.Data.Variant
  local player = game:GetPlayer(0)

  -- Prevent the usage of the Glowing Hour Glass in the pre-race room
  if roomVariant == 9999 then -- Only the pre-race room has this specific ID
    -- We want to signify to the player that using the Glowing Hour Glass here is forbidden
    player:AnimateSad()
    return true
  end

  -- Reset the Schoolbag
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) and
     player:HasTrinket(TrinketType.TRINKET_BROKEN_REMOTE) == false then
     -- Broken Remote cancels the Glowing Hour Glass effect

    Isaac.DebugString("Rewinding the Schoolbag item.")
    RPGlobals.run.schoolbag.item = RPGlobals.run.schoolbag.lastRoomItem
    RPGlobals.run.schoolbag.nextRoomCharge = true
    -- If we don't wait until the next room is entered, the slot 1 charge will just apply to the Glowing Hour Glass
    -- and not the item that was in the Schoolbag
    RPGlobals.run.schoolbag.charge = RPGlobals.run.schoolbag.lastRoomSlot2Charges
    if RPGlobals.run.schoolbag.item == CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS then
       RPGlobals.run.schoolbag.charge = 0 -- Prevent using the Glowing Hour Glass over and over
    end
    RPSchoolbag.sprites.item = nil
  end
end

-- This callback is used naturally by Gulp! pills
function RPItems:Smelter() -- 479
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

  -- By returning nothing, it will go on to do the Smelter effect
end

function RPItems:PreventItemPedestalEffects(itemID)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local player = game:GetPlayer(0)

  -- Car Battery will mess up the D6 and D100 (and possibly others) because
  -- this function will be entered twice on the same frame (and there will be no time to replace the pedestal)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) then -- 356
    return
  end

  if RPItems:UnreplacedItemsExist() then
    Isaac.DebugString("Canceling item " .. tostring(itemID) .. " due to unreplaced items in the room.")
    RPGlobals.run.rechargeItemFrame = gameFrameCount + 1
    return true
  end
end

function RPItems:UnreplacedItemsExist()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end

  -- Look for pedestals that have not been replaced yet
  local entities = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 5.100
                                    -1, false, false)
  for i = 1, #entities do
    local entity = entities[i]
    local alreadyReplaced = false
    for j = 1, #RPGlobals.run.replacedPedestals do
      if RPGlobals.run.replacedPedestals[j].room == roomIndex and
         RPGlobals.run.replacedPedestals[j].seed == entity.InitSeed then

        alreadyReplaced = true
        break
      end
    end

    if alreadyReplaced == false then
      return true
    end
  end

  return false
end

--
-- Post-use collectible item functions
-- ModCallbacks.MC_USE_ITEM (3)
--

-- Will get called for all items
function RPItems:Main(collectibleType)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local player = game:GetPlayer(0)
  local activeItem = player:GetActiveItem()
  local activeCharge = player:GetActiveCharge()
  local batteryCharge = player:GetBatteryCharge()

  -- Fix The Battery + 9 Volt synergy (1/2)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and -- 63
     player:HasCollectible(CollectibleType.COLLECTIBLE_NINE_VOLT) and -- 116
     RPGlobals:GetItemMaxCharges(activeItem) >= 2 and
     activeCharge == RPGlobals:GetItemMaxCharges(activeItem) and
     batteryCharge == RPGlobals:GetItemMaxCharges(activeItem) then

    RPGlobals.run.giveExtraCharge = true
  end

  -- Fix the Schoolbag + Butter! bug
  if player:HasTrinket(TrinketType.TRINKET_BUTTER) then
    RPGlobals.run.droppedButterItem = collectibleType -- (the pedestal will appear on the next game frame)
    Isaac.DebugString("The Butter! trinket dropped item " .. tostring(collectibleType) ..
                      " (on frame " .. tostring(gameFrameCount) .. ").")
    -- We will check this variable later in the PostUpdate callback (the "RPSchoolbag:CheckSecondItem()" function)
  end
end

-- This callback is used naturally by Broken Remote
-- This callback is manually called for Cursed Eye
function RPItems:Teleport() -- 44
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

function RPItems:BlankCard() -- 286
  local game = Game()
  local player = game:GetPlayer(0)
  local card = player:GetCard(0)
  if card == Card.CARD_FOOL or -- 1
     card == Card.CARD_EMPEROR or -- 5
     card == Card.CARD_HERMIT or -- 10
     card == Card.CARD_STARS or -- 18
     card == Card.CARD_MOON or -- 19
     card == Card.CARD_JOKER then -- 31

    -- We don't want to display the "use" animation, we just want to instantly teleport
    -- Blank Card is hard coded to queue the "use" animation, so stop it on the next frame
    RPGlobals.run.usedTelepills = true
  end
end

function RPItems:Undefined() -- 324
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

function RPItems:Void() -- 477
  -- We need to delay item replacement after using a Void (in case the player has consumed a D6)
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  RPGlobals.run.itemReplacementDelay = gameFrameCount + 5 -- Stall for 5 frames
end

function RPItems:MysteryGift() -- 515
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  RPGlobals.run.mysteryGiftFrame = gameFrameCount + 1
  Isaac.DebugString("Mystery Gift activated; setting the coal check frame to: " ..
                    tostring(RPGlobals.run.mysteryGiftFrame))
end

function RPItems:MovingBox() -- 523
  Isaac.DebugString("Moving Box activated.")
  if RPGlobals.run.movingBoxOpen then
    -- Check to see if there are any pickups on the ground
    local pickupsPresent = false
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      if entity.Type == EntityType.ENTITY_PICKUP and
         entity.Variant ~= PickupVariant.PICKUP_BIGCHEST and -- 340
         entity.Variant ~= PickupVariant.PICKUP_TROPHY and -- 370
         entity.Variant ~= PickupVariant.PICKUP_BED then -- 380

        pickupsPresent = true
        break
      end
    end
    if pickupsPresent then
      RPGlobals.run.movingBoxOpen = false
      Isaac.DebugString("Set the Moving Box graphic to the open state.")
    else
      Isaac.DebugString("No pickups found.")
    end
  else
    RPGlobals.run.movingBoxOpen = true
    Isaac.DebugString("Set the Moving Box graphic to the closed state.")
  end
end

return RPItems

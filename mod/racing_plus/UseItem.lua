local UseItem = {}

-- Includes
local g            = require("racing_plus/globals")
local Race         = require("racing_plus/race")
local SeededFloors = require("racing_plus/seededfloors")

-- ModCallbacks.MC_USE_ITEM (3)
function UseItem:Main(collectibleType)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local activeItem = g.p:GetActiveItem()
  local activeCharge = g.p:GetActiveCharge()
  local batteryCharge = g.p:GetBatteryCharge()

  -- Fix The Battery + 9 Volt synergy (1/2)
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and -- 63
     g.p:HasCollectible(CollectibleType.COLLECTIBLE_NINE_VOLT) and -- 116
     g:GetItemMaxCharges(activeItem) >= 2 and
     activeCharge == g:GetItemMaxCharges(activeItem) and
     batteryCharge == g:GetItemMaxCharges(activeItem) then

    g.run.giveExtraCharge = true
  end

  -- Fix the Schoolbag + Butter! bug
  if g.p:HasTrinket(TrinketType.TRINKET_BUTTER) then -- 122
    g.run.droppedButterItem = collectibleType -- (the pedestal will appear on the next game frame)
    Isaac.DebugString("The Butter! trinket dropped item " .. tostring(collectibleType) ..
                      " (on frame " .. tostring(gameFrameCount) .. ").")
    -- We will check this variable later in the PostUpdate callback (the "Schoolbag:CheckSecondItem()" function)
  end
end

-- CollectibleType.COLLECTIBLE_TELEPORT (44)
-- This callback is used naturally by Broken Remote
-- This callback is manually called for Cursed Eye
function UseItem:Item44()
  -- Local variables
  local rooms = g.l:GetRooms()

  -- Get a random room index
  -- We could adjust this so that our current room is exempt from the list of available rooms,
  -- but this would cause problems in seeded races, so seeded races would have to be exempt from this exemption
  -- Thus, don't bother with this in order to keep the behavior consistent through the different types of races
  g.RNGCounter.Teleport = g:IncrementRNG(g.RNGCounter.Teleport)
  math.randomseed(g.RNGCounter.Teleport)
  local roomNum = math.random(0, rooms.Size - 1)
  local gridIndex = rooms:Get(roomNum).SafeGridIndex
  -- We need to use SafeGridIndex instead of GridIndex because we will crash when teleporting to L rooms otherwise

  -- Teleport
  g.run.naturalTeleport = true -- Mark that this is not a Cursed Eye teleport
  g.run.usedTeleport = true -- Mark to potentially reposition the player (if they appear at a non-existent entrance)
  g.l.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
  g.g:StartRoomTransition(gridIndex, Direction.NO_DIRECTION, g.RoomTransition.TRANSITION_TELEPORT)
  Isaac.DebugString("Teleport! / Broken Remote / Cursed Eye to room: " .. tostring(gridIndex))

  -- This will override the existing Teleport! / Broken Remote effect because
  -- we have already locked in a room transition
end

-- CollectibleType.COLLECTIBLE_D6 (105)
function UseItem:Item105()
  -- Used to prevent bugs with The Void + D6
  g.run.usedD6Frame = g.g:GetFrameCount()
end

-- CollectibleType.COLLECTIBLE_FORGET_ME_NOW (127)
-- Also called manually when we touch a 5-pip Dice Room
function UseItem:Item127()
  -- Local variables
  local stage = g.l:GetStage()
  local customRun = g.seeds:IsCustomRun()
  local challenge = Isaac.GetChallenge()

  -- Do nothing if we are not playing on a set seed
  if challenge ~= 0 or
     not customRun then

    return
  end

  SeededFloors:Before(stage)
  g.run.forgetMeNow = true
  Isaac.DebugString("Forget Me Now / 5-pip Dice Room detected. Seeding the next floor...")
  -- We will call the "SeededFloors:After()" function manually in the MC_POST_NEW_LEVEL callback
end

-- CollectibleType.COLLECTIBLE_BLANK_CARD (286)
function UseItem:Item286()
  local card = g.p:GetCard(0)
  if card == Card.CARD_FOOL or -- 1
     card == Card.CARD_EMPEROR or -- 5
     card == Card.CARD_HERMIT or -- 10
     card == Card.CARD_STARS or -- 18
     card == Card.CARD_MOON or -- 19
     card == Card.CARD_JOKER then -- 48
     -- (checking for "? Card" is not necessary)

    -- We do not want to display the "use" animation
    -- Blank Card is hard coded to queue the "use" animation, so stop it on the next frame
    g.run.usedBlankCard = true
  end
end

-- CollectibleType.COLLECTIBLE_UNDEFINED (324)
function UseItem:Item324()
  -- Local variables
  local stage = g.l:GetStage()
  local rooms = g.l:GetRooms()

  -- It is not possible to teleport to I AM ERROR rooms and Black Markets on The Chest / Dark Room / The Void
  local insertErrorRoom = false
  local insertBlackMarket = false
  if stage ~= 11 and stage ~= 12 then
    insertErrorRoom = true

    -- There is a 1% chance have a Black Market inserted into the list of possibilities (according to blcd)
    g.RNGCounter.Undefined = g:IncrementRNG(g.RNGCounter.Undefined)
    math.randomseed(g.RNGCounter.Undefined)
    local blackMarketRoll = math.random(1, 100) -- Item room, secret room, super secret room, I AM ERROR room
    if blackMarketRoll <= 1 then
      insertBlackMarket = true
    end
  end

  -- Find the indexes for all of the room possibilities
  local roomIndexes = {}
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    -- We need to use SafeGridIndex instead of GridIndex because we will crash when teleporting to L rooms otherwise
    local room = rooms:Get(i)
    local roomType = room.Data.Type
    if roomType == RoomType.ROOM_TREASURE and -- 4
       not Race:CheckBanB1TreasureRoom() then

      roomIndexes[#roomIndexes + 1] = room.SafeGridIndex
    end
    if roomType == RoomType.ROOM_SECRET or -- 7
       roomType == RoomType.ROOM_SUPERSECRET then -- 8

      roomIndexes[#roomIndexes + 1] = room.SafeGridIndex
    end
  end
  if insertErrorRoom then
    roomIndexes[#roomIndexes + 1] = GridRooms.ROOM_ERROR_IDX -- -2
  end
  if insertBlackMarket then
    roomIndexes[#roomIndexes + 1] = GridRooms.ROOM_BLACK_MARKET_IDX -- -6
  end

  -- Get a random index
  g.RNGCounter.Undefined = g:IncrementRNG(g.RNGCounter.Undefined)
  math.randomseed(g.RNGCounter.Undefined)
  local gridIndex = roomIndexes[math.random(1, #roomIndexes)]

  -- Teleport
  g.run.naturalTeleport = true -- Mark that this is not a Cursed Eye teleport
  g.run.usedTeleport = true -- Mark to potentially reposition the player (if they appear at a non-existent entrance)
  g.l.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
  g.g:StartRoomTransition(gridIndex, Direction.NO_DIRECTION, g.RoomTransition.TRANSITION_TELEPORT)
  Isaac.DebugString("Undefined to room: " .. tostring(gridIndex))

  -- This will override the existing Undefined effect because we have already locked in a room transition
end

-- CollectibleType.COLLECTIBLE_TELEPORT_2 (419)
function UseItem:Item419()
  g.run.naturalTeleport = true -- Mark that this is not a Cursed Eye teleport
end

-- CollectibleType.COLLECTIBLE_VOID (477)
function UseItem:Item477()
  -- Used to prevent bugs with The Void + D6
  g.run.usedVoidFrame = g.g:GetFrameCount()

  -- Voided pedestal items should count as starting a Challenge Room or the Boss Rush
  local collectibles = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 5.100
                                        -1, false, false)
  if #collectibles > 0 then
    g.run.touchedPickup = true
  end
end

-- CollectibleType.COLLECTIBLE_MOVING_BOX (523)
function UseItem:Item523()
  Isaac.DebugString("Moving Box activated.")
  if g.run.movingBoxOpen then
    -- Check to see if there are any pickups on the ground
    local pickupsPresent = false
    local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP, -1, -1, false, false) -- 5
    for _, pickup in ipairs(pickups) do
      if pickup.Variant ~= PickupVariant.PICKUP_BIGCHEST and -- 340
         pickup.Variant ~= PickupVariant.PICKUP_TROPHY and -- 370
         pickup.Variant ~= PickupVariant.PICKUP_BED then -- 380

        pickupsPresent = true
        break
      end
    end
    if pickupsPresent then
      g.run.movingBoxOpen = false
      Isaac.DebugString("Set the Moving Box graphic to the open state.")
    else
      Isaac.DebugString("No pickups found.")
    end
  else
    g.run.movingBoxOpen = true
    Isaac.DebugString("Set the Moving Box graphic to the closed state.")
  end
end

-- Racing+ manually seeds all pedestal items based on the room seed
-- This is a problem for player-created pedestals, since they will be able to be rerolled into
-- different items depending on which room they are used in
function UseItem:PlayerGeneratedPedestal()
  local gameFrameCount = g.g:GetFrameCount()
  g.run.playerGenPedFrame = gameFrameCount + 1
end

return UseItem

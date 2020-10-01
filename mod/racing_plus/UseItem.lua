local UseItem = {}

-- Includes
local g = require("racing_plus/globals")
local PostNewRoom = require("racing_plus/postnewroom")
local SeededFloors = require("racing_plus/seededfloors")

-- ModCallbacks.MC_USE_ITEM (3)
function UseItem:Main(collectibleType)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local activeItem = g.p:GetActiveItem()
  local activeCharge = g.p:GetActiveCharge()
  local batteryCharge = g.p:GetBatteryCharge()

  -- Fix The Battery + 9 Volt synergy (1/2)
  if (
    g.p:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) -- 63
    and g.p:HasCollectible(CollectibleType.COLLECTIBLE_NINE_VOLT) -- 116
    and g:GetItemMaxCharges(activeItem) >= 2
    and activeCharge == g:GetItemMaxCharges(activeItem)
    and batteryCharge == g:GetItemMaxCharges(activeItem)
  ) then
    g.run.giveExtraCharge = true
  end

  -- Fix the Schoolbag + Butter! bug
  if g.p:HasTrinket(TrinketType.TRINKET_BUTTER) then -- 122
    g.run.droppedButterItem = collectibleType -- (the pedestal will appear on the next game frame)
    Isaac.DebugString(
      "The Butter! trinket dropped item " .. tostring(collectibleType)
      .. " (on frame " .. tostring(gameFrameCount) .. ")."
    )
    -- We will check this variable later in the PostUpdate callback
    -- (the "Schoolbag:CheckSecondItem()" function)
  end
end

-- CollectibleType.COLLECTIBLE_TELEPORT (44)
-- This callback is used naturally by Broken Remote
-- This callback is manually called for Cursed Eye
function UseItem:Teleport()
  -- Local variables
  local rooms = g.l:GetRooms()

  -- Get a random room index
  -- We could adjust this so that our current room is exempt from the list of available rooms,
  -- but this would cause problems in seeded races,
  -- so seeded races would have to be exempt from this exemption
  -- Thus, don't bother with this in order to keep the behavior consistent through the different
  -- types of races
  g.RNGCounter.Teleport = g:IncrementRNG(g.RNGCounter.Teleport)
  math.randomseed(g.RNGCounter.Teleport)
  local roomNum = math.random(0, rooms.Size - 1)

  -- We need to use SafeGridIndex instead of GridIndex because we will crash when teleporting to
  -- L rooms otherwise
  local gridIndexSafe = rooms:Get(roomNum).SafeGridIndex

  -- Mark to potentially reposition the player (if they appear at a non-existent entrance)
  g.run.usedTeleport = true

  -- You have to set LeaveDoor before every teleport or else it will send you to the wrong room
  g.l.LeaveDoor = -1

  g.g:StartRoomTransition(
    gridIndexSafe,
    Direction.NO_DIRECTION, -- -1
    g.RoomTransition.TRANSITION_TELEPORT -- 3
  )
  Isaac.DebugString("Teleport! / Broken Remote / Cursed Eye to room: " .. tostring(gridIndexSafe))

  -- This will override the existing Teleport! / Broken Remote effect because
  -- we have already locked in a room transition
end

-- CollectibleType.COLLECTIBLE_D6 (105)
function UseItem:D6()
  -- Used to prevent bugs with The Void + D6
  g.run.usedD6Frame = g.g:GetFrameCount()
end

-- CollectibleType.COLLECTIBLE_FORGET_ME_NOW (127)
-- Also called manually when we touch a 5-pip Dice Room
function UseItem:ForgetMeNow()
  -- Local variables
  local stage = g.l:GetStage()
  local customRun = g.seeds:IsCustomRun()
  local challenge = Isaac.GetChallenge()

  -- Do nothing if we are not playing on a set seed
  if (
    challenge ~= 0
    or not customRun
  ) then
    return
  end

  SeededFloors:Before(stage)
  g.run.forgetMeNow = true
  Isaac.DebugString("Forget Me Now / 5-pip Dice Room detected. Seeding the next floor...")
  -- We will call the "SeededFloors:After()" function manually in the MC_POST_NEW_LEVEL callback
end

-- CollectibleType.COLLECTIBLE_BLANK_CARD (286)
function UseItem:BlankCard()
  local card = g.p:GetCard(0)
  if ( -- Checking for "? Card" is not necessary
    card == Card.CARD_FOOL -- 1
    or card == Card.CARD_EMPEROR -- 5
    or card == Card.CARD_HERMIT -- 10
    or card == Card.CARD_STARS -- 18
    or card == Card.CARD_MOON -- 19
    or card == Card.CARD_JOKER -- 48
  ) then
    -- We do not want to display the "use" animation
    -- Blank Card is hard coded to queue the "use" animation, so stop it on the next frame
    g.run.usedBlankCard = true
  end
end

-- CollectibleType.COLLECTIBLE_UNDEFINED (324)
function UseItem:Undefined()
  -- Local variables
  local stage = g.l:GetStage()
  local rooms = g.l:GetRooms()

  -- It is not possible to teleport to I AM ERROR rooms and Black Markets on
  -- The Chest / Dark Room / The Void
  local insertErrorRoom = false
  local insertBlackMarket = false
  if stage ~= 11 and stage ~= 12 then
    insertErrorRoom = true

    -- There is a 1% chance have a Black Market inserted into the list of possibilities
    -- (according to blcd)
    g.RNGCounter.Undefined = g:IncrementRNG(g.RNGCounter.Undefined)
    math.randomseed(g.RNGCounter.Undefined)
    local blackMarketRoll = math.random(1, 100)
    if blackMarketRoll <= 1 then
      insertBlackMarket = true
    end
  end

  -- Find the indexes for all of the room possibilities
  local roomIndexes = {}
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    -- We need to use SafeGridIndex instead of GridIndex because we will crash when teleporting to
    -- L rooms otherwise
    local room = rooms:Get(i)
    local roomType = room.Data.Type
    if (
      roomType == RoomType.ROOM_TREASURE -- 4
      and not PostNewRoom:CheckBanB1TreasureRoom()
    ) then
      roomIndexes[#roomIndexes + 1] = room.SafeGridIndex
    end
    if (
      roomType == RoomType.ROOM_SECRET -- 7
      or roomType == RoomType.ROOM_SUPERSECRET -- 8
    ) then
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

  -- Mark to potentially reposition the player (if they appear at a non-existent entrance)
  g.run.usedTeleport = true

  -- You have to set LeaveDoor before every teleport or else it will send you to the wrong room
  g.l.LeaveDoor = -1

  g.g:StartRoomTransition(gridIndex, Direction.NO_DIRECTION, g.RoomTransition.TRANSITION_TELEPORT)
  Isaac.DebugString("Undefined to room: " .. tostring(gridIndex))

  -- This will override the existing Undefined effect because we have already locked in a room
  -- transition
end

-- CollectibleType.COLLECTIBLE_VOID (477)
function UseItem:Void()
  -- Used to prevent bugs with The Void + D6
  g.run.usedVoidFrame = g.g:GetFrameCount()

  -- Voided pedestal items should count as starting a Challenge Room or the Boss Rush
  local collectibles = Isaac.FindByType(
    EntityType.ENTITY_PICKUP, -- 5
    PickupVariant.PICKUP_COLLECTIBLE, -- 100
    -1,
    false,
    false
  )
  if #collectibles > 0 then
    g.run.touchedPickup = true
  end
end

-- CollectibleType.COLLECTIBLE_MOVING_BOX (523)
function UseItem:MovingBox()
  Isaac.DebugString("Moving Box activated.")
  if g.run.movingBoxOpen then
    -- Check to see if there are any pickups on the ground
    local pickupsPresent = false
    local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP, -1, -1, false, false) -- 5
    for _, pickup in ipairs(pickups) do
      if (
        pickup.Variant ~= PickupVariant.PICKUP_BIGCHEST -- 340
        and pickup.Variant ~= PickupVariant.PICKUP_TROPHY -- 370
        and pickup.Variant ~= PickupVariant.PICKUP_BED -- 380
      ) then
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

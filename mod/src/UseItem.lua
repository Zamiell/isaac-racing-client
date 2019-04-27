local UseItem = {}

-- Includes
local g            = require("src/globals")
local SeededFloors = require("src/seededfloors")

-- ModCallbacks.MC_USE_ITEM (3)
-- Will get called for all items
function UseItem:Main(collectibleType)
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
     g:GetItemMaxCharges(activeItem) >= 2 and
     activeCharge == g:GetItemMaxCharges(activeItem) and
     batteryCharge == g:GetItemMaxCharges(activeItem) then

    g.run.giveExtraCharge = true
  end

  -- Fix the Schoolbag + Butter! bug
  if player:HasTrinket(TrinketType.TRINKET_BUTTER) then
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
  local game = Game()
  local level = game:GetLevel()
  local rooms = level:GetRooms()

  -- Get a random room index
  g.RNGCounter.Teleport = g:IncrementRNG(g.RNGCounter.Teleport)
  math.randomseed(g.RNGCounter.Teleport)
  local roomNum = math.random(0, rooms.Size - 1)
  local gridIndex = rooms:Get(roomNum).SafeGridIndex
  -- We need to use SafeGridIndex instead of GridIndex because we will crash when teleporting to L rooms otherwise

  -- Teleport
  g.run.naturalTeleport = true -- Mark that this is not a Cursed Eye teleport
  level.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
  game:StartRoomTransition(gridIndex, Direction.NO_DIRECTION, g.RoomTransition.TRANSITION_TELEPORT)
  Isaac.DebugString("Teleport! / Broken Remote / Cursed Eye to room: " .. tostring(gridIndex))

  -- This will override the existing Teleport! / Broken Remote effect because
  -- we have already locked in a room transition
end

-- CollectibleType.COLLECTIBLE_FORGET_ME_NOW (127)
-- Also called manually when we touch a 5-pip Dice Room
function UseItem:Item127()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local seeds = game:GetSeeds()
  local customRun = seeds:IsCustomRun()
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
    g.run.usedTelepills = true
  end
end

-- CollectibleType.COLLECTIBLE_UNDEFINED (324)
function UseItem:Item324()
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
  g.RNGCounter.Undefined = g:IncrementRNG(g.RNGCounter.Undefined)
  math.randomseed(g.RNGCounter.Undefined)
  local gridIndex = roomIndexes[math.random(1, #roomIndexes)]

  -- Teleport
  g.run.naturalTeleport = true -- Mark that this is not a Cursed Eye teleport
  level.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
  game:StartRoomTransition(gridIndex, Direction.NO_DIRECTION, g.RoomTransition.TRANSITION_TELEPORT)
  Isaac.DebugString("Undefined to room: " .. tostring(gridIndex))

  -- This will override the existing Undefined effect because we have already locked in a room transition
end

-- CollectibleType.COLLECTIBLE_VOID (477)
function UseItem:Item477()
  -- We need to delay item replacement after using a Void (in case the player has consumed a D6)
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  g.run.itemReplacementDelay = gameFrameCount + 5 -- Stall for 5 frames
end

-- CollectibleType.COLLECTIBLE_MYSTERY_GIFT (515)
function UseItem:Item515()
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  g.run.mysteryGiftFrame = gameFrameCount + 1
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
-- This is a problem for player-created pedestals, since they will be able to be rerolled into different items
-- depending on which room they are used in
function UseItem:PlayerGeneratedPedestal()
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  g.run.playerGenPedFrame = gameFrameCount + 1
end

return UseItem

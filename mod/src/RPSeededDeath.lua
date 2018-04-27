local RPSeededDeath = {}

-- Variables
RPSeededDeath.DebuffTime = 45 -- In seconds

--
-- Includes
--

local RPGlobals = require("src/rpglobals")

-- ModCallbacks.MC_POST_RENDER (2)
function RPSeededDeath:PostRender()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local player = game:GetPlayer(0)
  local playerSprite = player:GetSprite()

  -- Keep track of whenever we take a deal with the devil
  if (roomType == RoomType.ROOM_DEVIL or -- 14
      roomType == RoomType.ROOM_BLACK_MARKET) and -- 22
     (playerSprite:IsPlaying("Pickup") or
      playerSprite:IsPlaying("PickupWalkDown") or
      playerSprite:IsPlaying("PickupWalkLeft") or
      playerSprite:IsPlaying("PickupWalkUp") or
      playerSprite:IsPlaying("PickupWalkRight")) then

    RPGlobals.run.seededDeath.dealTime = Isaac.GetTime()
  end

  -- Seeded death (1/3)
  if RPGlobals.race.rFormat == "seeded" and
     (playerSprite:IsPlaying("Death") or
      playerSprite:IsPlaying("LostDeath")) and
     playerSprite:GetFrame() >= 54 and
     player:WillPlayerRevive() == false and
     roomType ~= RoomType.ROOM_SACRIFICE then -- 13

    -- We want to make an exception for deaths from devil deals
    local elapsedTime = Isaac.GetTime() - RPGlobals.run.seededDeath.dealTime
    if elapsedTime > 5000 then
      RPGlobals:RevivePlayer()
      RPGlobals.run.seededDeath.state = 1
      Isaac.DebugString("Seeded death (1/3).")
    end
  end

  -- Seeded death (3/3)
  if RPGlobals.run.seededDeath.state == 2 then
    player.Position = RPGlobals.run.seededDeath.pos
    if playerSprite:IsPlaying("AppearVanilla") == false then
      RPGlobals.run.seededDeath.state = 3
      Isaac.DebugString("Seeded death (3/3).")
    end
  end

  -- Check to see if the debuff is over
  if RPGlobals.run.seededDeath.state == 3 then
    local elapsedTime = RPGlobals.run.seededDeath.time - Isaac.GetTime()
    if elapsedTime <= 0 then
      RPGlobals.run.seededDeath.state = 0
      RPGlobals.run.seededDeath.time = 0
      RPSeededDeath:DebuffOff()
      player:AnimateHappy()
      Isaac.DebugString("Seeded death debuff complete.")
    end
  end
end

-- ModCallbacks.MC_POST_NEW_ROOM (19)
function RPSeededDeath:PostNewRoom()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local playerSprite = player:GetSprite()
  local character = player:GetPlayerType()

  -- Seeded death (2/3)
  if RPGlobals.run.seededDeath.state ~= 1 then
    return
  end

  -- Set their health to explicitly 1.5 soul hearts
  player:AddMaxHearts(-24, false)
  player:AddSoulHearts(-24)
  if character == PlayerType.PLAYER_KEEPER then -- 14
    player:AddMaxHearts(2)
    player:AddHearts(2)
  else
    player:AddSoulHearts(3)
  end

  -- Start the debuff and set the finishing time to be in the future
  RPSeededDeath:DebuffOn()
  RPGlobals.run.seededDeath.time = Isaac.GetTime() + RPSeededDeath.DebuffTime * 1000

  -- Play the animation where Isaac lies in the fetal position
  player:PlayExtraAnimation("AppearVanilla")

  -- Fade the player
  playerSprite.Color = Color(1, 1, 1, 0.25, 0, 0, 0)

  RPGlobals.run.seededDeath.state = 2
  RPGlobals.run.seededDeath.pos = Vector(player.Position.X, player.Position.Y)
  Isaac.DebugString("Seeded death (2/3).")
end

function RPSeededDeath:DebuffOn()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- Remove any golden bombs and keys
  player:RemoveGoldenBomb()
  player:RemoveGoldenKey()

  -- Remove the items (and store them for later)
  local backupItems = RPGlobals:TableClone(RPGlobals.run.seededDeath.items)
  RPGlobals.run.seededDeath.items = {}
  RPGlobals.run.seededDeath.charge = player:GetActiveCharge()
  for i = 1, CollectibleType.NUM_COLLECTIBLES do
    local numItems = player:GetCollectibleNum(i)
    if numItems > 0 then
      for j = 1, numItems do
        RPGlobals.run.seededDeath.items[#RPGlobals.run.seededDeath.items + 1] = i
        player:RemoveCollectible(i)
        local debugString = "Removing collectible " .. tostring(i)
        if i == CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM then
          debugString = debugString .. " (Schoolbag)"
        end
        Isaac.DebugString(debugString)
        player:TryRemoveCollectibleCostume(i, false)
      end
    end
  end
  player:EvaluateItems()

  -- We need to handle the case where we die a second time before getting our items back
  if #RPGlobals.run.seededDeath.items == 0 then
    RPGlobals.run.seededDeath.items = backupItems
  end
end

function RPSeededDeath:DebuffOff()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local playerSprite = player:GetSprite()

  -- Unfade the character
  playerSprite.Color = Color(1, 1, 1, 1, 0, 0, 0)

  -- Store the current red hearts, soul/black hearts, bombs, and keys
  local hearts = player:GetHearts()
  local maxHearts = player:GetMaxHearts()
  local soulHearts = player:GetSoulHearts()
  local blackHearts = player:GetBlackHearts()
  local bombs = player:GetNumBombs()
  local keys = player:GetNumKeys()

  -- Add all of the items from the array
  local deletePickups = false
  for i = 1, #RPGlobals.run.seededDeath.items do
    local itemID = RPGlobals.run.seededDeath.items[i]
    player:AddCollectible(itemID, 0, false)
    if itemID == CollectibleType.COLLECTIBLE_PHD or -- 75
       itemID == CollectibleType.COLLECTIBLE_PAGEANT_BOY or -- 141
       itemID == CollectibleType.COLLECTIBLE_MAGIC_8_BALL or -- 194
       itemID == CollectibleType.COLLECTIBLE_MOMS_COIN_PURSE or -- 195
       itemID == CollectibleType.COLLECTIBLE_SQUEEZY or -- 196
       itemID == CollectibleType.COLLECTIBLE_BOX or -- 198
       itemID == CollectibleType.COLLECTIBLE_STARTER_DECK or -- 251
       itemID == CollectibleType.COLLECTIBLE_LITTLE_BAGGY or -- 252
       itemID == CollectibleType.COLLECTIBLE_CAFFEINE_PILL or -- 340
       itemID == CollectibleType.COLLECTIBLE_LATCH_KEY or -- 343
       itemID == CollectibleType.COLLECTIBLE_MATCH_BOOK or -- 344
       itemID == CollectibleType.COLLECTIBLE_CRACK_JACKS or -- 354
       itemID == CollectibleType.COLLECTIBLE_MR_DOLLY or -- 370
       itemID == CollectibleType.COLLECTIBLE_RESTOCK or -- 376
       itemID == CollectibleType.COLLECTIBLE_CHAOS or -- 402
       itemID == CollectibleType.COLLECTIBLE_SACK_HEAD or -- 424
       itemID == CollectibleType.COLLECTIBLE_TAROT_CLOTH or -- 451
       itemID == CollectibleType.COLLECTIBLE_POLYDACTYLY or -- 454
       itemID == CollectibleType.COLLECTIBLE_DADS_LOST_COIN or -- 455
       itemID == CollectibleType.COLLECTIBLE_BELLY_BUTTON then -- 458

      deletePickups = true
    end
  end
  player:SetActiveCharge(RPGlobals.run.seededDeath.charge)

  -- Set the health to the way it was before the items were added
  player:AddMaxHearts(-24, true) -- Remove all hearts
  player:AddSoulHearts(-24)
  player:AddMaxHearts(maxHearts, true)
  player:AddHearts(hearts)
  for i = 1, soulHearts do
    local bitPosition = math.floor((i - 1) / 2)
    local bit = (blackHearts & (1 << bitPosition)) >> bitPosition
    if bit == 0 then -- Soul heart
      player:AddSoulHearts(1)
    else -- Black heart
      player:AddBlackHearts(1)
    end
  end

  -- Set the inventory to the way it was before the items were added
  player:AddBombs(-99)
  player:AddBombs(bombs)
  player:AddKeys(-99)
  player:AddKeys(keys)

  -- Delete all pickups
  if deletePickups then
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      if entity.Type == EntityType.ENTITY_PICKUP and
         entity.Variant ~= PickupVariant.PICKUP_COLLECTIBLE then -- 100

        entity:Remove()
      end
    end
  end
end

return RPSeededDeath

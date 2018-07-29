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
  -- (they took fatal damage and begin the death animation)
  if (RPGlobals.race.rFormat == "seeded" or
      RPGlobals.race.rFormat == "seeded-mo") and
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

      -- Drop all trinkets and pocket items
      player:DropTrinket(room:FindFreePickupSpawnPosition(player.Position, 0, true), false)
      player:DropPoketItem(0, room:FindFreePickupSpawnPosition(player.Position, 0, true))
      player:DropPoketItem(1, room:FindFreePickupSpawnPosition(player.Position, 0, true))
    end
  end

  -- Seeded death (3/3)
  -- (they just slid back to the previous room)
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

  -- Seeded death (2/3)
  if RPGlobals.run.seededDeath.state ~= 1 then
    return
  end

  -- Start the debuff and set the finishing time to be in the future
  RPSeededDeath:DebuffOn()
  local debuffTimeMilliseconds = RPSeededDeath.DebuffTime * 1000
  if RPGlobals.debug then
    debuffTimeMilliseconds = 5 * 1000
  end
  RPGlobals.run.seededDeath.time = Isaac.GetTime() + debuffTimeMilliseconds

  -- Play the animation where Isaac lies in the fetal position
  player:PlayExtraAnimation("AppearVanilla")

  RPGlobals.run.seededDeath.state = 2
  RPGlobals.run.seededDeath.pos = Vector(player.Position.X, player.Position.Y)
  Isaac.DebugString("Seeded death (2/3).")
end

-- Prevent people from resetting for a Sacrifice Room in R+7 Season 4
function RPSeededDeath:PostNewRoomCheckSacrificeRoom()
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local gridSize = room:GetGridSize()
  local player = game:GetPlayer(0)

  if RPGlobals.run.seededDeath.state ~= 3 or
     roomType ~= RoomType.ROOM_SACRIFICE then -- 13

    return
  end

  player:AnimateSad()
  for i = 1, gridSize do
    local gridEntity = room:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState()
      if saveState.Type == GridEntityType.GRID_SPIKES then -- 8
        room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
      end

    end
  end
  Isaac.DebugString("Deleted the spikes in a Sacrifice Room (during a seeded death debuff).")
end

function RPSeededDeath:DebuffOn()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local playerSprite = player:GetSprite()
  local character = player:GetPlayerType()

  -- Set their health to explicitly 1.5 soul hearts
  -- (or custom values for Keeper & The Forgotton)
  player:AddMaxHearts(-24, false)
  player:AddSoulHearts(-24)
  if character == PlayerType.PLAYER_KEEPER then -- 14
    player:AddMaxHearts(2)
    player:AddHearts(2)
  elseif character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
    player:AddMaxHearts(2)
    player:AddHearts(1)
  elseif character == PlayerType.PLAYER_THESOUL then -- 17
    player:AddHearts(1)
  else
    player:AddSoulHearts(3)
  end

  -- Store their active item charge for later
  RPGlobals.run.seededDeath.charge = player:GetActiveCharge()

  -- Store their size for later, and then reset it to default
  -- (in case they had items like Magic Mushroom and so forth)
  RPGlobals.run.seededDeath.spriteScale = player.SpriteScale
  player.SpriteScale = Vector(1, 1)

  -- We need to remove every item (and store it for later)
  -- ("player:GetCollectibleNum()" is bugged if you feed it a number higher than the total amount of items and
  -- can cause the game to crash)
  for i = 1, RPGlobals:GetTotalItemCount() do
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

  -- Remove any golden bombs and keys
  player:RemoveGoldenBomb()
  player:RemoveGoldenKey()

  -- Remove any Dead Eye multiplier
  for i = 1, 100 do
    -- Each time this function is called, it only has a change of working,
    -- so just call it 100 times to be safe
    player:ClearDeadEyeCharge()
  end

  -- Fade the player
  playerSprite.Color = Color(1, 1, 1, 0.25, 0, 0, 0)
end

function RPSeededDeath:DebuffOff()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local playerSprite = player:GetSprite()
  local character = player:GetPlayerType()

  -- Unfade the character
  playerSprite.Color = Color(1, 1, 1, 1, 0, 0, 0)

  -- Store the current red hearts, soul/black hearts, bombs, and keys
  local hearts = player:GetHearts()
  local maxHearts = player:GetMaxHearts()
  local soulHearts = player:GetSoulHearts()
  local blackHearts = player:GetBlackHearts()
  local boneHearts = player:GetBoneHearts()
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
       itemID == CollectibleType.COLLECTIBLE_BELLY_BUTTON or -- 458
       itemID == CollectibleType.COLLECTIBLE_MARBLES or -- 538
       itemID == CollectibleType.COLLECTIBLE_MARROW or -- 541
       itemID == CollectibleType.COLLECTIBLE_DIVORCE_PAPERS then -- 547

      deletePickups = true
    end
  end

  -- Reset the items in the array
  RPGlobals.run.seededDeath.items = {}

  -- Set the charge to the way it was before the debuff was applied
  player:SetActiveCharge(RPGlobals.run.seededDeath.charge)

  -- Set their size to the way it was before the debuff was applied
  player.SpriteScale = RPGlobals.run.seededDeath.spriteScale

  -- Set the health to the way it was before the items were added
  player:AddMaxHearts(-24, true) -- Remove all hearts
  player:AddSoulHearts(-24)
  player:AddBoneHearts(-24)
  player:AddMaxHearts(maxHearts, true)
  player:AddBoneHearts(boneHearts)
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

  -- If The Soul is active when the debuff ends, the health will not be handled properly,
  -- so manually set everything
  if character == PlayerType.PLAYER_THESOUL then -- 17
    player:AddBoneHearts(-24)
    player:AddBoneHearts(1)
    player:AddHearts(-24)
    player:AddHearts(1)
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

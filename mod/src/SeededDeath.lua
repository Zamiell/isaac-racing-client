local SeededDeath = {}

-- Includes
local g         = require("src/globals")
local Schoolbag = require("src/schoolbag")

-- Variables
SeededDeath.DebuffTime = 45 -- In seconds

-- ModCallbacks.MC_POST_UPDATE (1)
function SeededDeath:PostUpdate()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local player = game:GetPlayer(0)
  local revive = player:WillPlayerRevive()
  local hearts = player:GetHearts()
  local soulHearts = player:GetSoulHearts()
  local boneHearts = player:GetBoneHearts()
  local challenge = Isaac.GetChallenge()

  -- Keep track of whenever we take a deal with the devil to prevent players from being able to take "free" items
  if (roomType == RoomType.ROOM_DEVIL or -- 14
      roomType == RoomType.ROOM_BLACK_MARKET) and -- 22
     player.QueuedItem.Item ~= nil then

    g.run.seededDeath.dealTime = Isaac.GetTime()
  end

  -- They took fatal damage and the death animation is playing
  -- (this used to be based on the "Death" and "LostDeath" animation, but this does not work for deaths inside Pitfalls)
  local totalHealth = hearts + soulHearts + boneHearts
  if g.run.seededDeath.deathFrame == 0 and
     (g.race.rFormat == "seeded" or
      g.race.rFormat == "seeded-mo" or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 6 Beta)")) and
     totalHealth == 0 and
     not revive and
     -- We want to make an exception for Sacrifice Rooms and the Boss Rush
     -- to prevent players from being able to take "free" items
     roomType ~= RoomType.ROOM_SACRIFICE and -- 13
     roomType ~= RoomType.ROOM_BOSSRUSH then -- 17

    g.run.seededDeath.deathFrame = gameFrameCount + 46 -- 56
    -- The "Death" animation is 57 frames long
    -- (when testing, the death screen appears if we wait 57 frames)
  end

  -- Seeded death (1/3) - The death animation is over
  if g.run.seededDeath.deathFrame ~= 0 and
     gameFrameCount >= g.run.seededDeath.deathFrame then

    g.run.seededDeath.deathFrame = 0

    -- Make sure that we don't revive the player if they recently took a devil deal
    local elapsedTime = Isaac.GetTime() - g.run.seededDeath.dealTime
    if elapsedTime > 5000 then
      g:RevivePlayer()
      g.run.seededDeath.state = 1
      Isaac.DebugString("Seeded death (1/3).")

      -- Drop all trinkets and pocket items
      player:DropTrinket(room:FindFreePickupSpawnPosition(player.Position, 0, true), false)
      player:DropPoketItem(0, room:FindFreePickupSpawnPosition(player.Position, 0, true))
      player:DropPoketItem(1, room:FindFreePickupSpawnPosition(player.Position, 0, true))
    end
  end

  -- Check to see if the debuff is over
  if g.run.seededDeath.state == 3 then
    local elapsedTime = g.run.seededDeath.time - Isaac.GetTime()
    if elapsedTime <= 0 then
      g.run.seededDeath.state = 0
      g.run.seededDeath.time = 0
      SeededDeath:DebuffOff()
      player:AnimateHappy()
      Isaac.DebugString("Seeded death debuff complete.")
    end
  end
end

-- ModCallbacks.MC_POST_RENDER (2)
function SeededDeath:PostRender()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local playerSprite = player:GetSprite()

  -- Seeded death (3/3) - The "AppearVanilla animation" is over and the debuff is on
  if g.run.seededDeath.state == 2 then
    -- Keep the player in place during the "AppearVanilla" animation
    player.Position = g.run.seededDeath.pos

    if not playerSprite:IsPlaying("AppearVanilla") then
      g.run.seededDeath.state = 3
      Isaac.DebugString("Seeded death (3/3).")
    end
  end
end

-- ModCallbacks.MC_POST_NEW_ROOM (19)
function SeededDeath:PostNewRoom()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local effects = player:GetEffects()
  local itemConfig = Isaac.GetItemConfig()

  -- Add a temporary Holy Mantle effect for Keeper after a seeded revival
  if g.run.tempHolyMantle then
    effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE) -- 313
    player:AddCostume(itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_HOLY_MANTLE)) -- 313
  end

  -- Seeded death (2/3) - The player is in the fetal position (the "AppearVanilla" animation)
  if g.run.seededDeath.state ~= 1 then
    return
  end

  -- Start the debuff and set the finishing time to be in the future
  SeededDeath:DebuffOn()
  local debuffTimeMilliseconds = SeededDeath.DebuffTime * 1000
  if g.debug then
    debuffTimeMilliseconds = 5 * 1000
  end
  g.run.seededDeath.time = Isaac.GetTime() + debuffTimeMilliseconds

  -- Play the animation where Isaac lies in the fetal position
  player:PlayExtraAnimation("AppearVanilla")

  g.run.seededDeath.state = 2
  g.run.seededDeath.pos = Vector(player.Position.X, player.Position.Y)
  Isaac.DebugString("Seeded death (2/3).")
end

-- Prevent people from abusing the death mechanic to use a Sacrifice Room
function SeededDeath:PostNewRoomCheckSacrificeRoom()
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local gridSize = room:GetGridSize()
  local player = game:GetPlayer(0)

  if g.run.seededDeath.state ~= 3 or
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

function SeededDeath:DebuffOn()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local player = game:GetPlayer(0)
  local playerSprite = player:GetSprite()
  local character = player:GetPlayerType()

  -- Store the current level
  g.run.seededDeath.stage = stage

  -- Set their health to explicitly 1.5 soul hearts
  -- (or custom values for Keeper & The Forgotton)
  player:AddMaxHearts(-24, true)
  player:AddSoulHearts(-24)
  if character == PlayerType.PLAYER_KEEPER then -- 14
    player:AddMaxHearts(2, true) -- One coin container
    player:AddHearts(2)
  elseif character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
    player:AddMaxHearts(2, true)
    player:AddHearts(1)
  elseif character == PlayerType.PLAYER_THESOUL then -- 17
    player:AddHearts(1)
  else
    player:AddSoulHearts(3)
  end

  -- Store their active item charge for later
  g.run.seededDeath.charge = player:GetActiveCharge()

  -- Store their size for later, and then reset it to default
  -- (in case they had items like Magic Mushroom and so forth)
  g.run.seededDeath.spriteScale = player.SpriteScale
  player.SpriteScale = Vector(1, 1)

  -- Store their golden bomb / key status
  g.run.seededDeath.goldenBomb = player:HasGoldenBomb()
  g.run.seededDeath.goldenKey = player:HasGoldenKey()

  -- We need to remove every item (and store it for later)
  -- ("player:GetCollectibleNum()" is bugged if you feed it a number higher than the total amount of items and
  -- can cause the game to crash)
  for i = 1, g:GetTotalItemCount() do
    local numItems = player:GetCollectibleNum(i)
    if numItems > 0 and
       player:HasCollectible(i) then

      -- Checking both "GetCollectibleNum()" and "HasCollectible()" prevents bugs such as Lilith having 1 Incubus
      for j = 1, numItems do
        g.run.seededDeath.items[#g.run.seededDeath.items + 1] = i
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

  -- Remove the Dead Eye multiplier, if any
  for i = 1, 100 do
    -- Each time this function is called, it only has a chance of working,
    -- so just call it 100 times to be safe
    player:ClearDeadEyeCharge()
  end

  -- Fade the player
  playerSprite.Color = Color(1, 1, 1, 0.25, 0, 0, 0)
end

function SeededDeath:DebuffOff()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)
  local playerSprite = player:GetSprite()
  local character = player:GetPlayerType()
  local effects = player:GetEffects()
  local itemConfig = Isaac.GetItemConfig()

  -- Unfade the character
  playerSprite.Color = Color(1, 1, 1, 1, 0, 0, 0)

  -- Store the current active item, red hearts, soul/black hearts, bombs, keys, and pocket items
  local activeItem = player:GetActiveItem()
  local activeCharge = player:GetActiveCharge()
  local hearts = player:GetHearts()
  local maxHearts = player:GetMaxHearts()
  local soulHearts = player:GetSoulHearts()
  local blackHearts = player:GetBlackHearts()
  local boneHearts = player:GetBoneHearts()
  local bombs = player:GetNumBombs()
  local keys = player:GetNumKeys()
  local cardSlot0 = player:GetCard(0)
  local pillSlot0 = player:GetPill(0)

  -- Add all of the items from the array
  for _, itemID in ipairs(g.run.seededDeath.items) do
    player:AddCollectible(itemID, 0, false)
  end

  -- Reset the items in the array
  g.run.seededDeath.items = {}

  -- Set the charge to the way it was before the debuff was applied
  player:SetActiveCharge(g.run.seededDeath.charge)

  -- Check to see if the active item changed
  -- (meaning that the player picked up a new active item during their ghost state)
  local newActiveItem = player:GetActiveItem()
  if activeItem ~= 0 and
     newActiveItem ~= activeItem then

    if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) and
       g.run.schoolbag.item == 0 then

      -- There is room in the Schoolbag, so put it in the Schoolbag
      Schoolbag:Put(activeItem, activeCharge)
      Isaac.DebugString("SeededDeath - Put the ghost active inside the Schoolbag.")

    else
      -- There is no room in the Schoolbag, so spawn it on the ground
      local position = room:FindFreePickupSpawnPosition(player.Position, 1, true)
      local pedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE,
                                  position, Vector(0, 0), nil, activeItem, 0):ToPickup()
      -- (we can use a seed of 0 beacuse it will be replaced on the next frame)
      pedestal.Charge = activeCharge
      pedestal.Touched = true
      Isaac.DebugString("SeededDeath - Put the old active item on the ground since there was no room for it.")
    end
  end

  -- Set their size to the way it was before the debuff was applied
  player.SpriteScale = g.run.seededDeath.spriteScale

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
  if g.run.seededDeath.goldenBomb then
    g.run.seededDeath.goldenBomb = false
    if stage == g.run.seededDeath.stage then
      player:AddGoldenBomb()
    end
  end
  if g.run.seededDeath.goldenKey then
    g.run.seededDeath.goldenKey = false
    if stage == g.run.seededDeath.stage then
      player:AddGoldenKey()
    end
  end

  -- We also have to account for Caffeine Pill,
  -- which is the only item in the game that directly puts a pocket item into your inventory
  if cardSlot0 ~= 0 then
    player:SetCard(0, cardSlot0)
  else
    player:SetPill(0, pillSlot0)
  end

  -- Delete all newly-spawned pickups in the room
  -- (re-giving back some items will cause pickups to spawn)
  local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP, -1, -1, false, false) -- 5
  for _, pickup in ipairs(pickups) do
    if pickup.Variant ~= PickupVariant.PICKUP_COLLECTIBLE and -- 100
       pickup.FrameCount == 0 then

      pickup:Remove()
    end
  end

  -- Fix character-specific bugs
  if character == PlayerType.PLAYER_LILITH then -- 13
    -- If Lilith had Incubus, the debuff will grant an extra Incubus, so account for this
    if player:HasCollectible(CollectibleType.COLLECTIBLE_INCUBUS) then -- 360
      player:RemoveCollectible(CollectibleType.COLLECTIBLE_INCUBUS) -- 360
    end
  elseif character == PlayerType.PLAYER_KEEPER then -- 14
    -- Keeper will get extra blue flies if he was given any items that grant soul hearts
    local blueFlies = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY, -1, false, false) -- 3.43
    for i, fly in ipairs(blueFlies) do
      fly:Remove()
    end

    -- Keeper will start with one coin container, which can lead to chain deaths
    -- Give Keeper a temporary Wooden Cross effect
    g.run.tempHolyMantle = true
    effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE) -- 313
    player:AddCostume(itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_HOLY_MANTLE)) -- 313
  end
end

return SeededDeath

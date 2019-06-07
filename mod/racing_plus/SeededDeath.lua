local SeededDeath = {}

-- Includes
local g         = require("racing_plus/globals")
local Schoolbag = require("racing_plus/schoolbag")

-- Enums
SeededDeath.state = {
  DISABLED = 0,
  CHANGING_ROOMS = 1,
  FETAL_POSITION = 2,
  GHOST_FORM = 3,
}

-- Variables
SeededDeath.debuffTime = 45 -- In seconds

-- ModCallbacks.MC_POST_UPDATE (1)
function SeededDeath:PostUpdate()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local roomType = g.r:GetType()
  local playerSprite = g.p:GetSprite()
  local revive = g.p:WillPlayerRevive()
  local hearts = g.p:GetHearts()
  local soulHearts = g.p:GetSoulHearts()
  local boneHearts = g.p:GetBoneHearts()
  local challenge = Isaac.GetChallenge()

  -- Keep track of whenever we take a deal with the devil to prevent players from being able to take "free" items
  if (roomType == RoomType.ROOM_DEVIL or -- 14
      roomType == RoomType.ROOM_CURSE or -- 10 (in Racing+ Rebalanced, there are DD items in a Curse Room)
      roomType == RoomType.ROOM_BLACK_MARKET) and -- 22
     g.p.QueuedItem.Item ~= nil then

    g.run.seededDeath.dealTime = Isaac.GetTime()

    -- Also delete any empty pedestals that we put in the Schoolbag
    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) then
      local collectibles = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 5.100
                                            -1, false, false)
      for _, entity in ipairs(collectibles) do
        if entity.FrameCount == 0 and
          entity.SubType == 0 then

          entity:Remove()
          Isaac.DebugString("Deleted an empty pedestal that we put in the Schoolbag.")
        end
      end
    end
  end

  -- Fix the bug where The Forgotten will not be properly faded
  -- if he switched from The Soul immediately before the debuff occured
  if g.run.fadeForgottenFrame ~= 0 and
     gameFrameCount >= g.run.fadeForgottenFrame then

    g.run.fadeForgottenFrame = 0

    -- Re-fade the player
    playerSprite.Color = Color(1, 1, 1, 0.25, 0, 0, 0)
  end

  -- They took fatal damage and the death animation is playing
  -- (this used to be based on the "Death" and "LostDeath" animation, but this does not work for deaths inside Pitfalls)
  local totalHealth = hearts + soulHearts + boneHearts
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_GUPPYS_COLLAR) and -- 212
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_ONE_UP) and -- 11
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_DEAD_CAT) and -- 81
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_ANKH) and -- 161
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_JUDAS_SHADOW) and -- 311
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_LAZARUS_RAGS) and -- 332
     not g.p:HasTrinket(TrinketType.TRINKET_MISSING_POSTER) then -- 23
     -- (Broken Ankh is already removed from the trinket pool)

    -- Guppy's Collar (and Broken Ankh) are bugged with "player:WillPlayerRevive()" such that
    -- they will randomly report either true or false,
    -- but that value won't correspond to whether or not the player will revive
    -- Thus, always assume that Guppy's Collar will not revive us in order to avoid permadeath
    revive = false
  end
  if g.run.seededDeath.deathFrame == 0 and
     (g.race.rFormat == "seeded" or
      g.race.rFormat == "seeded-mo" or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)")) and
     totalHealth == 0 and
     not revive and
     -- We want to make an exception for Sacrifice Rooms and the Boss Rush
     -- to prevent players from being able to take "free" items
     roomType ~= RoomType.ROOM_SACRIFICE and -- 13
     roomType ~= RoomType.ROOM_BOSSRUSH then -- 17

    -- The "Death" animation is 57 frames long
    -- (when testing, the death screen appears if we wait 57 frames,
    -- but we want it to be a bit faster than that)
    local framesToWait = 46
    local hands = Isaac.FindByType(EntityType.ENTITY_MOMS_HAND, -1, -1, false, false) -- 213
    if #hands > 0 then
      -- If players die getting grabbed by a Mom's Hand, then the game over screen will appear after 27 frames
      -- (instead of 57 frames) for some reason
      framesToWait = 26
    end
    g.run.seededDeath.deathFrame = gameFrameCount + framesToWait
  end

  -- Seeded death (1/3) - The death animation is over
  if g.run.seededDeath.deathFrame ~= 0 and
     gameFrameCount >= g.run.seededDeath.deathFrame then

    g.run.seededDeath.deathFrame = 0

    -- Make sure that we don't revive the player if they recently took a devil deal
    local elapsedTime = Isaac.GetTime() - g.run.seededDeath.dealTime
    if elapsedTime > 5000 then
      g:RevivePlayer()
      g.run.seededDeath.state = SeededDeath.state.CHANGING_ROOMS
      Isaac.DebugString("Seeded death (1/3).")

      -- Drop all trinkets and pocket items
      local pos1 = g.r:FindFreePickupSpawnPosition(g.p.Position, 0, true)
      g.p:DropTrinket(pos1, false)
      local pos2 = g.r:FindFreePickupSpawnPosition(g.p.Position, 0, true)
      g.p:DropPoketItem(0, pos2)
      local pos3 = g.r:FindFreePickupSpawnPosition(g.p.Position, 0, true)
      g.p:DropPoketItem(1, pos3)

      -- If we are The Soul, the manual revival will now work properly
      -- Thus, manually switch to the Forgotten to avoid this
      local character = g.p:GetPlayerType()
      if character == PlayerType.PLAYER_THESOUL then -- 17
        g.run.switchForgotten = true
      end
    end
  end

  -- Check to see if the debuff is over
  if g.run.seededDeath.state == SeededDeath.state.GHOST_FORM then
    local elapsedTime = g.run.seededDeath.time - Isaac.GetTime()
    if elapsedTime <= 0 then
      g.run.seededDeath.state = SeededDeath.state.DISABLED
      g.run.seededDeath.time = 0
      SeededDeath:DebuffOff()
      g.p:AnimateHappy()
      Isaac.DebugString("Seeded death debuff complete.")
    end
  end
end

-- ModCallbacks.MC_POST_RENDER (2)
function SeededDeath:PostRender()
  -- Local variables
  local playerSprite = g.p:GetSprite()

  -- Seeded death (3/3) - The "AppearVanilla animation" is over and the debuff is on
  if g.run.seededDeath.state == SeededDeath.state.FETAL_POSITION then
    -- Keep the player in place during the "AppearVanilla" animation
    g.p.Position = g.run.seededDeath.pos

    if not playerSprite:IsPlaying("AppearVanilla") then
      g.run.seededDeath.state = SeededDeath.state.GHOST_FORM
      Isaac.DebugString("Seeded death (3/3).")
    end
  end
end

-- ModCallbacks.MC_POST_NEW_ROOM (19)
function SeededDeath:PostNewRoom()
  -- Local variables
  local effects = g.p:GetEffects()

  -- Add a temporary Holy Mantle effect for Keeper after a seeded revival
  if g.run.tempHolyMantle then
    effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE) -- 313
    g.p:AddCostume(g.itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_HOLY_MANTLE)) -- 313
  end

  -- Make any Checkpoints not touchable
  if g.run.seededDeath.state > 0 then
    local checkpoints = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 5.100
                                         CollectibleType.COLLECTIBLE_CHECKPOINT, false, false)
    for _, checkpoint in ipairs(checkpoints) do
      checkpoint:ToPickup().Timeout = 10000000
      Isaac.DebugString("Delayed a Checkpoint due to seeded death.")
    end
  end

  -- Seeded death (2/3) - Put the player in the fetal position (the "AppearVanilla" animation)
  if g.run.seededDeath.state ~= SeededDeath.state.CHANGING_ROOMS then
    return
  end

  -- Start the debuff and set the finishing time to be in the future
  SeededDeath:DebuffOn()
  local debuffTimeMilliseconds = SeededDeath.debuffTime * 1000
  --[[
  if g.debug then
    debuffTimeMilliseconds = 5 * 1000
  end
  --]]
  g.run.seededDeath.time = Isaac.GetTime() + debuffTimeMilliseconds

  -- Play the animation where Isaac lies in the fetal position
  g.p:PlayExtraAnimation("AppearVanilla")

  g.run.seededDeath.state = SeededDeath.state.FETAL_POSITION
  g.run.seededDeath.pos = Vector(g.p.Position.X, g.p.Position.Y)
  Isaac.DebugString("Seeded death (2/3).")
end

-- Prevent people from abusing the death mechanic to use a Sacrifice Room
function SeededDeath:PostNewRoomCheckSacrificeRoom()
  local roomType = g.r:GetType()
  local gridSize = g.r:GetGridSize()

  if g.run.seededDeath.state ~= SeededDeath.state.GHOST_FORM or
     roomType ~= RoomType.ROOM_SACRIFICE then -- 13

    return
  end

  g.p:AnimateSad()
  for i = 1, gridSize do
    local gridEntity = g.r:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState()
      if saveState.Type == GridEntityType.GRID_SPIKES then -- 8
        g.r:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
      end

    end
  end
  Isaac.DebugString("Deleted the spikes in a Sacrifice Room (during a seeded death debuff).")
end

function SeededDeath:DebuffOn()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local stage = g.l:GetStage()
  local playerSprite = g.p:GetSprite()
  local character = g.p:GetPlayerType()

  -- Store the current level
  g.run.seededDeath.stage = stage

  -- Set their health to explicitly 1.5 soul hearts
  -- (or custom values for Keeper & The Forgotton)
  g.p:AddMaxHearts(-24, true)
  g.p:AddSoulHearts(-24)
  if character == PlayerType.PLAYER_KEEPER then -- 14
    g.p:AddMaxHearts(2, true) -- One coin container
    g.p:AddHearts(2)
  elseif character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
    g.p:AddMaxHearts(2, true)
    g.p:AddHearts(1)
  elseif character == PlayerType.PLAYER_THESOUL then -- 17
    g.p:AddHearts(1)
  else
    g.p:AddSoulHearts(3)
  end

  -- Store their active item charge for later
  g.run.seededDeath.charge = g.p:GetActiveCharge()

  -- Store their size for later, and then reset it to default
  -- (in case they had items like Magic Mushroom and so forth)
  g.run.seededDeath.spriteScale = g.p.SpriteScale
  g.p.SpriteScale = Vector(1, 1)

  -- Store their golden bomb / key status
  g.run.seededDeath.goldenBomb = g.p:HasGoldenBomb()
  g.run.seededDeath.goldenKey = g.p:HasGoldenKey()

  -- We need to remove every item (and store it for later)
  -- ("player:GetCollectibleNum()" is bugged if you feed it a number higher than the total amount of items and
  -- can cause the game to crash)
  for i = 1, g:GetTotalItemCount() do
    local numItems = g.p:GetCollectibleNum(i)
    if numItems > 0 and
       g.p:HasCollectible(i) then

      -- Checking both "GetCollectibleNum()" and "HasCollectible()" prevents bugs such as Lilith having 1 Incubus
      for j = 1, numItems do
        g.run.seededDeath.items[#g.run.seededDeath.items + 1] = i
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
  g.p:EvaluateItems()

  -- Remove any golden bombs and keys
  g.p:RemoveGoldenBomb()
  g.p:RemoveGoldenKey()

  -- Remove the Dead Eye multiplier, if any
  for i = 1, 100 do
    -- Each time this function is called, it only has a chance of working,
    -- so just call it 100 times to be safe
    g.p:ClearDeadEyeCharge()
  end

  -- Fade the player
  playerSprite.Color = Color(1, 1, 1, 0.25, 0, 0, 0)

  -- The fade will now work if we just switched from The Soul on the last frame,
  -- so mark to redo the fade a few frames from now
  if character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
    g.run.fadeForgottenFrame = gameFrameCount + 6 -- If we wait 5 frames or less, then the fade won't stick
  end
end

function SeededDeath:DebuffOff()
  -- Local variables
  local stage = g.l:GetStage()
  local playerSprite = g.p:GetSprite()
  local character = g.p:GetPlayerType()
  local effects = g.p:GetEffects()

  -- Unfade the character
  playerSprite.Color = g.color

  -- Store the current active item, red hearts, soul/black hearts, bombs, keys, and pocket items
  local subPlayer = g.p:GetSubPlayer()
  local activeItem = g.p:GetActiveItem()
  local activeCharge = g.p:GetActiveCharge()
  local hearts = g.p:GetHearts()
  local maxHearts = g.p:GetMaxHearts()
  local soulHearts = g.p:GetSoulHearts()
  local blackHearts = g.p:GetBlackHearts()
  if character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
    soulHearts = subPlayer:GetSoulHearts()
    blackHearts = subPlayer:GetBlackHearts()
  end
  local boneHearts = g.p:GetBoneHearts()
  local bombs = g.p:GetNumBombs()
  local keys = g.p:GetNumKeys()
  local card1 = g.p:GetCard(0)
  local pill1 = g.p:GetPill(0)

  -- Add all of the items from the array
  for _, itemID in ipairs(g.run.seededDeath.items) do
    -- Make an exception for The Quarter, since it will just give us an additional 25 cents
    if itemID ~= CollectibleType.COLLECTIBLE_QUARTER then -- 74
      g.p:AddCollectible(itemID, 0, false)
    end
  end

  -- Reset the items in the array
  g.run.seededDeath.items = {}

  -- Set the charge to the way it was before the debuff was applied
  g.p:SetActiveCharge(g.run.seededDeath.charge)

  -- Check to see if the active item changed
  -- (meaning that the player picked up a new active item during their ghost state)
  local newActiveItem = g.p:GetActiveItem()
  if activeItem ~= 0 and
     newActiveItem ~= activeItem then

    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) and
       g.run.schoolbag.item == 0 then

      -- There is room in the Schoolbag, so put it in the Schoolbag
      Schoolbag:Put(activeItem, activeCharge)
      Isaac.DebugString("SeededDeath - Put the ghost active inside the Schoolbag.")

    else
      -- There is no room in the Schoolbag, so spawn it on the ground
      local position = g.r:FindFreePickupSpawnPosition(g.p.Position, 1, true)
      local pedestal = g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE,
                                 position, g.zeroVector, nil, activeItem, 0):ToPickup()
      -- (we can use a seed of 0 beacuse it will be replaced on the next frame)
      pedestal.Charge = activeCharge
      pedestal.Touched = true
      Isaac.DebugString("SeededDeath - Put the old active item on the ground since there was no room for it.")
    end
  end

  -- Set their size to the way it was before the debuff was applied
  g.p.SpriteScale = g.run.seededDeath.spriteScale

  -- Set the health to the way it was before the items were added
  g.p:AddMaxHearts(-24, true) -- Remove all hearts
  g.p:AddSoulHearts(-24)
  g.p:AddBoneHearts(-24)
  g.p:AddMaxHearts(maxHearts, true)
  g.p:AddBoneHearts(boneHearts)
  g.p:AddHearts(hearts)
  for i = 1, soulHearts do
    local bitPosition = math.floor((i - 1) / 2)
    local bit = (blackHearts & (1 << bitPosition)) >> bitPosition
    if bit == 0 then -- Soul heart
      g.p:AddSoulHearts(1)
    else -- Black heart
      g.p:AddBlackHearts(1)
    end
  end

  -- If The Soul is active when the debuff ends, the health will not be handled properly,
  -- so manually set everything
  if character == PlayerType.PLAYER_THESOUL then -- 17
    g.p:AddBoneHearts(-24)
    g.p:AddBoneHearts(1)
    g.p:AddHearts(-24)
    g.p:AddHearts(1)
  end

  -- Set the inventory to the way it was before the items were added
  g.p:AddBombs(-99)
  g.p:AddBombs(bombs)
  g.p:AddKeys(-99)
  g.p:AddKeys(keys)
  if g.run.seededDeath.goldenBomb then
    g.run.seededDeath.goldenBomb = false
    if stage == g.run.seededDeath.stage then
      g.p:AddGoldenBomb()
    end
  end
  if g.run.seededDeath.goldenKey then
    g.run.seededDeath.goldenKey = false
    if stage == g.run.seededDeath.stage then
      g.p:AddGoldenKey()
    end
  end

  -- We also have to account for Caffeine Pill,
  -- which is the only item in the game that directly puts a pocket item into your inventory
  if card1 ~= 0 then
    g.p:SetCard(0, card1)
  else
    g.p:SetPill(0, pill1)
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
    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_INCUBUS) then -- 360
      g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_INCUBUS) -- 360
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
    g.p:AddCostume(g.itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_HOLY_MANTLE)) -- 313
  end

  -- Make any Checkpoints touchable again
  local checkpoints = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 5.100
                                       CollectibleType.COLLECTIBLE_CHECKPOINT, false, false)
  for _, checkpoint in ipairs(checkpoints) do
    checkpoint:ToPickup().Timeout = -1
  end
end

return SeededDeath

local RPPedestals = {}

-- Includes
local g         = require("racing_plus/globals")
local Schoolbag = require("racing_plus/schoolbag")
local Speedrun  = require("racing_plus/speedrun")

-- Fix seed "incrementation" from touching active pedestal items and do other various pedestal fixes
function RPPedestals:Replace(pickup)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local stage = g.l:GetStage()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end
  local roomType = g.r:GetType()
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"
  local stageSeed = g.seeds:GetStageSeed(stage)
  local challenge = Isaac.GetChallenge()

  -- Don't do anything if this is an empty pedestal
  if pickup.SubType == 0 then
    return
  end

  -- Check to see if this is a pedestal that was already replaced
  for _, pedestal in ipairs(g.run.replacedPedestals) do
    if pedestal.room == roomIndex and
       pedestal.seed == pickup.InitSeed then

      -- We have already replaced it, so check to see if we need to delete the delay
      if pickup.Wait > 15 then
        -- When we enter a new room, the "wait" variable on all pedestals is set to 18
        -- This is too long, so shorten it
        pickup.Wait = 15
      end
      return
    end
  end

  -- Check to see if this is a pedestal that was player-generated
  local playerGen = false
  if gameFrameCount <= g.run.playerGenPedFrame then
    -- The player just spawned this item a frame ago
    playerGen = true
  else
    -- Check to see if this is a reroll of a player-generated item
    for _, pedestal in ipairs(g.run.replacedPedestals) do
      if pedestal.room == roomIndex and
         Vector(pedestal.X, pedestal.Y):Distance(pickup.Position) <= 15 and
         pedestal.playerGen then

        playerGen = true
        break
      end
    end
  end

  -- We have not replaced this pedestal yet,
  -- so start off by assuming that we should set the new pedestal seed to that of the room
  local newSeed = roomSeed
  if playerGen then
    -- This is a player-spawned pedestal, so if we seed it per room then
    -- it would reroll to something different depending on the room the player generates the pedestal in
    -- Seed these items based on the start seed, and continually increment as we go
    newSeed = g:IncrementRNG(g.run.playerGenPedSeeds[#g.run.playerGenPedSeeds])
    g.run.playerGenPedSeeds[#g.run.playerGenPedSeeds + 1] = newSeed
  end

  if pickup.Touched then
    -- If we touched this item, we need to set it back to the last seed that we had for this position
    for _, pedestal in ipairs(g.run.replacedPedestals) do
      if pedestal.room == roomIndex and
         Vector(pedestal.X, pedestal.Y):Distance(pickup.Position) <= 15 then

        -- Don't break after this because we want it to be equal to the seed of the last item
        newSeed = pedestal.seed

        -- Also reset the position of the pedestal before we replace it
        -- (this is necessary because the player will push the pedestal slightly when they drop the item,
        -- so the replaced pedestal will be slightly off)
        pickup.Position = Vector(pedestal.X, pedestal.Y)
      end
    end

  elseif not playerGen then
    -- This is a new pedestal, so find the new seed that we should set for it,
    -- which will correspond with how many times it has been rolled
    -- (we can't just seed all items with the room seed because
    -- it causes items that are not fully decremented on sight to roll into themselves)
    for _, pedestal in ipairs(g.run.replacedPedestals) do
      if pedestal.room == roomIndex and
         not pedestal.playerGen then

        newSeed = g:IncrementRNG(newSeed)
      end
    end
  end

  -- Check to see if this is an item in a Basement 1 Treasure Room and the doors are supposed to be barred
  local offLimits = false
  if (g.race.rFormat == "seeded" or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") or
      (challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") and
       Speedrun.charNum >= 2) or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)")) and
     stage == 1 and
     roomType == RoomType.ROOM_TREASURE and -- 4
     pickup.SubType ~= CollectibleType.COLLECTIBLE_OFF_LIMITS then -- 235

    offLimits = true
  end

  -- Check to see if this is a natural Krampus pedestal
  -- (we want to remove it because we spawn Krampus items manually to both seed it properly and to speed it up)
  if (pickup.SubType == CollectibleType.COLLECTIBLE_LUMP_OF_COAL or -- 132
      pickup.SubType == CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS) and -- 293
     pickup.Price == 0 then

    if g.run.spawningKrampusItem then
      -- This is a manually spawned Krampus item with a seed of 0,
      -- so proceed with the replacement and change the flag to false
      g.run.spawningKrampusItem = false
    elseif gameFrameCount <= g.run.mysteryGiftFrame then
      Isaac.DebugString("A Lump of Coal from Mystery Gift detected; not deleting.")
    elseif not pickup.Touched then -- We don't want to delete a head that we are swapping for something else
      -- This is a naturally spawned Krampus item
      pickup:Remove()
      Isaac.DebugString("Removed a naturally spawned Krampus item.")
      return
    end
  end

  -- Check to see if this is a natural Key Piece 1 or Key Piece 2
  -- (we want to remove it because we spawn key pieces manually to speed it up)
  if g.run.spawningKeyPiece and
     (pickup.SubType == CollectibleType.COLLECTIBLE_KEY_PIECE_1 or -- 238
      pickup.SubType == CollectibleType.COLLECTIBLE_KEY_PIECE_2) then -- 239

    -- This is a manually spawned key piece with a seed of 0,
    -- so proceed with the replacement and change the flag to false
    g.run.spawningKeyPiece = false
  end

  -- Check to see if this is a special Basement 1 diversity reroll
  -- (these custom placeholder items are removed in all non-diveristy runs)
  local specialReroll = 0
  if stage == 1 and
     roomType == RoomType.ROOM_TREASURE and -- 4
     (g.race.rFormat == "diversity" and
      g.race.status == "in progress") then

    if pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1 then
      specialReroll = CollectibleType.COLLECTIBLE_INCUBUS -- 360
    elseif pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2 then
      specialReroll = CollectibleType.COLLECTIBLE_SACRED_HEART -- 182
    elseif pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3 then
      specialReroll = CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT -- 415
    end

  elseif stage == 1 and
         roomType == RoomType.ROOM_TREASURE and -- 4
         ((g.race.rFormat == "unseeded" and
           g.race.status == "in progress") or
          challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)")) then

    -- Check to see if this is a special Big 4 reroll (50% chance to reroll)
    math.randomseed(stageSeed)
    local big4rerollChance = math.random(1, 2)
    if big4rerollChance == 2 then
      if pickup.SubType == CollectibleType.COLLECTIBLE_MOMS_KNIFE then -- 114
        specialReroll = CollectibleType.COLLECTIBLE_INCUBUS -- 360
      elseif pickup.SubType == CollectibleType.COLLECTIBLE_TECH_X then -- 395
        specialReroll = CollectibleType.COLLECTIBLE_SACRED_HEART -- 182
      elseif pickup.SubType == CollectibleType.COLLECTIBLE_EPIC_FETUS then -- 168
        specialReroll = CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT -- 415
      elseif pickup.SubType == CollectibleType.COLLECTIBLE_IPECAC then -- 149
        specialReroll = CollectibleType.COLLECTIBLE_MUTANT_SPIDER_INNER_EYE
      end
    end

  elseif pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1 or
         pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2 or
         pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3 then

    -- If the player is on a diversity race and gets a Treasure pool item on basement 1,
    -- then there is a chance that they could get a placeholder item
    pickup.SubType = 0
  end

  -- Check to see if this item should go into a Schoolbag
  if Schoolbag:CheckSecondItem(pickup) then
    return
  end

  -- Replace the pedestal
  g.run.replacingPedestal = true
  g.run.usedButterFrame = 0
  -- If we are replacing a pedestal, make sure this is reset to avoid the bug where
  -- it takes two item touches to re-enable the Schoolbag
  local randomItem = false
  local newPedestal
  if offLimits then
    -- Change the item to Off Limits (5.100.235)
    newPedestal = g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pickup.Position,
                            pickup.Velocity, pickup.Parent, CollectibleType.COLLECTIBLE_OFF_LIMITS, newSeed)

    -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
    g.g:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0)
    Isaac.DebugString("Made an Off Limits pedestal using seed: " .. tostring(newSeed))

  elseif specialReroll ~= 0 then
    -- Change the item to the special reroll
    newPedestal = g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pickup.Position,
                            pickup.Velocity, pickup.Parent, specialReroll, newSeed)

    -- Remove the special item from the pools
    g.itemPool:RemoveCollectible(specialReroll)
    if specialReroll == CollectibleType.COLLECTIBLE_MUTANT_SPIDER_INNER_EYE then
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) -- 153
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) -- 2
    end

    -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
    g.g:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0)
    g.run.changeFartColor = true -- Change it to a bright red fart to distinguish that it is a special reroll
    Isaac.DebugString("Item " .. tostring(pickup.SubType) .. " is special, " ..
                      "made a new " .. tostring(specialReroll) .. " pedestal using seed: " .. tostring(newSeed))

  else
    -- Fix the bug where Steven can drop on runs where the player started with Steven
    local subType = pickup.SubType
    if subType == CollectibleType.COLLECTIBLE_STEVEN and -- 50
       g.p:HasCollectible(CollectibleType.COLLECTIBLE_STEVEN) then -- 50

      subType = CollectibleType.COLLECTIBLE_LITTLE_STEVEN -- 100
    end

    -- Make a new copy of this item
    newPedestal = g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pickup.Position,
                            pickup.Velocity, pickup.Parent, subType, newSeed)

    -- We don't need to make a fart noise because the swap will be completely transparent to the user
    -- (the sprites of the two items will obviously be identical)
    -- We don't need to add this item to the ban list because since it already existed, it was properly
    -- decremented from the pools on sight
    Isaac.DebugString("Made a copied " .. tostring(pickup.SubType) ..
                      " pedestal using seed " .. tostring(newSeed) .. " (on frame " .. tostring(gameFrameCount) .. ").")
  end
  newPedestal = newPedestal:ToPickup()

  -- We don't want to replicate the charge if this is a brand new item
  if specialReroll == 0 then
    -- If we don't do this, the item will be fully recharged every time the player swaps it out
    newPedestal.Charge = pickup.Charge
  end

  -- If we don't do this, shop and Devil Room items will become automatically bought
  newPedestal.Price = pickup.Price

  -- We need to keep track of touched items for banned item exception purposes
  newPedestal.Touched = pickup.Touched

  -- If we don't do this, shop items will reroll into consumables and
  -- shop items that are on sale will no longer be on sale
  newPedestal.ShopItemId = pickup.ShopItemId

  -- If we don't do this, you can take both of the pedestals in a double Treasure Room
  newPedestal.TheresOptionsPickup = pickup.TheresOptionsPickup

  -- The pedestal might be from a chest or machine, so we need to copy the overlay frame
  if pickup.Price == 0 then
    local overlayFrame = pickup:GetSprite():GetOverlayFrame()
    newPedestal:GetSprite():SetOverlayFrame("Alternates", overlayFrame)
  end

  -- Remove the pedestal delay for the Checkpoint, since players will always want to immediately pick it up
  if pickup.SubType == CollectibleType.COLLECTIBLE_CHECKPOINT then
    newPedestal.Wait = 0 -- On vanilla, all pedestals get a 20 frame delay
  end

  if pickup.State == 0 then
    -- Normally, collectibles always have state 0
    -- Mark it as state 1 to indicate to other mods that this is a replaced pedestal
    newPedestal.State = 1
  else
    -- Another mod has modified the state of this pedestal; make it persist over to the new pedestal
    newPedestal.State = pickup.State
  end

  -- If we don't do this, then mods that manually update the price of items will fail
  newPedestal.AutoUpdatePrice = pickup.AutoUpdatePrice

  -- Add it to the tracking table so that we don't replace it again
  -- (and don't add random items to the index in case a banned item rolls into another banned item)
  if not randomItem then
    g.run.replacedPedestals[#g.run.replacedPedestals + 1] = {
      room      = roomIndex,
      X         = pickup.Position.X,
      Y         = pickup.Position.Y,
      seed      = newSeed,
      playerGen = playerGen,
    }

    --[[
    local replacedPedestal = g.run.replacedPedestals[#g.run.replacedPedestals]
    Isaac.DebugString("Added to replacedPedestals #" .. tostring(#g.run.replacedPedestals) .. ":")
    Isaac.DebugString("   Room: " .. tostring(replacedPedestal.room))
    Isaac.DebugString("   Position: (" .. tostring(replacedPedestal.X) .. ", " .. tostring(replacedPedestal.Y) .. ")")
    Isaac.DebugString("   Seed: " .. tostring(replacedPedestal.seed))
    Isaac.DebugString("   Price: " .. tostring(newPedestal.Price))
    Isaac.DebugString("   ShopItemId: " .. tostring(newPedestal.ShopItemId))
    --]]
  end

  -- Now that we have created a new pedestal, we can delete the old one
  pickup:Remove()
end

return RPPedestals

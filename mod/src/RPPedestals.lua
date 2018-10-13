local RPPedestals = {}

-- Includes
local RPGlobals   = require("src/rpglobals")
local RPSchoolbag = require("src/rpschoolbag")

-- Fix seed "incrementation" from touching active pedestal items and do other various pedestal fixes
function RPPedestals:Replace(pickup)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local itemPool = game:GetItemPool()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local levelSeed = level:GetDungeonPlacementSeed()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
  local challenge = Isaac.GetChallenge()

  -- Check to see if this is a pedestal that was already replaced
  for i = 1, #RPGlobals.run.replacedPedestals do
    if RPGlobals.run.replacedPedestals[i].room == roomIndex and
       RPGlobals.run.replacedPedestals[i].seed == pickup.InitSeed then

      -- We have already replaced it, so check to see if we need to delete the delay
      if pickup.Wait > 15 then
        -- When we enter a new room, the "wait" variable on all pedestals is set to 18
        -- This is too long, so shorten it
        pickup.Wait = 15
      end
      return
    end
  end

  -- We haven't replaced this pedestal yet,
  -- so start off by assuming that we should set the new pedestal seed to that of the room
  local newSeed = roomSeed
  if RPGlobals.race.rFormat == "seeded" and
     RPGlobals.race.status == "in progress" then

    -- For seeded rooms, we don't want to use the room seed as the base
    -- (since we are manually seeding the room, different racers might have different room seeds)
    if roomType == RoomType.ROOM_BOSSRUSH then -- 17
      newSeed = RPGlobals.RNGCounter.BossRushItem
    elseif roomType == RoomType.ROOM_DEVIL then -- 14
      newSeed = RPGlobals.RNGCounter.DevilRoomItem
    elseif roomType == RoomType.ROOM_ANGEL then -- 15
      newSeed = RPGlobals.RNGCounter.AngelRoomItem
    end
  end

  if pickup.Touched then
    -- If we touched this item, we need to set it back to the last seed that we had for this position
    for i = 1, #RPGlobals.run.replacedPedestals do
      if RPGlobals.run.replacedPedestals[i].room == roomIndex and
         RPGlobals:InsideSquare(RPGlobals.run.replacedPedestals[i], pickup.Position, 15) then

        -- Don't break after this because we want it to be equal to the seed of the last item
        newSeed = RPGlobals.run.replacedPedestals[i].seed

        -- Also reset the position of the pedestal before we replace it
        -- (this is necessary because the player will push the pedestal slightly when they drop the item,
        -- so the replaced pedestal will be slightly off)
        pickup.Position = Vector(RPGlobals.run.replacedPedestals[i].X, RPGlobals.run.replacedPedestals[i].Y)
      end
    end
  else
    -- This is a new pedestal, so find the new seed that we should set for it,
    -- which will correspond with how many times it has been rolled
    -- (we can't just seed all items with the room seed because
    -- it causes items that are not fully decremented on sight to roll into themselves)
    for i = 1, #RPGlobals.run.replacedPedestals do
      if RPGlobals.run.replacedPedestals[i].room == roomIndex then
        newSeed = RPGlobals:IncrementRNG(newSeed)
      end
    end
  end

  -- Check to see if this is a B1 item room on a seeded race
  local offLimits = false
  if (RPGlobals.race.rFormat == "seeded" or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)")) and
     stage == 1 and
     roomType == RoomType.ROOM_TREASURE and -- 4
     pickup.SubType ~= CollectibleType.COLLECTIBLE_OFF_LIMITS then -- 235

    offLimits = true
  end

  -- Check to see if this is a natural Krampus pedestal
  -- (we want to remove it because we spawn Krampus items manually to both seed it properly and to speed it up)
  if pickup.SubType == CollectibleType.COLLECTIBLE_LUMP_OF_COAL or -- 132
     pickup.SubType == CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS then -- 293

    if RPGlobals.run.spawningKrampusItem then
      -- This is a manually spawned Krampus item with a seed of 0,
      -- so proceed with the replacement and change the flag to false
      RPGlobals.run.spawningKrampusItem = false
    elseif gameFrameCount <= RPGlobals.run.mysteryGiftFrame then
      Isaac.DebugString("A Lump of Coal from Mystery Gift detected; not deleting.")
    elseif pickup.Touched == false then -- We don't want to delete a head that we are swapping for something else
      -- This is a naturally spawned Krampus item
      pickup:Remove()
      Isaac.DebugString("Removed a naturally spawned Krampus item.")
      return
    end
  end

  -- Check to see if this is a natural Key Piece 1 or Key Piece 2
  -- (we want to remove it because we spawn key pieces manually to speed it up)
  if pickup.SubType == CollectibleType.COLLECTIBLE_KEY_PIECE_1 or -- 238
     pickup.SubType == CollectibleType.COLLECTIBLE_KEY_PIECE_2 then -- 239

    if RPGlobals.run.spawningKeyPiece then
      -- This is a manually spawned key piece with a seed of 0,
      -- so proceed with the replacement and change the flag to false
      RPGlobals.run.spawningKeyPiece = false
    else
      -- This is a naturally spawned Key Piece
      pickup:Remove()
      Isaac.DebugString("Removed a naturally spawned Key Piece.")
      return
    end
  end

  local specialReroll = 0
  if stage == 1 and
     roomType == RoomType.ROOM_TREASURE and -- 4
     (RPGlobals.race.rFormat == "diversity" and
      RPGlobals.race.status == "in progress") then

    -- Check to see if this is a special Basement 1 diversity reroll
    -- (these custom placeholder items are removed in all non-diveristy runs)
    if pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1 then
      specialReroll = CollectibleType.COLLECTIBLE_INCUBUS -- 360
    elseif pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2 then
      specialReroll = CollectibleType.COLLECTIBLE_SACRED_HEART -- 182
    elseif pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3 then
      specialReroll = CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT -- 415
    end

  elseif stage == 1 and
         roomType == RoomType.ROOM_TREASURE and -- 4
         --(not (RPGlobals.race.ranked and -- This should not apply to ranked unseeded solo
          --     RPGlobals.race.solo and
            --   RPGlobals.race.rFormat == "unseeded")) and
         ((RPGlobals.race.rFormat == "unseeded" and
           RPGlobals.race.status == "in progress" and
           (RPGlobals.race.ranked and RPGlobals.race.solo) == false) or
          challenge == Isaac.GetChallengeIdByName("R+7 (Season 5 Beta)")) then

    -- Check to see if this is a special Basement 1 diversity reroll
    -- (these custom placeholder items are removed in all non-diveristy runs)
    math.randomseed(levelSeed)
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

  -- Check to see if this is a banned item on the "Unseeded (Lite)" ruleset
  local big4Reroll = false
  if stage == 1 and
     roomType == RoomType.ROOM_TREASURE and -- 4
     RPGlobals.race.rFormat == "unseeded-lite" and
     (pickup.SubType == CollectibleType.COLLECTIBLE_MOMS_KNIFE or -- 114
      pickup.SubType == CollectibleType.COLLECTIBLE_IPECAC or -- 149
      pickup.SubType == CollectibleType.COLLECTIBLE_EPIC_FETUS or -- 168
      pickup.SubType == CollectibleType.COLLECTIBLE_TECH_X) then -- 395

    big4Reroll = true
  end

  -- Check to see if this item should go into a Schoolbag
  local putInSchoolbag = RPSchoolbag:CheckSecondItem(pickup)
  if putInSchoolbag then
    return
  end

  -- Replace the pedestal
  RPGlobals.run.usedButterFrame = 0
  -- If we are replacing a pedestal, make sure this is reset to avoid the bug where
  -- it takes two item touches to re-enable the Schoolbag
  local randomItem = false
  local newPedestal
  if offLimits then
    -- Change the item to Off Limits (5.100.235)
    newPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pickup.Position,
                             pickup.Velocity, pickup.Parent, CollectibleType.COLLECTIBLE_OFF_LIMITS, newSeed)

    -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
    game:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0)
    Isaac.DebugString("Made an Off Limits pedestal using seed: " .. tostring(newSeed))

  elseif specialReroll ~= 0 then
    -- Change the item to the special reroll
    newPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pickup.Position,
                             pickup.Velocity, pickup.Parent, specialReroll, newSeed)

    -- Remove the special item from the pools
    itemPool:RemoveCollectible(specialReroll)
    if specialReroll == CollectibleType.COLLECTIBLE_MUTANT_SPIDER_INNER_EYE then
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) -- 153
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) -- 2
    end

    -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
    game:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0)
    RPGlobals.run.changeFartColor = true -- Change it to a bright red fart to distinguish that it is a special reroll
    Isaac.DebugString("Item " .. tostring(pickup.SubType) .. " is special, " ..
                      "made a new " .. tostring(specialReroll) .. " pedestal using seed: " .. tostring(newSeed))

  elseif big4Reroll then
    -- Make a new random item pedestal
    -- (the new random item generated will automatically be decremented from item pools properly on sight)
    newPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pickup.Position,
                             pickup.Velocity, pickup.Parent, 0, newSeed)
    randomItem = true -- We need to set this so that banned items don't reroll into other banned items

    -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
    game:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0)
    Isaac.DebugString("Rerolled a big 4 item: " .. tostring(pickup.SubType))

  else
    -- Code in the MC_POST_PICKUP_SELECTION callback will prevent The Polaroid or The Negative from spawning,
    -- so let it know that we are explicitly spawning it using Lua code
    if pickup.SubType == CollectibleType.COLLECTIBLE_POLAROID or -- 327
       pickup.SubType == CollectibleType.COLLECTIBLE_NEGATIVE then -- 328

      RPGlobals.run.spawningPhoto = true
    end

    -- Make a new copy of this item
    newPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pickup.Position,
                             pickup.Velocity, pickup.Parent, pickup.SubType, newSeed)

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

  -- Also reduce the vanilla delay that is imposed upon newly spawned collectible items
  -- (this is commented out because people were accidentally taking items)
  --newPedestal.Wait = 15 -- On vanilla, all pedestals get a 20 frame delay

  -- We never need to worry about players accidentally picking up Checkpoint
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
  if randomItem == false then
    RPGlobals.run.replacedPedestals[#RPGlobals.run.replacedPedestals + 1] = {
      room = roomIndex,
      X    = pickup.Position.X,
      Y    = pickup.Position.Y,
      seed = newSeed,
    }

    --[[
    local replacedPedestal = RPGlobals.run.replacedPedestals[#RPGlobals.run.replacedPedestals]
    Isaac.DebugString("Added to replacedPedestals #" .. tostring(#RPGlobals.run.replacedPedestals) .. ":")
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

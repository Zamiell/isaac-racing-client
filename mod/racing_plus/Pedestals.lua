local Pedestals = {}

-- Includes
local g = require("racing_plus/globals")
local Schoolbag = require("racing_plus/schoolbag")
local PostNewRoom = require("racing_plus/postnewroom")
local Season8 = require("racing_plus/season8")

-- Racing+ replaces all item pedestals with custom seeds
-- This is in order to fix seed "incrementation" from touching active pedestal items over and over
-- Additionally, we also do some other various pedestal fixes
function Pedestals:Replace(pickup)
  -- Local variables
  local roomIndex = g:GetRoomIndex()
  local gameFrameCount = g.g:GetFrameCount()
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()
  local stageSeed = g.seeds:GetStageSeed(stage)
  local challenge = Isaac.GetChallenge()

  -- Don't do anything if this pedestal is not freshly spawned
  if pickup.FrameCount ~= 1 then
    return
  end

  -- Don't do anything if this is an empty pedestal
  if pickup.SubType == 0 then
    return
  end

  -- If the player uses a Void on a D6, then the pedestal replacement code will cause the pedestal
  -- to get duplicated
  -- (instead of getting consumed/deleted)
  -- Thus, explicitly check for this
  if (
    gameFrameCount == g.run.usedD6Frame + 1
    and gameFrameCount == g.run.usedVoidFrame + 1
  ) then

    -- Account for the Butter trinket
    if (
      g.p:HasTrinket(TrinketType.TRINKET_BUTTER) -- 122
      and pickup.SubType == CollectibleType.COLLECTIBLE_VOID -- 477
    ) then
      Isaac.DebugString(
        "Void dropped from a Butter! trinket. Explicitly not deleting this pedestal. "
        .. "(It will get replaced like any other normal pedestal.)"
      )
      -- (this pedestal will not be rolled, even if the player has consumed a D6)
    else
      Isaac.DebugString(
        "Not replacing pedestal with item " .. tostring(pickup.SubType)
        .. " due to Void + D6 usage. (It should be naturally consumed/deleted on the next frame.)"
      )
      return
    end
  end

  -- Check to see if this is a pedestal that was already replaced
  for _, pedestal in ipairs(g.run.replacedPedestals) do
    -- We can't check to see if the X and Y are exactly equivalent since players can push pedestals
    -- around a little bit
    local pedestalPosition = Vector(pedestal.X, pedestal.Y)
    if (
      pedestal.room == roomIndex
      and pedestalPosition:Distance(pickup.Position) <= 15 -- A litte less than half a square
      and pedestal.seed == pickup.InitSeed
    ) then
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
      if (
        pedestal.room == roomIndex
        and Vector(pedestal.X, pedestal.Y):Distance(pickup.Position) <= 15
        and pedestal.playerGen
      ) then
        playerGen = true
        break
      end
    end
  end

  -- We need to replace this item, so generate a consistent seed
  local newSeed = Pedestals:GetSeed(pickup, playerGen)

  -- Check to see if this is an item in a Basement 1 Treasure Room and the doors are supposed to be
  -- barred
  local offLimits = false
  if (
    PostNewRoom:CheckBanB1TreasureRoom()
    and roomType == RoomType.ROOM_TREASURE -- 4
    and pickup.SubType ~= CollectibleType.COLLECTIBLE_OFF_LIMITS -- 235
  ) then
    offLimits = true
  end

  -- Check for special rerolls
  local specialReroll = 0
  if (
    stage == 1
    and roomType == RoomType.ROOM_TREASURE -- 4
    and (
      (g.race.rFormat == "diversity" and g.race.status == "in progress")
      or challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)")
    )
  ) then
    -- This is a special Basement 1 diversity reroll
    -- (these custom placeholder items are removed in all non-diveristy runs)
    if pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1 then
      specialReroll = CollectibleType.COLLECTIBLE_INCUBUS -- 360
    elseif pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2 then
      specialReroll = CollectibleType.COLLECTIBLE_SACRED_HEART -- 182
    elseif pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3 then
      specialReroll = CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT -- 415
    end
  elseif (
    stage == 1
    and roomType == RoomType.ROOM_TREASURE -- 4
    and (
      (g.race.rFormat == "unseeded" and g.race.status == "in progress")
      or challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)")
    )
  ) then
    -- This is a special Big 4 reroll for unseeded races (50% chance to reroll)
    math.randomseed(stageSeed)
    local big4rerollChance = math.random(1, 2)
    if big4rerollChance == 2 then
      if pickup.SubType == CollectibleType.COLLECTIBLE_MOMS_KNIFE then -- 114
        specialReroll = CollectibleType.COLLECTIBLE_MUTANT_SPIDER_INNER_EYE
      elseif pickup.SubType == CollectibleType.COLLECTIBLE_TECH_X then -- 395
        specialReroll = CollectibleType.COLLECTIBLE_SACRED_HEART -- 182
      elseif pickup.SubType == CollectibleType.COLLECTIBLE_EPIC_FETUS then -- 168
        specialReroll = CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT -- 415
      elseif pickup.SubType == CollectibleType.COLLECTIBLE_IPECAC then -- 149
        specialReroll = CollectibleType.COLLECTIBLE_INCUBUS -- 360
      end
    end
  elseif (
    pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1
    or pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2
    or pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3
  ) then
    -- If the player is on a diversity race and gets a Treasure Room item on basement 1,
    -- then there is a chance that they could get a placeholder item
    pickup.SubType = 0
  end

  -- Account for the Butter Bean "surprise" mechanic
  -- (this is 10% according to Kilburn)
  if pickup.SubType == CollectibleType.COLLECTIBLE_BUTTER_BEAN then -- 294
    g.RNGCounter.ButterBean = g:IncrementRNG(g.RNGCounter.ButterBean)
    math.randomseed(g.RNGCounter.ButterBean)
    local surpriseChance = math.random(1, 10)
    if surpriseChance == 1 then
      pickup.SubType = CollectibleType.COLLECTIBLE_WAIT_WHAT -- 484
      pickup.Charge = g:GetItemMaxCharges(CollectibleType.COLLECTIBLE_WAIT_WHAT) -- 484
    end
  end

  -- Check to see if this item should go into a Schoolbag
  if Schoolbag:CheckSecondItem(pickup) then
    return
  end

  -- In season 8, prevent "set drops" from Lust, Gish, and so forth
  -- (if they have already been touched)
  pickup.SubType = Season8:Pedestals(pickup)

  -- Replace the pedestal
  local newPedestal
  if offLimits then
    -- Change the item to Off Limits
    newPedestal = g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_COLLECTIBLE, -- 100
      pickup.Position,
      pickup.Velocity,
      pickup.Parent,
      CollectibleType.COLLECTIBLE_OFF_LIMITS,
      newSeed
    )

    -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
    g.g:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0)
    Isaac.DebugString("Made an Off Limits pedestal using seed: " .. tostring(newSeed))
  elseif specialReroll ~= 0 then
    -- Change the item to the special reroll
    newPedestal = g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_COLLECTIBLE, -- 100
      pickup.Position,
      pickup.Velocity,
      pickup.Parent,
      specialReroll,
      newSeed
    )

    -- Remove the special item from the pools
    g.itemPool:RemoveCollectible(specialReroll)
    if specialReroll == CollectibleType.COLLECTIBLE_MUTANT_SPIDER_INNER_EYE then
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) -- 153
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) -- 2
    end

    -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
    g.g:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0)
    Isaac.DebugString(
      "Item " .. tostring(pickup.SubType) .. " is special, "
      .. "made a new " .. tostring(specialReroll) .. " pedestal using seed: " .. tostring(newSeed)
    )
  else
    -- Fix the bug where Steven can drop on runs where the player started with Steven
    -- (the case of Little Steven is automatically handled by the vanilla game,
    -- e.g. the boss will always drop Steven if the player has Little Steven)
    local subType = pickup.SubType
    if (
      subType == CollectibleType.COLLECTIBLE_STEVEN -- 50
      and g.p:HasCollectible(CollectibleType.COLLECTIBLE_STEVEN) -- 50
    ) then
      subType = CollectibleType.COLLECTIBLE_LITTLE_STEVEN -- 100
    end

    -- By default, put the new pedestal in the exact same place as the one we are replacing
    local position = pickup.Position

    -- Check to see if we already know about a pedestal that is near to where this one spawned
    -- If so, adjust the position of the pedestal to the old one
    -- This prevents the bug where players can "push" pedestals by swapping an active item
    for _, pedestal in ipairs(g.run.replacedPedestals) do
      local oldPedestalPosition = Vector(pedestal.X, pedestal.Y)
      if (
        pedestal.room == roomIndex
        and pickup.Position:Distance(oldPedestalPosition) <= 20
      ) then
        position = oldPedestalPosition
        Isaac.DebugString(
          "Pushed pedestal detected - using the old position of: "
          .. tostring(oldPedestalPosition.X) .. ", " .. tostring(oldPedestalPosition.Y) .. ")"
        )
        break
      end
    end

    -- Make a new copy of this item
    newPedestal = g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_COLLECTIBLE, -- 100
      position,
      pickup.Velocity,
      pickup.Parent,
      subType,
      newSeed
    )

    -- We don't need to make a fart noise because the swap will be completely transparent to the
    -- player (the sprites of the two items will obviously be identical)
    -- We don't need to add this item to the ban list because since it already existed,
    -- it was properly decremented from the pools on sight
    local itemName
    if subType == 0 then
      itemName = "[random]"
    else
      itemName = g.itemConfig:GetCollectible(subType).Name
    end
    Isaac.DebugString(
      "Made a copied pedestal of \"" .. itemName .. "\" "
      .. "at (" .. tostring(position.X) .. ", " .. tostring(position.Y) .. ") "
      .. "using seed " .. tostring(newSeed) .. " on frame " .. tostring(gameFrameCount) .. "."
    )
  end
  newPedestal = newPedestal:ToPickup()

  -- We don't want to replicate the charge if this is a brand new item
  if pickup.SubType ~= 0 then
    -- We need to replicate the charge of dropped active items,
    -- or else they will be fully charged every time
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
    if overlayFrame ~= 0 then
      newPedestal:GetSprite():SetOverlayFrame("Alternates", overlayFrame)

      -- Also mark that we have "touched" a chest, which should start a Challenge Room or Boss Rush
      g.run.touchedPickup = true -- This variable is tracked per room
      Isaac.DebugString(
        "Touched pickup (from a chest opening into a pedestal item): " .. tostring(pickup.Type)
        .. "." .. tostring(pickup.Variant) .. "." .. tostring(pickup.SubType)
      )
    end
  end

  -- Remove the pedestal delay for the Checkpoint,
  -- since players will always want to immediately pick it up
  if (
    pickup.SubType == CollectibleType.COLLECTIBLE_CHECKPOINT
    and stage ~= 8
  ) then
    -- On vanilla, all pedestals get a 20 frame delay
    -- Don't apply this to Checkpoints that spawn after It Lives!,
    -- since the player may not want to take them
    newPedestal.Wait = 0
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

  -- We probably need to add this item to the tracking table,
  -- but first check to see if it is already there
  -- This is necessary to prevent the bug where touching an item will cause the next seed to get
  -- "skipped"
  local alreadyInTable = false
  for _, pedestal in ipairs(g.run.replacedPedestals) do
    local pedestalPosition = Vector(pedestal.X, pedestal.Y)
    if (
      pedestal.room == roomIndex
      and pedestalPosition:Distance(pickup.Position) <= 15 -- A litte less than half a square
      and pedestal.seed == newSeed
      and pedestal.playerGen == playerGen
    ) then
      alreadyInTable = true
      break
    end
  end

  -- Add it to the tracking table so that we don't replace it again
  -- (we don't want to add subtype 0 items to the index in case a banned item rolls into another
  -- banned item)
  if not alreadyInTable then
    g.run.replacedPedestals[#g.run.replacedPedestals + 1] = {
      room = roomIndex,
      X = pickup.Position.X,
      Y = pickup.Position.Y,
      seed = newSeed,
      playerGen = playerGen,
    }
  end

  --[[
  local replacedPedestal = g.run.replacedPedestals[#g.run.replacedPedestals]
  Isaac.DebugString("Added to replacedPedestals #" .. tostring(#g.run.replacedPedestals) .. ":")
  Isaac.DebugString("   Room: " .. tostring(replacedPedestal.room))
  Isaac.DebugString(
    "   Position: (" .. tostring(replacedPedestal.X) .. ", " .. tostring(replacedPedestal.Y) .. ")"
  )
  Isaac.DebugString("   Seed: " .. tostring(replacedPedestal.seed))
  Isaac.DebugString("   Price: " .. tostring(newPedestal.Price))
  Isaac.DebugString("   ShopItemId: " .. tostring(newPedestal.ShopItemId))
  --]]

  -- Now that we have created a new pedestal, we can delete the old one
  pickup:Remove()
end

function Pedestals:GetSeed(pickup, playerGen)
  -- Local variables
  local roomIndex = g:GetRoomIndex()
  local roomSeed = g.r:GetSpawnSeed()

  -- Check to see if this is an item we already touched
  if pickup.Touched then
    -- If we touched this item,
    -- we need to set it back to the last seed that we had for this position
    local newSeed = 0
    for _, pedestal in ipairs(g.run.replacedPedestals) do
      local pedestalPosition = Vector(pedestal.X, pedestal.Y)
      if (
        pedestal.room == roomIndex
        and pedestalPosition:Distance(pickup.Position) <= 15 -- A litte less than half a square
      ) then
        -- Don't break after this because we want it to be equal to the seed of the last item
        newSeed = pedestal.seed
      end
    end

    -- The Butter trinket can cause new touched pedestals to spawn that we have not seen previously
    -- If this is the case, we continue into the below code block and use the room seed as a base
    if newSeed ~= 0 then
      return newSeed
    end
  end

  if playerGen then
    -- This is a player-spawned pedestal, so if we seed it per room then it would reroll to
    -- something different depending on the room the player generates the pedestal in
    -- Seed these items based on the start seed, and continually increment as we go
    local newSeed = g:IncrementRNG(g.run.playerGenPedSeeds[#g.run.playerGenPedSeeds])
    g.run.playerGenPedSeeds[#g.run.playerGenPedSeeds + 1] = newSeed
    return newSeed
  end

  -- This is an ordinary item spawn,
  -- so start off by assuming that we should set the new pedestal seed to that of the room
  -- We can't just seed all items with the room seed because
  -- it causes items that are not fully decremented on sight to roll into themselves
  local newSeed = roomSeed

  -- Increment the seed for each time the item has been rolled
  for _, pedestal in ipairs(g.run.replacedPedestals) do
    if (
      pedestal.room == roomIndex
      and not pedestal.playerGen
    ) then
      newSeed = g:IncrementRNG(newSeed)
    end
  end
  return newSeed
end

return Pedestals

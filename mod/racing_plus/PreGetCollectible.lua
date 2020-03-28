local PreGetCollectible = {}

-- Includes
local g = require("racing_plus/globals")

-- This callback is called when the game needs to get a new random item from an item pool
-- It is undocumented, but you can return an integer from this callback in order to change the returned item subtype
-- It is not called for "set" drops (like Mr. Boom from Wrath) and manually spawned items (like the Checkpoint)

-- ModCallbacks.MC_PRE_GET_COLLECTIBLE (62)
function PreGetCollectible:Main(poolType, decrease, seed)
  -- Isaac.DebugString("MC_PRE_GET_COLLECTIBLE - " .. tostring(poolType))

  if g.run.gettingCollectible then
    return
  end

  return PreGetCollectible:SeededRace(poolType, decrease, seed)
end

function PreGetCollectible:SeededRace(poolType, decrease, seed)
  -- Manually generate random items for specific item pools in seeded races
  if g.race.rFormat ~= "seeded" or
     g.race.status ~= "in progress" or
     (poolType ~= ItemPoolType.POOL_DEVIL and -- 3
      poolType ~= ItemPoolType.POOL_ANGEL and -- 4
      poolType ~= ItemPoolType.POOL_DEMON_BEGGAR) then -- 11

    return
  end

  -- We need to account for the NO! trinket;
  -- if the player has it, we need to temporarily remove it,
  -- otherwise the random items selected will not be consistent
  local hasTrinket = g.p:HasTrinket(TrinketType.TRINKET_NO) -- 88
  if hasTrinket then
    g.p:TryRemoveTrinket(TrinketType.TRINKET_NO) -- 88
  end

  for i = 1, 100 do -- Only attempt to find a valid item for 100 iterations in case something goes wrong
    local subType
    g.run.gettingCollectible = true
    if poolType == ItemPoolType.POOL_DEVIL then -- 3
      g.RNGCounter.DevilRoomItem = g:IncrementRNG(g.RNGCounter.DevilRoomItem)
      subType = g.itemPool:GetCollectible(poolType, true, g.RNGCounter.DevilRoomItem)
    elseif poolType == ItemPoolType.POOL_ANGEL then -- 4
      g.RNGCounter.AngelRoomItem = g:IncrementRNG(g.RNGCounter.AngelRoomItem)
      subType = g.itemPool:GetCollectible(poolType, true, g.RNGCounter.AngelRoomItem)
    elseif poolType == ItemPoolType.POOL_DEMON_BEGGAR then -- 11
      g.RNGCounter.DevilRoomBeggar = g:IncrementRNG(g.RNGCounter.DevilRoomBeggar)
      subType = g.itemPool:GetCollectible(poolType, true, g.RNGCounter.DevilRoomBeggar)
    end
    g.run.gettingCollectible = false

    -- Simply return the new subtype if we do not have the NO! trinket
    if not hasTrinket then
      return subType
    end

    -- Otherwise, check to see if this is an active item
    local item = g.itemConfig:GetCollectible(subType)
    if item.Type ~= ItemType.ITEM_ACTIVE then -- 3
      -- It is not an active item
      -- Give the NO! trinket back and return the new subtype
      g.p:AddTrinket(TrinketType.TRINKET_NO) -- 88
      return subType
    end

    -- It is an active item, so let the RNG increment and generate another random item
    Isaac.DebugString("Skipping over item " .. tostring(subType) .. " since we have the NO! trinket.")
  end
end

return PreGetCollectible

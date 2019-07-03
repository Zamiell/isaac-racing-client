local PreGetCollectible = {}

-- Includes
local g = require("racing_plus/globals")

-- This callback is called when the game needs to get a new random item from an item pool
-- It is undocumented, but you can return an integer from this callback in order to change the returned item pool type
-- It is not called for "set" drops (like Mr. Boom from Wrath) and manually spawned items (like the Checkpoint)

-- ModCallbacks.MC_PRE_GET_COLLECTIBLE (62)
function PreGetCollectible:Main(poolType, decrease, seed)
  if g.run.gettingCollectible or
     g.race.rFormat ~= "seeded" or
     g.race.status ~= "in progress" then

    return
  end

  if poolType == ItemPoolType.POOL_DEVIL then -- 3
    g.run.gettingCollectible = true
    g.RNGCounter.DevilRoomItem = g:IncrementRNG(g.RNGCounter.DevilRoomItem)
    local subType = g.itemPool:GetCollectible(poolType, true, g.RNGCounter.DevilRoomItem)
    g.run.gettingCollectible = false
    return subType
  elseif poolType == ItemPoolType.POOL_ANGEL then -- 4
    g.run.gettingCollectible = true
    g.RNGCounter.AngelRoomItem = g:IncrementRNG(g.RNGCounter.AngelRoomItem)
    local subType = g.itemPool:GetCollectible(poolType, true, g.RNGCounter.AngelRoomItem)
    g.run.gettingCollectible = false
    return subType
  elseif poolType == ItemPoolType.POOL_DEMON_BEGGAR then -- 11
    g.run.gettingCollectible = true
    g.RNGCounter.DevilRoomBeggar = g:IncrementRNG(g.RNGCounter.DevilRoomBeggar)
    local subType = g.itemPool:GetCollectible(poolType, true, g.RNGCounter.DevilRoomBeggar)
    g.run.gettingCollectible = false
    return subType
  end
end

return PreGetCollectible

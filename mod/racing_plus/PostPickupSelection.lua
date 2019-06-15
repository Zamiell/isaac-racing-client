local PostPickupSelection = {}

-- Includes
local g = require("racing_plus/globals")

-- ModCallbacks.MC_POST_PICKUP_SELECTION (37)
-- (you cannot provide a SubType as the third argument to this callback)
function PostPickupSelection:Main(pickup, variant, subType)
  --[[
  Isaac.DebugString("MC_POST_PICKUP_SELECTION - " ..
                    tostring(EntityType.ENTITY_PICKUP) .. "." .. tostring(variant) .. "." .. tostring(subType))
  --]]

  -- We don't care about non-collectible items
  if variant ~= PickupVariant.PICKUP_COLLECTIBLE then -- 100
    return
  end

  if subType == CollectibleType.COLLECTIBLE_POLAROID or -- 327
     subType == CollectibleType.COLLECTIBLE_NEGATIVE then -- 328

    return PostPickupSelection:ManualPhotos(variant, subType)
  end
end

function PostPickupSelection:ManualPhotos(variant, subType)
  if not g.run.photosSpawning then
    return
  end

  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()

  -- We want to delete the photos that are manually spawned by the game after defeating Mom
  -- Returning an array table here will convert the pickup to those values
  -- However, returning {0, 0} results in a random pickup being spawned
  -- (it will only show up if you reload the room)
  -- And returning {100, 0} will crash the game
  -- So we just make a custom invisible entity (with no anm2 file) and set the pickup to that
  -- We will spawn The Polaroid and The Negative manually in the MC_POST_NPC_DEATH callback
  Isaac.DebugString("Preventing a vanilla Polaroid / Negative from spawning on frame: " .. tostring(gameFrameCount))
  return { PickupVariant.INVISIBLE, 0 } -- Invisible Pickup, a custom entity
end

return PostPickupSelection

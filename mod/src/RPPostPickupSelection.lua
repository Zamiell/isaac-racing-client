local RPPostPickupSelection = {}

-- Includes
local RPGlobals  = require("src/rpglobals")

-- ModCallbacks.MC_POST_PICKUP_SELECTION (37)
function RPPostPickupSelection:Main(pickup, variant, subType)
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

    return RPPostPickupSelection:ManualPhotos(variant, subType)
  end
end

function RPPostPickupSelection:ManualPhotos(variant, subType)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local room = game:GetRoom()
  local roomFrameCount = room:GetFrameCount()

  -- We don't care if we are entering a new room (or re-entering an old room)
  -- (this callback will fire every time you go into a room with a collectible item,
  -- even if you have visited the room before)
  if roomFrameCount == -1 then
    return
  end

  -- We don't want to mess with pedestals that we explicitly spawned with Lua in the "RPPostEntityKill:NPC45()" function
  if RPGlobals.run.spawningPhoto then
    RPGlobals.run.spawningPhoto = false
    Isaac.DebugString("Reset the \"spawningPhoto\" variable on frame: " .. tostring(gameFrameCount))
    return
  end

  -- We only want to replace The Polaroid and The Negative
  -- Returning an array table here will convert the pickup to those values
  -- We just want to remove the pickup, but returning {0, 0} results in a random pickup being spawned
  -- (it will only show up if you reload the room)
  -- And returning {100, 0} will crash the game
  -- So we just make a custom invisible entity (with no anm2 file) and set the pickup to that
  -- We will spawn The Polaroid and The Negative manually in the MC_POST_NPC_DEATH callback
  Isaac.DebugString("Preventing a vanilla Polaroid / Negative from spawning on frame: " .. tostring(gameFrameCount))
  return {500, 0} -- Invisible Pickup (5.500), a custom entity
end

return RPPostPickupSelection

local RPPostPickupSelection = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")

-- ModCallbacks.MC_POST_PICKUP_SELECTION (37)
function RPPostPickupSelection:Main(pickup, variant, subType)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomFrameCount = room:GetFrameCount()

  -- We don't care if we are entering a new room (or re-entering an old room)
  -- (this callback will fire every time you go into a room with a collectible item,
  -- even if you have visited the room before)
  if roomFrameCount == -1 then
    return
  end

  -- We don't care about non-collectible items
  if variant ~= PickupVariant.PICKUP_COLLECTIBLE then -- 100
    return nil
  end

  --[[
  Isaac.DebugString("MC_POST_PICKUP_SELECTION - " ..
                    tostring(EntityType.ENTITY_PICKUP) .. "." .. tostring(variant) .. "." .. tostring(subType))
  --]]

  -- We don't want to mess with pedestals that we explicitly spawned with Lua in the "RPPostEntityKill:NPC45()" function
  if RPGlobals.run.spawningPhoto then
    RPGlobals.run.spawningPhoto = false
    Isaac.DebugString("Reset the \"spawningPhoto\" variable.")
    return nil
  end

  -- We only want to replace The Polaroid and The Negative
  -- Returning an array table here will convert the pickup to those values
  -- We just want to remove the pickup, but returning {0, 0} results in a random pickup being spawned
  -- (it will only show up if you reload the room)
  -- And returning {100, 0} will crash the game
  -- So we just make a custom invisible entity (with no anm2 file) and set the pickup to that
  -- We will spawn The Polaroid and The Negative manually in the MC_POST_NPC_DEATH callback
  if subType == CollectibleType.COLLECTIBLE_POLAROID then -- 327
    Isaac.DebugString("Preventing The Polaroid from spawning.")
    return {500, 0} -- Invisible Pickup (5.500), a custom entity
  elseif subType == CollectibleType.COLLECTIBLE_NEGATIVE then -- 328
    Isaac.DebugString("Preventing The Negative from spawning.")
    return {500, 0} -- Invisible Pickup (5.500), a custom entity
  end
end

return RPPostPickupSelection

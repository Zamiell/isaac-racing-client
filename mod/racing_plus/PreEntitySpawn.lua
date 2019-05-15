local PreEntitySpawn = {}

-- Includes
local g = require("racing_plus/globals")

-- ModCallbacks.MC_PRE_ENTITY_SPAWN (24)
function PreEntitySpawn:Main(type, variant, subType, position, velocity, spawner, seed)
  -- Local variables
  local roomType = g.r:GetType()

  -- Replace Cod Worms with Para-Bites
  if type == EntityType.ENTITY_COD_WORM then -- 221
    return {EntityType.ENTITY_PARA_BITE, 0, 0, seed} -- 58
  end

  -- Delete hearts in Devil Rooms that spawned from fires
  if type == EntityType.ENTITY_PICKUP and -- 5
     variant == PickupVariant.PICKUP_HEART and -- 10
     roomType == RoomType.ROOM_DEVIL and -- 14
     spawner ~= nil and
     spawner.Type == EntityType.ENTITY_FIREPLACE then -- 33

     Isaac.DebugString("Deleting a heart from a fire in a Devil Room.")
     -- If we return an entity type of 0, the game will crash
     -- Instead, return an effect with a variant of 0, which will just be a non-interacting invisible thing
     return {EntityType.ENTITY_EFFECT, 0, 0, 0} -- 1000
  end

  -- Remove Donation Machines
  -- Racing+ always enables the BLCK CNDL Easter Egg
  -- Nomrally, when playing on this Easter Egg, all Donation Machines are removed
  -- However, because of the save file check on the first run,
  -- it is possible for Donation Machines to spawn, so we have to explicitly check for them
  if type == EntityType.ENTITY_SLOT and -- 6
     variant == 8 then -- Donation Machine (6.8)

    -- If we return an entity type of 0, the game will crash
    -- Instead, return an effect with a variant of 0, which will just be a non-interacting invisible thing
    return {EntityType.ENTITY_EFFECT, 0, 0, 0} -- 1000
  end

  -- Change enemy red creep to green
  if type == EntityType.ENTITY_EFFECT and -- 1000
     variant == EffectVariant.CREEP_RED then -- 22

    return {EntityType.ENTITY_EFFECT, EffectVariant.CREEP_GREEN, subType, seed} -- 1000.23
  end

  -- Change player green creep to red
  if type == EntityType.ENTITY_EFFECT and -- 1000
     variant == EffectVariant.PLAYER_CREEP_GREEN then -- 53

    return {EntityType.ENTITY_EFFECT, EffectVariant. PLAYER_CREEP_RED, subType, seed} -- 1000.46
  end
end

return PreEntitySpawn

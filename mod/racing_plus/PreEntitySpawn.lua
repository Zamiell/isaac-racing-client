local PreEntitySpawn = {}

-- Note that:
-- 1) For this callback, you cannot specify an entity type as a second parameter
--    (e.g. "RacingPlus:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, PreEntitySpawn.Pickup, EntityType.ENTITY_PICKUP)")
-- 2) If we want to prevent entities from spawning, we cannot return an entity type of 0, since the game will crash
--    Instead, in most cases we can return an effect with a variant of 0
--    which is a non-interacting invisible thing
-- 3) Sometimes if you return something other than the type (e.g. replacing a pickup with an effect),
--    the game will crash, so you need to replace a pickup with a blank pickup (as opposed to a blank effect)

-- Includes
local g = require("racing_plus/globals")

-- ModCallbacks.MC_PRE_ENTITY_SPAWN (24)
function PreEntitySpawn:Main(entityType, variant, subType, position, velocity, spawner, seed)
  local preEntityFunction = PreEntitySpawn.functions[entityType]
  if preEntityFunction ~= nil then
    return preEntityFunction(variant, subType, position, spawner, seed)
  end
end

-- EntityType.ENTITY_PICKUP (5)
function PreEntitySpawn.Pickup(variant, subType, position, spawner, seed)
  local preEntityPickupFunction = PreEntitySpawn.pickupFunctions[variant]
  if preEntityPickupFunction ~= nil then
    return preEntityPickupFunction(subType, position, spawner, seed)
  end
end

-- PickupVariant.PICKUP_HEART (10)
function PreEntitySpawn.Heart(subType, position, spawner, seed)
  -- Delete hearts in Devil Rooms that spawned from fires
  if g.r:GetType() == RoomType.ROOM_DEVIL and -- 14
     spawner ~= nil and
     spawner.Type == EntityType.ENTITY_FIREPLACE then -- 33

     Isaac.DebugString("Preventing a heart from spawning from a fire in a Devil Room.")
     return {EntityType.ENTITY_PICKUP, PickupVariant.INVISIBLE_PICKUP, 0, 0} -- Invisible Pickup, a custom entity
  end
end

-- PickupVariant.PICKUP_COLLECTIBLE (100)
function PreEntitySpawn.Collectible(subType, position, spawner, seed)
  -- Local variables
  local stage = g.l:GetStage()
  local roomIndexUnsafe = g.l:GetCurrentRoomIndex()
  local challenge = Isaac.GetChallenge()

  -- Prevent the vanilla Polaroid and Negative from spawning
  -- (Racing+ spawns those manually to speed up the Mom fight)
  if g.run.photosSpawning and
     (subType == CollectibleType.COLLECTIBLE_POLAROID or -- 327
      subType == CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328

    local debugString = "Preventing a vanilla "
    if subType == CollectibleType.COLLECTIBLE_POLAROID then
      debugString = debugString .. "Polaroid"
    elseif subType == CollectibleType.COLLECTIBLE_NEGATIVE then
      debugString = debugString .. "Negative"
    end
    debugString = debugString .. " from spawning."
    Isaac.DebugString(debugString)
    return {EntityType.ENTITY_PICKUP, PickupVariant.INVISIBLE_PICKUP, 0, 0} -- Invisible Pickup, a custom entity
  end

  -- In season 7, prevent the boss item from spawning in The Void after defeating Ultra Greed
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") and
     subType ~= CollectibleType.COLLECTIBLE_CHECKPOINT and
     stage == 12 and
     roomIndexUnsafe == g.run.customBossRoomIndex then

    Isaac.DebugString("Prevented a boss item from spawning after Ultra Greed.")
    return {EntityType.ENTITY_PICKUP, PickupVariant.INVISIBLE_PICKUP, 0, 0} -- Invisible Pickup, a custom entity
  end
end

PreEntitySpawn.pickupFunctions = {
  [PickupVariant.PICKUP_HEART] = PreEntitySpawn.Heart, -- 10
  [PickupVariant.PICKUP_COLLECTIBLE] = PreEntitySpawn.Collectible, -- 100
}

-- EntityType.ENTITY_SLOT (6)
function PreEntitySpawn.Slot(variant, subType, position, spawner, seed)
  -- Remove Donation Machines
  -- Racing+ always enables the BLCK CNDL Easter Egg
  -- Nomrally, when playing on this Easter Egg, all Donation Machines are removed
  -- However, because of the save file check on the first run,
  -- it is possible for Donation Machines to spawn, so we have to explicitly check for them
  if variant == 8 then -- Donation Machine (6.8)
    Isaac.DebugString("Prevented a Donation Machine from spawning.")
    return {EntityType.ENTITY_EFFECT, 0, 0, 0} -- 1000
  end
end

-- EntityType.ENTITY_COD_WORM (221)
function PreEntitySpawn.CodWorm(variant, subType, position, spawner, seed)
  -- Replace Cod Worms with Para-Bites
  return {EntityType.ENTITY_PARA_BITE, 0, 0, seed} -- 58
end

-- EntityType.ENTITY_EFFECT (1000)
function PreEntitySpawn.Effect(variant, subType, position, spawner, seed)
  local preEntityFunction = PreEntitySpawn.effectFunctions[variant]
  if preEntityFunction ~= nil then
    return preEntityFunction(variant, subType, position, spawner, seed)
  end
end

PreEntitySpawn.functions = {
  [EntityType.ENTITY_PICKUP] = PreEntitySpawn.Pickup, -- 5
  [EntityType.ENTITY_SLOT] = PreEntitySpawn.Slot, -- 6
  [EntityType.ENTITY_COD_WORM] = PreEntitySpawn.CodWorm, -- 221
  [EntityType.ENTITY_EFFECT] = PreEntitySpawn.Effect, -- 1000
}

-- EffectVariant.CRACK_THE_SKY (19)
function PreEntitySpawn.CrackTheSky(variant, subType, position, spawner, seed)
  -- Custom Crack the Sky effect
  if g.run.spawningLight then
    return
  end

  if spawner.Type ~= EntityType.ENTITY_WAR and -- 65
     spawner.Type ~= EntityType.ENTITY_ISAAC then -- 102

    return
  end
  local npc = spawner:ToNPC()
  local isaacSpawn = spawner.Type == EntityType.ENTITY_ISAAC -- 102
  if isaacSpawn and
     npc.State == 9 then -- The "wave" light beam attack

    -- Only change the beams of light in the second phase
    return
  end

  -- Spawn effects randomly in a circle on or around the player
  local maxDist = 150
  if isaacSpawn then
    maxDist = 100
  end

  local newPosition
  while true do
    newPosition = (RandomVector() * math.random(0, maxDist)) + g.p.Position
    newPosition = g.r:GetClampedPosition(newPosition, 10)

    local redoPos = false

    -- Try to avoid respawning this effect where another one already spawned
    for _, posData in pairs(g.run.lightPositions) do
      if posData and g.r:GetFrameCount() - posData.Frame <= 60 and
         newPosition:Distance(posData.Position) <= 20 then

        redoPos = true
        break
      end
    end

    -- Try to avoid respawning this effect on top of who spawned it
    if newPosition:Distance(spawner.Position) <= 20 then
      redoPos = true
    end

    if not redoPos then
      break
    end
  end

  -- Spawn an extra light effect (so that Isaac spawns 4 lights instead of 2, which makes things more interesting)
  if isaacSpawn and not g.run.spawningExtraLight then
    g.run.spawningExtraLight = true
    local newSeed = g:IncrementRNG(seed)
    g.g:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, -- 1000.19
              newPosition, g.zeroVector, spawner, subType, newSeed)
    g.run.spawningExtraLight = false
  end

  g.run.lightPositions[#g.run.lightPositions + 1] = {
    Frame = g.r:GetFrameCount(),
    Position = newPosition,
  }

  newPosition = g.r:GetClampedPosition(newPosition, 10)

  local effect = g.g:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY_BASE, -- 1000
                           newPosition, g.zeroVector, spawner, subType, seed)
  local data, sprite = effect:GetData(), effect:GetSprite()
  effect:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
  effect.RenderZOffset = -10000
  sprite:Play("DelayedAppear", true)

  data.CrackSkySpawnPosition = newPosition
  data.CrackSkySpawnSpawner = spawner

  return {EntityType.ENTITY_EFFECT, 0, 0, 0}
end

-- EffectVariant.CREEP_RED (22)
function PreEntitySpawn.CreepRed(variant, subType, position, spawner, seed)
  -- Change enemy red creep to green
  return {EntityType.ENTITY_EFFECT, EffectVariant.CREEP_GREEN, subType, seed} -- 1000.23
end

-- EffectVariant.PLAYER_CREEP_GREEN (53)
function PreEntitySpawn.PlayerCreepGreen(variant, subType, position, spawner, seed)
  -- Ignore creep generated from Lil Spewer
  if spawner ~= nil and
     spawner.Type == EntityType.ENTITY_FAMILIAR and -- 3
     spawner.Variant == FamiliarVariant.LIL_SPEWER then -- 125

    return
  end

  -- Change player green creep to blue
  return {EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL, subType, seed} -- 1000.54
end

PreEntitySpawn.effectFunctions = {
  [EffectVariant.CRACK_THE_SKY] = PreEntitySpawn.CrackTheSky, -- 19
  [EffectVariant.CREEP_RED] = PreEntitySpawn.CreepRed, -- 22
  [EffectVariant.PLAYER_CREEP_GREEN] = PreEntitySpawn.PlayerCreepGreen, -- 53
}

return PreEntitySpawn

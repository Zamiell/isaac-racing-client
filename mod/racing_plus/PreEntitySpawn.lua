local PreEntitySpawn = {}

--[[

Note that:

1) For this callback, you cannot specify an entity type as a second parameter
   e.g. RacingPlus:AddCallback(
          ModCallbacks.MC_PRE_ENTITY_SPAWN, -- 24
          PreEntitySpawn.Pickup,
          EntityType.ENTITY_PICKUP -- 5
        )

2) If we want to prevent entities from spawning, we cannot return an entity type of 0,
   since the game will crash
   Instead, in most cases we can return an effect with a variant of 0,
   which is a non-interacting invisible thing

3) Sometimes if you return something other than the type (e.g. replacing a pickup with an effect),
   the game will crash, so you need to replace a pickup with a blank pickup
   (as opposed to a blank effect)

--]]

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
  if (
    g.r:GetType() == RoomType.ROOM_DEVIL -- 14
    and spawner ~= nil
    and spawner.Type == EntityType.ENTITY_FIREPLACE -- 33
  ) then
    Isaac.DebugString("Preventing a heart from spawning from a fire in a Devil Room.")
    return {EntityType.ENTITY_PICKUP, PickupVariant.INVISIBLE_PICKUP, 0, 0}
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
  if (
    g.run.photosSpawning
    and (
      subType == CollectibleType.COLLECTIBLE_POLAROID -- 327
      or subType == CollectibleType.COLLECTIBLE_NEGATIVE -- 328
    )
  ) then
    local debugString = "Preventing a vanilla "
    if subType == CollectibleType.COLLECTIBLE_POLAROID then
      debugString = debugString .. "Polaroid"
    elseif subType == CollectibleType.COLLECTIBLE_NEGATIVE then
      debugString = debugString .. "Negative"
    end
    debugString = debugString .. " from spawning."
    Isaac.DebugString(debugString)
    return {EntityType.ENTITY_PICKUP, PickupVariant.INVISIBLE_PICKUP, 0, 0}
  end

  -- In season 7, prevent the boss item from spawning in The Void after defeating Ultra Greed
  if (
    challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)")
    and subType ~= CollectibleType.COLLECTIBLE_CHECKPOINT
    and stage == 12
    and roomIndexUnsafe == g.run.customBossRoomIndex
  ) then
    Isaac.DebugString("Prevented a boss item from spawning after Ultra Greed.")
    return {EntityType.ENTITY_PICKUP, PickupVariant.INVISIBLE_PICKUP, 0, 0}
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
  -- Remove all unnecessary effects to decrease lag
  for _, lowFXVariant in ipairs(PreEntitySpawn.lowFXVariants) do
    if lowFXVariant == variant then
      return {EntityType.ENTITY_EFFECT, EffectVariant.INVISIBLE_EFFECT, 0, 0}
    end
  end

  -- We only remove blood explosions on specific laggy bosses
  if (
    g.run.preventBloodExplosion
    and (
      variant == EffectVariant.BLOOD_EXPLOSION -- 2
      or variant == EffectVariant.BLOOD_PARTICLE -- 5
    )
  ) then
    return {EntityType.ENTITY_EFFECT, EffectVariant.INVISIBLE_EFFECT, 0, 0}
  end

  local preEntityFunction = PreEntitySpawn.effectFunctions[variant]
  if preEntityFunction ~= nil then
    return preEntityFunction(subType, position, spawner, seed)
  end
end

-- EffectVariant.CRACK_THE_SKY (19)
function PreEntitySpawn.CrackTheSky(subType, position, spawner, seed)
  -- Custom Crack the Sky effect
  if g.run.spawningLight then
    return
  end

  if (
    spawner.Type ~= EntityType.ENTITY_WAR -- 65
    and spawner.Type ~= EntityType.ENTITY_ISAAC -- 102
  ) then
    return
  end
  local npc = spawner:ToNPC()
  local isaacSpawn = spawner.Type == EntityType.ENTITY_ISAAC -- 102
  if (
    isaacSpawn
    and npc.State == 9 -- The "wave" light beam attack
  ) then
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
      if (
        posData
        and g.r:GetFrameCount() - posData.Frame <= 60
        and newPosition:Distance(posData.Position) <= 20
      ) then
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

  -- Spawn an extra light effect
  -- (so that Isaac spawns 4 lights instead of 2, which makes things more interesting)
  if isaacSpawn and not g.run.spawningExtraLight then
    g.run.spawningExtraLight = true
    local newSeed = g:IncrementRNG(seed)
    g.g:Spawn(
      EntityType.ENTITY_EFFECT, -- 1000
      EffectVariant.CRACK_THE_SKY, -- 19
      newPosition,
      g.zeroVector,
      spawner,
      subType,
      newSeed
    )
    g.run.spawningExtraLight = false
  end

  g.run.lightPositions[#g.run.lightPositions + 1] = {
    Frame = g.r:GetFrameCount(),
    Position = newPosition,
  }

  newPosition = g.r:GetClampedPosition(newPosition, 10)

  local effect = g.g:Spawn(
    EntityType.ENTITY_EFFECT, -- 1000
    EffectVariant.CRACK_THE_SKY_BASE,
    newPosition,
    g.zeroVector,
    spawner,
    subType,
    seed
  )
  local data, sprite = effect:GetData(), effect:GetSprite()
  effect:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
  effect.RenderZOffset = -10000
  sprite:Play("DelayedAppear", true)

  data.CrackSkySpawnPosition = newPosition
  data.CrackSkySpawnSpawner = spawner

  return {EntityType.ENTITY_EFFECT, 0, 0, 0}
end

-- EffectVariant.CREEP_RED (22)
function PreEntitySpawn.CreepRed(subType, position, spawner, seed)
  -- Change enemy red creep to green
  return {EntityType.ENTITY_EFFECT, EffectVariant.CREEP_GREEN, subType, seed} -- 1000.23
end

-- EffectVariant.HOT_BOMB_FIRE (51)
function PreEntitySpawn.HotBombFire(subType, position, spawner, seed)
  if (
    subType ~= 0 -- Enemy fires are never subtype 0
    and spawner.Type == EntityType.ENTITY_TEAR -- 2
  ) then
    -- Fix the bug where Fire Mind fires from Fire Mind tears from Angelic Prism will damage the
    -- player
    return {EntityType.ENTITY_EFFECT, EffectVariant.HOT_BOMB_FIRE, 0, seed}
  end
end

-- EffectVariant.PLAYER_CREEP_GREEN (53)
function PreEntitySpawn.PlayerCreepGreen(subType, position, spawner, seed)
  -- Ignore creep generated from Lil Spewer
  if (
    spawner ~= nil
    and spawner.Type == EntityType.ENTITY_FAMILIAR -- 3
    and spawner.Variant == FamiliarVariant.LIL_SPEWER -- 125
  ) then
    return
  end

  -- Change player green creep to blue
  return {
    EntityType.ENTITY_EFFECT, -- 1000
    EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL, -- 54
    subType,
    seed
  }
end

PreEntitySpawn.effectFunctions = {
  [EffectVariant.CRACK_THE_SKY] = PreEntitySpawn.CrackTheSky, -- 19
  [EffectVariant.CREEP_RED] = PreEntitySpawn.CreepRed, -- 22
  [EffectVariant.HOT_BOMB_FIRE] = PreEntitySpawn.HotBombFire, -- 51
  [EffectVariant.PLAYER_CREEP_GREEN] = PreEntitySpawn.PlayerCreepGreen, -- 53
}

PreEntitySpawn.functions = {
  [EntityType.ENTITY_PICKUP] = PreEntitySpawn.Pickup, -- 5
  [EntityType.ENTITY_SLOT] = PreEntitySpawn.Slot, -- 6
  [EntityType.ENTITY_COD_WORM] = PreEntitySpawn.CodWorm, -- 221
  [EntityType.ENTITY_EFFECT] = PreEntitySpawn.Effect, -- 1000
}

-- This list is taken from the LowFX mod:
-- https://steamcommunity.com/sharedfiles/filedetails/?id=1188552584
-- Only the important ones are uncommented
PreEntitySpawn.lowFXVariants = {
  EffectVariant.BLOOD_SPLAT, -- 7
  EffectVariant.BOMB_CRATER, -- 18
  EffectVariant.TINY_BUG, -- 21
  EffectVariant.TINY_FLY, -- 33
  EffectVariant.TOOTH_PARTICLE, -- 35
  EffectVariant.WATER_DROPLET, -- 41
  EffectVariant.WORM, -- 63
  EffectVariant.BEETLE, -- 64
  EffectVariant.WISP, -- 65
  EffectVariant.EMBER_PARTICLE, -- 66
  EffectVariant.WALL_BUG, -- 68
  EffectVariant.BUTTERFLY, -- 69
  EffectVariant.BLOOD_DROP, -- 70
  EffectVariant.DIAMOND_PARTICLE, --- 85
  EffectVariant.NAIL_PARTICLE, -- 86
  EffectVariant.FALLING_EMBER, -- 87
  EffectVariant.DARK_BALL_SMOKE_PARTICLE, -- 88
  EffectVariant.ULTRA_GREED_FOOTPRINT, -- 89
  EffectVariant.GOLD_PARTICLE, -- 95
  EffectVariant.COIN_PARTICLE, -- 98
  EffectVariant.WATER_SPLASH, -- 99
  EffectVariant.HUSH_ASHES, -- 100

  --[[
  EffectVariant.BLOOD_EXPLOSION, -- 2 (normal enemy death effect)
  EffectVariant.FLY_EXPLOSION, -- 3 (fly death effects)
  EffectVariant.ROCK_PARTICLE, -- 4 (when rocks are destroyed with a bomb)
  EffectVariant.BLOOD_PARTICLE, -- 5 (when Bonies are killed, bones fly outwards)
  EffectVariant.BULLET_POOF, -- 11
  EffectVariant.TEAR_POOF_A, -- 12
  EffectVariant.TEAR_POOF_B, -- 13
  EffectVariant.POOF01, -- 15
  EffectVariant.POOF02, -- 16
  EffectVariant.POOF04, -- 17
  EffectVariant.WOOD_PARTICLE, -- 27
  EffectVariant.BLOOD_GUSH, -- 42
  EffectVariant.POOP_EXPLOSION, -- 43
  EffectVariant.LASER_IMPACT, -- 50
  EffectVariant.POOP_PARTICLE, -- 58
  EffectVariant.DUST_CLOUD, -- 59
  EffectVariant.BAR_PARTICLE, -- 75
  EffectVariant.LARGE_BLOOD_EXPLOSION, -- 77
  EffectVariant.TEAR_POOF_SMALL, -- 79
  EffectVariant.TEAR_POOF_VERYSMALL, -- 80
  EffectVariant.IMPACT, -- 97
  EffectVariant.BULLET_POOF_HUSH, -- 102
  EffectVariant.ULTRA_GREED_BLING, -- 103
  --]]
}

return PreEntitySpawn

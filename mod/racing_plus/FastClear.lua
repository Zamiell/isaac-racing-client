local FastClear = {}

-- Includes
local g        = require("racing_plus/globals")
local Speedrun = require("racing_plus/speedrun")

--
-- Variables
--

-- These are reset in the "FastClear:InitRun()" function
FastClear.familiars = {}
FastClear.roomClearAwardRNG = 0

-- These are reset in the "FastClear:InitRun()" function and
-- the "FastClear:PostNPCInit()" function (upon entering a new room)
FastClear.aliveEnemies = {}
FastClear.aliveEnemiesCount = 0
FastClear.aliveBossesCount = 0
FastClear.roomInitializing = false -- Set to true in the MC_POST_NEW_ROOM callback
FastClear.delayFrame = 0

-- These are reset in the "PostNewRoom:NewRoom()" function
FastClear.buttonsAllPushed = false

--
-- Fast clear functions
--

-- Called from the PostGameStarted callback
function FastClear:InitRun()
  -- Local variables
  local stage = g.l:GetStage()
  local startSeed = g.seeds:GetStartSeed()
  local stageSeed = g.seeds:GetStageSeed(stage)

  local familiars = {
    "BombBag",
    "SackOfPennies",
    "LittleCHAD",
    "TheRelic",
    "JuicySack",
    "MysterySack",
    "Bumbo",
    "LilChest",
    "RuneBag",
    "SpiderMod",
    "AcidBaby",
    "SackOfSacks",
  }
  FastClear.familiars = {}
  for _, familiar in ipairs(familiars) do
    FastClear.familiars[familiar] = {
      seed         = stageSeed,
      roomsCleared = 0,
      incremented  = false,
    }
  end
  FastClear.roomClearAwardRNG = startSeed

  FastClear.aliveEnemies = {}
  FastClear.aliveEnemiesCount = 0
  FastClear.aliveBossesCount = 0
  FastClear.buttonsAllPushed = false
  FastClear.roomInitializing = false
  FastClear.delayFrame = 0
end

-- ModCallbacks.MC_NPC_UPDATE (0)
function FastClear:NPCUpdate(npc)
  -- Friendly enemies (from Delirious or Friendly Ball) will be added to the aliveEnemies table because
  -- there are no flags set yet in the MC_POST_NPC_INIT callback
  -- Thus, we have to wait until they are initialized and then remove them from the table
  if npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then -- 1 << 29
    -- Remove it from the list if it is on it
    FastClear:CheckDeadNPC(npc)
    return
  end

  -- We can't rely on the MC_POST_NPC_INIT callback because it is not fired for certain NPCs
  -- (like when a Gusher emerges from killing a Gaper)
  FastClear:PostNPCInit(npc)
end

-- ModCallbacks.MC_NPC_UPDATE (0)
-- EntityType.ENTITY_RAGLING (246)
function FastClear:NPC246(npc)
  -- Rag Man Raglings don't actually die (they turn into patches on the ground),
  -- so we need to manually keep track of when this happens
  if npc.Variant == 1 and -- 246.1
     npc.State == NpcState.STATE_UNIQUE_DEATH then -- 16
     -- They go to state 16 when they are patches on the ground

    FastClear:CheckDeadNPC(npc)
  end
end

-- ModCallbacks.MC_NPC_UPDATE (0)
-- EntityType.ENTITY_STONEY (302)
function FastClear:NPC302(npc)
  -- Stoneys have a chance to morph from EntityType.ENTITY_FATTY (208),
  -- so they will get added to the aliveEnemies table before the room is loaded
  -- To correct for this, we constantly check to see if Stoneys are on the aliveEnemies table
  local index = GetPtrHash(npc)
  if FastClear.aliveEnemies[index] ~= nil then
    FastClear.aliveEnemies[index] = nil
    FastClear.aliveEnemiesCount = FastClear.aliveEnemiesCount - 1
    Isaac.DebugString("Removed a Fatty that morphed into Stoney from the aliveEnemies table.")
  end
end

-- ModCallbacks.MC_POST_NPC_INIT (27)
function FastClear:PostNPCInit(npc)
  -- Local variables
  local roomFrameCount = g.r:GetFrameCount()
  local isBoss = npc:IsBoss()

  --[[
  local index = GetPtrHash(npc)
  Isaac.DebugString("MC_POST_NPC_INIT - " ..
                    tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "." ..
                    tostring(npc.SubType) .. "." .. tostring(npc.State) .. ", " ..
                    "index " .. tostring(index) .. ", " ..
                    "frame " .. tostring(gameFrameCount))
  --]]

  -- Don't do anything if we are already tracking this NPC
  -- (we can't use npc.Index for this because it is always 0 in the MC_POST_NPC_INIT callback)
  local index = GetPtrHash(npc)
  if FastClear.aliveEnemies[index] ~= nil then
    return
  end

  -- We don't care if this is a non-battle NPC
  if not npc.CanShutDoors then
    return
  end

  -- We don't care if the NPC is already dead
  -- (this is needed because we can enter this function from the MC_NPC_UPDATE callback)
  if npc:IsDead() then
    return
  end

  -- Rag Man Raglings don't actually die (they turn into patches on the ground),
  -- so they will get past the above check
  if npc.Type == EntityType.ENTITY_RAGLING and npc.Variant == 1 and -- 246.1
     npc.State == NpcState.STATE_UNIQUE_DEATH then -- 16
     -- They go to state 16 when they are patches on the ground

    return
  end

  -- We don't care if this is a specific child NPC attached to some other NPC
  if FastClear:AttachedNPC(npc) then
    return
  end

  -- If we are entering a new room, flush all of the stuff in the old room
  -- (we can't use the MC_POST_NEW_ROOM callback to handle this since that callback fires after this one)
  -- (roomFrameCount will be at -1 during the initialization phase)
  if roomFrameCount == -1 and
     not FastClear.roomInitializing then

    FastClear.aliveEnemies = {}
    FastClear.aliveEnemiesCount = 0
    FastClear.aliveBossesCount = 0
    FastClear.roomInitializing = true -- This will get set back to false in the MC_POST_NEW_ROOM callback
    FastClear.delayFrame = 0
    Isaac.DebugString("Reset fast-clear variables.")
  end

  -- Keep track of the enemies in the room that are alive
  FastClear.aliveEnemies[index] = isBoss
  FastClear.aliveEnemiesCount = FastClear.aliveEnemiesCount + 1
  if isBoss then
    FastClear.aliveBossesCount = FastClear.aliveBossesCount + 1
  end

  --[[
  Isaac.DebugString("Added NPC " ..
                    tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "." ..
                    tostring(npc.SubType) .. "." .. tostring(npc.State) .. ", " ..
                    "index " .. tostring(index) .. ", " ..
                    "frame " .. tostring(gameFrameCount) .. ", " ..
                    "total " .. tostring(FastClear.aliveEnemiesCount))
  --]]
end

function FastClear:AttachedNPC(npc)
  -- These are NPCs that have "CanShutDoors" equal to true naturally by the game,
  -- but shouldn't actually keep the doors closed
  if (npc.Type == EntityType.ENTITY_CHARGER and npc.Variant == 0 and npc.Subtype == 1) or -- My Shadow (23.0.1)
     -- These are the black worms generated by My Shadow; they are similar to charmed enemies,
     -- but do not actually have the "charmed" flag set, so we don't want to add them to the "aliveEnemies" table
     (npc.Type == EntityType.ENTITY_VIS and npc.Variant == 22) or -- Cubber Projectile (39.22)
     -- (needed because Fistuloids spawn them on death)
     (npc.Type == EntityType.ENTITY_DEATH and npc.Variant == 10) or -- Death Scythe (66.10)
     (npc.Type == EntityType.ENTITY_PEEP and npc.Variant == 10) or -- Peep Eye (68.10)
     (npc.Type == EntityType.ENTITY_PEEP and npc.Variant == 11) or -- Bloat Eye (68.11)
     (npc.Type == EntityType.ENTITY_BEGOTTEN and npc.Variant == 10) or -- Begotten Chain (251.10)
     (npc.Type == EntityType.ENTITY_MAMA_GURDY and npc.Variant == 1) or -- Mama Gurdy Left Hand (266.1)
     (npc.Type == EntityType.ENTITY_MAMA_GURDY and npc.Variant == 2) or -- Mama Gurdy Right Hand (266.2)
     (npc.Type == EntityType.ENTITY_BIG_HORN and npc.Variant == 1) or -- Small Hole (411.1)
     (npc.Type == EntityType.ENTITY_BIG_HORN and npc.Variant == 2) then -- Big Hole (411.2)

    return true
  else
    return false
  end
end

-- ModCallbacks.MC_POST_ENTITY_REMOVE (67)
function FastClear:PostEntityRemove(entity)
  -- We only care about NPCs dying
  local npc = entity:ToNPC()
  if npc == nil then
    return
  end

  -- Local variables
  --[[
  local gameFrameCount = g.g:GetFrameCount()
  local index = GetPtrHash(npc)

  Isaac.DebugString("MC_POST_ENTITY_REMOVE - " ..
                    tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "." ..
                    tostring(npc.SubType) .. "." .. tostring(npc.State) .. ", " ..
                    "index " .. tostring(index) .. ", " ..
                    "frame " .. tostring(gameFrameCount))
  --]]

  -- We can't rely on the MC_POST_ENTITY_KILL callback because it is not fired for certain NPCs
  -- (like when Daddy Long Legs does a stomp attack or a Portal despawns)
  FastClear:CheckDeadNPC(npc)
end

-- ModCallbacks.MC_POST_ENTITY_KILL (68)
-- (we can't use the MC_POST_NPC_DEATH callback because that will only fire once the death animation is finished)
function FastClear:PostEntityKill(entity)
  -- We only care about NPCs dying
  local npc = entity:ToNPC()
  if npc == nil then
    return
  end

  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local index = GetPtrHash(npc)

  Isaac.DebugString("MC_POST_ENTITY_KILL - " ..
                    tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "." ..
                    tostring(npc.SubType) .. "." .. tostring(npc.State) .. ", " ..
                    "index " .. tostring(index) .. ", " ..
                    "frame " .. tostring(gameFrameCount))

  -- We can't rely on the MC_POST_ENTITY_REMOVE callback because it is only fired once the death animation is complete
  FastClear:CheckDeadNPC(npc)
end

function FastClear:CheckDeadNPC(npc)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()

  -- We only care about entities that are in the aliveEnemies table
  local index = GetPtrHash(npc)
  if FastClear.aliveEnemies[index] == nil then
    return
  end

  -- We don't care if this is a Dark Red champion flesh pile
  if npc:GetChampionColorIdx() == 12 and -- Dark Red champion (collapses into a flesh pile upon death)
     npc:GetSprite():GetFilename() ~= "gfx/024.000_Globin.anm2" then
     -- The filename will be set to this if it is in the flesh pile state

    -- This callback will be triggered when the champion changes into the flesh pile
    -- We don't want to open the doors yet until the flesh pile is actually killed
    return
  end

  -- Keep track of the enemies in the room that are alive
  local isBoss = FastClear.aliveEnemies[index]
  FastClear.aliveEnemies[index] = nil
  FastClear.aliveEnemiesCount = FastClear.aliveEnemiesCount - 1
  if isBoss then
    FastClear.aliveBossesCount = FastClear.aliveBossesCount - 1
  end

  --[[
  Isaac.DebugString("Removed NPC " ..
                    tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "." ..
                    tostring(npc.SubType) .. "." .. tostring(npc.State) .. ", " ..
                    "index " .. tostring(index) .. ", " ..
                    "frame " .. tostring(gameFrameCount) .. ", " ..
                    "total " .. tostring(FastClear.aliveEnemiesCount))
  --]]

  -- We want to delay a frame before opening the doors to give time for splitting enemies to spawn their children
  FastClear.delayFrame = gameFrameCount + 1

  -- We check every frame to see if the "aliveEnemiesCount" variable is set to 0 in MC_POST_UPDATE callback
end

-- ModCallbacks.MC_POST_UPDATE (1)
-- Check on every frame to see if we need to open the doors
function FastClear:PostUpdate()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local roomClear = g.r:IsClear()

  -- Disable this in Greed Mode
  if g.g.Difficulty >= Difficulty.DIFFICULTY_GREED then -- 2
    return
  end

  -- Disable this if we are on the "PAC1F1CM" seed / Easter Egg
  if g.seeds:HasSeedEffect(SeedEffect.SEED_PACIFIST) then -- 25
    return
  end

  -- If a frame has passed since an enemy died, reset the delay counter
  if FastClear.delayFrame ~= 0 and
     gameFrameCount >= FastClear.delayFrame then

    FastClear.delayFrame = 0
  end

  -- Check on every frame to see if we need to open the doors
  if FastClear.aliveEnemiesCount == 0 and
     FastClear.delayFrame == 0 and
     not roomClear and
     FastClear:CheckAllPressurePlatesPushed() and
     gameFrameCount > 1 then -- If a Mushroom is replaced, the room can be clear of enemies on the first frame

    FastClear:ClearRoom()
  end
end

function FastClear:CheckAllPressurePlatesPushed()
  -- If we are in a puzzle room, check to see if all of the plates have been pressed
  if not g.r:HasTriggerPressurePlates() or
     FastClear.buttonsAllPushed then

    return true
  end

  -- Check all the grid entities in the room
  local num = g.r:GetGridSize()
  for i = 1, num do
    local gridEntity = g.r:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState();
      if saveState.Type == GridEntityType.GRID_PRESSURE_PLATE and -- 20
         saveState.State ~= 3 then

        return false
      end
    end
  end

  FastClear.buttonsAllPushed = true
  return true
end

-- This emulates what happens when you normally clear a room
function FastClear:ClearRoom()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end
  local roomType = g.r:GetType()
  local customRun = g.seeds:IsCustomRun()
  local challenge = Isaac.GetChallenge()

  -- Set the room clear to true (so that it gets marked off on the minimap)
  g.r:SetClear(true)
  g.run.fastCleared = true -- Keep track that the room was cleared artificially
  Isaac.DebugString("Initiated a fast-clear on frame: " .. tostring(gameFrameCount))

  -- Open the doors
  for i = 0, 7 do
    local door = g.r:GetDoor(i)
    if door ~= nil then
      local openDoor = true
      if g.race.rFormat == "seeded" and
         door:IsRoomType(RoomType.ROOM_TREASURE) and -- 4
         roomType ~= RoomType.ROOM_TREASURE then -- 4

        openDoor = false
      end
      if openDoor then
        door:Open()
      end
    end
  end

  -- Manually kill Death's Heads, Flesh Death's Heads, and any type of creep
  -- (by default, they will only die after the death animations are completed)
  for _, entity in ipairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_DEATHS_HEAD and entity.Variant == 0 then -- 212.0
      -- Activate its death state
      entity:ToNPC().State = 18
    elseif entity.Type == EntityType.ENTITY_FLESH_DEATHS_HEAD then -- 286.0
      -- Activating the death state won't make the tears explode out of it, so just kill it and spawn another one to die
      entity.Visible = false
      entity:Kill()
      local newHead = g.g:Spawn(entity.Type, entity.Variant, entity.Position, entity.Velocity,
                                entity.Parent, entity.SubType, entity.InitSeed)
      newHead:ToNPC().State = 18
    elseif entity.Type == EntityType.ENTITY_EFFECT then -- 1000
      if entity.Variant >= 22 and entity.Variant <= 26 then
        -- EffectVariant.CREEP_RED (22)
        -- EffectVariant.CREEP_GREEN (23)
        -- EffectVariant.CREEP_YELLOW (24)
        -- EffectVariant.CREEP_WHITE (25)
        -- EffectVariant.CREEP_BLACK (26)
        entity:Kill()

      elseif entity.Type == EffectVariant.CREEP_BROWN or -- 56
             entity.Type == EffectVariant.CREEP_SLIPPERY_BROWN then -- 94

        entity:Kill()
      end
    end
  end

  -- Check to see if it is a boss room
  if roomType == RoomType.ROOM_BOSS then
    -- Try and spawn a Devil Room or Angel Room
    -- (this takes into account their Devil/Angel percentage and so forth)
    if g.r:TrySpawnDevilRoomDoor(true) then -- The argument is "Animate"
      g.run.lastDDLevel = stage
    end

    -- Try to spawn the Boss Rush door
    if stage == 6 then
      g.r:TrySpawnBossRushDoor(false) -- The argument is "IgnoreTime"
    end

    -- Try to spawn the Blue Womb door
    if stage == 8 and
       ((g.race.status == "in progress" and g.race.goal == "Hush") or
        (challenge == Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)") and
         g:TableContains(Speedrun.remainingGoals, "Hush"))) then

      g.r:TrySpawnBlueWombDoor(true, true)
    end
  end

  -- Subvert the "Would you like to do a Victory Lap!?" popup that happens after defeating The Lamb
  if stage == 11 and stageType == 0 and -- 11.0 is the Dark Room
     roomType == RoomType.ROOM_BOSS and -- 5
     roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    g.g:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROOM_CLEAR_DELAY, -- 10000
              g:GridToPos(0, 0), g.zeroVector, nil, 0, 0)
    Isaac.DebugString("Spawned the \"Room Clear Delay Effect\" custom entity (for The Lamb).")
    -- This won't work to delay the room clearing if "debug 10" is on

    -- Track that we have defeated The Lamb (for the "Everything" race goal)
    g.run.killedLamb = true

    -- Spawn a big chest (which will get replaced with a trophy if we happen to be in a race)
    g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, -- 5.340
              g.zeroVector, g.zeroVector, nil, 0, 0) -- It does not matter where we spawn it

  else
    -- Spawn the award for clearing the room (the pickup, chest, etc.)
    -- (this also makes the trapdoor appear if we are in a boss room)
    if challenge == 0 and
       customRun and
       roomType ~= RoomType.ROOM_BOSS and -- 5
       roomType ~= RoomType.ROOM_DUNGEON then -- 16

      -- If we are on a set seed, then use a custom system to award room drops in order
      -- (we only care about normal room drops, so ignore Boss Rooms)
      -- (room drops are not supposed to spawn in crawlspaces)
      FastClear:SpawnClearAward()
    else
      -- Use the vanilla function to spawn a room drop, which takes into account the player's luck and so forth
      -- (room drops are not supposed to spawn in crawlspaces, but this function will internally exit
      -- if we are in a crawlspace, so we don't need to explicitly check for that)
      -- We also mark to delete the photos spawned by the game during this step
      -- (in the MC_POST_PICKUP_SELECTION callback)
      g.run.photosSpawning = true
      g.r:SpawnClearAward()
      g.run.photosSpawning = false
    end
  end

  -- Manually spawn the appropriate photos, if necessary
  FastClear:SpawnPhotos()

  -- Give a charge to the player's active item
  FastClear:AddCharge()

  -- Play the sound effect for the doors opening
  if roomType ~= RoomType.ROOM_DUNGEON then -- 16
    g.sfx:Play(SoundEffect.SOUND_DOOR_HEAVY_OPEN, 1, 0, false, 1) -- 36
  end

  -- Check to see if any bag familiars will drop anything
  FastClear:CheckBagFamiliars()
end

function FastClear:SpawnPhotos()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"
  local challenge = Isaac.GetChallenge()

  -- Only spawn the photos after the boss of Depths 2
  if stage ~= 6 or
     roomType ~= RoomType.ROOM_BOSS then -- 5

    return
  end

  -- Define pedestal positions
  local posCenter = Vector(320, 360)
  local posCenterLeft = Vector(280, 360)
  local posCenterRight = Vector(360, 360)

  -- Figure out if we need to spawn either The Polaroid, The Negative, or both
  local situations = {
    POLAROID = 1,
    NEGATIVE = 2,
    BOTH = 3,
    RANDOM = 4,
  }
  local hasPolaroid = g.p:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID)
  local hasNegative = g.p:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE)
  local hasMysteriousPaper = g.p:HasTrinket(TrinketType.TRINKET_MYSTERIOUS_PAPER)
  if hasMysteriousPaper then
    -- On every frame, the Mysterious Paper trinket will randomly give The Polaroid or The Negative
    -- Since it is impossible to determine the player's actual photo status,
    -- assume that they do not have either photo yet, which will almost always be the case
    -- (unless they are Eden or this is a Diversity race where they started with a photo / photos)
    hasPolaroid = false
    hasNegative = false
  end
  local situation
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") or
     challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") or
     Speedrun.inSeededSpeedrun then

    -- Season 1 and Seeded speedruns spawn only The Polaroid
    situation = situations.POLAROID

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") or
         challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") or
         challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") or
         challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") or
         challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") then

    -- Most seasons give the player a choice between the two photos
    situation = situations.BOTH

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)") then
    if #Speedrun.remainingGoals == 1 and Speedrun.remainingGoals[1] == "Blue Baby" then
      -- The only thing left to do is to kill Blue Baby, so they must take The Polaroid
      situation = situations.POLAROID
    elseif #Speedrun.remainingGoals == 1 and Speedrun.remainingGoals[1] == "The Lamb" then
      -- The only thing left to do is to kill The Lamb, so they must take The Negative
      situation = situations.NEGATIVE
    else
      -- Give them a choice between the photos because he player needs the ability
      -- to choose what goal they want on the fly
      situation = situations.BOTH
    end

  elseif hasPolaroid and -- 327
         hasNegative then -- 328

    -- The player has both photos already (which can only occur in a diversity race)
    -- Spawn a random boss item instead of a photo
    situation = situations.RANDOM

  elseif hasPolaroid then -- 327
    -- The player has The Polaroid already (which can occur in a diversity race or if Eden)
    -- Spawn The Negative instead
    situation = situations.NEGATIVE

  elseif hasNegative then -- 328
    -- The player has The Negative already (which can occur in a diversity race or if Eden)
    -- Spawn The Polaroid instead
    situation = situations.POLAROID

  elseif g.race.rFormat == "pageant" then
    -- Give the player a choice between the photos on the Pageant Boy ruleset
    situation = situations.BOTH

  elseif g.race.status == "in progress" and
         g.race.goal == "Blue Baby" then

    -- Races to Blue Baby need The Polaroid
    situation = situations.POLAROID

  elseif g.race.status == "in progress" and
         g.race.goal == "The Lamb" then


    -- Races to The Lamb need The Negative
    situation = situations.NEGATIVE

  elseif g.race.status == "in progress" and
         (g.race.goal == "Mega Satan" or
          g.race.goal == "Everything") then

    -- Give the player a choice between the photos for races to Mega Satan
    situation = situations.BOTH

  else
    -- They are doing a normal non-client run, so by default spawn both photos
    situation = situations.BOTH
  end

  -- Do the appropriate action depending on the situation
  if situation == situations.POLAROID then
    g.run.spawningPhoto = true
    g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, posCenter, g.zeroVector,
              nil, CollectibleType.COLLECTIBLE_POLAROID, roomSeed)
    Isaac.DebugString("Spawned The Polaroid (on frame " .. tostring(gameFrameCount) .. ").")

  elseif situation == situations.NEGATIVE then
    g.run.spawningPhoto = true
    g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, posCenter, g.zeroVector,
              nil, CollectibleType.COLLECTIBLE_NEGATIVE, roomSeed)
    Isaac.DebugString("Spawned The Negative (on frame " .. tostring(gameFrameCount) .. ").")

  elseif situation == situations.BOTH then
    g.run.spawningPhoto = true
    local polaroid = g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE,
                               posCenterLeft, g.zeroVector, nil, CollectibleType.COLLECTIBLE_POLAROID, roomSeed)
    polaroid:ToPickup().TheresOptionsPickup = true

    g.run.spawningPhoto = true
    local newSeed = g:IncrementRNG(roomSeed) -- We don't want both of the photos to have the same RNG
    local negative = g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE,
                               posCenterRight, g.zeroVector, nil, CollectibleType.COLLECTIBLE_NEGATIVE, newSeed)
    negative:ToPickup().TheresOptionsPickup = true

    Isaac.DebugString("Spawned both The Polaroid and The Negative (on frame " .. tostring(gameFrameCount) .. ").")

  elseif situation == situations.RANDOM then
    g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, posCenter, g.zeroVector, nil, 0, roomSeed)
    -- (a SubType of 0 will make a random item of the pool according to the room type)
    -- (if we use an InitSeed of 0, the item will always be Magic Mushroom, so use the room seed instead)
    Isaac.DebugString("Spawned a random boss item instead of a photo (on frame " .. tostring(gameFrameCount) .. ").")
  end
end

-- Give a charge to the player's active item
-- (and handle co-op players, if present)
function FastClear:AddCharge()
  -- Local variables
  local roomShape = g.r:GetRoomShape()

  for i = 1, g.g:GetNumPlayers() do
    local player = Isaac.GetPlayer(i - 1)
    local activeItem = player:GetActiveItem()
    local activeCharge = player:GetActiveCharge()
    local batteryCharge = player:GetBatteryCharge()

    if player:NeedsCharge() then
      -- Find out if we are in a 2x2 or L room
      local chargesToAdd = 1
      if roomShape >= 8 then
        -- L rooms and 2x2 rooms should grant 2 charges
        chargesToAdd = 2

      elseif player:HasTrinket(TrinketType.TRINKET_AAA_BATTERY) and -- 3
             activeCharge == g:GetItemMaxCharges(activeItem) - 2 then

        -- The AAA Battery grants an extra charge when the active item is one away from being fully charged
        chargesToAdd = 2

      elseif player:HasTrinket(TrinketType.TRINKET_AAA_BATTERY) and -- 3
             activeCharge == g:GetItemMaxCharges(activeItem) and
             player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and -- 63
             batteryCharge == g:GetItemMaxCharges(activeItem) - 2 then

        -- The AAA Battery should grant an extra charge when the active item is one away from being fully charged
        -- with The Battery (this is bugged in vanilla for The Battery)
        chargesToAdd = 2
      end

      -- Add the correct amount of charges
      local currentCharge = player:GetActiveCharge()
      player:SetActiveCharge(currentCharge + chargesToAdd)
    end
  end
end

-- Emulate various familiars dropping things
-- (all of these formula were reverse engineered by blcd:
-- https://bindingofisaacrebirth.gamepedia.com/User:Blcd/RandomTidbits#Pickup_Familiars)
function FastClear:CheckBagFamiliars()
  -- Local variables
  local constant1 = 1.1 -- For Little C.H.A.D., Bomb Bag, Acid Baby, Sack of Sacks
  local constant2 = 1.11 -- For The Relic, Mystery Sack, Rune Bag
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then -- 247
    constant1 = 1.2
    constant2 = 1.15
  end

  -- Look through all of the player's familiars
  local familiars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, -1, -1, false, false) -- 3
  for _, familiar in ipairs(familiars) do
    if familiar.Variant == FamiliarVariant.BOMB_BAG then -- 20
      -- This drops a bomb based on the formula:
      -- floor(cleared / 1.1) > 0 && floor(cleared / 1.1) & 1 == 0
      -- or:
      -- floor(cleared / 1.2) > 0 && floor(cleared / 1.2) & 1 == 0
      local newRoomsCleared = FastClear.familiars.BombBag.roomsCleared + 1
      if math.floor(newRoomsCleared / constant1) > 0 and math.floor(newRoomsCleared / constant1) & 1 == 0 then
        -- Random Bomb - 5.40.0
        FastClear.familiars.BombBag.seed = g:IncrementRNG(FastClear.familiars.BombBag.seed)
        g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, familiar.Position, g.zeroVector,
                  familiar, 0, FastClear.familiars.BombBag.seed)
      end

    elseif familiar.Variant == FamiliarVariant.SACK_OF_PENNIES then -- 21
      -- This drops a penny/nickel/dime/etc. based on the formula:
      -- cleared > 0 && cleared & 1 == 0
      -- or:
      -- cleared > 0 && (cleared & 1 == 0 || rand() % 3 == 0)
      local newRoomsCleared = FastClear.familiars.SackOfPennies.roomsCleared + 1
      FastClear.familiars.SackOfPennies.seed = g:IncrementRNG(FastClear.familiars.SackOfPennies.seed)
      math.randomseed(FastClear.familiars.SackOfPennies.seed)
      local sackBFFChance = math.random(1, 4294967295)
      if newRoomsCleared > 0 and
          (newRoomsCleared & 1 == 0 or
          (g.p:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and sackBFFChance % 3 == 0)) then

        -- Random Coin - 5.20.0
        FastClear.familiars.SackOfPennies.seed = g:IncrementRNG(FastClear.familiars.SackOfPennies.seed)
        g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, familiar.Position, g.zeroVector,
                  g.p, 0, FastClear.familiars.SackOfPennies.seed)
      end

    elseif familiar.Variant == FamiliarVariant.LITTLE_CHAD then -- 22
      -- This drops a half a red heart based on the formula:
      -- floor(cleared / 1.1) > 0 && floor(cleared / 1.1) & 1 == 0
      -- or:
      -- floor(cleared / 1.2) > 0 && floor(cleared / 1.2) & 1 == 0
      local newRoomsCleared = FastClear.familiars.LittleCHAD.roomsCleared + 1
      if math.floor(newRoomsCleared / constant1) > 0 and math.floor(newRoomsCleared / constant1) & 1 == 0 then
        -- Heart (half) - 5.10.2
        g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, familiar.Position, g.zeroVector,
                  familiar, 2, 0)
      end

    elseif familiar.Variant == FamiliarVariant.RELIC then -- 23
      -- This drops a soul heart based on the formula:
      -- floor(cleared / 1.11) & 3 == 2
      -- or:
      -- floor(cleared / 1.15) & 3 == 2
      local newRoomsCleared = FastClear.familiars.TheRelic.roomsCleared + 1
      if math.floor(newRoomsCleared / constant2) & 3 == 2 then
        -- Heart (soul) - 5.10.3
        g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, familiar.Position, g.zeroVector,
                  familiar, 3, 0)
      end

    elseif familiar.Variant == FamiliarVariant.JUICY_SACK then -- 52

      -- Spawn either 1 or 2 blue spiders (50% chance of each)
      FastClear.familiars.JuicySack.seed = g:IncrementRNG(FastClear.familiars.JuicySack.seed)
      math.randomseed(FastClear.familiars.JuicySack.seed)
      local spiders = math.random(1, 2)
      g.p:AddBlueSpider(familiar.Position)
      if spiders == 2 then
        g.p:AddBlueSpider(familiar.Position)
      end

      -- The BFFs! synergy gives an additional spider
      if g.p:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
        g.p:AddBlueSpider(familiar.Position)
      end

    elseif familiar.Variant == FamiliarVariant.MYSTERY_SACK then -- 57
      -- This drops a heart, coin, bomb, or key based on the formula:
      -- floor(cleared / 1.11) & 3 == 2
      -- or:
      -- floor(cleared / 1.15) & 3 == 2
      -- (also, each pickup sub-type has an equal chance of occuring)
      local newRoomsCleared = FastClear.familiars.MysterySack.roomsCleared + 1
      if math.floor(newRoomsCleared / constant2) & 3 == 2 then
        -- First, decide whether we get a heart, coin, bomb, or key
        FastClear.familiars.MysterySack.seed = g:IncrementRNG(FastClear.familiars.MysterySack.seed)
        math.randomseed(FastClear.familiars.MysterySack.seed)
        local sackPickupType = math.random(1, 4)
        FastClear.familiars.MysterySack.seed = g:IncrementRNG(FastClear.familiars.MysterySack.seed)
        math.randomseed(FastClear.familiars.MysterySack.seed)

        if sackPickupType == 1 then
          local heartType = math.random(1, 10) -- From Heart (5.10.1) to Blended Heart (5.10.10)
          g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, familiar.Position, g.zeroVector,
                    familiar, heartType, FastClear.familiars.MysterySack.seed)

        elseif sackPickupType == 2 then
          local coinType = math.random(1, 6) -- From Penny (5.20.1) to Sticky Nickel (5.20.6)
          g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, familiar.Position, g.zeroVector,
                    familiar, coinType, FastClear.familiars.MysterySack.seed)

        elseif sackPickupType == 3 then
          local keyType = math.random(1, 4) -- From Key (5.30.1) to Charged Key (5.30.4)
          g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, familiar.Position, g.zeroVector,
                    familiar, keyType, FastClear.familiars.MysterySack.seed)

        elseif sackPickupType == 4 then
          local bombType = math.random(1, 5) -- From Bomb (5.40.1) to Megatroll Bomb (5.40.5)
          g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, familiar.Position, g.zeroVector,
                    familiar, bombType, FastClear.familiars.MysterySack.seed)
        end
      end

    elseif familiar.Variant == FamiliarVariant.LIL_CHEST then -- 82
      -- This drops a heart, coin, bomb, or key based on the formula:
      -- 10% chance for a trinket, if no trinket, 25% chance for a random consumable (based on time)
      -- Or, with BFFS!, 12.5% chance for a trinket, if no trinket, 31.25% chance for a random consumable
      -- We don't want it based on time in the Racing+ mod

      -- First, decide whether we get a trinket
      FastClear.familiars.LilChest.seed = g:IncrementRNG(FastClear.familiars.LilChest.seed)
      math.randomseed(FastClear.familiars.LilChest.seed)
      local chestTrinket = math.random(1, 1000)
      if chestTrinket <= 100 or
          (g.p:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 125) then

          -- Random Trinket - 5.350.0
        g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, familiar.Position, g.zeroVector,
                  familiar, 0, FastClear.familiars.LilChest.seed)
      else
        -- Second, decide whether it spawns a consumable
        FastClear.familiars.LilChest.seed = g:IncrementRNG(FastClear.familiars.LilChest.seed)
        math.randomseed(FastClear.familiars.LilChest.seed)
        local chestConsumable = math.random(1, 10000)
        if chestConsumable <= 2500 or
            (g.p:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 3125) then

          -- Third, decide whether we get a heart, coin, bomb, or key
          FastClear.familiars.LilChest.seed = g:IncrementRNG(FastClear.familiars.LilChest.seed)
          math.randomseed(FastClear.familiars.LilChest.seed)
          local chestPickupType = math.random(1, 4)
          FastClear.familiars.LilChest.seed = g:IncrementRNG(FastClear.familiars.LilChest.seed)

          -- If heart
          if chestPickupType == 1 then
            -- Random Heart - 5.10.0
            g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, familiar.Position, g.zeroVector,
                      familiar, 0, FastClear.familiars.LilChest.seed)

          -- If coin
          elseif chestPickupType == 2 then
            -- Random Coin - 5.20.0
            g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, familiar.Position, g.zeroVector,
                      familiar, 0, FastClear.familiars.LilChest.seed)

          -- If bomb
          elseif chestPickupType == 3 then
            -- Random Bomb - 5.40.0
            g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, familiar.Position, g.zeroVector,
                      familiar, 0, FastClear.familiars.LilChest.seed)

          -- If key
          elseif chestPickupType == 4 then
            -- Random Key - 5.30.0
            g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, familiar.Position, g.zeroVector,
                      familiar, 0, FastClear.familiars.LilChest.seed)
          end
        end
      end

    elseif familiar.Variant == FamiliarVariant.BUMBO and -- 88
           familiar:ToFamiliar().State + 1 == 2 then
            -- It will be state 0 at level 1, state 1 at level 2, state 2 at level 3, and state 3 at level 4

      -- Level 2 Bumbo has a 32% / 40% chance to drop a random pickup
      FastClear.familiars.Bumbo.seed = g:IncrementRNG(FastClear.familiars.Bumbo.seed)
      math.randomseed(FastClear.familiars.Bumbo.seed)
      local chestTrinket = math.random(1, 100)
      if chestTrinket <= 32 or
          (g.p:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 40) then

        -- Spawn a random pickup
        g.g:Spawn(EntityType.ENTITY_PICKUP, 0, familiar.Position, g.zeroVector,
                  familiar, 0, FastClear.familiars.Bumbo.seed)
      end

    elseif familiar.Variant == FamiliarVariant.RUNE_BAG then -- 91
      -- This drops a random rune based on the formula:
      -- floor(roomsCleared / 1.11) & 3 == 2
      local newRoomsCleared = FastClear.familiars.RuneBag.roomsCleared + 1
      if math.floor(newRoomsCleared / constant2) & 3 == 2 then
        -- For some reason you cannot spawn the normal "Random Rune" entity (5.301.0)
        -- So, spawn a random card (5.300.0) over and over until we get a rune
        while true do
          FastClear.familiars.RuneBag.seed = g:IncrementRNG(FastClear.familiars.RuneBag.seed)
          local rune = g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD,
                                 familiar.Position, g.zeroVector, familiar, 0, FastClear.familiars.RuneBag.seed)
          -- Hagalaz is 32 and Black Rune is 41
          if rune.SubType >= 32 and rune.SubType <= 41 then
            break
          end
          rune:Remove()
        end
      end

    elseif familiar.Variant == FamiliarVariant.SPIDER_MOD then -- 94
      -- Spider Mod has a 10% or 12.5% chance to drop something
      FastClear.familiars.SpiderMod.seed = g:IncrementRNG(FastClear.familiars.SpiderMod.seed)
      math.randomseed(FastClear.familiars.SpiderMod.seed)
      local chestTrinket = math.random(1, 1000)
      if chestTrinket <= 100 or
          (g.p:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 125) then

        -- There is a 1/3 chance to spawn a battery and a 2/3 chance to spawn a blue spider
        FastClear.familiars.SpiderMod.seed = g:IncrementRNG(FastClear.familiars.SpiderMod.seed)
        math.randomseed(FastClear.familiars.SpiderMod.seed)
        local spiderModDrop = math.random(1, 3)
        if spiderModDrop == 1 then
          -- Lil' Battery (5.90)
          g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, familiar.Position, g.zeroVector,
                    familiar, 0, FastClear.familiars.SpiderMod.seed)
        else
          g.p:AddBlueSpider(familiar.Position)
        end
      end

    elseif familiar.Variant == FamiliarVariant.ACID_BABY then -- 112
      -- This drops a pill based on the formula:
      -- floor(roomsCleared / 1.1) > 0 && floor(roomsCleared / 1.1) & 1 == 0
      local newRoomsCleared = FastClear.familiars.AcidBaby.roomsCleared + 1
      if math.floor(newRoomsCleared / constant1) > 0 and math.floor(newRoomsCleared / constant1) & 1 == 0 then
        -- Random Pill - 5.70.0
        FastClear.familiars.AcidBaby.seed = g:IncrementRNG(FastClear.familiars.AcidBaby.seed)
        g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, familiar.Position, g.zeroVector,
                  familiar, 0, FastClear.familiars.AcidBaby.seed)
      end

    elseif familiar.Variant == FamiliarVariant.SACK_OF_SACKS then -- 114
      -- This drops a sack based on the formula:
      -- floor(roomsCleared / 1.1) > 0 && floor(roomsCleared / 1.1) & 1 == 0
      local newRoomsCleared = FastClear.familiars.SackOfSacks.roomsCleared + 1
      if math.floor(newRoomsCleared / constant1) > 0 and math.floor(newRoomsCleared / constant1) & 1 == 0 then
        -- Grab Bag - 5.69.0
        FastClear.familiars.SackOfSacks.seed = g:IncrementRNG(FastClear.familiars.SackOfSacks.seed)
        g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_GRAB_BAG, familiar.Position, g.zeroVector,
                  familiar, 0, FastClear.familiars.SackOfSacks.seed)
      end
    end
  end
end

function FastClear:IncrementBagFamiliars()
  -- Look through all of the player's familiars
  local familiars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, -1, -1, false, false) -- 3
  for _, familiar in ipairs(familiars) do
    -- We only want to increment the rooms cleared variable once, even if they have multiple of the same familiar
    if familiar.Variant == FamiliarVariant.BOMB_BAG and -- 20
       not FastClear.familiars.BombBag.incremented then

      FastClear.familiars.BombBag.incremented = true
      FastClear.familiars.BombBag.roomsCleared = FastClear.familiars.BombBag.roomsCleared + 1

    elseif familiar.Variant == FamiliarVariant.SACK_OF_PENNIES and -- 21
           not FastClear.familiars.SackOfPennies.incremented then

      FastClear.familiars.SackOfPennies.incremented = true
      FastClear.familiars.SackOfPennies.roomsCleared = FastClear.familiars.SackOfPennies.roomsCleared + 1

    elseif familiar.Variant == FamiliarVariant.LITTLE_CHAD and -- 22
           not FastClear.familiars.LittleCHAD.incremented then

      FastClear.familiars.LittleCHAD.incremented = true
      FastClear.familiars.LittleCHAD.roomsCleared = FastClear.familiars.LittleCHAD.roomsCleared + 1

    elseif familiar.Variant == FamiliarVariant.RELIC and -- 23
           not FastClear.familiars.TheRelic.incremented then

      FastClear.familiars.TheRelic.incremented = true
      FastClear.familiars.TheRelic.roomsCleared = FastClear.familiars.TheRelic.roomsCleared + 1
      Isaac.DebugString("The Relic counter increased: " .. tostring(FastClear.familiars.TheRelic.roomsCleared))

    elseif familiar.Variant == FamiliarVariant.MYSTERY_SACK and -- 57
           not FastClear.familiars.MysterySack.incremented then

      FastClear.familiars.MysterySack.incremented = true
      FastClear.familiars.MysterySack.roomsCleared = FastClear.familiars.MysterySack.roomsCleared + 1

    elseif familiar.Variant == FamiliarVariant.RUNE_BAG and -- 91
           not FastClear.familiars.RuneBag.incremented then

      FastClear.familiars.RuneBag.incremented = true
      FastClear.familiars.RuneBag.roomsCleared = FastClear.familiars.RuneBag.roomsCleared + 1

    elseif familiar.Variant == FamiliarVariant.ACID_BABY and -- 112
           not FastClear.familiars.AcidBaby.incremented then

      FastClear.familiars.AcidBaby.incremented = true
      FastClear.familiars.AcidBaby.roomsCleared = FastClear.familiars.AcidBaby.roomsCleared + 1

    elseif familiar.Variant == FamiliarVariant.SACK_OF_SACKS and -- 114
           not FastClear.familiars.SackOfSacks.incremented then

      FastClear.familiars.SackOfSacks.incremented = true
      FastClear.familiars.SackOfSacks.roomsCleared = FastClear.familiars.SackOfSacks.roomsCleared + 1
    end
  end

  -- Reset the incremented variable
  for k, v in pairs(FastClear.familiars) do
    FastClear.familiars[k].incremented = false
  end
end

-- Normally, room drops are based on the room's seed
-- This is undesirable, since someone can go a wrong way in a seeded race and then
-- get rewarded with an Emperor card that the other player does not get
-- Thus, overwrite the game's room drop system with one that manually spawns awards in order
-- The following code is based on the game's internal logic, documented here:
-- https://bindingofisaacrebirth.gamepedia.com/Room_Clear_Awards
-- (it was reverse engineered by Blade / blcd / Will)
-- However, there is some major difference from vanilla:
-- we hardcode values of 0 luck so that room drops are completely consistent
-- (otherwise, one player would be able to get a lucky Emperor card by using a Luck Up or Luck Down pill, for example)
-- Furthermore, we ignore the following items, since we remove them from pools:
-- Lucky Foot, Silver Dollar, Bloody Crown, Daemon's Tail, Child's Heart, Rusted Key, Match Stick, Lucky Toe,
-- Safety Cap, Ace of Spades, and Watch Battery
function FastClear:SpawnClearAward()
  -- Local variables
  local centerPos = g.r:GetCenterPos()

  -- Get a random value between 0 and 1 that will determine what kind of reward we get
  FastClear.roomClearAwardRNG = g:IncrementRNG(FastClear.roomClearAwardRNG)
  local rng = RNG()
  rng:SetSeed(FastClear.roomClearAwardRNG, 35)
  local pickupPercent = rng:RandomFloat()

  -- Determine the kind of pickup
  local pickupVariant = PickupVariant.PICKUP_NULL -- 0
  if pickupPercent > 0.22 then -- 22% chance for nothing to drop
    if pickupPercent < 0.3 then -- 7% chance for a card / trinket / pill
      if rng:RandomInt(3) == 0 then -- 7% * 33% = 2.3% chance
        pickupVariant = PickupVariant.PICKUP_TAROTCARD -- 300
      elseif rng:RandomInt(2) == 0 then -- 7% * 66% * 50% = 2.3% chance
        pickupVariant = PickupVariant.PICKUP_TRINKET -- 350
      else -- 7% * 66% * 50% = 2.3% chance
        pickupVariant = PickupVariant.PICKUP_PILL -- 70
      end

    elseif pickupPercent < 0.45 then -- 15% for a coin
      pickupVariant = PickupVariant.PICKUP_COIN -- 20

    elseif pickupPercent < 0.6 then -- 15% for a heart
      pickupVariant = PickupVariant.PICKUP_HEART -- 10

    elseif pickupPercent < 0.8 then -- 20% for a key
      pickupVariant = PickupVariant.PICKUP_KEY -- 30

    elseif pickupPercent < 0.95 then -- 15% for a bomb
      pickupVariant = PickupVariant.PICKUP_BOMB -- 40

    else -- 5% for a chest
      pickupVariant = PickupVariant.PICKUP_CHEST -- 50
    end

    if rng:RandomInt(20) == 0 then
      pickupVariant = PickupVariant.PICKUP_LIL_BATTERY -- 90
    end

    if (rng:RandomInt(50) == 0) then
      pickupVariant = PickupVariant.PICKUP_GRAB_BAG -- 69
    end
  end

  -- Contract From Below has a chance to increase the amount of pickups that drop or make nothing drop
  local pickupCount = 1
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_CONTRACT_FROM_BELOW) and -- 241
     pickupVariant ~= PickupVariant.PICKUP_TRINKET then -- 350

    pickupCount = g.p:GetCollectibleNum(CollectibleType.COLLECTIBLE_CONTRACT_FROM_BELOW) + 1 -- 241

    -- Nothing chance with:
    -- 1 contract / 2 pickups: 0.44
    -- 2 contracts / 3 pickups: 0.44 (base) (would be 0.3 otherwise)
    -- 3 contracts / 4 pickups: 0.2
    -- 4 contracts / 5 pickups: 0.13
    local nothingChance = 0.666^pickupCount -- "math.pow()" does not exist in Isaac's Lua version
    if nothingChance * 0.5 > rng:RandomFloat() then
      pickupCount = 0
    end
  end

  -- Hard mode has a chance to remove a heart drop
  if g.g.Difficulty == Difficulty.DIFFICULTY_HARD and -- 1
     pickupVariant == PickupVariant.PICKUP_HEART then -- 10

    if rng:RandomInt(100) >= 35 then
      pickupVariant = PickupVariant.PICKUP_NULL -- 0
    end
  end

  -- Broken Modem has a chance to increase the amount of pickups that drop
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_BROKEN_MODEM) and
     rng:RandomInt(4) == 0 and
     pickupCount >= 1 and
      (pickupVariant == PickupVariant.PICKUP_COIN or -- 20
       pickupVariant == PickupVariant.PICKUP_HEART or -- 10
       pickupVariant == PickupVariant.PICKUP_KEY or -- 30
       pickupVariant == PickupVariant.PICKUP_GRAB_BAG or -- 69
       pickupVariant == PickupVariant.PICKUP_BOMB) then -- 40

    pickupCount = pickupCount + 1
  end

  if pickupCount > 0 and
     pickupVariant ~= PickupVariant.PICKUP_NULL then -- 0

    local subType = 0
    for i = 1, pickupCount do
      local pos = g.r:FindFreePickupSpawnPosition(centerPos, 1, true)
      local pickup = g.g:Spawn(EntityType.ENTITY_PICKUP, pickupVariant, -- 5
                     pos, g.zeroVector, nil, subType, rng:Next())
      subType = pickup.SubType
    end
  end
end

return FastClear

local FastClear = {}

-- Includes
local g = require("racing_plus/globals")
local BagFamiliars = require("racing_plus/bagfamiliars")
local Season6 = require("racing_plus/season6")
local Season7 = require("racing_plus/season7")
local Season8 = require("racing_plus/season8")
local Season9 = require("racing_plus/season9")

--
-- Variables
--

-- These are reset in the "FastClear:PostGameStarted()" function
FastClear.roomClearAwardRNG = 0
FastClear.roomClearAwardRNG2 = 0 -- Used for Devil Rooms and Angel Rooms

-- These are reset in the "FastClear:PostGameStarted()" function and
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

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function FastClear:PostGameStarted()
  -- Local variables
  local startSeed = g.seeds:GetStartSeed()

  BagFamiliars:PostGameStarted()

  FastClear.roomClearAwardRNG = startSeed
  FastClear.roomClearAwardRNG2 = startSeed
  for i = 1, 500 do
    -- We want to insure that the second RNG counter does not overlap with the first one
    -- (around 175 rooms are cleared in an average speedrun, so 500 is a reasonable upper limit)
    FastClear.roomClearAwardRNG2 = g:IncrementRNG(FastClear.roomClearAwardRNG2)
  end

  FastClear.aliveEnemies = {}
  FastClear.aliveEnemiesCount = 0
  FastClear.aliveBossesCount = 0
  FastClear.buttonsAllPushed = false
  FastClear.roomInitializing = false
  FastClear.delayFrame = 0
end

-- ModCallbacks.MC_NPC_UPDATE (0)
function FastClear:NPCUpdate(npc)
  -- Friendly enemies (from Delirious or Friendly Ball) will be added to the aliveEnemies table
  -- because there are no flags set yet in the MC_POST_NPC_INIT callback
  -- Thus, we have to wait until they are initialized and then remove them from the table
  if npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then -- 1 << 29
    -- Remove it from the list if it is on it
    FastClear:CheckDeadNPC(npc, "NPCUpdate")
    return
  end

  -- We can't rely on the MC_POST_NPC_INIT callback because it is not fired for certain NPCs
  -- (like when a Gusher emerges from killing a Gaper)
  FastClear:PostNPCInit(npc)
end

-- ModCallbacks.MC_NPC_UPDATE (0)
-- EntityType.ENTITY_RAGLING (246)
function FastClear:Ragling(npc)
  -- Rag Man Raglings don't actually die (they turn into patches on the ground),
  -- so we need to manually keep track of when this happens
  if (
    npc.Variant == 1 -- 246.1
    and npc.State == NpcState.STATE_UNIQUE_DEATH -- 16
    -- (they go to state 16 when they are patches on the ground)
  ) then
    FastClear:CheckDeadNPC(npc, "Ragling")
  end
end

-- ModCallbacks.MC_NPC_UPDATE (0)
-- EntityType.ENTITY_STONEY (302)
function FastClear:Stoney(npc)
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
  Isaac.DebugString(
    "MC_POST_NPC_INIT - "
    .. tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "."
    .. tostring(npc.SubType) .. "." .. tostring(npc.State) .. ", "
    .. "index " .. tostring(index) .. ", "
    .. "frame " .. tostring(gameFrameCount)
  )
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
  if (
    npc.Type == EntityType.ENTITY_RAGLING and npc.Variant == 1 -- 246.1
    and npc.State == NpcState.STATE_UNIQUE_DEATH -- 16
     -- (they go to state 16 when they are patches on the ground)
  ) then
    return
  end

  -- We don't care if this is a specific child NPC attached to some other NPC
  if FastClear:AttachedNPC(npc) then
    return
  end

  -- If we are entering a new room, flush all of the stuff in the old room
  -- (we can't use the MC_POST_NEW_ROOM callback to handle this since that callback fires after this
  -- one)
  -- (roomFrameCount will be at -1 during the initialization phase)
  if (
    roomFrameCount == -1
    and not FastClear.roomInitializing
  ) then
    FastClear.aliveEnemies = {}
    FastClear.aliveEnemiesCount = 0
    FastClear.aliveBossesCount = 0
    FastClear.roomInitializing = true
    -- (this will get set back to false in the MC_POST_NEW_ROOM callback)
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
  Isaac.DebugString(
    "Added NPC "
    .. tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "."
    .. tostring(npc.SubType) .. "." .. tostring(npc.State) .. ", "
    .. "index " .. tostring(index) .. ", "
    .. "frame " .. tostring(gameFrameCount) .. ", "
    .. "total " .. tostring(FastClear.aliveEnemiesCount)
  )
  --]]
end

function FastClear:AttachedNPC(npc)
  -- These are NPCs that have "CanShutDoors" equal to true naturally by the game,
  -- but shouldn't actually keep the doors closed
  if (
    -- My Shadow (23.0.1)
    (npc.Type == EntityType.ENTITY_CHARGER and npc.Variant == 0 and npc.Subtype == 1)
    -- These are the black worms generated by My Shadow; they are similar to charmed enemies,
    -- but do not actually have the "charmed" flag set, so we don't want to add them to the
    -- "aliveEnemies" table
    or (npc.Type == EntityType.ENTITY_VIS and npc.Variant == 22) -- Cubber Projectile (39.22)
    -- (needed because Fistuloids spawn them on death)
    or (npc.Type == EntityType.ENTITY_DEATH and npc.Variant == 10) -- Death Scythe (66.10)
    or (npc.Type == EntityType.ENTITY_PEEP and npc.Variant == 10) -- Peep Eye (68.10)
    or (npc.Type == EntityType.ENTITY_PEEP and npc.Variant == 11) -- Bloat Eye (68.11)
    or (npc.Type == EntityType.ENTITY_BEGOTTEN and npc.Variant == 10) -- Begotten Chain (251.10)
    -- Mama Gurdy Left Hand (266.1)
    or (npc.Type == EntityType.ENTITY_MAMA_GURDY and npc.Variant == 1)
    -- Mama Gurdy Right Hand (266.2)
    or (npc.Type == EntityType.ENTITY_MAMA_GURDY and npc.Variant == 2)
    or (npc.Type == EntityType.ENTITY_BIG_HORN and npc.Variant == 1) -- Small Hole (411.1)
    or (npc.Type == EntityType.ENTITY_BIG_HORN and npc.Variant == 2) -- Big Hole (411.2)
  ) then
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

  Isaac.DebugString(
    "MC_POST_ENTITY_REMOVE - "
    .. tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "."
    .. tostring(npc.SubType) .. "." .. tostring(npc.State) .. ", "
    .. "index " .. tostring(index) .. ", "
    .. "frame " .. tostring(gameFrameCount)
  )
  --]]

  -- We can't rely on the MC_POST_ENTITY_KILL callback because it is not fired for certain NPCs
  -- (like when Daddy Long Legs does a stomp attack or a Portal despawns)
  FastClear:CheckDeadNPC(npc, "PostEntityRemove")
end

-- ModCallbacks.MC_POST_ENTITY_KILL (68)
-- (we can't use the MC_POST_NPC_DEATH callback or MC_POST_ENTITY_REMOVE callbacks because
-- they are only fired once the death animation is finished)
function FastClear:PostEntityKill(entity)
  -- We only care about NPCs dying
  local npc = entity:ToNPC()
  if npc == nil then
    return
  end

  --[[
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local index = GetPtrHash(npc)

  Isaac.DebugString(
    "MC_POST_ENTITY_KILL - "
    .. tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "."
    .. tostring(npc.SubType) .. "." .. tostring(npc.State) .. ", "
    .. "index " .. tostring(index) .. ", "
    .. "frame " .. tostring(gameFrameCount)
  )
  --]]

  FastClear:CheckDeadNPC(npc, "PostEntityKill")
end

function FastClear:CheckDeadNPC(npc, parentFunction)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()

  -- We only care about entities that are in the aliveEnemies table
  local index = GetPtrHash(npc)
  if FastClear.aliveEnemies[index] == nil then
    return
  end

  -- The "MC_POST_ENTITY_KILL" callback will be triggered when
  -- a Dark Red champion changes to a flesh pile
  -- This does not count as a real death (and the NPC should not be removed),
  -- so we need to handle this
  -- We cannot check for "npc:GetSprite():GetFilename() == "gfx/024.000_Globin.anm2"",
  -- because that won't work for champion Gapers & Globins
  -- We cannot check for "npc:GetSprite():IsPlaying("ReGenChamp")",
  -- because that will only be updated on the next frame
  if (
    npc:GetChampionColorIdx() == 12 and -- Dark Red champion
    -- (collapses into a flesh pile upon death)
    parentFunction == "PostEntityKill"
  ) then
    -- We don't want to open the doors yet until the flesh pile is actually removed in the
    -- "MC_POST_ENTITY_REMOVE" callback
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
  Isaac.DebugString(
    "Removed NPC "
    .. tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "."
    .. tostring(npc.SubType) .. "." .. tostring(npc.State) .. ", "
    .. "index " .. tostring(index) .. ", "
    .. "frame " .. tostring(gameFrameCount) .. ", "
    .. "total " .. tostring(FastClear.aliveEnemiesCount)
  )
  --]]

  -- We want to delay a frame before opening the doors to give time for splitting enemies to spawn
  -- their children
  FastClear.delayFrame = gameFrameCount + 1

  -- We check every frame to see if the "aliveEnemiesCount" variable is set to 0 the
  -- "MC_POST_UPDATE" callback
end

-- ModCallbacks.MC_POST_UPDATE (1)
-- Check on every frame to see if we need to open the doors
function FastClear:PostUpdate()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local roomClear = g.r:IsClear()
  local roomFrameCount = g.r:GetFrameCount()

  -- Disable this in Greed Mode
  if g.g.Difficulty >= Difficulty.DIFFICULTY_GREED then -- 2
    return
  end

  -- Disable this if we are on the "PAC1F1CM" seed / Easter Egg
  if g.seeds:HasSeedEffect(SeedEffect.SEED_PACIFIST) then -- 25
    return
  end

  -- If a frame has passed since an enemy died, reset the delay counter
  if (
    FastClear.delayFrame ~= 0
    and gameFrameCount >= FastClear.delayFrame
  ) then
    FastClear.delayFrame = 0
  end

  -- Check on every frame to see if we need to open the doors
  if (
    FastClear.aliveEnemiesCount == 0
    and FastClear.delayFrame == 0
    and not roomClear
    and FastClear:CheckAllPressurePlatesPushed()
    and roomFrameCount > 1
    -- (if a Mushroom is replaced, the room can be clear of enemies on the first frame)
  ) then
    FastClear:ClearRoom()
  end
end

function FastClear:CheckAllPressurePlatesPushed()
  -- If we are in a puzzle room, check to see if all of the plates have been pressed
  if (
    not g.r:HasTriggerPressurePlates()
    or FastClear.buttonsAllPushed
  ) then
    return true
  end

  -- Check all the grid entities in the room
  local num = g.r:GetGridSize()
  for i = 1, num do
    local gridEntity = g.r:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState();
      if (
        saveState.Type == GridEntityType.GRID_PRESSURE_PLATE -- 20
        and saveState.State ~= 3
      ) then
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
  local roomIndex = g:GetRoomIndex()
  local gameFrameCount = g.g:GetFrameCount()
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomType = g.r:GetType()
  local centerPos = g.r:GetCenterPos()
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
      if (
        g.race.rFormat == "seeded"
        and door:IsRoomType(RoomType.ROOM_TREASURE) -- 4
        and roomType ~= RoomType.ROOM_TREASURE -- 4
      ) then
        openDoor = false
      end
      if openDoor then
        door:Open()
      end
    end
  end

  -- Manually kill Death's Heads, Flesh Death's Heads, and any type of creep
  -- (by default, they will only die after the death animations are completed)
  -- Additionally, open any closed heaven doors
  for _, entity in ipairs(Isaac.GetRoomEntities()) do
    if (
      entity.Type == EntityType.ENTITY_DEATHS_HEAD -- 212
      and entity.Variant == 0
    ) then
      -- Activate its death state
      -- (we don't want to target Dank Death's Heads)
      entity:ToNPC().State = 18
    elseif entity.Type == EntityType.ENTITY_FLESH_DEATHS_HEAD then -- 286
      -- Activating the death state won't make the tears explode out of it,
      -- so just kill it and spawn another one to die
      entity.Visible = false
      entity:Kill()
      local newHead = g.g:Spawn(
        entity.Type,
        entity.Variant,
        entity.Position,
        entity.Velocity,
        entity.Parent,
        entity.SubType,
        entity.InitSeed
      )
      newHead:ToNPC().State = 18
    elseif entity.Type == EntityType.ENTITY_EFFECT then -- 1000
      if (
        entity.Variant == EffectVariant.CREEP_RED -- 22
        or entity.Variant == EffectVariant.CREEP_GREEN -- 23
        or entity.Variant == EffectVariant.CREEP_YELLOW -- 24
        or entity.Variant == EffectVariant.CREEP_WHITE -- 25
        or entity.Variant == EffectVariant.CREEP_BLACK -- 26
        or entity.Variant == EffectVariant.CREEP_BROWN -- 56
        or entity.Variant == EffectVariant.CREEP_SLIPPERY_BROWN -- 94
      ) then
        entity:Kill()
      elseif entity.Variant == EffectVariant.HEAVEN_DOOR_FAST_TRAVEL then
        local effect = entity:ToEffect()
        if effect.State == 1 then
          effect.State = 0
          effect:GetSprite():Play("Appear", true)
        end
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
    if (
      stage == 8
      and (
        (g.race.status == "in progress" and g.race.goal == "Hush")
        or (g.race.status == "in progress" and g.race.goal == "Delirium")
        or (
          challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)")
          and g:TableContains(Season7.remainingGoals, "Hush")
        )
      )
    ) then
      g.r:TrySpawnBlueWombDoor(true, true)
    end
  end

  -- Subvert the "Would you like to do a Victory Lap!?" popup that happens after defeating The Lamb
  if (
    stage == 11
    and stageType == 0 -- 11.0 is the Dark Room
    and roomType == RoomType.ROOM_BOSS -- 5
    and roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX -- -7
  ) then
    Isaac.Spawn(
      EntityType.ENTITY_EFFECT, -- 1000
      EffectVariant.ROOM_CLEAR_DELAY,
      0,
      g:GridToPos(0, 0),
      g.zeroVector,
      nil
    )
    Isaac.DebugString("Spawned the \"Room Clear Delay Effect\" custom entity (for The Lamb).")
    -- This won't work to delay the room clearing if "debug 10" is on

    -- Track that we have defeated The Lamb (for the "Everything" race goal)
    g.run.killedLamb = true

    -- Spawn a big chest (which will get replaced with a trophy if we happen to be in a race)
    Isaac.Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_BIGCHEST, -- 340
      0,
      centerPos,
      g.zeroVector,
      nil
    )
  else
    -- Spawn the award for clearing the room (the pickup, chest, etc.)
    -- (this also makes the trapdoor appear if we are in a boss room)
    if (
      challenge == 0
      and customRun
      and roomType ~= RoomType.ROOM_BOSS -- 5
      and roomType ~= RoomType.ROOM_DUNGEON -- 16
    ) then
      -- If we are on a set seed, then use a custom system to award room drops in order
      -- (we only care about normal room drops, so ignore Boss Rooms)
      -- (room drops are not supposed to spawn in crawlspaces)
      FastClear:SpawnClearAward()
    else
      -- Use the vanilla function to spawn a room drop,
      -- which takes into account the player's luck and so forth
      -- (room drops are not supposed to spawn in crawlspaces,
      -- but this function will internally exit
      -- if we are in a crawlspace, so we don't need to explicitly check for that)
      -- Just in case we just killed Mom,
      -- we also mark to delete the photos spawned by the game during this step
      -- (in the MC_PRE_ENTITY_SPAWN callback)
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
  BagFamiliars:CheckSpawn()

  Season6:PostClearRoom()
  Season9:PostClearRoom()
end

function FastClear:SpawnPhotos()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()
  local roomSeed = g.r:GetSpawnSeed()
  local challenge = Isaac.GetChallenge()

  -- Only spawn the photos after the boss of Depths 2
  if (
    stage ~= 6
    or roomType ~= RoomType.ROOM_BOSS -- 5
  ) then
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
  if (
    challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)")
    or challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)")
  ) then
    -- Season 1 speedruns spawn only The Polaroid
    situation = situations.POLAROID
  elseif (
    challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)")
    or challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)")
    or challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)")
    or challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)")
    or challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)")
    or challenge == Isaac.GetChallengeIdByName("R+7 (Season 9 Beta)")
  ) then
    -- Most seasons give the player a choice between the two photos
    situation = situations.BOTH
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 8)") then
    if (
      g:TableContains(Season8.touchedItems, CollectibleType.COLLECTIBLE_POLAROID) -- 327
      and g:TableContains(Season8.touchedItems, CollectibleType.COLLECTIBLE_NEGATIVE) -- 328
    ) then
      situation = situations.RANDOM
    elseif g:TableContains(Season8.touchedItems, CollectibleType.COLLECTIBLE_POLAROID) then -- 327
      situation = situations.NEGATIVE
    elseif g:TableContains(Season8.touchedItems, CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328
      situation = situations.POLAROID
    else
      situation = situations.BOTH
    end
  elseif hasPolaroid and hasNegative then
    -- The player has both photos already (which can only occur in a diversity race)
    -- Spawn a random boss item instead of a photo
    situation = situations.RANDOM
  elseif hasPolaroid then
    -- The player has The Polaroid already (which can occur in a diversity race or if Eden)
    -- Spawn The Negative instead
    situation = situations.NEGATIVE
  elseif hasNegative then
    -- The player has The Negative already (which can occur in a diversity race or if Eden)
    -- Spawn The Polaroid instead
    situation = situations.POLAROID
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    -- We need the Season 7 logic to be below the Polaroid and Negative checks above,
    -- because it is possible to start with either The Polaroid or The Negative as one of the
    -- three starting passive items
    if #Season7.remainingGoals == 1 and Season7.remainingGoals[1] == "Blue Baby" then
      -- The only thing left to do is to kill Blue Baby, so they must take The Polaroid
      situation = situations.POLAROID
    elseif #Season7.remainingGoals == 1 and Season7.remainingGoals[1] == "The Lamb" then
      -- The only thing left to do is to kill The Lamb, so they must take The Negative
      situation = situations.NEGATIVE
    else
      -- Give them a choice between the photos because he player needs the ability
      -- to choose what goal they want on the fly
      situation = situations.BOTH
    end
  elseif g.race.rFormat == "pageant" then
    -- Give the player a choice between the photos on the Pageant Boy ruleset
    situation = situations.BOTH
  elseif g.race.status == "in progress" and g.race.goal == "Blue Baby" then
    -- Races to Blue Baby need The Polaroid
    situation = situations.POLAROID
  elseif g.race.status == "in progress" and g.race.goal == "The Lamb" then
    -- Races to The Lamb need The Negative
    situation = situations.NEGATIVE
  elseif (
    g.race.status == "in progress"
    and (g.race.goal == "Mega Satan" or g.race.goal == "Everything")
  ) then
    -- Give the player a choice between the photos for races to Mega Satan
    situation = situations.BOTH
  else
    -- They are doing a normal non-client run, so by default spawn both photos
    situation = situations.BOTH
  end

  -- Do the appropriate action depending on the situation
  if situation == situations.POLAROID then
    g.run.spawningPhoto = true
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_COLLECTIBLE, -- 100
      posCenter,
      g.zeroVector,
      nil,
      CollectibleType.COLLECTIBLE_POLAROID, -- 327
      roomSeed
    )
    Isaac.DebugString(
      "FastClear:SpawnPhotos() - Spawned The Polaroid "
      .. "(on frame " .. tostring(gameFrameCount) .. ")."
    )
  elseif situation == situations.NEGATIVE then
    g.run.spawningPhoto = true
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_COLLECTIBLE, -- 100
      posCenter,
      g.zeroVector,
      nil,
      CollectibleType.COLLECTIBLE_NEGATIVE, -- 328
      roomSeed
    )
    Isaac.DebugString(
      "FastClear:SpawnPhotos() - Spawned The Negative "
      .. "(on frame " .. tostring(gameFrameCount) .. ")."
    )
  elseif situation == situations.BOTH then
    g.run.spawningPhoto = true
    local polaroid = g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_COLLECTIBLE, -- 100
      posCenterLeft,
      g.zeroVector,
      nil,
      CollectibleType.COLLECTIBLE_POLAROID, -- 327
      roomSeed
    )
    polaroid:ToPickup().TheresOptionsPickup = true

    -- We don't want both of the photos to have the same RNG
    local newSeed = g:IncrementRNG(roomSeed)

    g.run.spawningPhoto = true
    local negative = g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_COLLECTIBLE, -- 100
      posCenterRight,
      g.zeroVector,
      nil,
      CollectibleType.COLLECTIBLE_NEGATIVE, -- 328
      newSeed
    )
    negative:ToPickup().TheresOptionsPickup = true

    Isaac.DebugString(
      "FastClear:SpawnPhotos() - Spawned both The Polaroid and The Negative "
      .. "(on frame " .. tostring(gameFrameCount) .. ")."
    )
  elseif situation == situations.RANDOM then
    -- If the player has There's Options, they should get two boss items instead of 1
    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS) then -- 246
      local item1 = g.g:Spawn(
        EntityType.ENTITY_PICKUP, -- 5
        PickupVariant.PICKUP_COLLECTIBLE, -- 100
        posCenterLeft,
        g.zeroVector,
        nil,
        0,
        roomSeed
      )
      item1:ToPickup().TheresOptionsPickup = true
      local nextSeed = g:IncrementRNG(roomSeed)
      local item2 = g.g:Spawn(
        EntityType.ENTITY_PICKUP, -- 5
        PickupVariant.PICKUP_COLLECTIBLE, -- 100
        posCenterRight,
        g.zeroVector,
        nil,
        0,
        nextSeed
      )
      item2:ToPickup().TheresOptionsPickup = true
      Isaac.DebugString(
        "FastClear:SpawnPhotos() - Spawned two random boss items instead of a photo "
        .. "(on frame " .. tostring(gameFrameCount) .. ")."
      )
    else
      g.g:Spawn(
        EntityType.ENTITY_PICKUP, -- 5
        PickupVariant.PICKUP_COLLECTIBLE, -- 100
        posCenter,
        g.zeroVector,
        nil,
        0, -- A SubType of 0 will make a random item of the pool according to the room type
        -- If we use an InitSeed of 0, the item will always be Magic Mushroom,
        -- so use the room seed instead
        roomSeed
      )
      Isaac.DebugString(
        "FastClear:SpawnPhotos() - Spawned a random boss item instead of a photo "
        .. "(on frame " .. tostring(gameFrameCount) .. ")."
      )
    end
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
      elseif (
        player:HasTrinket(TrinketType.TRINKET_AAA_BATTERY) -- 3
        and activeCharge == g:GetItemMaxCharges(activeItem) - 2
      ) then
        -- The AAA Battery grants an extra charge when the active item is one away from being fully
        -- charged
        chargesToAdd = 2
      elseif (
        player:HasTrinket(TrinketType.TRINKET_AAA_BATTERY) -- 3
        and activeCharge == g:GetItemMaxCharges(activeItem)
        and player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) -- 63
        and batteryCharge == g:GetItemMaxCharges(activeItem) - 2
      ) then
        -- The AAA Battery should grant an extra charge when the active item is one away from being
        -- fully charged with The Battery (this is bugged in vanilla for The Battery)
        chargesToAdd = 2
      end

      -- Add the correct amount of charges
      local currentCharge = player:GetActiveCharge()
      player:SetActiveCharge(currentCharge + chargesToAdd)
    end
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
-- (otherwise, one player would be able to get a lucky Emperor card by using a Luck Up or Luck Down
-- pill, for example)
-- Furthermore, we ignore the following items, since we remove them from pools:
-- Lucky Foot, Silver Dollar, Bloody Crown, Daemon's Tail, Child's Heart, Rusted Key, Match Stick,
-- Lucky Toe, Safety Cap, Ace of Spades, and Watch Battery
function FastClear:SpawnClearAward()
  -- Local variables
  local roomType = g.r:GetType()
  local centerPos = g.r:GetCenterPos()

  -- Find out whic seed we should use
  -- (Devil Rooms and Angel Rooms use a separate RNG counter so that players cannot get a lucky
  -- battery)
  local seed
  if (
    roomType == RoomType.ROOM_DEVIL -- 14
    or roomType == RoomType.ROOM_ANGEL -- 15
  ) then
    FastClear.roomClearAwardRNG2 = g:IncrementRNG(FastClear.roomClearAwardRNG2)
    seed = FastClear.roomClearAwardRNG2
  else
    FastClear.roomClearAwardRNG = g:IncrementRNG(FastClear.roomClearAwardRNG)
    seed = FastClear.roomClearAwardRNG
  end

  -- Get a random value between 0 and 1 that will determine what kind of reward we get
  local rng = RNG()
  rng:SetSeed(seed, 35)
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

  -- Contract From Below has a chance to increase the amount of pickups that drop or make nothing
  -- drop
  local pickupCount = 1
  if (
    g.p:HasCollectible(CollectibleType.COLLECTIBLE_CONTRACT_FROM_BELOW) -- 241
    and pickupVariant ~= PickupVariant.PICKUP_TRINKET -- 350
  ) then
    pickupCount = g.p:GetCollectibleNum(CollectibleType.COLLECTIBLE_CONTRACT_FROM_BELOW) + 1 -- 241

    -- Nothing chance with:
    -- 1 contract / 2 pickups: 0.44
    -- 2 contracts / 3 pickups: 0.44 (base) (would be 0.3 otherwise)
    -- 3 contracts / 4 pickups: 0.2
    -- 4 contracts / 5 pickups: 0.13
    local nothingChance = 0.666 ^ pickupCount -- "math.pow()" does not exist in Isaac's Lua version
    if nothingChance * 0.5 > rng:RandomFloat() then
      pickupCount = 0
    end
  end

  -- Hard mode has a chance to remove a heart drop
  if (
    g.g.Difficulty == Difficulty.DIFFICULTY_HARD -- 1
    and pickupVariant == PickupVariant.PICKUP_HEART -- 10
  ) then
    if rng:RandomInt(100) >= 35 then
      pickupVariant = PickupVariant.PICKUP_NULL -- 0
    end
  end

  -- Broken Modem has a chance to increase the amount of pickups that drop
  if (
    g.p:HasCollectible(CollectibleType.COLLECTIBLE_BROKEN_MODEM)
    and rng:RandomInt(4) == 0
    and pickupCount >= 1
    and (
      pickupVariant == PickupVariant.PICKUP_COIN -- 20
      or pickupVariant == PickupVariant.PICKUP_HEART -- 10
      or pickupVariant == PickupVariant.PICKUP_KEY -- 30
      or pickupVariant == PickupVariant.PICKUP_GRAB_BAG -- 69
      or pickupVariant == PickupVariant.PICKUP_BOMB -- 40
    )
  ) then
    pickupCount = pickupCount + 1
  end

  if (
    pickupCount > 0
    and pickupVariant ~= PickupVariant.PICKUP_NULL -- 0
  ) then
    local subType = 0
    for i = 1, pickupCount do
      local pos = g.r:FindFreePickupSpawnPosition(centerPos, 1, true)
      local pickup = g.g:Spawn(
        EntityType.ENTITY_PICKUP, -- 5
        pickupVariant,
        pos,
        g.zeroVector,
        nil,
        subType,
        rng:Next()
      )
      subType = pickup.SubType
    end
  end
end

return FastClear

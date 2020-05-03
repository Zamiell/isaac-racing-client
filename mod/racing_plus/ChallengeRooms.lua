local ChallengeRooms = {}

-- Racing+ replaces the vanilla Challenge Rooms with a custom version

-- Includes
local g         = require("racing_plus/globals")
local FastClear = require("racing_plus/fastclear")
local Schoolbag = require("racing_plus/schoolbag")

-- For normal waves, each wave is specified by entity type and number of entities to spawn
ChallengeRooms.normalWaves = {
  {
    -- Basement / Cellar / Burning Basement
    {EntityType.ENTITY_GAPER, 4}, -- 10
    {EntityType.ENTITY_HORF, 3}, -- 12
    {EntityType.ENTITY_POOTER, 5}, -- 14
    {EntityType.ENTITY_CLOTTY, 2}, -- 15
    {EntityType.ENTITY_ATTACKFLY, 5}, -- 18
    {EntityType.ENTITY_HOPPER, 3}, -- 29
    {EntityType.ENTITY_FATTY, 3}, -- 208
    {EntityType.ENTITY_DIP, 5}, -- 217
    {EntityType.ENTITY_ROUND_WORM, 3}, -- 244
  },
  {
    -- Caves / Catacombs / Flooded Caves
    {EntityType.ENTITY_HIVE, 3}, -- 22
    {EntityType.ENTITY_CHARGER, 5}, -- 23
    {EntityType.ENTITY_GLOBIN, 4}, -- 24
    {EntityType.ENTITY_MAW, 4}, -- 26
    {EntityType.ENTITY_HOST, 3}, -- 27
    {EntityType.ENTITY_SPITY, 5}, -- 31
    {EntityType.ENTITY_BONY, 2}, -- 227
    {EntityType.ENTITY_TUMOR, 2}, -- 229
    {EntityType.ENTITY_GRUB, 1}, -- 239
    {EntityType.ENTITY_WALL_CREEP, 3}, -- 240
    {EntityType.ENTITY_ROUND_WORM, 4}, -- 244
    {EntityType.ENTITY_NIGHT_CRAWLER, 3}, -- 255
  },
  {
    -- Depths / Necropolis / Dank Depths
    {EntityType.ENTITY_GLOBIN, 4}, -- 24
    {EntityType.ENTITY_HOPPER, 5}, -- 29
    {EntityType.ENTITY_LEAPER, 4}, -- 34
    {EntityType.ENTITY_BABY, 4}, -- 38
    {EntityType.ENTITY_VIS, 3}, -- 39
    {EntityType.ENTITY_KNIGHT, 4}, -- 41
    {EntityType.ENTITY_FAT_SACK, 3}, -- 209
    {EntityType.ENTITY_MOMS_HAND, 3}, -- 213
    {EntityType.ENTITY_SQUIRT, 2}, -- 220
    {EntityType.ENTITY_BONY, 4}, -- 227
    {EntityType.ENTITY_NULLS, 3}, -- 252
  },
  {
    -- Womb / Utero / Scarred Womb / Cathedral / Sheol
    {EntityType.ENTITY_CLOTTY, 5}, -- 15
    {EntityType.ENTITY_BRAIN, 5}, -- 32
    {EntityType.ENTITY_MRMAW, 4}, -- 35
    {EntityType.ENTITY_BABY, 5}, -- 38
    {EntityType.ENTITY_VIS, 5}, -- 39
    {EntityType.ENTITY_LEECH, 5}, -- 55
    {EntityType.ENTITY_LUMP, 5}, -- 56
    {EntityType.ENTITY_PARA_BITE, 5}, -- 58
    {EntityType.ENTITY_FRED, 5}, -- 59
    {EntityType.ENTITY_EYE, 5}, -- 60
    {EntityType.ENTITY_SWINGER, 5}, -- 216
    {EntityType.ENTITY_TUMOR, 5}, -- 229
    {EntityType.ENTITY_RAGE_CREEP, 4}, -- 241
    {EntityType.ENTITY_FLESH_MOBILE_HOST, 5}, -- 247
  },
}

-- For boss waves, each wave is specified by entity type and entity variant
ChallengeRooms.bossWaves = {
  {
    -- Basement / Cellar / Burning Basement
    {EntityType.ENTITY_LARRYJR, 0}, -- 19
    {EntityType.ENTITY_MONSTRO, 0}, -- 20
    {EntityType.ENTITY_PIN, 0}, -- 62
    {EntityType.ENTITY_FAMINE, 0}, -- 63
    {EntityType.ENTITY_DUKE, 0}, -- 67
    {EntityType.ENTITY_FISTULA_BIG, 0}, -- 71
    {EntityType.ENTITY_GEMINI, 0}, -- 79
    {EntityType.ENTITY_GEMINI, 1}, -- 79 (Steven)
    {EntityType.ENTITY_GEMINI, 2}, -- 79 (Blighted Ovum)
    {EntityType.ENTITY_WIDOW, 0}, -- 100
    {EntityType.ENTITY_GURGLING, 1}, -- 237 (boss variant)
    {EntityType.ENTITY_GURGLING, 2}, -- 237 (Turdlings)
    {EntityType.ENTITY_THE_HAUNT, 0}, -- 260
    {EntityType.ENTITY_DINGLE, 0}, -- 261
    {EntityType.ENTITY_DINGLE, 1}, -- 261 (Dangle)
    {EntityType.ENTITY_LITTLE_HORN, 0}, -- 404
    {EntityType.ENTITY_RAG_MAN, 0}, -- 405
  },
  {
    -- Caves / Catacombs / Flooded Caves
    {EntityType.ENTITY_LARRYJR, 1}, -- 19 (The Hollow)
    {EntityType.ENTITY_CHUB, 0}, -- 28
    {EntityType.ENTITY_CHUB, 1}, -- 28 (C.H.A.D.)
    {EntityType.ENTITY_CHUB, 2}, -- 28 (Carrion Queen)
    {EntityType.ENTITY_GURDY, 0}, -- 36
    {EntityType.ENTITY_PIN, 2}, -- 62 (Frail)
    {EntityType.ENTITY_PESTILENCE, 0}, -- 64
    {EntityType.ENTITY_DUKE, 1}, -- 67 (The Husk)
    {EntityType.ENTITY_PEEP, 0}, -- 68
    {EntityType.ENTITY_GURDY_JR, 0}, -- 99
    {EntityType.ENTITY_WIDOW, 1}, -- 100 (The Wretched)
    {EntityType.ENTITY_MEGA_MAW, 0}, -- 262
    {EntityType.ENTITY_MEGA_FATTY, 0}, -- 264
    {EntityType.ENTITY_DARK_ONE, 0}, -- 267
    {EntityType.ENTITY_POLYCEPHALUS, 0}, -- 269
    {EntityType.ENTITY_STAIN, 0}, -- 401
    {EntityType.ENTITY_FORSAKEN, 0}, -- 403
    {EntityType.ENTITY_RAG_MEGA, 0}, -- 409
    {EntityType.ENTITY_BIG_HORN, 0}, -- 411
  },
  {
    -- Depths / Necropolis / Dank Depths
    {EntityType.ENTITY_MONSTRO2, 0}, -- 43
    {EntityType.ENTITY_MONSTRO2, 1}, -- 43 (Gish)
    {EntityType.ENTITY_WAR, 0}, -- 65
    {EntityType.ENTITY_PEEP, 1}, -- 68 (The Bloat)
    {EntityType.ENTITY_LOKI, 0}, -- 69
    {EntityType.ENTITY_MASK_OF_INFAMY, 0}, -- 97
    {EntityType.ENTITY_GATE, 0}, -- 263
    {EntityType.ENTITY_CAGE, 0}, -- 265
    {EntityType.ENTITY_ADVERSARY, 0}, -- 268
    {EntityType.ENTITY_BROWNIE, 0}, -- 402
    {EntityType.ENTITY_SISTERS_VIS, 0}, -- 410
  },
  {
    -- Womb / Utero / Scarred Womb / Cathedral / Sheol
    {EntityType.ENTITY_PEEP, 1}, -- 68 (The Bloat)
    {EntityType.ENTITY_BLASTOCYST_BIG, 0}, -- 74
    {EntityType.ENTITY_DADDYLONGLEGS, 0}, -- 101
    {EntityType.ENTITY_DADDYLONGLEGS, 1}, -- 101 (Triachnid)
    {EntityType.ENTITY_LOKI, 1}, -- 69 (Lokii)
    {EntityType.ENTITY_MAMA_GURDY, 0}, -- 266
    {EntityType.ENTITY_MR_FRED, 0}, -- 270
    {EntityType.ENTITY_PIN, 1}, -- 62 (Scolex)
    {EntityType.ENTITY_FISTULA_BIG, 1}, -- 71 (Teratoma)
    {EntityType.ENTITY_WAR, 1}, -- 65 (War)
    {EntityType.ENTITY_DEATH, 0}, -- 66
    {EntityType.ENTITY_SISTERS_VIS, 0}, -- 410
    {EntityType.ENTITY_MATRIARCH, 0}, -- 413
  },
}

ChallengeRooms.delay = 15 -- The amount of frames to wait before spawning the next wave

function ChallengeRooms:PostUpdate()
  -- Local variables
  local roomType = g.r:GetType()

  if roomType ~= RoomType.ROOM_CHALLENGE then -- 11
    return
  end

  ChallengeRooms:CheckStart()
  ChallengeRooms:CheckSpawnNewWave()
end

function ChallengeRooms:CheckStart()
  if g.run.touchedPickup and
     not g.run.challengeRoom.started and
     not g.run.challengeRoom.finished then

    ChallengeRooms:Start()
  end
end

function ChallengeRooms:Start()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local stage = g.l:GetStage()
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"

  -- The "ambush" is active and we have not started the Challenge Room yet, so start spawning mobs
  g.run.challengeRoom.started = true
  g.run.challengeRoom.currentWave = 0
  Isaac.DebugString("Started the Challenge Room on frame: " .. tostring(gameFrameCount))

  -- Spawn a room clear delay NPC as a helper to keep the doors closed
  -- (otherwise, the doors will re-open on every frame)
  local roomClearDelayNPC = Isaac.Spawn(EntityType.ENTITY_ROOM_CLEAR_DELAY_NPC, 0, 0,
                                        g.zeroVector, g.zeroVector, nil)
  roomClearDelayNPC:ClearEntityFlags(EntityFlag.FLAG_APPEAR) -- 1 << 2
  roomClearDelayNPC.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE -- 0
  Isaac.DebugString("Spawned the \"Room Clear Delay NPC\" custom entity (for a Challenge Room).")

  -- Close the door
  local num = g.r:GetGridSize()
  for i = 1, num do
    local gridEntity = g.r:GetGridEntity(i)
    if gridEntity ~= nil then
      local door = gridEntity:ToDoor()
      if door ~= nil then
        door:Close(true)
      end
    end
  end

  -- Get the specific waves for this particular Challenge Room
  local waveType = math.ceil(stage / 2) -- e.g. Depths 1 is stage 5, which is wave type 3
  if waveType > 4 then
    -- Challenge Rooms in Cathedral & Sheol use Womb enemies/bosses
    waveType = 4
  end
  local possibleWaves
  local numWaves
  if stage % 2 == 0 then
    -- Boss Challenge Room
    possibleWaves = ChallengeRooms.bossWaves[waveType]
    numWaves = 2
  else
    -- Normal Challenge Room
    possibleWaves = ChallengeRooms.normalWaves[waveType]
    numWaves = 3
  end

  g.run.challengeRoom.waves = {}
  local seed = roomSeed
  while #g.run.challengeRoom.waves < numWaves do
    seed = g:IncrementRNG(seed)
    math.randomseed(seed)
    local waveIndex = math.random(1, #possibleWaves)
    local wave = possibleWaves[waveIndex]

    -- Check to see if we already chose this wave
    local valid = true
    for i = 1, #g.run.challengeRoom.waves do
      -- We compare both the first and second values in case this is a Boss Challenge Room
      local alreadyChosenWave = g.run.challengeRoom.waves[i]
      if wave[1] == alreadyChosenWave[1] and
         wave[2] == alreadyChosenWave[2] then

        valid = false
        break
      end
    end

    if valid then
      g.run.challengeRoom.waves[#g.run.challengeRoom.waves + 1] = wave
      Isaac.DebugString("Chose wave #" .. tostring(waveIndex) .. ".")
    end
  end
end

function ChallengeRooms:CheckSpawnNewWave()
  if not g.run.challengeRoom.started then
    return
  end

  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()

  -- Don't do anything if we are in the short delay between waves
  if g.run.challengeRoom.spawnWaveFrame ~= 0 then
    if gameFrameCount >= g.run.challengeRoom.spawnWaveFrame then
      g.run.challengeRoom.spawnWaveFrame = 0
      ChallengeRooms:SpawnWave()
    end
    return
  end

  -- Find out whether it is time to spawn the next wave
  -- When the Challenge Room is active, the "Room Clear Delay NPC" boss will always be present,
  -- which is why we check for equal to 1
  local spawnNextWave = false
  if FastClear.aliveEnemiesCount == 1 then
    -- Every enemy is dead, but also check to see if any splitting enemies exist
    local splittingEnemyExists = false
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
      for _, splittingEntity in ipairs(g.splittingBosses) do
        if entity.Type == splittingEntity then
          splittingEnemyExists = true
          break
        end
      end
      if splittingEnemyExists then
        break
      end
    end
    if splittingEnemyExists then
      return
    end

    -- No splitting enemies exist, so consider the Challenge Room finished
    spawnNextWave = true
    Isaac.DebugString("Challenge Room wave " .. tostring(g.run.challengeRoom.currentWave) ..
                      " finished on frame: " .. tostring(gameFrameCount))
  end
  if not spawnNextWave then
    return
  end

  -- The wave is clear, so give a charge to the active item(s)
  -- (unless we are just starting the Challenge Room)
  if g.run.challengeRoom.currentWave > 0 then
    FastClear:AddCharge()
    Schoolbag:AddCharge()
    FastClear:IncrementBagFamiliars()
    FastClear:CheckBagFamiliars()
  end

  -- Find out if the Challenge Room is over
  if g.run.challengeRoom.currentWave >= #g.run.challengeRoom.waves then
    ChallengeRooms:Finish()
  else
    -- Spawn the next wave after a short delay
    if g.run.challengeRoom.currentWave > 0 then
      Isaac.DebugString("Bosses defeated on frame: " .. tostring(gameFrameCount))
    end
    g.run.challengeRoom.spawnWaveFrame = gameFrameCount + ChallengeRooms.delay
    g.run.challengeRoom.currentWave = g.run.challengeRoom.currentWave + 1
    Isaac.DebugString("Marking to spawn the next wave on frame: " .. tostring(g.run.challengeRoom.spawnWaveFrame))
  end
end

-- ModCallbacks.MC_POST_NEW_ROOM (19)
function ChallengeRooms:PostNewRoom()
  -- Local variables
  local roomType = g.r:GetType()

  if roomType ~= RoomType.ROOM_CHALLENGE then -- 11
    g.run.challengeRoom.started = false
    g.run.challengeRoom.currentWave = 0
    return
  end

  -- Ensure that the vanilla Challenge Room does not activate by setting it to be already cleared
  g.r:SetAmbushDone(true)

  -- If we already started the Challenge Room and did not finish it,
  -- and are now returning to the room, then start spawning the waves again from the beginning
  if g.run.challengeRoom.started and
     not g.run.challengeRoom.finished then

    g.run.challengeRoom.currentWave = 0
    g.run.challengeRoom.spawnWaveFrame = 0
    ChallengeRooms:Start()
  end
end

function ChallengeRooms:SpawnWave()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local stage = g.l:GetStage()

  -- For groups of 2
  local wavePositions2 = {
    g:GridToPos(1, 3), -- Near the left door
    g:GridToPos(11, 3), -- Near the right door
  }

  -- For groups of 3 enemies
  local wavePositions3 = {
    g:GridToPos(1, 1), -- Top left corner
    g:GridToPos(1, 5), -- Bottom left corner
    g:GridToPos(11, 3), -- Near the right door
  }

  -- For groups of 4 enemies or 5 enemies
  local wavePositions5 = {
    g:GridToPos(1, 1), -- Top left corner
    g:GridToPos(11, 1), -- Top right corner
    g:GridToPos(1, 5), -- Bottom left corner
    g:GridToPos(11, 5), -- Bottom right corner
    g.r:GetCenterPos(),
  }

  -- For normal waves, each wave is specified by entity type and number of entities to spawn
  -- For boss waves, each wave is specified by entity type and entity variant
  local wave = g.run.challengeRoom.waves[g.run.challengeRoom.currentWave]
  local bossChallengeRoom = false
  local numEnemiesInWave = wave[2]
  if stage % 2 == 0 then
    -- Boss Challenge Room
    bossChallengeRoom = true
    numEnemiesInWave = 1
  end

  for i = 1, numEnemiesInWave do
    -- We might need to spawn multiple of some bosses
    local numToSpawn = 1
    if wave[1] == EntityType.ENTITY_LARRYJR then -- 19
      -- Larry Jr. and The Hollow have 10 segments
      numToSpawn = 10
    elseif wave[1] == EntityType.ENTITY_GURGLING then -- 237
      -- Gurglings and Turdlings spawn in sets of 2
      -- (this is how it is in vanilla Challenge Rooms)
      numToSpawn = 2
    end

    for j = 1, numToSpawn do
      local position
      for k = 1, 100 do
        -- Get a position to spawn the enemy at
        if bossChallengeRoom or numEnemiesInWave == 1 then
          position = g.r:FindFreePickupSpawnPosition(g.r:GetCenterPos(), k, true)
        elseif numEnemiesInWave == 2 then
          position = g.r:FindFreePickupSpawnPosition(wavePositions2[i], k, true)
        elseif numEnemiesInWave == 3 then
          position = g.r:FindFreePickupSpawnPosition(wavePositions3[i], k, true)
        else
          position = g.r:FindFreePickupSpawnPosition(wavePositions5[i], k, true)
        end

        -- Ensure that we do not spawn a boss too close to the player
        if position:Distance(g.p.Position) > 120 then
          break
        end
      end

      if wave[1] == EntityType.ENTITY_MAMA_GURDY then -- 266
        -- Hard code Mama Gurdy to spawn at the top of the room to prevent glitchy behavior
        position = g:GridToPos(6, 0)
      end

      if bossChallengeRoom then
        Isaac.Spawn(wave[1], wave[2], 0, position, g.zeroVector, nil)
      else
        Isaac.Spawn(wave[1], 0, 0, position, g.zeroVector, nil)
      end
    end
  end

  -- Play the summon sound
  g.sfx:Play(SoundEffect.SOUND_SUMMONSOUND, 1, 0, false, 1) -- 265

  Isaac.DebugString("Spawned wave " .. tostring(g.run.challengeRoom.currentWave) ..
                    " on frame: " .. tostring(gameFrameCount))
end

function ChallengeRooms:Finish()
  g.run.challengeRoom.started = false
  g.run.challengeRoom.finished = true
  Isaac.DebugString("Custom Challenge Room finished.")

  -- Spawn a random room drop
  g.r:SpawnClearAward()

  -- Open the door
  local num = g.r:GetGridSize()
  for i = 1, num do
    local gridEntity = g.r:GetGridEntity(i)
    if gridEntity ~= nil then
      local door = gridEntity:ToDoor()
      if door ~= nil then
        -- Doing "door:Open()" does not work
        if not door:IsOpen() then
          door:TryUnlock(true)
          g.sfx:Stop(SoundEffect.SOUND_UNLOCK00) -- 156
        end
      end
    end
  end

  -- Play the sound effect for the doors opening
  g.sfx:Play(SoundEffect.SOUND_DOOR_HEAVY_OPEN, 1, 0, false, 1) -- 36
end

return ChallengeRooms

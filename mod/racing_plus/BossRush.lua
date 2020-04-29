local BossRush = {}

-- Racing+ replaces the vanilla Boss Rush with a custom version

-- Includes
local g         = require("racing_plus/globals")
local FastClear = require("racing_plus/fastclear")
local Schoolbag = require("racing_plus/schoolbag")

-- This is the pool to pull random bosses from
BossRush.bosses = {
  {19, 0}, -- Larry Jr.
  {19, 1}, -- The Hollow
  {20, 0}, -- Monstro
  {28, 0}, -- Chub
  {28, 1}, -- C.H.A.D.
  {28, 2}, -- Carrion Queen
  {36, 0}, -- Gurdy
  {43, 0}, -- Monstro II
  {43, 1}, -- Gish
  {62, 0}, -- Pin
  {62, 2}, -- Frail
  {63, 0}, -- Famine
  {64, 0}, -- Pestilence
  {65, 0}, -- War
  {65, 1}, -- Conquest
  {66, 0}, -- Death
  {67, 0}, -- The Duke of Flies
  {67, 1}, -- The Husk
  {68, 0}, -- Peep
  {68, 1}, -- The Bloat
  {69, 0}, -- Loki
  {69, 1}, -- Lokii
  {71, 0}, -- Fistula
  {71, 1}, -- Teratoma
  {74, 0}, -- Blastocyst
  {79, 0}, -- Gemini
  {79, 1}, -- Steven
  {79, 2}, -- The Blighted Ovum
  {81, 0}, -- The Fallen
  {82, 0}, -- The Headless Horseman
  {97, 0}, -- Mask of Infamy
  {99, 0}, -- Gurdy Jr.
  {100, 0}, -- Widow
  {100, 1}, -- The Wretched
  {101, 0}, -- Daddy Long Legs
  {101, 1}, -- Triachnid
  {237, 1}, -- Gurglings
  {237, 2}, -- Turdling
  {260, 0}, -- The Haunt
  {261, 0}, -- Dingle
  {261, 1}, -- Dangle
  {262, 0}, -- Mega Maw
  {263, 0}, -- The Gate
  {264, 0}, -- Mega Fatty
  {265, 0}, -- The Cage
  {266, 0}, -- Mama Gurdy
  {267, 0}, -- Dark One
  {268, 0}, -- The Adversary
  {269, 0}, -- Polycephalus
  {270, 0}, -- Mr. Fred
  {271, 0}, -- Uriel
  {272, 0}, -- Gabriel
  {401, 0}, -- The Stain
  {402, 0}, -- Brownie
  {403, 0}, -- The Forsaken
  {404, 0}, -- Little Horn
  {405, 0}, -- Rag Man
  {409, 0}, -- Rag Mega
  {410, 0}, -- Sisters Vis
  {411, 0}, -- Big Horn
  {413, 0}, -- The Matriarch
}

-- Other constants
BossRush.totalBosses = 30 -- In vanilla, it spawns 2 bosses at a time for 15 waves
BossRush.delay = 20 -- The amount of frames to wait before spawning the next wave

-- ModCallbacks.MC_POST_UPDATE (1)
function BossRush:PostUpdate()
  -- Local variables
  local roomType = g.r:GetType()

  if roomType ~= RoomType.ROOM_BOSSRUSH then -- 17
    return
  end

  BossRush:CheckStart()
  BossRush:CheckSpawnNewWave()
end

function BossRush:CheckStart()
  if not g.p:IsItemQueueEmpty() and
     not g.run.bossRush.started and
     not g.run.bossRush.finished then

    BossRush:Start()
  end
end

function BossRush:Start()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local roomDescriptor = g.l:GetCurrentRoomDesc()
  local roomData = roomDescriptor.Data
  local roomVariant = roomData.Variant
  local startSeed = g.seeds:GetStartSeed()

  -- We have touched an item and have not started the Boss Rush yet, so start spawning mobs
  g.run.bossRush.started = true
  g.run.bossRush.currentWave = 0
  Isaac.DebugString("Started the Boss Rush on frame: " .. tostring(gameFrameCount))

  -- Spawn a room clear delay NPC as a helper to keep the doors closed
  -- (otherwise, the doors will re-open on every frame)
  local roomClearDelayNPC = Isaac.Spawn(EntityType.ENTITY_ROOM_CLEAR_DELAY_NPC, 0, 0,
                                        g:GridToPos(0, 0), g.zeroVector, nil)
  roomClearDelayNPC:ClearEntityFlags(EntityFlag.FLAG_APPEAR) -- 1 << 2
  Isaac.DebugString("Spawned the \"Room Clear Delay NPC\" custom entity (for the Boss Rush).")

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

  -- Calculate the bosses for each wave
  g.run.bossRush.bosses = {}
  local seed = startSeed
  while #g.run.bossRush.bosses < BossRush.totalBosses do
    seed = g:IncrementRNG(seed)
    math.randomseed(seed)
    local bossIndex = math.random(1, #BossRush.bosses)
    local boss = BossRush.bosses[bossIndex]

    -- Check to see if we already chose this boss
    local valid = true
    for i = 1, #g.run.bossRush.bosses do
      local alreadyChosenBoss = g.run.bossRush.bosses[i]
      if boss[1] == alreadyChosenBoss[1] and
         boss[2] == alreadyChosenBoss[2] then

        valid = false
        break
      end
    end

    -- Check to see if the boss would be blocked by rocks at the top of the screen
    if roomVariant == 3 and
       (boss[1] == EntityType.ENTITY_THE_HAUNT or -- 260
        boss[1] == EntityType.ENTITY_MAMA_GURDY or -- 266
        boss[1] == EntityType.ENTITY_MEGA_MAW or -- 262
        boss[1] == EntityType.ENTITY_GATE) then -- 263

      valid = false
    end

    if valid then
      g.run.bossRush.bosses[#g.run.bossRush.bosses + 1] = boss
    end
  end
end

function BossRush:CheckSpawnNewWave()
  if not g.run.bossRush.started then
    return
  end

  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local challenge = Isaac.GetChallenge()
  local bossesPerWave = 2
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    bossesPerWave = 3
  end
  local totalBossesDefeatedIfWaveIsClear = g.run.bossRush.currentWave * bossesPerWave

  -- Don't do anything if we are in the short delay between waves
  if g.run.bossRush.spawnWaveFrame ~= 0 then
    if gameFrameCount >= g.run.bossRush.spawnWaveFrame then
      g.run.bossRush.spawnWaveFrame = 0
      BossRush:SpawnWave(bossesPerWave)
    end
    return
  end

  -- Find out whether it is time to spawn the next wave
  -- If this is the final wave, then we only want to proceed if every enemy is killed (not just the bosses)
  -- When the Boss Rush is active, the "Room Clear Delay NPC" boss will always be present,
  -- which is why we check for equal to 1 instead of equal to 0
  local spawnNextWave = false
  if totalBossesDefeatedIfWaveIsClear >= BossRush.totalBosses then
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

      -- No splitting enemies exist, so consider the Boss Rush finished
      spawnNextWave = true
      Isaac.DebugString("All bosses killed on frame: " .. tostring(gameFrameCount))
    end
  elseif FastClear.aliveBossesCount == 0 then
    spawnNextWave = true
    Isaac.DebugString("Bosses for this wave were defeated on frame: " .. tostring(gameFrameCount))
  end
  if not spawnNextWave then
    return
  end

  -- All of the bosses for this wave have been defeated, so give a charge to the active item(s)
  -- (unless we are just starting the Boss Rush)
  if g.run.bossRush.currentWave > 0 then
    FastClear:AddCharge()
    Schoolbag:AddCharge()
    FastClear:IncrementBagFamiliars()
    FastClear:CheckBagFamiliars()
  end

  -- Find out if the Boss Rush is over
  Isaac.DebugString("Total bosses defeated so far: " .. tostring(totalBossesDefeatedIfWaveIsClear))
  if totalBossesDefeatedIfWaveIsClear >= BossRush.totalBosses then
    BossRush:Finish()
  else
    -- Spawn the next wave after a short delay
    if g.run.bossRush.currentWave > 0 then
      Isaac.DebugString("Bosses defeated on frame: " .. tostring(gameFrameCount))
    end
    g.run.bossRush.spawnWaveFrame = gameFrameCount + BossRush.delay
    g.run.bossRush.currentWave = g.run.bossRush.currentWave + 1
    Isaac.DebugString("Marking to spawn the next wave on frame: " .. tostring(g.run.bossRush.spawnWaveFrame))
  end
end

-- ModCallbacks.MC_POST_NEW_ROOM (19)
function BossRush:PostNewRoom()
  -- Local variables
  local roomType = g.r:GetType()

  if roomType ~= RoomType.ROOM_BOSSRUSH then -- 17
    g.run.bossRush.started = false
    g.run.bossRush.currentWave = 0
    return
  end

  -- Ensure that the vanilla Challenge Room does not activate by setting it to be already cleared
  g.r:SetAmbushDone(true)

  -- If we already started the Boss Rush and did not finish it,
  -- and are now returning to the room, then start spawning the waves again from the beginning
  if g.run.bossRush.started and
     not g.run.bossRush.finished then

    g.run.bossRush.currentWave = 0
    g.run.bossRush.spawnWaveFrame = 0
    BossRush:Start()
  end
end

function BossRush:SpawnWave(bossesPerWave)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()

  local bossPos = {
    g:GridToPos(7, 6), -- Left of the items
    g:GridToPos(18, 7), -- Right of the items
    g:GridToPos(12, 2), -- Above the items
    --g:GridToPos(13, 11), -- Below the items (currently unused)
  }

  for i = 1, bossesPerWave do
    -- Get the boss to spawn
    local bossIndex = g.run.bossRush.currentWave * bossesPerWave - bossesPerWave + i
    local boss = g.run.bossRush.bosses[bossIndex]

    -- Find out how many to spawn
    local numToSpawn = 1
    if boss[1] == EntityType.ENTITY_LARRYJR then -- 19
      -- Larry Jr. and The Hollow have 10 segments
      numToSpawn = 10
    elseif boss[1] == EntityType.ENTITY_GURGLING then -- 237
      -- Gurglings and Turdlings spawn in sets of 3
      -- (this is how it is in the vanilla Boss Rush)
      numToSpawn = 3
    end

    for j = 1, numToSpawn do
      local position
      for k = 1, 100 do
        -- If this is the first boss, spawn it to the left of the items
        -- If this is the second boss, spawn it to the right of the items
        -- If this is the third boss, spawn it above the items
        position = g.r:FindFreePickupSpawnPosition(bossPos[i], k, true)

        -- However, ensure that we do not spawn a boss too close to the player
        if position:Distance(g.p.Position) > 120 then
          break
        end
      end

      if boss[1] == EntityType.ENTITY_MAMA_GURDY then -- 266
        -- Hard code Mama Gurdy to spawn at the top of the room to prevent glitchy behavior
        position = g:GridToPos(12, 0)
      end

      Isaac.Spawn(boss[1], boss[2], 0, position, g.zeroVector, nil)
    end
  end

  -- Play the summon sound
  g.sfx:Play(SoundEffect.SOUND_SUMMONSOUND, 1, 0, false, 1) -- 265

  -- Display the wave number as streak text
  local totalWaves = math.floor(BossRush.totalBosses / bossesPerWave)
  g.run.streakText = "Wave " .. tostring(g.run.bossRush.currentWave) .. " / " .. tostring(totalWaves)
  g.run.streakFrame = Isaac.GetFrameCount()

  Isaac.DebugString("Spawned wave " .. tostring(g.run.bossRush.currentWave) ..
                    " on frame: " .. tostring(gameFrameCount))
end

function BossRush:Finish()
  -- Local variables
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"
  local centerPos = g.r:GetCenterPos()
  local challenge = Isaac.GetChallenge()

  g.run.bossRush.started = false
  g.run.bossRush.finished = true
  g.g:SetStateFlag(GameStateFlag.STATE_BOSSRUSH_DONE, true)
  Isaac.DebugString("Custom Boss Rush finished.")

  local pos = g.r:FindFreePickupSpawnPosition(g.r:GetCenterPos(), 1, true)
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    -- Spawn a big chest (which will get replaced with either a checkpoint or a trophy on the next frame)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, 0, -- 5.340
                centerPos, g.zeroVector, nil)

  elseif g.race.status == "in progress" and
         g.race.goal == "Boss Rush" then

    -- Spawn a big chest (which will get replaced with a trophy on the next frame)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, 0, -- 5.340
                centerPos, g.zeroVector, nil)

  else
    -- Spawn a random item
    g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pos, g.zeroVector, nil, 0, roomSeed) -- 5.100
  end

  -- Open the door
  local num = g.r:GetGridSize()
  for i = 1, num do
    local gridEntity = g.r:GetGridEntity(i)
    if gridEntity ~= nil then
      local door = gridEntity:ToDoor()
      if door ~= nil then
        door:Open()
      end
    end
  end

  -- Play the sound effect for the doors opening
  g.sfx:Play(SoundEffect.SOUND_DOOR_HEAVY_OPEN, 1, 0, false, 1) -- 36

  -- Announce the completion via streak text
  g.run.streakText = "Complete!"
  g.run.streakFrame = Isaac.GetFrameCount()
end

return BossRush

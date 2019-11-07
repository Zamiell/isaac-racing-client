local BossRush = {}

-- Includes
local g = require("racing_plus/globals")
local FastClear = require("racing_plus/fastclear")
local Schoolbag = require("racing_plus/schoolbag")
local Speedrun = require("racing_plus/speedrun")

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
  {62, 1}, -- Scolex
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
  if g.run.bossRush.started or
     not g.r:IsAmbushActive() then

    return
  end

  BossRush:Start()
end

function BossRush:Start()
  -- We spawn an invisible boss in the center of the room that has no collision;
  -- this will prevent the normal Boss Rush waves from spawning
  -- (this has to be above the below finish check)
  Isaac.Spawn(EntityType.ENTITY_ROOM_CLEAR_DELAY_NPC, 0, 0, g:GridToPos(0, 0), g.zeroVector, nil)

  -- Prevent the bug where the door will erroneously close if the player completes the custom Boss Rush,
  -- exits the room, re-enters the room, and takes an item
  if g.run.bossRush.finished then
    BossRush:OpenDoor()
    return
  end

  g.run.bossRush.started = true
  g.run.bossRush.currentWave = 0
  Isaac.DebugString("Started the Boss Rush.")

  -- Local variables
  local startSeed = g.seeds:GetStartSeed()

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
  local totalBossesDefeated = g.run.bossRush.currentWave * bossesPerWave

  -- Find out whether it is time to spawn the next wave
  -- If this is the final wave, then we only want to proceed if every enemy is killed (not just the bosses)
  -- When the boss rush is active, the "Room Clear Delay NPC" boss will always be present,
  -- which is why we check for equal to 1
  local spawnNextWave = false
  if totalBossesDefeated >= BossRush.totalBosses then
    if FastClear.aliveEnemiesCount == 1 then
      spawnNextWave = true
    end
  elseif FastClear.aliveBossesCount == 1 then
    spawnNextWave = true
  end
  if not spawnNextWave then
    return
  end

  if g.run.bossRush.spawnWaveFrame ~= 0 then
    if gameFrameCount >= g.run.bossRush.spawnWaveFrame then
      -- The short delay has elapsed, so spawn the next wave
      g.run.bossRush.spawnWaveFrame = 0
      BossRush:SpawnWave(bossesPerWave)
    end

    -- All of the bosses are dead, but we are waiting for a short delay before spawning the next wave
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
  Isaac.DebugString("Total bosses defeated: " .. tostring(totalBossesDefeated))
  if totalBossesDefeated >= BossRush.totalBosses then
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
  local challenge = Isaac.GetChallenge()

  if roomType ~= RoomType.ROOM_BOSSRUSH then
    return
  end

  -- Reset the Boss Rush status
  -- (so that we can reset the waves to the beginning if they exit the room, save and quit, etc.)
  g.run.bossRush.started = false
  g.run.bossRush.currentWave = 0
  g.run.bossRush.spawnWaveFrame = 0

  -- Check to see the player already started the Boss Rush
  local collectibles = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 5.100
                                        -1, false, false)
  if not g.run.bossRush.finished and
     #collectibles == 0 and
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") and
     g:TableContains(Speedrun.remainingGoals, "Boss Rush") then

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

  Isaac.DebugString("Spawned wave " .. tostring(g.run.bossRush.currentWave) ..
                    " on frame: " .. tostring(gameFrameCount))
end

function BossRush:Finish()
  -- Local variables
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"
  local challenge = Isaac.GetChallenge()

  g.run.bossRush.started = false
  g.run.bossRush.finished = true
  g.g:SetStateFlag(GameStateFlag.STATE_BOSSRUSH_DONE, true)
  Isaac.DebugString("Custom Boss Rush finished.")

  local pos = g.r:FindFreePickupSpawnPosition(g.r:GetCenterPos(), 1, true)
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    -- Spawn a big chest (which will get replaced with either a checkpoint or a trophy on the next frame)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, 0, -- 5.340
                g.zeroVector, g.zeroVector, nil) -- It does not matter where we spawn it since it will be replaced

  elseif g.race.status == "in progress" and
         g.race.goal == "Boss Rush" then

    -- Spawn a big chest (which will get replaced with a trophy on the next frame)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, 0, -- 5.340
                g.zeroVector, g.zeroVector, nil) -- It does not matter where we spawn it since it will be replaced

  else
    -- Spawn a random item
    g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pos, g.zeroVector, nil, 0, roomSeed) -- 5.100
  end

  -- Open the door
  BossRush:OpenDoor()

  -- Play the sound effect for the doors opening
  g.sfx:Play(SoundEffect.SOUND_DOOR_HEAVY_OPEN, 1, 0, false, 1) -- 36
end

function BossRush:OpenDoor()
  local num = g.r:GetGridSize()
  for i = 1, num do
    local gridEntity = g.r:GetGridEntity(i)
    if gridEntity ~= nil then
      if gridEntity:ToDoor() ~= nil then
        local door = gridEntity:ToDoor()
        door:Open()
      end
    end
  end
end

return BossRush

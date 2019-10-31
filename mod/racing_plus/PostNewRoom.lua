
local PostNewRoom = {}

-- Includes
local g                   = require("racing_plus/globals")
local Race                = require("racing_plus/race")
local FastClear           = require("racing_plus/fastclear")
local FastTravel          = require("racing_plus/fasttravel")
local Speedrun            = require("racing_plus/speedrun")
local SpeedrunPostNewRoom = require("racing_plus/speedrunpostnewroom")
local ChangeCharOrder     = require("racing_plus/changecharorder")
local ChangeKeybindings   = require("racing_plus/changekeybindings")
local Sprites             = require("racing_plus/sprites")
local SeededDeath         = require("racing_plus/seededdeath")
local SeededRooms         = require("racing_plus/seededrooms")
local BossRush            = require("racing_plus/bossrush")
local Samael              = require("racing_plus/samael")

-- ModCallbacks.MC_POST_NEW_ROOM (19)
function PostNewRoom:Main()
  -- Update some cached API functions to avoid crashing
  g.l = g.g:GetLevel()
  g.r = g.g:GetRoom()
  g.p = g.g:GetPlayer(0)
  g.seeds = g.g:GetSeeds()
  g.itemPool = g.g:GetItemPool()

  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomDesc = g.l:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant

  Isaac.DebugString("MC_POST_NEW_ROOM - " .. tostring(roomStageID) .. "." .. tostring(roomVariant))

  -- Make sure the callbacks run in the right order
  -- (naturally, PostNewRoom gets called before the PostNewLevel and PostGameStarted callbacks)
  if gameFrameCount == 0 or
     g.run.currentFloor ~= stage or
     g.run.currentFloorType ~= stageType then

    -- Make an exception if we are using the "goto" command to go to a debug room
    if g.run.goingToDebugRoom and
       roomStageID == 2 and
       roomVariant == 0 then

      g.run.goingToDebugRoom = false
    else
      return
    end
  end

  PostNewRoom:NewRoom()
end

function PostNewRoom:NewRoom()
  -- Local variables
  local roomDesc = g.l:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant
  local roomType = g.r:GetType()
  local roomClear = g.r:IsClear()
  local character = g.p:GetPlayerType()
  local activeCharge = g.p:GetActiveCharge()
  local maxHearts = g.p:GetMaxHearts()
  local soulHearts = g.p:GetSoulHearts()
  local boneHearts = g.p:GetBoneHearts()

  Isaac.DebugString("MC_POST_NEW_ROOM2 - " .. tostring(roomStageID) .. "." .. tostring(roomVariant))

  g.run.roomsEntered = g.run.roomsEntered + 1
  g.run.currentRoomClearState = roomClear
  -- This is needed so that we don't get credit for clearing a room when
  -- bombing from a room with enemies into an empty room

  -- Check to see if we need to remove the heart container from a Strength card on Keeper
  -- (this has to be above the resetting of the "g.run.usedStrength" variable)
  if character == PlayerType.PLAYER_KEEPER and -- 14
     g.run.keeper.baseHearts == 4 and
     g.run.usedStrength then

    g.run.keeper.baseHearts = 2
    g.p:AddMaxHearts(-2, true) -- Take away a heart container
    Isaac.DebugString("Took away 1 heart container from Keeper (via a Strength card). (PostNewRoom)")
  end

  -- Clear variables that track things per room
  g:InitRoom()

  -- Clear fast-clear variables that track things per room
  FastClear.buttonsAllPushed = false
  FastClear.roomInitializing = false
  -- (this is set to true when the room frame count is -1 and set to false here, where the frame count is 0)

  -- Check to see if we need to fix the Wraith Skull + Hairpin bug
  Samael:CheckHairpin()

  -- Check to see if we need to respawn trapdoors / crawlspaces / beams of light
  FastTravel:CheckRoomRespawn()

  -- Check if we are just arriving on a new floor
  FastTravel:CheckTrapdoor2()

  -- Check for miscellaneous crawlspace bugs
  FastTravel:CheckCrawlspaceMiscBugs()

  -- Remove the "More Options" buff if they have entered a Treasure Room
  if g.run.removeMoreOptions == true and
     roomType == RoomType.ROOM_TREASURE then -- 4

    g.run.removeMoreOptions = false
    g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) -- 414
  end

  -- Check health (to fix the bug where we don't die at 0 hearts)
  -- (this happens if Keeper uses Guppy's Paw or when Magdalene takes a devil deal that grants soul/black hearts)
  if maxHearts == 0 and
     soulHearts == 0 and
     boneHearts == 0 and
     not g.run.seededSwap.swapping and -- Make an exception if we are manually swapping health values
     InfinityTrueCoopInterface == nil then -- Make an exception if the True Co-op mod is on

    g.p:Kill()
    Isaac.DebugString("Manually killing the player since they are at 0 hearts.")
  end

  -- Make the Schoolbag work properly with the Glowing Hour Glass
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) then
    -- Recharge our active item if we used the Glowing Hour Glass
    if g.run.schoolbag.nextRoomCharge then
      g.run.schoolbag.nextRoomCharge = false
      g.p:SetActiveCharge(g.run.schoolbag.lastRoomSlot1Charges)
    end

    -- Keep track of our last Schoolbag item
    g.run.schoolbag.lastRoomItem = g.run.schoolbag.item
    g.run.schoolbag.lastRoomSlot1Charges = activeCharge
    g.run.schoolbag.lastRoomSlot2Charges = g.run.schoolbag.charge
  end

  -- Check for the Boss Rush
  BossRush:PostNewRoom()

  -- Check for the Satan room
  PostNewRoom:CheckSatanRoom()

  -- Check to see if we are entering the Mega Satan room so we can update the floor tracker and
  -- prevent cheating on the "Everything" race goal
  PostNewRoom:CheckMegaSatanRoom()

  -- Check for all of the Scolex boss rooms
  PostNewRoom:CheckScolexRoom()

  -- Check for the unavoidable puzzle room in the Dank Depths
  PostNewRoom:CheckDepthsPuzzle()

  -- Check for various NPCs
  PostNewRoom:CheckEntities()

  -- Check to see if we need to respawn an end-of-race or end-of-speedrun trophy
  PostNewRoom:CheckRespawnTrophy()

  -- Certain formats ban the Treasure Room in Basement 1
  PostNewRoom:BanB1TreasureRoom()

  -- Check for the custom challenges
  ChangeCharOrder:PostNewRoom()
  ChangeKeybindings:PostNewRoom()

  -- Do race related stuff
  PostNewRoom:Race()

  -- Do speedrun related stuff
  SpeedrunPostNewRoom:Main()
end

-- Instantly spawn the first part of the fight (there is an annoying delay before The Fallen and the leeches spawn)
function PostNewRoom:CheckSatanRoom()
  -- Local variables
  local roomDesc = g.l:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant
  local roomClear = g.r:IsClear()
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"
  local challenge = Isaac.GetChallenge()

  if roomClear then
    return
  end

  if roomStageID ~= 0 or roomVariant ~= 3600 then -- Satan
    return
  end

  -- In the season 3 speedrun challenge, there is a custom boss instead of Satan
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") then
    return
  end

  local seed = roomSeed
  seed = g:IncrementRNG(seed)
  g.g:Spawn(EntityType.ENTITY_LEECH, 1, g:GridToPos(5, 3), g.zeroVector, nil, 0, seed) -- 55.1 (Kamikaze Leech)
  seed = g:IncrementRNG(seed)
  g.g:Spawn(EntityType.ENTITY_LEECH, 1, g:GridToPos(7, 3), g.zeroVector, nil, 0, seed) -- 55.1 (Kamikaze Leech)
  seed = g:IncrementRNG(seed)
  g.g:Spawn(EntityType.ENTITY_FALLEN, 0, g:GridToPos(6, 3), g.zeroVector, nil, 0, seed) -- 81.0 (The Fallen)

  -- Prime the statue to wake up quicker
  local satans = Isaac.FindByType(EntityType.ENTITY_SATAN, -1, -1, false, false) -- 84
  for _, satan in ipairs(satans) do
    satan:ToNPC().I1 = 1
  end

  Isaac.DebugString("Spawned the first wave manually and primed the statue.")
end

-- Check to see if we are entering the Mega Satan room so we can update the floor tracker and
-- prevent cheating on the "Everything" race goal
function PostNewRoom:CheckMegaSatanRoom()
  -- Local variables
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end

  -- Check to see if we are entering the Mega Satan room
  if roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
    return
  end

  -- Emulate reaching a new floor, using a custom floor number of 13 (The Void is 12)
  Isaac.DebugString('Entered the Mega Satan room.')

  -- Check to see if we are cheating on the "Everything" race goal
  if g.race.goal == "Everything" and
     not g.run.killedLamb then

    -- Do a little something fun
    g.sfx:Play(SoundEffect.SOUND_THUMBS_DOWN, 1, 0, false, 1) -- 267
    for i = 1, 20 do
      local pos = g.r:FindFreePickupSpawnPosition(g.p.Position, 50, true)
      -- Use a value of 50 to spawn them far from the player
      local monstro = Isaac.Spawn(EntityType.ENTITY_MONSTRO, 0, 0, pos, g.zeroVector, nil)
      monstro.MaxHitPoints = 1000000
      monstro.HitPoints = 1000000
    end
  end
end

function PostNewRoom:CheckScolexRoom()
  -- Local variables
  local roomDesc = g.l:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant
  local roomClear = g.r:IsClear()
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"
  local challenge = Isaac.GetChallenge()

  -- We don't need to modify Scolex if the room is already cleared
  if roomClear then
    return
  end

  -- We only need to check for rooms from the "Special Rooms" STB
  if roomStageID ~= 0 then
    return
  end

  -- Don't do anything if we are not in one of the Scolex boss rooms
  -- (there are no Double Trouble rooms with Scolexes)
  if roomVariant ~= 1070 and
     roomVariant ~= 1071 and
     roomVariant ~= 1072 and
     roomVariant ~= 1073 and
     roomVariant ~= 1074 and
     roomVariant ~= 1075 then

    return
  end

  if g.race.rFormat == "seeded" or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") then

     -- Since Scolex attack patterns ruin seeded races, delete it and replace it with two Frails
    -- (there are 10 Scolex entities)
    local scolexes = Isaac.FindByType(EntityType.ENTITY_PIN, 1, -1, false, false) -- 62.1 (Scolex)
    for _, scolex in ipairs(scolexes) do
      scolex:Remove() -- This takes a game frame to actually get removed
    end

    local seed = roomSeed
    for i = 1, 2 do
      -- We don't want to spawn both of them on top of each other since that would make them behave a little glitchy
      local pos = g.r:GetCenterPos()
      if i == 1 then
        pos.X = pos.X - 150
      elseif i == 2 then
        pos.X = pos.X + 150
      end
      -- Note that pos.X += 200 causes the hitbox to appear too close to the left/right side,
      -- causing damage if the player moves into the room too quickly
      seed = g:IncrementRNG(seed)
      local frail = g.g:Spawn(EntityType.ENTITY_PIN, 2, pos, g.zeroVector, nil, 0, seed)
      frail.Visible = false -- It will show the head on the first frame after spawning unless we do this
      -- The game will automatically make the entity visible later on
    end
    Isaac.DebugString("Spawned 2 replacement Frails for Scolex.")
  end
end

-- Prevent unavoidable damage in a specific room in the Dank Depths
function PostNewRoom:CheckDepthsPuzzle()
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomDesc = g.l:GetCurrentRoomDesc()
  local roomVariant = roomDesc.Data.Variant
  local gridSize = g.r:GetGridSize()

  -- We only need to check if we are in the Dank Depths
  if stage ~= 5 and
     stage ~= 6 then

    return
  end
  if stageType ~= 2 then
    return
  end

  if roomVariant ~= 41 and
     roomVariant ~= 10041 and -- (flipped)
     roomVariant ~= 20041 and -- (flipped)
     roomVariant ~= 30041 then -- (flipped)

    return
  end

  -- Scan the entire room to see if any rocks were replaced with spikes
  for i = 1, gridSize do
    local gridEntity = g.r:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState()
      if saveState.Type == GridEntityType.GRID_SPIKES then -- 17
        -- Remove the spikes
        gridEntity.Sprite = Sprite() -- If we don't do this, it will still show for a frame
        g.r:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work

        -- Originally, we would add a rock here with:
        -- "Isaac.GridSpawn(GridEntityType.GRID_ROCK, 0, gridEntity.Position, true) -- 17"
        -- However, this results in invisible collision persisting after the rock is killed
        -- This bug can probably be subverted by waiting a frame for the spikes to fully despawn,
        -- but then having rocks spawn "out of nowhere" would look glitchy,
        -- so just remove the spikes and don't do anything else
        Isaac.DebugString("Removed spikes from the Dank Depths bomb puzzle room.")
      end
    end
  end
end

-- Check for various NPCs all at once
-- (we want to loop through all of the entities in the room only once to maximize performance)
function PostNewRoom:CheckEntities()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local roomClear = g.r:IsClear()
  local roomShape = g.r:GetRoomShape()
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"
  local character = g.p:GetPlayerType()

  local subvertTeleport = false
  for _, entity in ipairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_GURDY or -- 36
       entity.Type == EntityType.ENTITY_MOM or -- 45
       entity.Type == EntityType.ENTITY_MOMS_HEART then -- 78 (this includes It Lives!)

      subvertTeleport = true
      if entity.Type == EntityType.ENTITY_MOM then -- 45
        g.run.forceMomStomp = true
      end

    elseif entity.Type == EntityType.ENTITY_SLOTH or -- Sloth (46.0) and Super Sloth (46.1)
           entity.Type == EntityType.ENTITY_PRIDE then -- Pride (52.0) and Super Pride (52.1)

      -- Replace all Sloths / Super Sloths / Prides / Super Prides with a new one that has an InitSeed equal to the room
      -- (we want the card drop to always be the same if there happens to be more than one in the room;
      -- in vanilla the type of card that drops depends on the order you kill them in)
      g.g:Spawn(entity.Type, entity.Variant, entity.Position, entity.Velocity, entity.Parent, entity.SubType, roomSeed)
      entity:Remove()

    elseif entity.Type == EntityType.ENTITY_THE_HAUNT and
           entity.Variant == 0 then -- Haunt (260.0)

      -- Speed up the first Lil' Haunt attached to a Haunt (1/3)
      -- Later on this frame, the Lil' Haunts will spawn and have their state altered
      -- in the "PostNPCInit:Main()" function
      -- We will mark to actually detach one of them one frame from now
      -- (or two of them, if there are two Haunts in the room)
      g.run.speedLilHauntsFrame = gameFrameCount + 1

      -- We also need to check for the black champion version of The Haunt,
      -- since both of his Lil' Haunts should detach at the same time
      if entity:ToNPC():GetBossColorIdx() == 17 then
        g.run.speedLilHauntsBlack = true
      end
    end
  end

  -- Subvert the disruptive teleportation from Gurdy, Mom, Mom's Heart, and It Lives
  if subvertTeleport and
     not roomClear and
     roomShape == RoomShape.ROOMSHAPE_1x1 then -- 1
     -- (there are Double Trouble rooms with Gurdy but they don't cause a teleport)

     g.run.teleportSubverted = true

    -- Make the player invisible or else it will show them on the teleported position for 1 frame
    -- (we can't just move the player here because the teleport occurs after this callback finishes)
    g.run.teleportSubvertScale = g.p.SpriteScale
    g.p.SpriteScale = g.zeroVector
    -- (we actually move the player on the next frame in the "PostRender:CheckSubvertTeleport()" function)

    -- Also make the familiars invisible
    -- (for some reason, we can use the "Visible" property instead of
    -- resorting to "SpriteScale" like we do for the player)
    local familiars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, -1, -1, false, false) -- 3
    for _, familiar in ipairs(familiars) do
      familiar.Visible = false
    end

    -- If we are The Soul, the Forgotten body will also need to be teleported
    -- However, if we change its position manually, it will just warp back to the same spot on the next frame
    -- Thus, just manually switch to the Forgotten to avoid this bug
    if character == PlayerType.PLAYER_THESOUL then -- 17
      g.run.switchForgotten = true
    end

    Isaac.DebugString("Subverted a position teleport (1/2).")
  end
end

-- Check to see if we need to respawn an end-of-race or end-of-speedrun trophy
function PostNewRoom:CheckRespawnTrophy()
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end
  local roomType = g.r:GetType()
  local roomClear = g.r:IsClear()

  -- There are only trophies on The Chest or the Dark Room
  if stage ~= 11 then
    return
  end

  -- If the room is not clear, we couldn't have already finished the race/speedrun
  if not roomClear then
    return
  end

  -- All races finish in some sort of boss room
  if roomType ~= RoomType.ROOM_BOSS then -- 5
    return
  end

  -- From here on out, handle custom speedrun challenges and races separately
  if Speedrun:InSpeedrun() then
    -- All of the custom speedrun challenges end at the Blue Baby room or The Lamb room
    if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
      return
    end

     -- Don't respawn the trophy if the player just finished a R+9/14 speedrun
    if Speedrun.finished then
      return
    end

    -- Don't respawn the trophy if the player is in the middle of a R+9/14 speedrun
    if Speedrun.spawnedCheckpoint then
      return
    end

  elseif not g.raceVars.finished and
         g.race.status == "in progress" then

    -- Check to see if we are in the final room corresponding to the goal
    if g.race.goal == "Blue Baby" then
      if stageType == 0 or roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then
        return
      end

    elseif g.race.goal == "The Lamb" then
      if stageType == 1 or roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then
        return
      end

    elseif g.race.goal == "Mega Satan" then
      if roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then
        return
      end

    elseif g.race.goal == "Everything" then
      if stageType == 1 or roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then
        return
      end
    end

  else
    -- We are not in a custom speedrun challenge and not in a race
    return
  end

  -- We are re-entering a boss room after we have already spawned the trophy (which is a custom entity),
  -- so we need to respawn it
  Isaac.Spawn(EntityType.ENTITY_RACE_TROPHY, 0, 0, g.r:GetCenterPos(), g.zeroVector, nil)
  Isaac.DebugString("Respawned the end of race trophy.")
end

function PostNewRoom:BanB1TreasureRoom()
  if not Race:CheckBanB1TreasureRoom() then
    return
  end

  -- Delete the doors to the Basement 1 treasure room, if any
  -- (this includes the doors in a Secret Room)
  local treasureIndex = g.l:QueryRoomTypeIndex(RoomType.ROOM_TREASURE, false, RNG()) -- 4
  local door
  for i = 0, 7 do
    door = g.r:GetDoor(i)
    if door ~= nil and
        door.TargetRoomIndex == treasureIndex then

      g.r:RemoveDoor(i)
    end
  end

  -- Delete the icon on the map
  -- (this has to be done on every room, because it will reappear)
  local treasureRoom = g.l:GetRoomByIdx(treasureIndex)
  treasureRoom.DisplayFlags = 0
  g.l:UpdateVisibility() -- Setting the display flag will not actually update the map
end

function PostNewRoom:Race()
  -- Local variables
  local stage = g.l:GetStage()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end
  local roomDesc = g.l:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant
  local roomType = g.r:GetType()
  local roomClear = g.r:IsClear()
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"
  local gridSize = g.r:GetGridSize()

  -- Remove the final place graphic if it is showing
  Sprites:Init("place2", 0)

  -- Go to the custom "Race Start" room
  if (g.race.status == "open" or
      g.race.status == "starting") then

    if g.run.roomsEntered == 1 then
      Isaac.ExecuteCommand("stage 1a") -- The Cellar is the cleanest floor
      g.run.goingToDebugRoom = true
      Isaac.ExecuteCommand("goto d.0") -- We do more things in the next "PostNewRoom" callback
    elseif g.run.roomsEntered == 2 then
      PostNewRoom:RaceStartRoom()
    end
    return
  end

  -- Check for the special death condition
  SeededDeath:PostNewRoom()
  SeededDeath:PostNewRoomCheckSacrificeRoom()

  -- Check for rooms that should be manually seeded during seeded races
  SeededRooms:PostNewRoom()

  -- Prevent players from skipping a floor by using the I AM ERROR room on Womb 2 on the "Everything" race goal
  if stage == 8 and
     roomType == RoomType.ROOM_ERROR and -- 3
     g.race.goal == "Everything" then

    for i = 1, gridSize do
      local gridEntity = g.r:GetGridEntity(i)
      if gridEntity ~= nil then
        local saveState = gridEntity:GetSaveState()
        if saveState.Type == GridEntityType.GRID_TRAPDOOR then -- 17
          -- Remove the crawlspace and spawn a Heaven Door (1000.39), which will get replaced on the next frame
          -- in the "FastTravel:ReplaceHeavenDoor()" function
          -- Make the spawner entity the player so that we can distinguish it from the vanilla heaven door
          g.r:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
          Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, 0, -- 1000.39
                      gridEntity.Position, g.zeroVector, g.p)
          Isaac.DebugString("Stopped the player from skipping Cathedral from the I AM ERROR room.")
        end
      end
    end
  end

  -- Check to see if we need to open the Mega Satan Door
  if (g.race.goal == "Mega Satan" or
      g.raceVars.finished or
      (g.race.goal == "Everything") and
       g.run.killedLamb) and
     stage == 11 and -- If this is The Chest or Dark Room
     roomIndex == g.l:GetStartingRoomIndex() then

    local door = g.r:GetDoor(1) -- The top door is always 1
    door:TryUnlock(true)
    g.sfx:Stop(SoundEffect.SOUND_UNLOCK00) -- 156
    -- door:IsOpen() is always equal to false here for some reason,
    -- so just open it every time we enter the room and silence the sound effect
    Isaac.DebugString("Opened the Mega Satan door.")
  end

  -- Check to see if we need to spawn Victory Lap bosses
  if g.raceVars.finished and
     not roomClear and
     roomStageID == 0 and
     (roomVariant == 3390 or -- Blue Baby
      roomVariant == 3391 or
      roomVariant == 3392 or
      roomVariant == 3393 or
      roomVariant == 5130) then -- The Lamb

    -- Replace Blue Baby / The Lamb with some random bosses (based on the number of Victory Laps)
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
      if entity.Type == EntityType.ENTITY_ISAAC or -- 102
         entity.Type == EntityType.ENTITY_THE_LAMB then -- 273

        entity:Remove()
      end
    end

    local randomBossSeed = roomSeed
    local numBosses = g.raceVars.victoryLaps + 1
    for i = 1, numBosses do
      randomBossSeed = g:IncrementRNG(randomBossSeed)
      math.randomseed(randomBossSeed)
      local randomBoss = g.bossArray[math.random(1, #g.bossArray)]
      if randomBoss[1] == EntityType.ENTITY_LARRYJR then -- 19
        -- Larry Jr. and The Hollow require multiple segments
        for j = 1, 6 do
          Isaac.Spawn(randomBoss[1], randomBoss[2], randomBoss[3], g.r:GetCenterPos(), g.zeroVector, nil)
        end
      else
        Isaac.Spawn(randomBoss[1], randomBoss[2], randomBoss[3], g.r:GetCenterPos(), g.zeroVector, nil)
      end
    end
    Isaac.DebugString("Replaced Blue Baby / The Lamb with " .. tostring(numBosses) .. " random bosses.")
  end

  PostNewRoom:CheckSeededMOTreasure()
end

function PostNewRoom:RaceStartRoom()
  -- Remove all enemies
  for _, entity in ipairs(Isaac.GetRoomEntities()) do
    local npc = entity:ToNPC()
    if npc ~= nil then
      entity:Remove()
    end
  end
  g.r:SetClear(true)

  -- We want to trap the player in the room, so delete all 4 doors
  for i = 0, 3 do
    g.r:RemoveDoor(i)
  end

  -- Put the player next to the bottom door
  local pos = Vector(320, 400)
  g.p.Position = pos

  -- Put familiars next to the bottom door, if any
  local familiars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, -1, -1, false, false) -- 3
  for _, familiar in ipairs(familiars) do
    familiar.Position = pos
  end

  -- Spawn two Gaping Maws (235.0)
  Isaac.Spawn(EntityType.ENTITY_GAPING_MAW, 0, 0, g:GridToPos(5, 5), g.zeroVector, nil)
  Isaac.Spawn(EntityType.ENTITY_GAPING_MAW, 0, 0, g:GridToPos(7, 5), g.zeroVector, nil)
end

function PostNewRoom:CheckSeededMOTreasure()
  -- Local variables
  local roomType = g.r:GetType()
  local gridSize = g.r:GetGridSize()
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"

  -- Check to see if we need to make a custom item room for Seeded MO
  if roomType == RoomType.ROOM_TREASURE and -- 4
     g.race.rFormat == "seededMO" then

    -- Delete everything in the room
    for i = 1, gridSize do
      local gridEntity = g.r:GetGridEntity(i)
      if gridEntity ~= nil then
        if gridEntity:GetSaveState().Type ~= GridEntityType.GRID_WALL and -- 15
           gridEntity:GetSaveState().Type ~= GridEntityType.GRID_DOOR then -- 16

          g.r:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
        end
      end
    end
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
      if entity.Type ~= EntityType.ENTITY_PLAYER then -- 1
        entity:Remove()
      end
    end

    -- Define the item pedestal positions
    local itemPos = {
      {
        {X = 6, Y = 3},
      },
      {
        {X = 5, Y = 3},
        {X = 7, Y = 3},
      },
      {
        {X = 4, Y = 3},
        {X = 6, Y = 3},
        {X = 8, Y = 3},
      },
      {
        {X = 5, Y = 2},
        {X = 7, Y = 2},
        {X = 5, Y = 4},
        {X = 7, Y = 4},
      },
      {
        {X = 5, Y = 2},
        {X = 7, Y = 2},
        {X = 4, Y = 4},
        {X = 6, Y = 4},
        {X = 8, Y = 4},
      },
      {
        {X = 4, Y = 2},
        {X = 6, Y = 2},
        {X = 8, Y = 2},
        {X = 4, Y = 4},
        {X = 6, Y = 4},
        {X = 8, Y = 4},
      },
    }

    -- Define the various item tiers
    local itemTiers = {
      {1, 2, 3, 4, 5},
      {6, 7, 8, 9, 10},
    }

    -- Find out which tier we need
    math.randomseed(roomSeed)
    local chosenTier = math.random(1, #itemTiers)

    -- Place the item pedestals (5.100)
    for i = 1, #itemTiers[chosenTier] do
      local X = itemPos[#itemTiers[chosenTier]][i].X
      local Y = itemPos[#itemTiers[chosenTier]][i].Y
      local itemID = itemTiers[chosenTier][i]
      local itemPedestal = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, itemID,
                                       g:GridToPos(X, Y), g.zeroVector, nil)
      -- (we don't care about the seed since the pedestal will be replaced on the next frame)
      itemPedestal:ToPickup().TheresOptionsPickup = true
    end
  end
end

return PostNewRoom

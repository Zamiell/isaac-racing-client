local RPPostNewRoom = {}

--
-- Includes
--

local RPGlobals    = require("src/rpglobals")
local RPFastClear  = require("src/rpfastclear")
local RPFastTravel = require("src/rpfasttravel")
local RPSpeedrun   = require("src/rpspeedrun")
local RPSprites    = require("src/rpsprites")
local SamaelMod    = require("src/rpsamael")

-- ModCallbacks.MC_POST_NEW_ROOM (19)
function RPPostNewRoom:Main()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  Isaac.DebugString("MC_POST_NEW_ROOM")

  -- Make an exception for the "Race Start Room" and the "Change Char Order" room
  RPPostNewRoom:RaceStart()
  RPSpeedrun:PostNewRoomChangeCharOrder()

  -- Make sure the callbacks run in the right order
  -- (naturally, PostNewRoom gets called before the PostNewLevel and PostGameStarted callbacks)
  if gameFrameCount == 0 or
     (RPGlobals.run.currentFloor ~= stage or
      RPGlobals.run.currentFloorType ~= stageType) then

    return
  end

  RPPostNewRoom:NewRoom()
end

function RPPostNewRoom:NewRoom()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomClear = room:IsClear()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()
  local activeCharge = player:GetActiveCharge()
  local maxHearts = player:GetMaxHearts()
  local soulHearts = player:GetSoulHearts()
  local challenge = Isaac.GetChallenge()

  Isaac.DebugString("MC_POST_NEW_ROOM2")

  RPGlobals.run.roomsEntered = RPGlobals.run.roomsEntered + 1
  RPGlobals.run.currentRoomClearState = roomClear
  -- This is needed so that we don't get credit for clearing a room when
  -- bombing from a room with enemies into an empty room

  -- Check to see if we need to remove the heart container from a Strength card on Keeper
  -- (this has to be above the resetting of the "RPGlobals.run.keeper.usedStrength" variable)
  if character == PlayerType.PLAYER_KEEPER and -- 14
     RPGlobals.run.keeper.baseHearts == 4 and
     RPGlobals.run.keeper.usedStrength then

    RPGlobals.run.keeper.baseHearts = 2
    player:AddMaxHearts(-2, true) -- Take away a heart container
    Isaac.DebugString("Took away 1 heart container from Keeper (via a Strength card).")
  end

  -- Clear variables that track things per room
  RPGlobals.run.currentGlobins    = {} -- Used for softlock prevention
  RPGlobals.run.currentKnights    = {} -- Used to delete invulnerability frames
  RPGlobals.run.currentLilHaunts  = {} -- Used to delete invulnerability frames
  RPGlobals.run.naturalTeleport   = false
  RPGlobals.run.handsDelay        = 0
  RPGlobals.run.megaSatanDead     = false
  RPGlobals.run.teleportSubverted = false
  RPGlobals.run.bossHearts = { -- Copied from RPGlobals
    spawn       = false,
    extra       = false,
    extraIsSoul = false,
    position    = {},
    velocity    = {},
  }
  RPGlobals.run.keeper.usedStrength = false

  -- Clear fast-clear variables that track things per room
  RPFastClear.buttonsAllPushed = false
  RPFastClear.roomInitializing = false
  -- (this is set to true when the room frame count is -1 and set to false here, where the frame count is 0)

  -- Check to see if we are entering the Mega Satan room
  if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
    -- Emulate reaching a new floor, using a custom floor number of 13 (The Void is 12)
    Isaac.DebugString('Entered the Mega Satan room.')
  end

  -- Check to see if we need to fix the Wraith Skull + Hairpin bug
  SamaelMod:CheckHairpin()

  -- Check to see if we need to respawn trapdoors / crawlspaces / beams of light
  RPFastTravel:CheckRoomRespawn()

  -- Check to see if we need to respawn a trophy
  if stage == 11 and
     roomType == RoomType.ROOM_BOSS and -- 5
     roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX and -- -7
     -- The Mega Satan room counts as a boss room, and we don't want to respawn any trophies there
     roomClear and
     RPGlobals.raceVars.finished == false and
     (RPGlobals.race.status == "in progress" or
      challenge == Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") or
      challenge == Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") or
      challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") or
      challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S3)")) and
     RPGlobals.race.goal ~= "Mega Satan" and
     RPGlobals.race.goal ~= "Everything" and
     -- We don't want to respawn any trophies if the player is supposed to kill Mega Satan
     -- (Mega Satan is also killed in the "Everything" race goal)
     RPSpeedrun.finished == false and -- Don't respawn the trophy if the player just finished a R+9/14 speedrun
     RPSpeedrun.spawnedCheckpoint == false then
     -- Don't respawn the trophy if the player is in the middle of a R+9/14 speedrun

    game:Spawn(Isaac.GetEntityTypeByName("Race Trophy"), Isaac.GetEntityVariantByName("Race Trophy"),
               room:GetCenterPos(), Vector(0, 0), nil, 0, 0)
    Isaac.DebugString("Respawned the end of race trophy.")
  end

  -- Check if we are just arriving on a new floor
  RPFastTravel:CheckTrapdoor2()

  -- Check for miscellaneous crawlspace bugs
  RPFastTravel:CheckCrawlspaceMiscBugs()

  -- Check health (to fix the bug where we don't die at 0 hearts)
  -- (this happens if Keeper uses Guppy's Paw or when Magdalene takes a devil deal that grants soul/black hearts)
  if maxHearts == 0 and soulHearts == 0 then
    player:Kill()
  end

  -- Make the Schoolbag work properly with the Glowing Hour Glass
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) then
    -- Recharge our active item if we used the Glowing Hour Glass
    if RPGlobals.run.schoolbag.nextRoomCharge then
      RPGlobals.run.schoolbag.nextRoomCharge = false
      player:SetActiveCharge(RPGlobals.run.schoolbag.lastRoomSlot1Charges)
    end

    -- Keep track of our last Schoolbag item
    RPGlobals.run.schoolbag.lastRoomItem = RPGlobals.run.schoolbag.item
    RPGlobals.run.schoolbag.lastRoomSlot1Charges = activeCharge
    RPGlobals.run.schoolbag.lastRoomSlot2Charges = RPGlobals.run.schoolbag.charges
  end

  -- Check for disruptive teleportation from Gurdy, Mom's Heart, or It Lives
  RPPostNewRoom:CheckSubvertTeleport()

  -- Check for the Satan room
  RPPostNewRoom:CheckSatanRoom()

  -- Check for all of the Scolex boss rooms
  RPPostNewRoom:CheckScolexRoom()

  -- Check for the unavoidable puzzle room in the Dank Depths
  RPPostNewRoom:CheckDepthsPuzzle()

  -- Check for double Sloths / Super Sloths / Pride / Super Prides
  RPPostNewRoom:CheckSlothPride()

  -- Do race related stuff
  RPPostNewRoom:Race()
end

-- Check for disruptive teleportation from Gurdy, Mom's Heart, or It Lives
function RPPostNewRoom:CheckSubvertTeleport()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomDesc = level:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant
  local room = game:GetRoom()
  local roomClear = room:IsClear()
  local player = game:GetPlayer(0)

  if roomClear == false and
     ((roomStageID == 0 and roomVariant == 1040) or -- Gurdy
      (roomStageID == 0 and roomVariant == 1041) or
      (roomStageID == 0 and roomVariant == 1042) or
      (roomStageID == 0 and roomVariant == 1043) or
      (roomStageID == 0 and roomVariant == 1044) or
      (roomStageID == 0 and roomVariant == 1058) or
      (roomStageID == 0 and roomVariant == 1059) or
      (roomStageID == 0 and roomVariant == 1065) or
      (roomStageID == 0 and roomVariant == 1066) or
      (roomStageID == 0 and roomVariant == 1130) or
      (roomStageID == 0 and roomVariant == 1131) or
      (roomStageID == 0 and roomVariant == 1080) or -- Mom's Heart
      (roomStageID == 0 and roomVariant == 1081) or
      (roomStageID == 0 and roomVariant == 1082) or
      (roomStageID == 0 and roomVariant == 1083) or
      (roomStageID == 0 and roomVariant == 1084) or
      (roomStageID == 0 and roomVariant == 1090) or -- It Lives!
      (roomStageID == 0 and roomVariant == 1091) or
      (roomStageID == 0 and roomVariant == 1092) or
      (roomStageID == 0 and roomVariant == 1093) or
      (roomStageID == 0 and roomVariant == 1094) or
      (roomStageID == 17 and roomVariant == 18)) then -- Gurdy (The Chest)

    -- Make the player invisible or else it will show them on the teleported position for 1 frame
    -- (we can't just move the player here because the teleport occurs after this callback finishes)
    RPGlobals.run.teleportSubverted = true
    RPGlobals.run.teleportSubvertScale = player.SpriteScale
    player.SpriteScale = Vector(0, 0)
    -- (we actually move the player on the next PostRender frame)
  end
end

function RPPostNewRoom:CheckSatanRoom()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomDesc = level:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant
  local room = game:GetRoom()
  local roomClear = room:IsClear()

  if roomClear == false and
     roomStageID == 0 and roomVariant == 3600 then -- Satan

    -- Instantly spawn the first part of the fight
    -- (the vanilla delay is very annoying)
    game:Spawn(EntityType.ENTITY_LEECH, 1, -- 55.1 (Kamikaze Leech)
               RPGlobals:GridToPos(5, 3), Vector(0, 0), nil, 0, 0)
    game:Spawn(EntityType.ENTITY_LEECH, 1, -- 55.1 (Kamikaze Leech)
               RPGlobals:GridToPos(7, 3), Vector(0, 0), nil, 0, 0)
    game:Spawn(EntityType.ENTITY_FALLEN, 0, -- 81.0 (The Fallen)
               RPGlobals:GridToPos(6, 3), Vector(0, 0), nil, 0, 0)

    -- Prime the statue to wake up quicker
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      if entity.Type == EntityType.ENTITY_SATAN then -- 84
        entity:ToNPC().I1 = 1
      end
    end

    Isaac.DebugString("Spawned the first wave manually and primed the statue.")
  end
end

function RPPostNewRoom:CheckScolexRoom()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local roomDesc = level:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant
  local room = game:GetRoom()
  local roomClear = room:IsClear()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"

  -- We don't need to modify Scolex if the room is already cleared
  if roomClear then
    return
  end

  -- We only need to check for rooms from the "Special Rooms" STB
  if roomStageID ~= 0 then
    return
  end

  -- Don't do anything if we are not in one of the Scolex boss rooms
  if roomVariant ~= 1070 and
     roomVariant ~= 1071 and
     roomVariant ~= 1072 and
     roomVariant ~= 1073 and
     roomVariant ~= 1074 and
     roomVariant ~= 1075 then

    return
  end

  if RPGlobals.race.rFormat == "seeded" then
    -- Since Scolex attack patterns ruin seeded races, delete it and replace it with two Frails
    -- (there are 10 Scolex entities)
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      if entity.Type == EntityType.ENTITY_PIN and entity.Variant == 1 then -- 62.1 (Scolex)
        entity:Remove() -- This takes a game frame to actually get removed
      end
    end

    for i = 1, 2 do
      -- We don't want to spawn both of them on top of each other since that would make them behave a little glitchy
      local pos = room:GetCenterPos()
      if i == 1 then
        pos.X = pos.X - 150
      elseif i == 2 then
        pos.X = pos.X + 150
      end
      -- Note that pos.X += 200 causes the hitbox to appear too close to the left/right side,
      -- causing damage if the player moves into the room too quickly
      local frail = game:Spawn(EntityType.ENTITY_PIN, 2, pos, Vector(0,0), nil, 0, roomSeed)
      frail.Visible = false -- It will show the head on the first frame after spawning unless we do this
      -- The game will automatically make the entity visible later on
    end
    Isaac.DebugString("Spawned 2 replacement Frails for Scolex with seed: " .. tostring(roomSeed))

  else
    -- Replace the bugged Scolex champion with the non-champion version (1/2)
    local foundBuggedChampion = false
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      if entity.Type == EntityType.ENTITY_PIN and entity.Variant == 1 and -- 62.1 (Scolex)
         entity:ToNPC():GetBossColorIdx() == 15 then -- The bugged black champion type

        foundBuggedChampion = true
        break
      end
    end
    if foundBuggedChampion then
      -- If we morph the Scolex right now, it won't do anything, because it takes 1 frame to actually spawn
      -- (right now there is 1 Scolex entity, but one frame from now there will be 10)
      -- So mark to morph it on the next frame
      RPGlobals.run.replaceBuggedScolex = gameFrameCount + 1
    end
  end
end

-- Prevent unavoidable damage in a specific room in the Dank Depths
function RPPostNewRoom:CheckDepthsPuzzle()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local roomDesc = level:GetCurrentRoomDesc()
  local roomVariant = roomDesc.Data.Variant
  local room = game:GetRoom()
  local gridSize = room:GetGridSize()

  -- We only need to check if we are in the Dank Depths
  if stage ~= LevelStage.STAGE3_2 and -- 6
     stageType ~= StageType.STAGETYPE_AFTERBIRTH then -- 2

    return
  end

  if roomVariant ~= 41 then
    return
  end

  -- Scan the entire room to see if any rocks were replaced with spikes
  for i = 1, gridSize do
    local gridEntity = room:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState()
      if saveState.Type == GridEntityType.GRID_SPIKES then -- 17
        -- Remove the spikes
        gridEntity.Sprite = Sprite() -- If we don't do this, it will still show for a frame
        room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work

        -- Originally, we would add a rock here with:
        --Isaac.GridSpawn(GridEntityType.GRID_ROCK, 0, gridEntity.Position, true) -- 17
        -- However, this results in invisible collision persisting after the rock is killed
        -- This bug can probably be subverted by waiting a frame for the spikes to fully despawn,
        -- but then having rocks spawn "out of nowhere" would look glitchy,
        -- so just remove the spikes and don't do anything else
        Isaac.DebugString("Removed spikes from the Dank Depths bomb puzzle room.")
      end
    end
  end
end

-- Check for more than one Sloth / Super Sloth / Pride / Super Prides
-- (we want the card drop to always be the same; in vanilla it will depend on the order you kill them in)
function RPPostNewRoom:CheckSlothPride()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomDesc = level:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant
  local room = game:GetRoom()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"

  if (roomStageID == 10 and roomVariant == 120) or -- Womb (Double Sloth)
     (roomStageID == 11 and roomVariant == 120) or -- Utero (Double Sloth)
     (roomStageID == 14 and roomVariant == 63) or -- Sheol (Double Sloth)
     (roomStageID == 14 and roomVariant == 64) or -- Sheol (Double Sloth)
     (roomStageID == 15 and roomVariant == 63) or -- Cathedral (Double Sloth)
     (roomStageID == 15 and roomVariant == 64) or -- Cathedral (Double Sloth)
     (roomStageID == 15 and roomVariant == 111) or -- Cathedral (Double Pride)
     (roomStageID == 15 and roomVariant == 133) or -- Cathedral (Quadruple Pride)
     (roomStageID == 16 and roomVariant == 30) or -- Dark Room (Triple Super Sloth)
     (roomStageID == 16 and roomVariant == 73) or -- Dark Room (Double Sloth + Double Super Sloth)
     (roomStageID == 17 and roomVariant == 8) then -- The Chest (Double Super Sloth)

    for i, entity in pairs(Isaac.GetRoomEntities()) do
      if entity.Type == EntityType.ENTITY_SLOTH or -- Sloth (46.0) and Super Sloth (46.1)
         entity.Type == EntityType.ENTITY_PRIDE then -- Pride (52.0) and Super Pride (52.1)

        -- Replace it with a new one that has an InitSeed equal to the room
        game:Spawn(entity.Type, entity.Variant, entity.Position, entity.Velocity,
                   entity.Parent, entity.SubType, roomSeed)

        -- Delete the old one
        entity:Remove()
      end
    end
  end
end

function RPPostNewRoom:Race()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local roomDesc = level:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant
  local roomType = room:GetType()
  local roomClear = room:IsClear()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
  local player = game:GetPlayer(0)
  local sfx = SFXManager()

  -- Remove the final place graphic if it is showing
  RPSprites:Init("place2", 0)

  -- Check to see if we need to remove More Options in a diversity race or an "Unseeded (Lite)" race
  if roomType == RoomType.ROOM_TREASURE and -- 4
     player:HasCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) and -- 414
     (RPGlobals.race.rFormat == "diversity" or
      RPGlobals.race.rFormat == "unseeded-lite") and
     RPGlobals.raceVars.removedMoreOptions == false then

    RPGlobals.raceVars.removedMoreOptions = true
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) -- 414
  end

  -- Check to see if we need to open the Mega Satan Door
  if (RPGlobals.race.goal == "Mega Satan" or
      RPGlobals.raceVars.finished or
      (RPGlobals.race.goal == "Everything") and
       RPGlobals.run.killedLamb) and
     stage == 11 and -- If this is The Chest or Dark Room
     roomIndex == level:GetStartingRoomIndex() then

    local door = room:GetDoor(1) -- The top door is always 1
    door:TryUnlock(true)
    sfx:Stop(SoundEffect.SOUND_UNLOCK00) -- 156
    -- door:IsOpen() is always equal to false here for some reason,
    -- so just open it every time we enter the room and silence the sound effect
    Isaac.DebugString("Opened the Mega Satan door.")
  end

  -- Check to see if we need to spawn Victory Lap bosses
  if RPGlobals.raceVars.finished and
     roomClear == false and
     roomStageID == 0 and
     (roomVariant == 3390 or -- Blue Baby
      roomVariant == 3391 or
      roomVariant == 3392 or
      roomVariant == 3393 or
      roomVariant == 5130) then -- The Lamb

    -- Replace Blue Baby / The Lamb with some random bosses (based on the number of Victory Laps)
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      if entity.Type == EntityType.ENTITY_ISAAC or -- 102
         entity.Type == EntityType.ENTITY_THE_LAMB then -- 273

        entity:Remove()
      end
    end

    local randomBossSeed = roomSeed
    local numBosses = RPGlobals.raceVars.victoryLaps + 1
    for i = 1, numBosses do
      randomBossSeed = RPGlobals:IncrementRNG(randomBossSeed)
      math.randomseed(randomBossSeed)
      local randomBoss = RPGlobals.bossArray[math.random(1, #RPGlobals.bossArray)]
      if randomBoss[1] == 19 then
        -- Larry Jr. and The Hollow require multiple segments
        for j = 1, 6 do
          game:Spawn(randomBoss[1], randomBoss[2], room:GetCenterPos(), Vector(0,0), nil, randomBoss[3], roomSeed)
        end
      else
        game:Spawn(randomBoss[1], randomBoss[2], room:GetCenterPos(), Vector(0,0), nil, randomBoss[3], roomSeed)
      end
    end
    Isaac.DebugString("Replaced Blue Baby / The Lamb with " .. tostring(numBosses) .. " random bosses.")
  end

  RPPostNewRoom:CheckSeededMOTreasure()
end

function RPPostNewRoom:RaceStart()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local room = game:GetRoom()
  local sfx = SFXManager()

  -- Set up the "Race Room"
  if gameFrameCount ~= 0 or
     roomIndex ~= GridRooms.ROOM_DEBUG_IDX or -- -3
     (RPGlobals.race.status ~= "open" and
      RPGlobals.race.status ~= "starting") then

    return
  end

  -- Stop the boss room sound effect
  sfx:Stop(SoundEffect.SOUND_CASTLEPORTCULLIS) -- 190

  -- We want to trap the player in the room,
  -- but we can't make a room with no doors because then the "goto" command would crash the game,
  -- so we have one door at the bottom
  room:RemoveDoor(3) -- The bottom door is always 3

  -- Spawn two Gaping Maws (235.0)
  game:Spawn(EntityType.ENTITY_GAPING_MAW, 0, RPGlobals:GridToPos(5, 5), Vector(0, 0), nil, 0, 0)
  game:Spawn(EntityType.ENTITY_GAPING_MAW, 0, RPGlobals:GridToPos(7, 5), Vector(0, 0), nil, 0, 0)
end

function RPPostNewRoom:CheckSeededMOTreasure()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local gridSize = room:GetGridSize()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"

  -- Check to see if we need to make a custom item room for Seeded MO
  if roomType == RoomType.ROOM_TREASURE and -- 4
     RPGlobals.race.rFormat == "seededMO" then

    -- Delete everything in the room
    for i = 1, gridSize do
      local gridEntity = room:GetGridEntity(i)
      if gridEntity ~= nil then
        if gridEntity:GetSaveState().Type ~= GridEntityType.GRID_WALL and -- 15
           gridEntity:GetSaveState().Type ~= GridEntityType.GRID_DOOR then -- 16

          room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
        end
      end
    end
    for i, entity in pairs(Isaac.GetRoomEntities()) do
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
      local itemPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE,
                                      RPGlobals:GridToPos(X, Y), Vector(0, 0), nil, itemID, 0)
      -- The seed can be 0 since the pedestal will be replaced on the next frame
      itemPedestal:ToPickup().TheresOptionsPickup = true
    end
  end
end

return RPPostNewRoom

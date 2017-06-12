local RPCallbacks = {}

--
-- Includes
--

local RPGlobals    = require("src/rpglobals")
local RPFastClear  = require("src/rpfastclear")
local RPFastTravel = require("src/rpfasttravel")
local RPSpeedrun   = require("src/rpspeedrun")
local RPSprites    = require("src/rpsprites")
local SamaelMod    = require("src/rpsamael")

--
-- Miscellaneous game callbacks
--

-- ModCallbacks.MC_EVALUATE_CACHE (8)
function RPCallbacks:EvaluateCache(player, cacheFlag)
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local character = player:GetPlayerType()
  local maxHearts = player:GetMaxHearts()
  local coins = player:GetNumCoins()
  local coinContainers = 0

  --
  -- Manage Keeper's heart containers
  --

  if character == PlayerType.PLAYER_KEEPER and -- 14
     cacheFlag == CacheFlag.CACHE_RANGE then -- 8

    -- Find out how many coin containers we should have
    -- (2 is equal to 1 actual heart container)
    if coins >= 99 then
      coinContainers = 8
    elseif coins >= 75 then
      coinContainers = 6
    elseif coins >= 50 then
      coinContainers = 4
    elseif coins >= 25 then
      coinContainers = 2
    end
    local baseHearts = maxHearts - coinContainers

    -- We have to add the range cache to all health up items
    --   12  - Magic Mushroom (already has range cache)
    --   15  - <3
    --   16  - Raw Liver (gives 2 containers)
    --   22  - Lunch
    --   23  - Dinner
    --   24  - Dessert
    --   25  - Breakfast
    --   26  - Rotten Meat
    --   81  - Dead Cat
    --   92  - Super Bandage
    --   101 - The Halo (already has range cache)
    --   119 - Blood Bag
    --   121 - Odd Mushroom (Thick) (already has range cache)
    --   129 - Bucket of Lard (gives 2 containers)
    --   138 - Stigmata
    --   176 - Stem Cells
    --   182 - Sacred Heart (already has range cache)
    --   184 - Holy Grail
    --   189 - SMB Super Fan (already has range cache)
    --   193 - Meat!
    --   218 - Placenta
    --   219 - Old Bandage
    --   226 - Black Lotus
    --   230 - Abaddon
    --   253 - Magic Scab
    --   307 - Capricorn (already has range cache)
    --   312 - Maggy's Bow
    --   314 - Thunder Theighs
    --   334 - The Body (gives 3 containers)
    --   342 - Blue Cap
    --   346 - A Snack
    --   354 - Crack Jacks
    --   456 - Moldy Bread
    local HPItemArray = {
      12,  15,  16,  22,  23,
      24,  25,  26,  81,  92,
      101, 119, 121, 129, 138,
      176, 182, 184, 189, 193,
      218, 219, 226, 230, 253,
      307, 312, 314, 334, 342,
      346, 354, 456,
    }
    for i = 1, #HPItemArray do
      if player:HasCollectible(HPItemArray[i]) then
        if RPGlobals.run.keeper.healthItems[HPItemArray[i]] == nil then
          RPGlobals.run.keeper.healthItems[HPItemArray[i]] = true

          if HPItemArray[i] == CollectibleType.COLLECTIBLE_ABADDON then -- 230
            player:AddMaxHearts(-24, true) -- Remove all hearts
            player:AddMaxHearts(coinContainers, true) -- Give whatever containers we should have from coins
            player:AddHearts(24) -- This is needed because all the new heart containers will be empty
            -- We have no way of knowing what the current health was before, because "player:GetHearts()"
            -- returns 0 at this point. So, just give them max health.
            Isaac.DebugString("Set 0 heart containers to Keeper (Abaddon).")

          elseif HPItemArray[i] == CollectibleType.COLLECTIBLE_DEAD_CAT then -- 81
            player:AddMaxHearts(-24, true) -- Remove all hearts
            player:AddMaxHearts(2 + coinContainers, true) -- Give 1 heart container +
                                                          -- whatever containers we should have from coins
            player:AddHearts(24) -- This is needed because all the new heart containers will be empty
            -- We have no way of knowing what the current health was before, because "player:GetHearts()"
            -- returns 0 at this point. So, just give them max health.
            Isaac.DebugString("Set 1 heart container to Keeper (Dead Cat).")

          elseif baseHearts < 0 and
             HPItemArray[i] == CollectibleType.COLLECTIBLE_BODY then -- 334

            player:AddMaxHearts(6, true) -- Give 3 heart containers
            Isaac.DebugString("Gave 3 heart containers to Keeper.")

            -- Fill in the new containers
            player:AddCoins(1)
            player:AddCoins(1)
            player:AddCoins(1)

          elseif baseHearts < 2 and
                 (HPItemArray[i] == CollectibleType.COLLECTIBLE_RAW_LIVER or -- 16
                  HPItemArray[i] == CollectibleType.COLLECTIBLE_BUCKET_LARD or -- 129
                  HPItemArray[i] == CollectibleType.COLLECTIBLE_BODY) then -- 334

            player:AddMaxHearts(4, true) -- Give 2 heart containers
            Isaac.DebugString("Gave 2 heart containers to Keeper.")

            -- Fill in the new containers
            player:AddCoins(1)
            player:AddCoins(1)

          elseif baseHearts < 4 then
            player:AddMaxHearts(2, true) -- Give 1 heart container
            Isaac.DebugString("Gave 1 heart container to Keeper.")

            if HPItemArray[i] ~= CollectibleType.COLLECTIBLE_ODD_MUSHROOM_DAMAGE and -- 121
               HPItemArray[i] ~= CollectibleType.COLLECTIBLE_OLD_BANDAGE then -- 219

              -- Fill in the new container
              -- (Odd Mushroom (Thick) and Old Bandage do not give filled heart containers)
              player:AddCoins(1)
            end

          else
            Isaac.DebugString("Health up detected, but baseHearts are full.")
          end
        end
      end
    end
  end

  --
  -- Race stuff
  --

  -- Look for the custom start item that gives 13 luck
  if cacheFlag == CacheFlag.CACHE_LUCK and -- 1024
     player:HasCollectible(CollectibleType.COLLECTIBLE_13_LUCK) then

    player.Luck = player.Luck + 13
  end

  -- The Pageant Boy ruleset starts with 7 luck
  if cacheFlag == CacheFlag.CACHE_LUCK and -- 1024
     RPGlobals.race.rFormat == "pageant" then

    player.Luck = player.Luck + 7
  end

  -- In diversity races, Crown of Light should heal for a half heart
  -- (don't explicitly check for race format in case loading failed)
  if cacheFlag == CacheFlag.CACHE_SHOTSPEED and -- 4
     player:HasCollectible(CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT) and -- 415
     stage == 1 and
     roomType == RoomType.ROOM_TREASURE and -- 4
     -- (this will still work even if you exit the room with the item held overhead)
     (character == PlayerType.PLAYER_JUDAS or -- 3
      character == PlayerType.PLAYER_AZAZEL) then -- 7

    player:AddHearts(1)
  end
end

-- ModCallbacks.MC_POST_PLAYER_INIT (9)
-- (this will get called before the "PostGameStarted" callback)
function RPCallbacks:PostPlayerInit(player)
  -- Local variables
  local game = Game()
  local mainPlayer = game:GetPlayer(0)

  Isaac.DebugString("MC_POST_PLAYER_INIT")

  -- Check for co-op babies
  if player.Variant == 0 then
    return
  end

  -- A co-op baby spawned
  mainPlayer:AnimateSad() -- Play a sound effect to communicate that the player made a mistake
  player:Kill() -- This kills the co-op baby, but the main character will still get their health back for some reason

  -- Since the player gets their health back, it is still possible to steal devil deals, so remove all unpurchased
  -- Devil Room items in the room (which will have prices of either -1 or -2)
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_PICKUP and -- If this is a pedestal item (5.100)
       entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and
       entity:ToPickup().Price < 0 then

      entity:Remove()
    end
  end
end

-- ModCallbacks.MC_ENTITY_TAKE_DMG (11)
-- (this must return nil or false)
function RPCallbacks:EntityTakeDamage(tookDamage, damageAmount, damageFlag, damageSource, damageCountdownFrames)
  -- local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local player = tookDamage:ToPlayer()

  -- Check to see if it was the player that took damage
  if player ~= nil then
    -- Make us invincibile while interacting with a trapdoor
    if RPGlobals.run.trapdoor.state > 0 then
      return false
    end

    -- Prevent unavoidable damage from Mushrooms (when walking over skulls with Leo / Thunder Thighs)
    if damageSource.Type == EntityType.ENTITY_MUSHROOM and -- 300
       stage ~= LevelStage.STAGE2_1 and -- 3
       stage ~= LevelStage.STAGE2_2 then -- 4

      return false
    end

    local selfDamage = false
    for i = 0, 21 do -- There are 21 damage flags
      local bit = (damageFlag & (1 << i)) >> i

      -- Soul Jar damage tracking
      if (i == 5 or i == 18) and bit == 1 then -- 5 is DAMAGE_RED_HEARTS, 18 is DAMAGE_IV_BAG
        selfDamage = true
      end
    end
    if selfDamage == false then
      RPGlobals.run.levelDamaged = true
    end

    -- Betrayal (custom)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BETRAYAL_NOANIM) then
      for i, entity in pairs(Isaac.GetRoomEntities()) do
        local npc = entity:ToNPC()
        if npc ~= nil and npc:IsVulnerableEnemy() then
          npc:AddCharmed(150) -- 5 seconds
        end
      end
    end

  elseif damageSource.Type == EntityType.ENTITY_KNIFE then -- 8
    -- An enemy that took damage from a knife
    if RPGlobals.run.knife.isFlying then
      RPGlobals.run.knife.isMissed = false
    end
  end
end

-- ModCallbacks.MC_INPUT_ACTION (13)
function RPCallbacks:InputAction(entity, inputHook, buttonAction)
  -- Disable resetting if the countdown is close to hitting 0
  if RPGlobals.raceVars.resetEnabled == false and
     buttonAction == ButtonAction.ACTION_RESTART then -- 16

    return false
  end

  -- Disable using cards if we are in the trapdoor animation
  if RPGlobals.run.trapdoor.state > 0 and
     buttonAction == ButtonAction.ACTION_PILLCARD then -- 10

    return
  end
end

-- ModCallbacks.MC_POST_NEW_LEVEL (18)
function RPCallbacks:PostNewLevel()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  Isaac.DebugString("MC_POST_NEW_LEVEL")

  -- Make sure the callbacks run in the right order
  -- (naturally, PostNewLevel gets called before the PostGameStarted callbacks)
  if gameFrameCount == 0 then
    return
  end

  RPCallbacks:PostNewLevel2()
end

function RPCallbacks:PostNewLevel2()
  -- Local variables
  local game = Game()
  local itemPool = game:GetItemPool()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  Isaac.DebugString("MC_POST_NEW_LEVEL2")

  -- Find out if we performed a Sacrifice Room teleport
  if (RPGlobals.race.goal == "The Lamb" or
      RPGlobals.race.goal == "Mega Satan") and
     stage == 11 and stageType == 0 and -- 11.0 is Dark Room
     (RPGlobals.run.currentFloor ~= 10 and
      RPGlobals.run.currentFloor ~= 11) then -- This is necessary because of Forget Me Now

    -- We arrivated at the Dark Room without going through Sheol
    Isaac.DebugString("Sacrifice Room teleport detected.")
    RPFastTravel:GotoNextFloor(false, RPGlobals.run.currentFloor)
    -- The first argument is "upwards", the second argument is "redirect"
    return
  end

  -- Set the new floor
  RPGlobals.run.currentFloor = stage
  Isaac.DebugString("New floor: " .. tostring(RPGlobals.run.currentFloor))

  -- Reset some per level flags
  RPGlobals.run.levelDamaged = false
  RPGlobals.run.replacedPedestals = {}
  RPGlobals.run.replacedTrapdoors = {}
  RPGlobals.run.replacedCrawlspaces = {}
  RPGlobals.run.replacedHeavenDoors = {}

  -- Reset the RNG of some items that should be seeded per floor
  local floorSeed = level:GetDungeonPlacementSeed()
  RPGlobals.RNGCounter.Teleport = floorSeed
  RPGlobals.RNGCounter.Undefined = floorSeed
  RPGlobals.RNGCounter.Telepills = floorSeed
  for i = 1, 100 do
    -- Increment the RNG 100 times so that players cannot use knowledge of Teleport! teleports
    -- to determine where the Telepills destination will be
    RPGlobals.RNGCounter.Telepills = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.Telepills)
  end

  -- Start showing the place graphic if we get to Basement 2
  if stage >= 2 then
    RPGlobals.raceVars.showPlaceGraphic = true
  end

  -- Make sure that the diveristy placeholder items are removed
  if stage >= 2 then
    itemPool:RemoveCollectible(Isaac.GetItemIdByName("Diversity Placeholder #1"))
    itemPool:RemoveCollectible(Isaac.GetItemIdByName("Diversity Placeholder #2"))
    itemPool:RemoveCollectible(Isaac.GetItemIdByName("Diversity Placeholder #3"))
  end

  -- Call PostNewRoom manually (they get naturally called out of order)
  RPCallbacks:PostNewRoom2()
end

-- ModCallbacks.MC_POST_NEW_ROOM (19)
function RPCallbacks:PostNewRoom()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local stage = level:GetStage()

  Isaac.DebugString("MC_POST_NEW_ROOM")

  -- Make an exception for the "Race Start Room" and the "Change Char Order" room
  RPCallbacks:PostNewRoomRaceStart()
  RPSpeedrun:PostNewRoomChangeCharOrder()

  -- Make sure the callbacks run in the right order
  -- (naturally, PostNewRoom gets called before the PostNewLevel and PostGameStarted callbacks)
  if gameFrameCount == 0 or RPGlobals.run.currentFloor ~= stage then
    return
  end

  RPCallbacks:PostNewRoom2()
end

function RPCallbacks:PostNewRoom2()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local roomDesc = level:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomClear = room:IsClear()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
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
  RPGlobals.run.trapdoorCollision = nil
  RPGlobals.run.bossHearts = { -- Copied from RPGlobals
    spawn       = false,
    extra       = false,
    extraIsSoul = false,
    position    = {},
    velocity    = {},
  }
  RPGlobals.run.keeper.usedStrength = false
  RPFastClear.aliveEnemies = {}
  RPFastClear.aliveEnemiesCount = 0
  RPFastClear.buttonsAllPushed = false

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
      challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S2)")) and
     RPGlobals.race.goal ~= "Mega Satan" and
     -- We don't want to respawn any trophies if the player is supposed to kill Mega Satan
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
  RPCallbacks:CheckSubvertTeleport()

  -- Check for the Satan room
  RPCallbacks:CheckSatanRoom()

  -- Check for Scolex's room
  if roomClear == false and
     roomStageID == 0 and
     (roomVariant == 1070 or -- Scolex
      roomVariant == 1071 or
      roomVariant == 1072 or
      roomVariant == 1073 or
      roomVariant == 1074 or
      roomVariant == 1075) then

    if RPGlobals.race.rFormat == "seeded" and
       RPGlobals.race.status == "in progress" then

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
    end

  else
    -- Check to see if we need to replace the bugged Scolex champion with the non-champion version
    local foundBuggedChampion = false
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      if entity.Type == EntityType.ENTITY_PIN and entity.Variant == 1 and -- 62.1 (Scolex)
         entity:ToNPC():GetBossColorIdx() == 15 then -- The bugged black champion type

        foundBuggedChampion = true
        break
      end
    end
    if foundBuggedChampion then
      -- Remove all of the existing Scolexs (there are 10 Scolex entities)
      for i, entity in pairs(Isaac.GetRoomEntities()) do
        if entity.Type == EntityType.ENTITY_PIN and entity.Variant == 1 then -- 62.1 (Scolex)
          entity:Remove()
        end
      end

      -- Spawn a new one
      local scolex = game:Spawn(EntityType.ENTITY_PIN, 1, room:GetCenterPos(), Vector(0,0), nil, 0, roomSeed)
      scolex:ToNPC():Morph(EntityType.ENTITY_PIN, 1, 0, -1) -- 62.1 (Scolex)
      Isaac.DebugString("Fixed a black champion Scolex.")
    end
  end

  -- Do race related stuff
  RPCallbacks:PostNewRoomRace()
end

function RPCallbacks:PostNewRoomRace()
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

  -- Check to see if we need to remove More Options in a diversity race
  if roomType == RoomType.ROOM_TREASURE and -- 4
     player:HasCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) and -- 414
     RPGlobals.race.rFormat == "diversity" and
     RPGlobals.raceVars.removedMoreOptions == false then

    RPGlobals.raceVars.removedMoreOptions = true
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) -- 414
  end

  -- Check to see if we need to open the Mega Satan Door
  if (RPGlobals.race.goal == "Mega Satan" or
      RPGlobals.raceVars.finished) and
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

  RPCallbacks:CheckSeededMOTreasure()
end

-- Check for disruptive teleportation from Gurdy, Mom's Heart, or It Lives
function RPCallbacks:CheckSubvertTeleport()
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

function RPCallbacks:CheckSatanRoom()
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

function RPCallbacks:PostNewRoomRaceStart()
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

function RPCallbacks:CheckSeededMOTreasure()
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

return RPCallbacks

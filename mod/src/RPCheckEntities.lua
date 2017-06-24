local RPCheckEntities = {}

--
-- Includes
--

local RPGlobals    = require("src/rpglobals")
local RPSchoolbag  = require("src/rpschoolbag")
local RPFastTravel = require("src/rpfasttravel")
local RPSpeedrun   = require("src/rpspeedrun")
local SamaelMod    = require("src/rpsamael")

--
-- Variables
--

RPCheckEntities.fireworkActive = false

--
-- Check entities functions
--

-- Check all the grid entities in the room
-- (called from the PostUpdate callback)
function RPCheckEntities:Grid()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local gridSize = room:GetGridSize()

  for i = 1, gridSize do
    local gridEntity = room:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState();
      if saveState.Type == GridEntityType.GRID_TRAPDOOR and -- 17
         saveState.VarData == 1 then -- Void Portals have a VarData of 1

        -- Delete all Void Portals
        gridEntity.Sprite = Sprite() -- If we don't do this, it will still show for a frame
        room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work

      elseif saveState.Type == GridEntityType.GRID_TRAPDOOR then -- 17
        RPFastTravel:ReplaceTrapdoor(gridEntity, i)

      elseif saveState.Type == GridEntityType.GRID_STAIRS then -- 18
        RPFastTravel:ReplaceCrawlspace(gridEntity, i)

      elseif saveState.Type == GridEntityType.GRID_PRESSURE_PLATE then -- 20
        RPSpeedrun:CheckButtonPressed(gridEntity)
      end
    end
  end
end

-- Check all the non-grid entities in the room
-- (called from the PostUpdate callback)
function RPCheckEntities:NonGrid()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local room = game:GetRoom()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
  local player = game:GetPlayer(0)
  local sfx = SFXManager()
  local challenge = Isaac.GetChallenge()

  -- Go through all the entities
  RPCheckEntities.fireworkActive = false
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_BOMBDROP then -- 4
      RPCheckEntities:Entity4(entity)

    elseif entity.Type == EntityType.ENTITY_PICKUP then
      RPCheckEntities:Entity5(entity)

    elseif entity.Type == EntityType.ENTITY_KNIFE then -- 8
      RPCheckEntities:Entity8(entity)

    elseif entity.Type == EntityType.ENTITY_KNIGHT or -- 41
           entity.Type == EntityType.ENTITY_FLOATING_KNIGHT or -- 254
           entity.Type == EntityType.ENTITY_BONE_KNIGHT then -- 283

      RPCheckEntities:Entity41(entity)

    elseif entity.Type == EntityType.ENTITY_EYE then -- 60
      RPCheckEntities:Entity60(entity)

    elseif entity.Type == EntityType.ENTITY_THE_HAUNT then -- 260
      RPCheckEntities:Entity260(entity)

    elseif entity.Type == EntityType.ENTITY_EFFECT then -- 1000
      RPCheckEntities:Entity1000(entity)

    elseif entity.Type == Isaac.GetEntityTypeByName("Race Trophy") and -- 1001
           entity.Variant == Isaac.GetEntityVariantByName("Race Trophy") and -- 0
           RPGlobals.raceVars.finished == false and
           RPGlobals:InsideSquare(player.Position, entity.Position, 24) then -- 25 is a touch too big

      -- Check to see if we are touching the trophy
      entity:Remove()
      player:AnimateCollectible(CollectibleType.COLLECTIBLE_TROPHY, "Pickup", "PlayerPickupSparkle2")

      if challenge == Challenge.CHALLENGE_NULL then -- 0
        -- Finish the race
        Isaac.DebugString("Finished run.") -- The client looks for this line to know when the goal was achieved
        RPGlobals.raceVars.finished = true
        RPGlobals.raceVars.finishedTime = Isaac.GetTime() - RPGlobals.raceVars.startedTime

        -- Spawn a Victory Lap (a custom item that emulates Forget Me Now) in the corner of the room
        local victoryLapPosition = RPGlobals:GridToPos(11, 1)
        if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then
          victoryLapPosition = RPGlobals:GridToPos(11, 6) -- A Y of 1 is out of bounds inside of the Mega Satan room
        end
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, victoryLapPosition, Vector(0, 0),
                   nil, CollectibleType.COLLECTIBLE_VICTORY_LAP, roomSeed)

        -- Spawn a Finish (a custom item that takes you to the main menu) in the corner of the room
        local finishedPosition = RPGlobals:GridToPos(1, 1)
        if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then
          finishedPosition = RPGlobals:GridToPos(1, 6) -- A Y of 1 is out of bounds inside of the Mega Satan room
        end
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, finishedPosition, Vector(0, 0),
                   nil, CollectibleType.COLLECTIBLE_FINISHED, roomSeed)

        Isaac.DebugString("Spawned a Victory Lap / Finished in the corners of the room.")
      else
        RPSpeedrun:Finish()
      end
    end
  end

  -- Spawn seeded heart drops from bosses
  if RPGlobals.run.bossHearts.spawn then
    RPGlobals.run.bossHearts.spawn = false

    -- Random Heart - 5.10.0
    for i = 1, 2 do
      if i == 2 and RPGlobals.run.bossHearts.extra == false then
        break
      end

      -- Get the position of the heart
      local position = RPGlobals.run.bossHearts.position[i]
      if position == nil then
        position = room:GetCenterPos() -- This should never happen
        Isaac.DebugString("Error: Not enough entries for position in the bossHearts table. " ..
                          "(i is " .. tostring(i) .. ")")
      end

      -- Get the velocity of the heart
      local velocity = RPGlobals.run.bossHearts.velocity[i]
      if velocity == nil then
        velocity = Vector(0, 0)
        Isaac.DebugString("Error: Not enough entries for velocity in the bossHearts table. " ..
                          "(i is " .. tostring(i) .. ")")
      end

      -- Spawn the heart
      local heartSeed = roomSeed
      if i == 2 then
        heartSeed = RPGlobals:IncrementRNG(heartSeed)
      end
      if i == 2 and RPGlobals.run.bossHearts.extraIsSoul then
        -- Heart (soul) - 5.10.3
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, position, velocity, nil, 3, heartSeed)
        RPGlobals.run.bossHearts.extraIsSoul = false
        Isaac.DebugString("Spawned an extra boss heart drop (soul heart).")
      else
        -- Random Heart - 5.10.0
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, position, velocity, nil, 0, heartSeed)
        Isaac.DebugString("Spawned a boss heart drop.")
      end
    end

    -- The bossHearts variables is reset upon entering a new room
  end

  -- Make Fireworks quieter
  if RPCheckEntities.fireworkActive then
    if sfx:IsPlaying(SoundEffect.SOUND_BOSS1_EXPLOSIONS) then -- 182
      sfx:AdjustVolume(SoundEffect.SOUND_BOSS1_EXPLOSIONS, 0.2)
    end
  end
end

-- EntityType.ENTITY_BOMBDROP (4)
function RPCheckEntities:Entity4(entity)
  if (entity.Variant == 3 or -- Troll Bomb
      entity.Variant == 4) and -- Mega Troll Bomb
     entity.FrameCount == 1 then

    -- Make Troll Bomb and Mega Troll Bomb fuses deterministic (exactly 2 seconds long)
    -- (in vanilla the fuse is: 45 + random(1, 2147483647) % 30)
    local bomb = entity:ToBomb()
    bomb:SetExplosionCountdown(59) -- 60 minus 1 because we start at frame 1
    -- Note that game physics occur at 30 frames per second instead of 60
  end
end

-- EntityType.ENTITY_PICKUP (5)
function RPCheckEntities:Entity5(entity)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local room = game:GetRoom()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local roomData = level:GetCurrentRoomDesc().Data
  local roomType = room:GetType()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
  local player = game:GetPlayer(0)
  local challenge = Isaac.GetChallenge()

  if entity.Variant == PickupVariant.PICKUP_HEART then -- 10
    if RPCheckEntities:IsBossType(entity.SpawnerType) and
       roomType == RoomType.ROOM_BOSS and -- 5
       stage ~= 11 then -- We don't need to seed the heart drops from Blue Baby, The Lamb, or Victory Lap bosses

      -- Delete heart drops in boss rooms so that we can properly seed them
      RPGlobals.run.bossHearts.spawn = true
      RPGlobals.run.bossHearts.position[#RPGlobals.run.bossHearts.position + 1] = entity.Position
      RPGlobals.run.bossHearts.velocity[#RPGlobals.run.bossHearts.velocity + 1] = entity.Velocity
      entity:Remove()
      Isaac.DebugString("Removed boss room heart drop #" .. tostring(#RPGlobals.run.bossHearts.position) .. ": " ..
                    "(" .. tostring(entity.Position.X) .. "," .. tostring(entity.Position.Y) .. ") " ..
                    "(" .. tostring(entity.Velocity.X) .. "," .. tostring(entity.Velocity.Y) .. ")")
    end

  elseif entity.Variant == PickupVariant.PICKUP_LIL_BATTERY or -- 90
         (entity.Variant == PickupVariant.PICKUP_KEY and entity.SubType == 4) then -- Charged Key (30.4)

    if entity:GetSprite():IsPlaying("Collect") and
       entity:ToPickup().Touched == false then

      -- Mark that we have touched this Lil' Battery / Charged Key
      entity:ToPickup().Touched = true

      -- Recharge the Wraith Skull
      -- (we have to do this manually because the charges on the Wraith Skull are not handled naturally by the game)
      SamaelMod:CheckRechargeWraithSkull()
    end

  elseif (entity.Variant == PickupVariant.PICKUP_SPIKEDCHEST or -- 52
          entity.Variant == PickupVariant.PICKUP_MIMIC) then -- 54

    -- We can't check for the "Appear" animation because this is not fast enough
    -- to intercept the unavoidable damage when a Mimic spawns on top of the player
    if entity:ToPickup().TheresOptionsPickup then -- This is used as a replacement counter
      return
    end

    -- Change all Mimics and Spiked Chests to normal chests until the appearing animation is complete
    -- (this also fixes the unavoidable damage when a Mimic spawns where you happen to be standing)
    -- (Spiked Chests do not have this problem)
    -- (the unavoidable damage still happens if you spawn the Mimic using the console, but is fixed from room drops)
    entity.Variant = 50

    -- Check to see if we are in a specific room where a Spiked Chest or Mimic will cause unavoidable damage
    if (roomData.StageID == 4 and roomData.Variant == 12) or -- Caves
       (roomData.StageID == 4 and roomData.Variant == 19) or
       (roomData.StageID == 4 and roomData.Variant == 244) or
       (roomData.StageID == 4 and roomData.Variant == 518) or
       (roomData.StageID == 4 and roomData.Variant == 519) or
       (roomData.StageID == 5 and roomData.Variant == 19) or -- Catacombs
       (roomData.StageID == 5 and roomData.Variant == 518) or
       (roomData.StageID == 10 and roomData.Variant == 458) or -- Womb
       (roomData.StageID == 10 and roomData.Variant == 489) or
       (roomData.StageID == 11 and roomData.Variant == 458) or -- Utero
       (roomData.StageID == 11 and roomData.Variant == 489) then

      -- Leave it as a normal chest, but changing the variant doesn't actually change the sprite
      entity:GetSprite():Load("gfx/005.050_chest.anm2", true)

      -- We have to play an animation for the new sprite to actually appear
      entity:GetSprite():Play("Appear", false)
      Isaac.DebugString("Replaced a Spiked Chest / Mimic with a normal chest (for an unavoidable damage room).")

    else
      -- Changing the variant doesn't actually change the sprite
      -- Furthermore, we need to make it look like a Mimic
      entity:GetSprite():Load("gfx/005.054_mimic chest.anm2", true)

      -- We have to play an animation for the new sprite to actually appear
      entity:GetSprite():Play("Appear", false)

      -- Use the normally unused "TheresOptionsPickup" varaible to store that this is not a normal chest
      entity:ToPickup().TheresOptionsPickup = true

      Isaac.DebugString("Replaced a Spiked Chest / Mimic (1/2).")
    end

  elseif entity.Variant == PickupVariant.PICKUP_CHEST then -- 50
    if entity:ToPickup().TheresOptionsPickup and
       entity:GetSprite():IsPlaying("Appear") and
       entity:GetSprite():GetFrame() == 21 then -- This is the last frame of the "Appear" animation

      -- The "Appear" animation is finished, so now change this back to a Mimic
      -- (we can't just check for "IsPlaying("Appear") == false" because if the player is touching it,
      -- they will get the contents of a normal chest before the swap back occurs)
      entity.Variant = 54
      Isaac.DebugString("Replaced a Spiked Chest / Mimic (2/2).")
    end

  elseif entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then -- 100
    RPCheckEntities:Entity5_100(entity)

  elseif entity.Variant == PickupVariant.PICKUP_TRINKET then -- 350
    if RPGlobals.run.roomsEntered <= 1 and
       RPGlobals.race.rFormat == "pageant" then

      -- Delete Pageant Boy starting trinkets
      entity:Remove()
    end

  elseif entity.Variant == PickupVariant.PICKUP_BIGCHEST then -- 340
    if stage == 10 and stageType == 0 and -- Sheol
       (player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) or -- 328
        challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S2)")) then

      -- Delete the chest and replace it with a trapdoor so that we can fast-travel normally
      RPFastTravel:ReplaceTrapdoor(entity, -1)
      -- A -1 indicates that we are replacing an entity instead of a grid entity

    elseif stage == 10 and stageType == 1 and -- Cathedral
           player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327

      -- Delete the chest and replace it with the custom beam of light so that we can fast-travel normally
      RPFastTravel:ReplaceHeavenDoor(entity)

    elseif stage == 11 and stageType == 0 and -- Dark Room
           challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") then

      -- For custom Dark Room challenges, sometimes the vanilla end of challenge trophy does not appear
      -- Thus, we need to handle replacing both the trophy and the big chest
      -- So replace the big chest with either a checkpoint flag or a custom trophy,
      -- depending on if we are on the last character or not
      if RPSpeedrun.charNum == 7 then
        game:Spawn(Isaac.GetEntityTypeByName("Race Trophy"), Isaac.GetEntityVariantByName("Race Trophy"),
                   entity.Position, entity.Velocity, nil, 0, 0)
        Isaac.DebugString("Spawned the end of speedrun trophy.")
      else
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, room:GetCenterPos(), Vector(0, 0),
                   nil, CollectibleType.COLLECTIBLE_CHECKPOINT, roomSeed)
        RPSpeedrun.spawnedCheckpoint = true
        Isaac.DebugString("Spawned a Checkpoint in the center of the room.")
      end

      -- Get rid of the vanilla big chest
      entity:Remove()

    elseif stage == 11 and
           RPGlobals.race.rFormat == "pageant" then

      -- Delete all big chests on the Pageant Boy ruleset so that
      -- you don't accidently end your run before you can show off your build to the judges
      entity:Remove()

    elseif stage == 11 and
           RPGlobals.raceVars.finished == false and
           RPGlobals.race.status == "in progress" and
           ((RPGlobals.race.goal == "Blue Baby" and stageType == 1 and
             roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX) or -- -7
            (RPGlobals.race.goal == "The Lamb" and stageType == 0 and
             roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX) or -- -7
            (RPGlobals.race.goal == "Mega Satan" and
             roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX)) then -- -7

      -- Spawn the "Race Trophy" custom entity
      game:Spawn(Isaac.GetEntityTypeByName("Race Trophy"), Isaac.GetEntityVariantByName("Race Trophy"),
                 entity.Position, entity.Velocity, nil, 0, 0)
      Isaac.DebugString("Spawned the end of race trophy.")

      -- Get rid of the chest
      entity:Remove()

    elseif stage == 11 and
           RPGlobals.raceVars.finished == false and
           RPGlobals.race.status == "in progress" and
           (RPGlobals.race.goal == "Mega Satan" and
            roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX) then -- -7

      -- Get rid of the chest as a reminder that the race goal is Mega Satan
      entity:Remove()
      Isaac.DebugString("Got rid of the big chest since the goal is Mega Satan.")

    elseif stage == 11 and
           RPGlobals.raceVars.finished then

      -- Spawn a Victory Lap (a custom item that emulates Forget Me Now) in the center of the room
      local victoryLapPosition = room:GetCenterPos()
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, victoryLapPosition, Vector(0, 0),
                 nil, CollectibleType.COLLECTIBLE_VICTORY_LAP, roomSeed)
      Isaac.DebugString("Spawned a Victory Lap in the center of the room.")

      -- Get rid of the chest
      entity:Remove()
    end

  elseif entity.Variant == PickupVariant.PICKUP_TROPHY then -- 370
    if stage == 11 and
       ((challenge == Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") and stageType == 1) or
        (challenge == Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") and stageType == 1) or
        (challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") and stageType == 0) or
        (challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S3)") and stageType == 1)) then

      -- Replace the vanilla challenge trophy with either a checkpoint flag or a custom trophy,
      -- depending on if we are on the last character or not
      if (challenge == Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") and
          RPSpeedrun.charNum == 9) or
         (challenge == Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") and
          RPSpeedrun.charNum == 14) or
         (challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") and
          RPSpeedrun.charNum == 7) or
         (challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S3)") and
          RPSpeedrun.charNum == 7) then

        -- Spawn the "Race Trophy" custom entity
        game:Spawn(Isaac.GetEntityTypeByName("Race Trophy"), Isaac.GetEntityVariantByName("Race Trophy"),
                   entity.Position, entity.Velocity, nil, 0, 0)
        Isaac.DebugString("Spawned the end of speedrun trophy.")

      else
        -- Spawn a Checkpoint (a custom item) in the center of the room
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, room:GetCenterPos(), Vector(0, 0),
                   nil, CollectibleType.COLLECTIBLE_CHECKPOINT, roomSeed)
        RPSpeedrun.spawnedCheckpoint = true
        Isaac.DebugString("Spawned a Checkpoint in the center of the room.")
      end

      -- Get rid of the vanilla challenge trophy
      entity:Remove()
    end

  elseif entity.EntityCollisionClass ~= 0 then
    -- Pickups will still exist for 15 frames after being picked up since they will be playing the "Collect"
    -- animation; however, as soon as they are touched, their EntityCollisionClass will be set to 0
    -- (this is necessary to fix the bug where pickups can be duplicated from touching them)

    -- Make sure that pickups are not overlapping with trapdoors / beams of light / crawlspaces
    RPFastTravel:CheckPickupOverHole(entity)
  end
end

-- Collectible (5.100)
function RPCheckEntities:Entity5_100(entity)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local challenge = Isaac.GetChallenge()

  if entity.SubType == CollectibleType.COLLECTIBLE_NULL then -- 0
    if RPSpeedrun.spawnedCheckpoint then
      RPSpeedrun:CheckpointTouched()
    end

  elseif entity.SubType == CollectibleType.COLLECTIBLE_POLAROID then -- 327
    if RPGlobals.race.goal == "The Lamb" and
       RPGlobals.race.rFormat ~= "pageant" and
       challenge ~= Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") then

      entity:Remove()
      Isaac.DebugString("Removed The Polaroid.")

    elseif entity.Position.X >= 270 and entity.Position.X <= 290 and
           RPGlobals.race.goal ~= "Mega Satan" and
           RPGlobals.race.rFormat ~= "pageant" and
           challenge ~= Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") then

      -- Reposition it to the center
      game:Spawn(entity.Type, entity.Variant, Vector(320, 360), Vector(0, 0),
                 entity.Parent, entity.SubType, entity.InitSeed)
      -- (respawn it with the initial seed so that it will be replaced normally on the next frame)
      entity:Remove()
      Isaac.DebugString("Moved The Polaroid.")
    end

  elseif entity.SubType == CollectibleType.COLLECTIBLE_NEGATIVE then -- 328
    if challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") then
      -- Check to see if this is a Negative sitting in the center of the room
      -- (spawned naturally by the challenge)
      if entity.Position.X >= 310 and entity.Position.X <= 330 then
        -- Move The Negative to the right side
        local negative = game:Spawn(entity.Type, entity.Variant, Vector(360, 360), Vector(0, 0),
                   entity.Parent, entity.SubType, entity.InitSeed)
        negative:ToPickup().TheresOptionsPickup = true
        entity:Remove()

        -- Spawn The Polaroid (5.100.327) on the left side
        local polaroid = game:Spawn(entity.Type, entity.Variant, Vector(280, 360), Vector(0, 0),
                                    entity.Parent, CollectibleType.COLLECTIBLE_POLAROID, entity.InitSeed)
        polaroid:ToPickup().TheresOptionsPickup = true

        Isaac.DebugString("Spawned The Polaroid and Moved The Negative for a custom speedrun to the Dark Room.")
      end

    elseif RPGlobals.race.goal == "Blue Baby" and
           RPGlobals.race.rFormat ~= "pageant" then

      entity:Remove()
      Isaac.DebugString("Removed The Negative.")

    elseif entity.Position.X >= 350 and entity.Position.X <= 370 and
           RPGlobals.race.goal ~= "Mega Satan" and
           RPGlobals.race.rFormat ~= "pageant" then

      -- Reposition it to the center
      game:Spawn(entity.Type, entity.Variant, Vector(320, 360), Vector(0, 0),
                 entity.Parent, entity.SubType, entity.InitSeed)
      -- (respawn it with the initial seed so that it will be replaced normally on the frame)
      entity:Remove()
      Isaac.DebugString("Moved The Negative.")
    end

  elseif gameFrameCount >= RPGlobals.run.itemReplacementDelay then
    -- We need to delay after using a Void (in case the player has consumed a D6)
    RPCheckEntities:ReplacePedestal(entity)
  end
end

-- EntityType.ENTITY_KNIFE (8)
function RPCheckEntities:Entity8(entity)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomClear = room:IsClear()
  local knife = entity:ToKnife()
  local isFlying = knife:IsFlying()

  -- Keep track of whether the knife is being thrown or not so that we can calculate accuracy
  if RPGlobals.run.knife.isFlying == false and
     isFlying and
     roomClear == false then

    RPGlobals.run.knife.isFlying = true
    RPGlobals.run.knife.isMissed = true -- Assume they missed the shot by default

  elseif RPGlobals.run.knife.isFlying and
         isFlying == false then

    RPGlobals.run.knife.isFlying = false
    RPGlobals.run.knife.totalShots = RPGlobals.run.knife.totalShots + 1
    if RPGlobals.run.knife.isMissed == false then
      RPGlobals.run.knife.hitShots = RPGlobals.run.knife.hitShots + 1
    end
  end
end

-- EntityType.ENTITY_KNIGHT (41)
-- EntityType.ENTITY_FLOATING_KNIGHT (254)
-- EntityType.ENTITY_BONE_KNIGHT (283)
function RPCheckEntities:Entity41(entity)
  -- Knights, Selfless Knights, Floating Knights, and Bone Knights
  -- (this can't be in the NPCUpdate callback because it does not fire during the "Appear" animation)
  if RPGlobals.run.currentKnights[entity.Index] == nil then
    -- Add their position to the table so that we can keep track of it on future frames
    RPGlobals.run.currentKnights[entity.Index] = {
      pos = entity.Position,
    }
  end

  if entity.FrameCount == 4 then
    -- Changing the NPC's state triggers the invulnerability removal in the next frame
    entity:ToNPC().State = 4

    -- Manually setting visible to true allows us to disable the invulnerability 1 frame earlier
    -- (this is to compensate for having only post update hooks)
    entity.Visible = true

  elseif entity.FrameCount >= 5 and
         entity.FrameCount <= 30 then

    -- Keep the 5th frame of the spawn animation going
    entity:GetSprite():SetFrame("Down", 0)

    -- Make sure that it stays in place
    entity.Position = RPGlobals.run.currentKnights[entity.Index].pos
    entity.Velocity = Vector(0, 0)
  end
end

-- EntityType.ENTITY_EYE (60)
function RPCheckEntities:Entity60(entity)
  -- Eyes and Blootshot Eyes
  -- (this can't be in the NPCUpdate callback because it does not fire during the "Appear" animation)
  if entity.FrameCount == 4 then
    entity:GetSprite():SetFrame("Eye Opened", 0)
    entity:ToNPC().State = 3
    entity.Visible = true
  end

  -- Prevent the Eye from shooting for 30 frames
  if (entity:ToNPC().State == 4 or
      entity:ToNPC().State == 8) and
     entity.FrameCount < 31 then

    entity:ToNPC().StateFrame = 0
  end
end

-- EntityType.ENTITY_THE_HAUNT (260)
function RPCheckEntities:Entity260(entity)
  if entity.Variant ~= 10 or
     entity.Parent ~= nil then

    return
  end

  -- Lil' Haunts (260.10)
  -- (this can't be in the NPCUpdate callback because it does not fire during the "Appear" animation)
  if RPGlobals.run.currentLilHaunts[entity.Index] == nil then
    -- Add their position to the table so that we can keep track of it on future frames
    RPGlobals.run.currentLilHaunts[entity.Index] = {
      pos = entity.Position,
    }
  end

  if entity.FrameCount == 4 then
    -- Get rid of the Lil' Haunt invulnerability frames
    entity:ToNPC().State = 4 -- Changing the NPC's state triggers the invulnerability removal in the next frame
    entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL -- 4
    -- Tears will pass through Lil' Haunts when they first spawn, so fix that
    entity.Visible = true -- If we don't do this, they will be invisible after being spawned by a Haunt

  elseif entity.FrameCount >= 5 and
         entity.FrameCount <= 16 then

    -- Lock Lil' Haunts that are in the "warmup" animation
    entity.Position = RPGlobals.run.currentLilHaunts[entity.Index].pos
    entity.Velocity = Vector(0, 0)
  end
end

-- EntityType.ENTITY_EFFECT (1000)
function RPCheckEntities:Entity1000(entity)
  if entity.Variant == EffectVariant.FART and -- 34
     RPGlobals.run.changeFartColor == true then

    -- We want special rolls to have a different fart color to distinguish them
    RPGlobals.run.changeFartColor = false
    local color = Color(5.5, 0.2, 0.2, 1, 0, 0, 0) -- Bright red
    entity:SetColor(color, 0, 0, false, false)

  elseif entity.Variant == EffectVariant.HEAVEN_LIGHT_DOOR then -- 39
    RPFastTravel:ReplaceHeavenDoor(entity)

  elseif entity.Variant == EffectVariant.FIREWORKS then -- 104
    -- Check for fireworks so that we can reduce the volume
    RPCheckEntities.fireworkActive = true

  elseif entity.Variant == Isaac.GetEntityVariantByName("Trapdoor (Fast-Travel)") or -- 201
         entity.Variant == Isaac.GetEntityVariantByName("Womb Trapdoor (Fast-Travel)") or -- 203
         entity.Variant == Isaac.GetEntityVariantByName("Blue Womb Trapdoor (Fast-Travel)") then -- 204

    RPFastTravel:CheckTrapdoorCrawlspaceOpen(entity)
    RPFastTravel:CheckTrapdoorEnter(entity, false) -- The second argument is "upwards"

  elseif entity.Variant == Isaac.GetEntityVariantByName("Crawlspace (Fast-Travel)") then -- 202
    RPFastTravel:CheckTrapdoorCrawlspaceOpen(entity)
    RPFastTravel:CheckCrawlspaceEnter(entity)

  elseif entity.Variant == Isaac.GetEntityVariantByName("Heaven Door (Fast-Travel)") then -- 205
    RPFastTravel:CheckTrapdoorEnter(entity, true) -- The second argument is "upwards"
  end
end

-- Fix seed "incrementation" from touching active pedestal items and do other various pedestal fixes
-- (this also fixes Angel key pieces and Pandora's Box items being unseeded)
function RPCheckEntities:ReplacePedestal(entity)
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
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"

  -- Check to see if this is a pedestal that was already replaced
  for i = 1, #RPGlobals.run.replacedPedestals do
    if RPGlobals.run.replacedPedestals[i].room == roomIndex and
       RPGlobals.run.replacedPedestals[i].seed == entity.InitSeed then

      -- We have already replaced it, so check to see if we need to delete the delay
      if entity:ToPickup().Wait > 15 then
        -- When we enter a new room, the "wait" variable on all pedestals is set to 18
        -- This is too long, so shorten it
        entity:ToPickup().Wait = 15
      end
      return
    end
  end

  -- We haven't replaced this pedestal yet,
  -- so start off by assuming that we should set the new pedestal seed to that of the room
  local newSeed = roomSeed

  if entity:ToPickup().Touched then
    -- If we touched this item, we need to set it back to the last seed that we have for this position
    for i = 1, #RPGlobals.run.replacedPedestals do
      if RPGlobals.run.replacedPedestals[i].room == roomIndex and
         RPGlobals:InsideSquare(RPGlobals.run.replacedPedestals[i], entity.Position, 15) then

        -- Don't break after this because we want it to be equal to the seed of the last item
        newSeed = RPGlobals.run.replacedPedestals[i].seed

        -- Also reset the X and Y coordinates of the pedestal before we replace it
        -- (this is necessary because the player will push the pedestal slightly when they drop the item,
        -- so the replaced pedestal will be slightly off)
        entity.Position.X = RPGlobals.run.replacedPedestals[i].X
        entity.Position.Y = RPGlobals.run.replacedPedestals[i].Y
      end
    end
  else
    -- This is a new pedestal, so find the new seed that we should set for it,
    -- which will correspond with how many times it has been rolled
    -- (we can't just seed all items with the room seed because
    -- it causes items that are not fully decremented on sight to roll into themselves)
    for i = 1, #RPGlobals.run.replacedPedestals do
      if RPGlobals.run.replacedPedestals[i].room == roomIndex then
        newSeed = RPGlobals:IncrementRNG(newSeed)
      end
    end
  end

  -- Check to see if this is a B1 item room on a seeded race
  local offLimits = false
  if RPGlobals.race.rFormat == "seeded" and
     stage == 1 and
     roomType == RoomType.ROOM_TREASURE and -- 4
     entity.SubType ~= CollectibleType.COLLECTIBLE_OFF_LIMITS then -- 235

    offLimits = true
  end

  -- Check to see if this is a "moved" Krampus pedestal
  -- (this can occur when you have Gimpy and Krampus drops a heart,
  -- which causes the spawned pedestal to be moved one tile over,
  -- and this movement can cause the item to be different)
  -- (this has to be before checking to see if the item is banned)
  if roomType == RoomType.ROOM_DEVIL and -- 14
     entity:ToPickup().Touched == false and -- This is necessary because we only want to target fresh Krampus items
     (entity.SubType == CollectibleType.COLLECTIBLE_LUMP_OF_COAL or -- 132
      entity.SubType == CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS) then -- 293

    -- Seed the pedestal ourselves manually
    math.randomseed(newSeed)
    local krampusItem = math.random(1, 2)
    if krampusItem == 1 then
      entity.SubType = CollectibleType.COLLECTIBLE_LUMP_OF_COAL -- 132
    else
      entity.SubType = CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS -- 293
      entity:ToPickup().Charge = 6 -- This is necessary because it would spawn with 0 charge otherwise
    end
  end

  -- Check to see if we need to swap Krampus items
  if (entity.SubType == CollectibleType.COLLECTIBLE_LUMP_OF_COAL or -- 132
      entity.SubType == CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS) and -- 293
     entity:ToPickup().Touched == false then

    local coalBanned = false
    local headBanned = false
    for i = 1, #RPGlobals.race.startingItems do
      if RPGlobals.race.startingItems[i] == CollectibleType.COLLECTIBLE_LUMP_OF_COAL then -- 132
        coalBanned = true
      elseif RPGlobals.race.startingItems[i] == CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS then -- 293
        headBanned = true
      end
    end
    if coalBanned and headBanned then
      -- Both A Lump of Coal and Krampus' Head are on the ban list, so make a random item instead
      entity.SubType = 0
      Isaac.DebugString("Switched A Lump of Coal / Krampus' Head to a random item.")
    elseif coalBanned then
      -- Switch A Lump of Coal to Krampus' Head
      entity.SubType = CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS -- 293
      entity:ToPickup().Charge = 6 -- This is necessary because it would spawn with 0 charge otherwise
      Isaac.DebugString("Switched A Lump of Coal to Krampus' Head.")
    elseif headBanned then
      -- Switch Krampus' Head to A Lump of Coal
      entity.SubType = CollectibleType.COLLECTIBLE_LUMP_OF_COAL -- 132
      Isaac.DebugString("Switched Krampus' Head to A Lump of Coal.")
    end
  end

  -- Check to see if this is a special Basement 1 diversity reroll
  -- (these custom placeholder items are removed in all non-diveristy runs)
  local specialReroll = 0
  if stage == 1 and
     roomType == RoomType.ROOM_TREASURE and -- 4
     RPGlobals.race.rFormat == "diversity" then

    if entity.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1 then
      specialReroll = CollectibleType.COLLECTIBLE_INCUBUS -- 360
    elseif entity.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2 then
      specialReroll = CollectibleType.COLLECTIBLE_SACRED_HEART -- 182
    elseif entity.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3 then
      specialReroll = CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT -- 415
    end

  elseif entity.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1 or
         entity.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2 or
         entity.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3 then

    -- If the player is on a diversity race and gets a Treasure pool item on basement 1,
    -- then there is a chance that they could get a placeholder item
    entity.SubType = 0
  end

  -- Check to see if this item should go into a Schoolbag
  local putInSchoolbag = RPSchoolbag:CheckSecondItem(entity)
  if putInSchoolbag == false then
    -- Replace the pedestal
    RPGlobals.run.usedButterFrame = 0
    -- If we are replacing a pedestal, make sure this is reset to avoid the bug where
    -- it takes two item trouches to re-enable the Schoolbag
    local randomItem = false
    local newPedestal
    if offLimits then
      -- Change the item to Off Limits (5.100.235)
      newPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, entity.Position,
                               entity.Velocity, entity.Parent, CollectibleType.COLLECTIBLE_OFF_LIMITS, newSeed)

      -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
      game:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0)
      Isaac.DebugString("Made an Off Limits pedestal using seed: " .. tostring(newSeed))

    elseif specialReroll ~= 0 then
      -- Change the item to the special reroll
      newPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, entity.Position,
                               entity.Velocity, entity.Parent, specialReroll, newSeed)

      -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
      game:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0)
      RPGlobals.run.changeFartColor = true -- Change it to a bright red fart to distinguish that it is a special reroll
      Isaac.DebugString("Item " .. tostring(entity.SubType) .. " is special, " ..
                        "made a new " .. tostring(specialReroll) .. " pedestal using seed: " .. tostring(newSeed))

    else
      -- Make a new copy of this item
      newPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, entity.Position,
                               entity.Velocity, entity.Parent, entity.SubType, newSeed)

      -- We don't need to make a fart noise because the swap will be completely transparent to the user
      -- (the sprites of the two items will obviously be identical)
      -- We don't need to add this item to the ban list because since it already existed, it was properly
      -- decremented from the pools on sight
      Isaac.DebugString("Made a copied " .. tostring(newPedestal.SubType) ..
                        " pedestal using seed: " .. tostring(newSeed))
    end

    -- We don't want to replicate the charge if this is a brand new item
    if specialReroll == 0 then
      -- If we don't do this, the item will be fully recharged every time the player swaps it out
      newPedestal:ToPickup().Charge = entity:ToPickup().Charge
    end

    -- If we don't do this, shop and Devil Room items will become automatically bought
    newPedestal:ToPickup().Price = entity:ToPickup().Price

    -- We need to keep track of touched items for banned item exception purposes
    newPedestal:ToPickup().Touched = entity:ToPickup().Touched

    -- If we don't do this, shop items will reroll into consumables and
    -- shop items that are on sale will no longer be on sale
    newPedestal:ToPickup().ShopItemId = entity:ToPickup().ShopItemId

    -- If we don't do this, you can take both of the pedestals in a double Treasure Room
    newPedestal:ToPickup().TheresOptionsPickup = entity:ToPickup().TheresOptionsPickup

    -- Also reduce the vanilla delay that is imposed upon newly spawned collectible items
    -- (this is commented out because people were accidentally taking items)
    --newPedestal:ToPickup().Wait = 15 -- On vanilla, all pedestals get a 20 frame delay

    -- Add it to the tracking table so that we don't replace it again
    -- (don't add random items to the index in case a banned item rolls into another banned item)
    if randomItem == false then
      RPGlobals.run.replacedPedestals[#RPGlobals.run.replacedPedestals + 1] = {
        room = roomIndex,
        X    = entity.Position.X,
        Y    = entity.Position.Y,
        seed = newSeed,
      }
      --[[
      Isaac.DebugString("Added to replacedPedestals (" .. tostring(#RPGlobals.run.replacedPedestals) .. "): (" ..
                        tostring(RPGlobals.run.replacedPedestals[#RPGlobals.run.replacedPedestals].room) .. "," ..
                        tostring(RPGlobals.run.replacedPedestals[#RPGlobals.run.replacedPedestals].X) .. "," ..
                        tostring(RPGlobals.run.replacedPedestals[#RPGlobals.run.replacedPedestals].Y) .. "," ..
                        tostring(RPGlobals.run.replacedPedestals[#RPGlobals.run.replacedPedestals].seed) .. ")")
      --]]
    end

    -- Now that we have created a new pedestal, we can delete the old one
    entity:Remove()
  end
end

-- We can't use "entity:IsBoss()" for certain things, like if the parent of a pickup is dead
function RPCheckEntities:IsBossType(entityType)
  if entityType == EntityType.ENTITY_LARRYJR or -- 19
     entityType == EntityType.ENTITY_MONSTRO or -- 20
     entityType == EntityType.ENTITY_CHUB or -- 28
     entityType == EntityType.ENTITY_GURDY or -- 36
     entityType == EntityType.ENTITY_MONSTRO2 or -- 43
     entityType == EntityType.ENTITY_MOM or -- 45
     entityType == EntityType.ENTITY_FRED or -- 59
     entityType == EntityType.ENTITY_PIN or -- 62
     entityType == EntityType.ENTITY_FAMINE or -- 63
     entityType == EntityType.ENTITY_PESTILENCE or -- 64
     entityType == EntityType.ENTITY_WAR or -- 65
     entityType == EntityType.ENTITY_DEATH or -- 66
     entityType == EntityType.ENTITY_DUKE or -- 67
     entityType == EntityType.ENTITY_PEEP or -- 68
     entityType == EntityType.ENTITY_LOKI or -- 69
     entityType == EntityType.ENTITY_FISTULA_BIG or -- 71
     entityType == EntityType.ENTITY_FISTULA_MEDIUM or -- 72
     entityType == EntityType.ENTITY_FISTULA_SMALL or -- 73
     entityType == EntityType.ENTITY_BLASTOCYST_BIG or -- 74
     entityType == EntityType.ENTITY_BLASTOCYST_MEDIUM or -- 75
     entityType == EntityType.ENTITY_BLASTOCYST_SMALL or -- 76
     entityType == EntityType.ENTITY_MOMS_HEART or -- 78
     entityType == EntityType.ENTITY_GEMINI or -- 79
     entityType == EntityType.ENTITY_FALLEN or -- 81
     entityType == EntityType.ENTITY_HEADLESS_HORSEMAN or -- 82
     entityType == EntityType.ENTITY_SATAN or -- 84
     entityType == EntityType.ENTITY_MASK_OF_INFAMY or -- 97
     entityType == EntityType.ENTITY_GURDY_JR or -- 99
     entityType == EntityType.ENTITY_WIDOW or -- 100
     entityType == EntityType.ENTITY_DADDYLONGLEGS or -- 101
     entityType == EntityType.ENTITY_ISAAC or -- 102
     entityType == EntityType.ENTITY_GURGLING or -- 237
     entityType == EntityType.ENTITY_THE_HAUNT or -- 260
     entityType == EntityType.ENTITY_DINGLE or -- 261
     entityType == EntityType.ENTITY_MEGA_MAW or -- 262
     entityType == EntityType.ENTITY_GATE or -- 263
     entityType == EntityType.ENTITY_MEGA_FATTY or -- 264
     entityType == EntityType.ENTITY_CAGE or -- 265
     entityType == EntityType.ENTITY_MAMA_GURDY or -- 266
     entityType == EntityType.ENTITY_DARK_ONE or -- 267
     entityType == EntityType.ENTITY_ADVERSARY or -- 268
     entityType == EntityType.ENTITY_POLYCEPHALUS or -- 269
     entityType == EntityType.ENTITY_URIEL or -- 271
     entityType == EntityType.ENTITY_GABRIEL or -- 272
     entityType == EntityType.ENTITY_THE_LAMB or -- 273
     entityType == EntityType.ENTITY_MEGA_SATAN or -- 274
     entityType == EntityType.ENTITY_MEGA_SATAN_2 or -- 275
     entityType == EntityType.ENTITY_STAIN or -- 401
     entityType == EntityType.ENTITY_BROWNIE or -- 402
     entityType == EntityType.ENTITY_FORSAKEN or -- 403
     entityType == EntityType.ENTITY_LITTLE_HORN or -- 404
     entityType == EntityType.ENTITY_RAG_MAN or -- 405
     entityType == EntityType.ENTITY_ULTRA_GREED or -- 406
     entityType == EntityType.ENTITY_HUSH or -- 407
     entityType == EntityType.ENTITY_RAG_MEGA or -- 409
     entityType == EntityType.ENTITY_SISTERS_VIS or -- 410
     entityType == EntityType.ENTITY_BIG_HORN or -- 411
     entityType == EntityType.ENTITY_DELIRIUM then -- 412

    return true
  else
    return false
  end
end

return RPCheckEntities

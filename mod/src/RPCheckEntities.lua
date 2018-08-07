local RPCheckEntities = {}

--
-- Includes
--

local RPGlobals         = require("src/rpglobals")
local RPSchoolbag       = require("src/rpschoolbag")
local RPFastTravel      = require("src/rpfasttravel")
local RPSpeedrun        = require("src/rpspeedrun")
local RPChangeCharOrder = require("src/rpchangecharorder")
local SamaelMod         = require("src/rpsamael")

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
      local saveState = gridEntity:GetSaveState()
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
        RPChangeCharOrder:CheckButtonPressed(gridEntity)
      end
    end
  end
end

-- Check all the non-grid entities in the room
-- (called from the PostUpdate callback)
function RPCheckEntities:NonGrid()
  -- Local variables
  local sfx = SFXManager()

  -- Go through all the entities
  RPCheckEntities.fireworkActive = false
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_BOMBDROP then -- 4
      RPCheckEntities:Entity4(entity:ToBomb())

    elseif entity.Type == EntityType.ENTITY_PICKUP then -- 5
      RPCheckEntities:Entity5(entity:ToPickup())

    elseif entity.Type == EntityType.ENTITY_THE_HAUNT then -- 260
      RPCheckEntities:Entity260(entity:ToNPC())

    elseif entity.Type == EntityType.ENTITY_EFFECT then -- 1000
      RPCheckEntities:Entity1000(entity:ToEffect())

    elseif entity.Type == Isaac.GetEntityTypeByName("Race Trophy") and -- 1001
           entity.Variant == Isaac.GetEntityVariantByName("Race Trophy") then -- 0

      RPCheckEntities:EntityRaceTrophy(entity)
    end
  end

  -- Make Fireworks quieter
  if RPCheckEntities.fireworkActive then
    if sfx:IsPlaying(SoundEffect.SOUND_BOSS1_EXPLOSIONS) then -- 182
      sfx:AdjustVolume(SoundEffect.SOUND_BOSS1_EXPLOSIONS, 0.2)
    end
  end
end

-- EntityType.ENTITY_BOMBDROP (4)
function RPCheckEntities:Entity4(bomb)
  if (bomb.Variant == 3 or -- Troll Bomb
      bomb.Variant == 4) and -- Mega Troll Bomb
     bomb.FrameCount == 1 then

    -- Make Troll Bomb and Mega Troll Bomb fuses deterministic (exactly 2 seconds long)
    -- (in vanilla the fuse is: 45 + random(1, 2147483647) % 30)
    bomb:SetExplosionCountdown(59) -- 60 minus 1 because we start at frame 1
    -- Note that game physics occur at 30 frames per second instead of 60
  end
end

-- EntityType.ENTITY_PICKUP (5)
function RPCheckEntities:Entity5(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local roomData = level:GetCurrentRoomDesc().Data

  -- Keep track of pickups that are touched
  -- (used for moving pickups on top of a trapdoor/crawlspace)
  if pickup:GetSprite():IsPlaying("Collect") and
     pickup.Touched == false then

    pickup.Touched = true
    Isaac.DebugString("Touched pickup: " ..
                      tostring(pickup.Type) .. "." .. tostring(pickup.Variant) .. "." .. tostring(pickup.SubType))

    if pickup.Variant == PickupVariant.PICKUP_LIL_BATTERY or -- 90
       (pickup.Variant == PickupVariant.PICKUP_KEY and pickup.SubType == 4) then -- Charged Key (30.4)

      -- Recharge the Wraith Skull
      -- (we have to do this manually because the charges on the Wraith Skull are not handled naturally by the game)
      SamaelMod:CheckRechargeWraithSkull()
    end
  end

  if pickup.Variant == PickupVariant.PICKUP_SPIKEDCHEST or -- 52
     pickup.Variant == PickupVariant.PICKUP_MIMICCHEST then -- 54

    -- We can't check for the "Appear" animation because this is not fast enough
    -- to intercept the unavoidable damage when a Mimic spawns on top of the player
    if pickup.TheresOptionsPickup then -- This is used as a replacement counter
      return
    end

    -- Change all Mimics and Spiked Chests to normal chests until the appearing animation is complete
    -- (this also fixes the unavoidable damage when a Mimic spawns where you happen to be standing)
    -- (Spiked Chests do not have this problem)
    -- (the unavoidable damage still happens if you spawn the Mimic using the console, but is fixed from room drops)
    pickup.Variant = 50

    -- Check to see if we are in a specific room where a Spiked Chest or Mimic will cause unavoidable damage
    local roomDataVariant = roomData.Variant
    while roomDataVariant > 10000 do
      -- The 3 flipped versions of room #1 would be #10001, #20001, and #30001
      roomDataVariant = roomDataVariant - 10000
    end

    -- roomData.StageID always returns 0 for some reason, so just use stage and stageType as a workaround
    if ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 12) or -- Caves
       ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 19) or
       ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 125) or
       ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 244) or
       ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 518) or
       ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 519) or
       ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 19) or -- Catacombs
       ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 518) or
       ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 12) or -- Flooded Caves
       ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 19) or
       ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 125) or
       ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 244) or
       ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 518) or
       ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 519) or
       ((stage == 7 or stage == 8) and stageType == 0 and roomDataVariant == 458) or -- Womb
       ((stage == 7 or stage == 8) and stageType == 0 and roomDataVariant == 489) or
       ((stage == 7 or stage == 8) and stageType == 1 and roomDataVariant == 458) or -- Utero
       ((stage == 7 or stage == 8) and stageType == 1 and roomDataVariant == 489) or
       ((stage == 7 or stage == 8) and stageType == 2 and roomDataVariant == 458) or -- Scarred Womb
       ((stage == 7 or stage == 8) and stageType == 2 and roomDataVariant == 489) then

      -- Leave it as a normal chest, but changing the variant doesn't actually change the sprite
      pickup:GetSprite():Load("gfx/005.050_chest.anm2", true)

      -- We have to play an animation for the new sprite to actually appear
      pickup:GetSprite():Play("Appear", false)
      Isaac.DebugString("Replaced a Spiked Chest / Mimic with a normal chest (for an unavoidable damage room).")

    else
      -- Changing the variant doesn't actually change the sprite
      -- Furthermore, we need to make it look like a Mimic
      pickup:GetSprite():Load("gfx/005.054_mimic chest.anm2", true)

      -- We have to play an animation for the new sprite to actually appear
      pickup:GetSprite():Play("Appear", false)

      -- Use the normally unused "TheresOptionsPickup" varaible to store that this is not a normal chest
      pickup.TheresOptionsPickup = true

      Isaac.DebugString("Replaced a Spiked Chest / Mimic (1/2).")
    end

  elseif pickup.Variant == PickupVariant.PICKUP_CHEST then -- 50
    if pickup.TheresOptionsPickup and
       pickup:GetSprite():IsPlaying("Appear") and
       pickup:GetSprite():GetFrame() == 21 then -- This is the last frame of the "Appear" animation

      -- The "Appear" animation is finished, so now change this back to a Mimic
      -- (we can't just check for "IsPlaying("Appear") == false" because if the player is touching it,
      -- they will get the contents of a normal chest before the swap back occurs)
      pickup.Variant = 54
      Isaac.DebugString("Replaced a Spiked Chest / Mimic (2/2).")
    end

  elseif pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then -- 100
    RPCheckEntities:Entity5_100(pickup)

  elseif pickup.Variant == PickupVariant.PICKUP_TRINKET then -- 350
    if RPGlobals.run.roomsEntered <= 1 and
       RPGlobals.race.rFormat == "pageant" then

      -- Delete Pageant Boy starting trinkets
      pickup:Remove()
    end

  elseif pickup.Variant == PickupVariant.PICKUP_BIGCHEST then -- 340
    RPCheckEntities:Entity5_340(pickup)

  elseif pickup.Variant == PickupVariant.PICKUP_TROPHY then -- 370
    RPCheckEntities:Entity5_370(pickup)
  end

  -- We want to check all pickups
  if pickup.Touched == false then
    -- Pickups will still exist for 15 frames after being picked up since they will be playing the "Collect" animation
    -- So we don't want to move a pickup that is already collected, or it will duplicate it
    -- ("Touched" was manually set to true by the mod earlier)

    -- Alternatively, we could check for "entity.EntityCollisionClass ~= 0",
    -- but this is bad because the collision is 0 during the long "Appear" animation

    -- Make sure that pickups are not overlapping with trapdoors / beams of light / crawlspaces
    RPFastTravel:CheckPickupOverHole(pickup)
  end
end

-- PickupVariant.PICKUP_COLLECTIBLE (5.100)
function RPCheckEntities:Entity5_100(pickup)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  -- We manually manage the seed of all collectible items
  if gameFrameCount >= RPGlobals.run.itemReplacementDelay then
    -- We need to delay after using a Void (in case the player has consumed a D6)
    RPCheckEntities:ReplacePedestal(pickup)
  end
end

-- PickupVariant.PICKUP_BIGCHEST (5.340)
function RPCheckEntities:Entity5_340(pickup)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
  local challenge = Isaac.GetChallenge()

  -- Check to see if we already determined that we should leave this big chest
  if pickup.Touched then
    return
  end

  Isaac.DebugString("Big Chest detected.")
  RPCheckEntities.bigChestAction = "leave" -- Leave the big chest there by default
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") then
    RPCheckEntities:Entity5_340_S1R9(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
    RPCheckEntities:Entity5_340_S1R14(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") then
    RPCheckEntities:Entity5_340_S2(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") then
    RPCheckEntities:Entity5_340_S3(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") then
    RPCheckEntities:Entity5_340_S4(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 5 Beta)") then
    RPCheckEntities:Entity5_340_S5(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then
    RPCheckEntities:Entity5_340_S0(pickup)
  elseif RPGlobals.raceVars.finished then
    RPCheckEntities.bigChestAction = "victorylap"
  elseif RPGlobals.race.rFormat == "pageant" then
    RPCheckEntities:Entity5_340_Pageant(pickup)
  elseif RPGlobals.race.goal == "Blue Baby" then
    RPCheckEntities:Entity5_340_BlueBaby(pickup)
  elseif RPGlobals.race.goal == "The Lamb" then
    RPCheckEntities:Entity5_340_TheLamb(pickup)
  elseif RPGlobals.race.goal == "Mega Satan" then
    RPCheckEntities:Entity5_340_MegaSatan(pickup)
  elseif RPGlobals.race.goal == "Everything" then
    RPCheckEntities:Entity5_340_Everything(pickup)
  else
    Isaac.DebugString("Error: Failed to parse the race goal when figuring out what to do with the big chest.")
  end

  -- Now that we know what to do with the big chest, do it
  if RPCheckEntities.bigChestAction == "leave" then
    -- Set a flag so that we leave it alone on the next frame
    pickup.Touched = true

  elseif RPCheckEntities.bigChestAction == "up" then
    -- Delete the chest and replace it with a beam of light so that we can fast-travel normally
    RPFastTravel:ReplaceHeavenDoor(pickup, -1)
    -- A -1 indicates that we are replacing an entity instead of a grid entity

  elseif RPCheckEntities.bigChestAction == "down" then
    -- Delete the chest and replace it with a trapdoor so that we can fast-travel normally
    RPFastTravel:ReplaceTrapdoor(pickup, -1)
    -- A -1 indicates that we are replacing an entity instead of a grid entity

  elseif RPCheckEntities.bigChestAction == "remove" then
    pickup:Remove()

  elseif RPCheckEntities.bigChestAction == "checkpoint" then
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, room:GetCenterPos(), Vector(0, 0),
               nil, CollectibleType.COLLECTIBLE_CHECKPOINT, roomSeed)
    RPSpeedrun.spawnedCheckpoint = true
    RPGlobals.run.endOfRunText = true -- Show the run summary
    Isaac.DebugString("Spawned a Checkpoint in the center of the room.")
    pickup:Remove()

  elseif RPCheckEntities.bigChestAction == "trophy" then
    if challenge ~= 0 or RPGlobals.race.status ~= "none" then
      -- We only want to spawn a trophy if we are on a custom speedrun challenge or currently in a race
      game:Spawn(Isaac.GetEntityTypeByName("Race Trophy"), Isaac.GetEntityVariantByName("Race Trophy"),
                 pickup.Position, pickup.Velocity, nil, 0, 0)
      Isaac.DebugString("Spawned the end of race/speedrun trophy.")
      pickup:Remove()
    end

  elseif RPCheckEntities.bigChestAction == "victorylap" then
    -- Spawn a Victory Lap (a custom item that emulates Forget Me Now) in the center of the room
    local victoryLapPosition = room:GetCenterPos()
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, victoryLapPosition, Vector(0, 0),
               nil, CollectibleType.COLLECTIBLE_VICTORY_LAP, roomSeed)
    Isaac.DebugString("Spawned a Victory Lap in the center of the room.")
    pickup:Remove()
  end
end

function RPCheckEntities:Entity5_340_S1R9(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local player = game:GetPlayer(0)

  if stage == 10 and stageType == 1 and -- Cathedral
     player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327

    RPCheckEntities.bigChestAction = "up"

  elseif stage == 11 and stageType == 1 then -- The Chest
    if RPSpeedrun.charNum == 9 then
      RPCheckEntities.bigChestAction = "trophy"
    else
      RPCheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function RPCheckEntities:Entity5_340_S1R14(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local player = game:GetPlayer(0)

  if stage == 10 and stageType == 1 and -- Cathedral
     player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327

    RPCheckEntities.bigChestAction = "up"

  elseif stage == 11 and stageType == 1 then -- The Chest
    if RPSpeedrun.charNum == 14 then
      RPCheckEntities.bigChestAction = "trophy"
    else
      RPCheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function RPCheckEntities:Entity5_340_S2(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  if stage == 10 and stageType == 0 then -- Sheol
    RPCheckEntities.bigChestAction = "down"

  elseif stage == 11 and stageType == 0 then -- Dark Room
    -- For custom Dark Room challenges, sometimes the vanilla end of challenge trophy does not appear
    -- Thus, we need to handle replacing both the trophy and the big chest
    -- So replace the big chest with either a checkpoint flag or a custom trophy,
    -- depending on if we are on the last character or not
    if RPSpeedrun.charNum == 7 then
      RPCheckEntities.bigChestAction = "trophy"
    else
      RPCheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function RPCheckEntities:Entity5_340_S3(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  -- Season 3 runs alternate between directions, so we need to make sure we only handle the intended direction
  local direction = RPSpeedrun.charNum % 2 -- 1 is up, 2 is down
  if direction == 0 then
    direction = 2
    Isaac.DebugString("Going down.")
  else
    Isaac.DebugString("Going up.")
  end

  if stage == 10 and stageType == 1 and -- Cathedral
     direction == 1 then

    RPCheckEntities.bigChestAction = "up"

  elseif stage == 10 and stageType == 0 and -- Sheol
         direction == 2 then

    RPCheckEntities.bigChestAction = "down"

  elseif (stage == 11 and stageType == 1 and -- The Chest
          direction == 1) or
         (stage == 11 and stageType == 0 and -- Dark Room
          direction == 2) then

    -- Sometimes the vanilla end of challenge trophy does not appear
    -- Thus, we need to handle replacing both the trophy and the big chest
    -- So replace the big chest with either a checkpoint flag or a custom trophy,
    -- depending on if we are on the last character or not
    if RPSpeedrun.charNum == 7 then
      RPCheckEntities.bigChestAction = "trophy"
    else
      RPCheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function RPCheckEntities:Entity5_340_S4(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  if stage == 10 and stageType == 1 then -- Cathedral
    -- It is not required to take The Polaroid in Season 4
    RPCheckEntities.bigChestAction = "up"

  elseif stage == 11 and stageType == 1 then -- The Chest
    if RPSpeedrun.charNum == 7 then
      RPCheckEntities.bigChestAction = "trophy"
    else
      RPCheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function RPCheckEntities:Entity5_340_S5(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  if stage == 10 and stageType == 1 then -- Cathedral
    -- It is not required to take The Polaroid in Season 5
    RPCheckEntities.bigChestAction = "up"

  elseif stage == 11 and stageType == 1 then -- The Chest
    if RPSpeedrun.charNum == 7 then
      RPCheckEntities.bigChestAction = "trophy"
    else
      RPCheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function RPCheckEntities:Entity5_340_S0(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local player = game:GetPlayer(0)

  if stage == 10 and stageType == 1 and -- Cathedral
     player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327

    RPCheckEntities.bigChestAction = "up"

  elseif stage == 11 and stageType == 1 then -- The Chest
    if RPSpeedrun.charNum == 15 then
      RPCheckEntities.bigChestAction = "trophy"
    else
      RPCheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function RPCheckEntities:Entity5_340_Pageant(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local player = game:GetPlayer(0)

  -- Pageant Boy races can go in either direction so we need to handle all 4 cases
  if stage == 10 and stageType == 1 and -- Cathedral
     player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327

    RPCheckEntities.bigChestAction = "up"

  elseif stage == 10 and stageType == 0 and -- Sheol
         player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328

    RPCheckEntities.bigChestAction = "down"

  elseif stage == 11 then -- The Chest or the Dark Room
    -- We want to delete all big chests on the Pageant Boy ruleset so that
    -- you don't accidently end your run before you can show off your build to the judges
    RPCheckEntities.bigChestAction = "remove"
  end
end

function RPCheckEntities:Entity5_340_BlueBaby(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local player = game:GetPlayer(0)

  if stage == 10 and stageType == 1 and -- Cathedral
     player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327

    RPCheckEntities.bigChestAction = "up"

  elseif stage == 11 and stageType == 1 and -- The Chest
         roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    RPCheckEntities.bigChestAction = "remove"

  elseif stage == 11 and stageType == 1 and -- The Chest
         roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    RPCheckEntities.bigChestAction = "trophy"
  end
end

function RPCheckEntities:Entity5_340_TheLamb(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local player = game:GetPlayer(0)

  if stage == 10 and stageType == 0 and -- Sheol
     player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328

    RPCheckEntities.bigChestAction = "down"

  elseif stage == 11 and stageType == 0 and -- Dark Room
         roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    RPCheckEntities.bigChestAction = "remove"

  elseif stage == 11 and stageType == 0 and -- Dark Room
         roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    RPCheckEntities.bigChestAction = "trophy"
  end
end

function RPCheckEntities:Entity5_340_Everything(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  if stage == 10 and stageType == 1 then
    -- Cathedral goes to Sheol
    RPCheckEntities.bigChestAction = "down"

  elseif stage == 10 and stageType == 0 then
    -- Sheol goes to The Chest
    RPCheckEntities.bigChestAction = "up"

  elseif stage == 11 and stageType == 1 then -- 7
    -- The Chest goes to the Dark Room
    RPCheckEntities.bigChestAction = "down"

  elseif stage == 11 and stageType == 0 then
    if roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
      RPCheckEntities.bigChestAction = "remove"
    else
      RPCheckEntities.bigChestAction = "trophy"
    end
  end
end

function RPCheckEntities:Entity5_340_MegaSatan(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local player = game:GetPlayer(0)

  -- Mega Satan races can go in either direction so we need to handle all 4 cases
  if stage == 10 and stageType == 1 and -- Cathedral
     player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327

    RPCheckEntities.bigChestAction = "up"

  elseif stage == 10 and stageType == 0 and -- Sheol
         player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328

    RPCheckEntities.bigChestAction = "down"

  elseif stage == 11 and -- The Chest or the Dark Room
         roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    -- We want to delete the big chest after Blue Baby or The Lamb
    -- to remind the player that they have to go to Mega Satan
    RPCheckEntities.bigChestAction = "remove"

  elseif stage == 11 and -- The Chest or the Dark Room
        roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    RPCheckEntities.bigChestAction = "trophy"
  end
end

-- PickupVariant.PICKUP_TROPHY (5.370)
function RPCheckEntities:Entity5_370(pickup)
  -- Local variables
  local game = Game()

  -- Do nothing if we are not on a custom speedrun challenge
  -- (otherwise we would mess with the normal challenges)
  if RPSpeedrun:InSpeedrun() == false then
    return
  end

  -- It can be unpredicable whether a big chest or a trophy will spawn;
  -- so funnel all decision making through the Big Chest code
  Isaac.DebugString("Vanilla trophy detected; replacing it with a Big Chest.")
  game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, -- 5.340
             pickup.Position, pickup.Velocity, nil, 0, 0)
  pickup:Remove()
end

-- EntityType.ENTITY_THE_HAUNT (260)
function RPCheckEntities:Entity260(npc)
  -- We only care about Lil' Haunts (260.10)
  if npc.Variant ~= 10 then
    return
  end

  -- Add them to the table so that we can track them
  local index = GetPtrHash(npc)
  if RPGlobals.run.currentLilHaunts[index] == nil then
    -- This can't be in the NPC_UPDATE callback because it does not fire during the "Appear" animation
    -- This can't be in the MC_POST_NPC_INIT callback because the position is always equal to (0, 0) there
    RPGlobals.run.currentLilHaunts[index] = {
      index = npc.Index, -- We could have this just be table index instead, but it's safer to use the hash
      pos = npc.Position,
      ptr = EntityPtr(npc),
    }
    local string = "Added a Lil' Haunt with index " .. tostring(index) .. " to the table (with "
    if npc.Parent == nil then
      string = string .. "no"
    else
      string = string .. "a"
      RPGlobals.run.currentLilHaunts[index].parentIndex = npc.Parent.Index
    end
    string = string .. " parent)."
    Isaac.DebugString(string)
  end

  -- Remove invulnerability frames from Lil' Haunts that are not attached to a Haunt
  -- (we can't do it any earlier than the 4th frame because it will introduce additional bugs,
  -- such as the Lil' Haunt becoming invisible)
  if npc.Parent == nil and
     npc.FrameCount == 4 then

     -- Changing the NPC's state triggers the invulnerability removal in the next frame
    npc.State = NpcState.STATE_MOVE -- 4

    -- Additionally, we also have to manually set the collision, because
    -- tears will pass through Lil' Haunts when they first spawn
    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL -- 4

    Isaac.DebugString("Removed invulnerability frames and set collision for a Lil' Haunt with index: " ..
                      tostring(npc.Index))
  end

  -- Lock newly spawned Lil' Haunts in place so that they don't immediately rush the player
  if npc.State == NpcState.STATE_MOVE and -- 4
     npc.FrameCount <= 16 then

    npc.Position = RPGlobals.run.currentLilHaunts[index].pos
    npc.Velocity = Vector(0, 0)
  end
end

-- EntityType.ENTITY_EFFECT (1000)
function RPCheckEntities:Entity1000(effect)
  if effect.Variant == EffectVariant.FART and -- 34
     RPGlobals.run.changeFartColor == true then

    -- We want special rolls to have a different fart color to distinguish them
    RPGlobals.run.changeFartColor = false
    local color = Color(5.5, 0.2, 0.2, 1, 0, 0, 0) -- Bright red
    effect:SetColor(color, 0, 0, false, false)

  elseif effect.Variant == EffectVariant.HEAVEN_LIGHT_DOOR then -- 39
    RPFastTravel:ReplaceHeavenDoor(effect)

  elseif effect.Variant == EffectVariant.FIREWORKS then -- 104
    -- Check for fireworks so that we can reduce the volume
    RPCheckEntities.fireworkActive = true

  elseif effect.Variant == Isaac.GetEntityVariantByName("Trapdoor (Fast-Travel)") or -- 201
         effect.Variant == Isaac.GetEntityVariantByName("Womb Trapdoor (Fast-Travel)") or -- 203
         effect.Variant == Isaac.GetEntityVariantByName("Blue Womb Trapdoor (Fast-Travel)") then -- 204

    RPFastTravel:CheckTrapdoorCrawlspaceOpen(effect)
    RPFastTravel:CheckTrapdoorEnter(effect, false) -- The second argument is "upwards"

  elseif effect.Variant == Isaac.GetEntityVariantByName("Crawlspace (Fast-Travel)") then -- 202
    RPFastTravel:CheckTrapdoorCrawlspaceOpen(effect)
    RPFastTravel:CheckCrawlspaceEnter(effect)

  elseif effect.Variant == Isaac.GetEntityVariantByName("Heaven Door (Fast-Travel)") then -- 205
    RPFastTravel:CheckTrapdoorEnter(effect, true) -- The second argument is "upwards"
  end
end

function RPCheckEntities:EntityRaceTrophy(entity)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
  local challenge = Isaac.GetChallenge()

  if RPGlobals.raceVars.finished or RPSpeedrun.finished then
    return
  end

  -- Check to see if we are touching the trophy
  if RPGlobals:InsideSquare(player.Position, entity.Position, 24) == false then -- 25 is a touch too big
    return
  end

  entity:Remove()
  player:AnimateCollectible(CollectibleType.COLLECTIBLE_TROPHY, "Pickup", "PlayerPickupSparkle2")

  if challenge == Challenge.CHALLENGE_NULL then -- 0
    -- Finish the race
    RPGlobals.raceVars.finished = true
    RPGlobals.raceVars.finishedTime = Isaac.GetTime() - RPGlobals.raceVars.startedTime
    RPGlobals.run.endOfRunText = true -- Show the run summary

    -- Tell the client that the goal was achieved (and the race length)
    Isaac.DebugString("Finished run - " .. tostring(RPGlobals.raceVars.finishedTime))

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

-- Fix seed "incrementation" from touching active pedestal items and do other various pedestal fixes
function RPCheckEntities:ReplacePedestal(pickup)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
  local challenge = Isaac.GetChallenge()

  -- Check to see if this is a pedestal that was already replaced
  for i = 1, #RPGlobals.run.replacedPedestals do
    if RPGlobals.run.replacedPedestals[i].room == roomIndex and
       RPGlobals.run.replacedPedestals[i].seed == pickup.InitSeed then

      -- We have already replaced it, so check to see if we need to delete the delay
      if pickup.Wait > 15 then
        -- When we enter a new room, the "wait" variable on all pedestals is set to 18
        -- This is too long, so shorten it
        pickup.Wait = 15
      end
      return
    end
  end

  -- We haven't replaced this pedestal yet,
  -- so start off by assuming that we should set the new pedestal seed to that of the room
  local newSeed = roomSeed

  if pickup.Touched then
    -- If we touched this item, we need to set it back to the last seed that we have for this position
    for i = 1, #RPGlobals.run.replacedPedestals do
      if RPGlobals.run.replacedPedestals[i].room == roomIndex and
         RPGlobals:InsideSquare(RPGlobals.run.replacedPedestals[i], pickup.Position, 15) then

        -- Don't break after this because we want it to be equal to the seed of the last item
        newSeed = RPGlobals.run.replacedPedestals[i].seed

        -- Also reset the position of the pedestal before we replace it
        -- (this is necessary because the player will push the pedestal slightly when they drop the item,
        -- so the replaced pedestal will be slightly off)
        pickup.Position = Vector(RPGlobals.run.replacedPedestals[i].X, RPGlobals.run.replacedPedestals[i].Y)
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
  if (RPGlobals.race.rFormat == "seeded" or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)")) and
     stage == 1 and
     roomType == RoomType.ROOM_TREASURE and -- 4
     pickup.SubType ~= CollectibleType.COLLECTIBLE_OFF_LIMITS then -- 235

    offLimits = true
  end

  -- Check to see if this is a natural Krampus pedestal
  -- (we want to remove it because we spawn Krampus items manually to both seed it properly and speed it up)
  if pickup.SubType == CollectibleType.COLLECTIBLE_LUMP_OF_COAL or -- 132
     pickup.SubType == CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS then -- 293

    if RPGlobals.run.spawningKrampusItem then
      -- This is a manually spawned Krampus item with a seed of 0,
      -- so proceed with the replacement and change the flag to false
      RPGlobals.run.spawningKrampusItem = false
    elseif gameFrameCount <= RPGlobals.run.mysteryGiftFrame then
      Isaac.DebugString("A Lump of Coal from Mystery Gift detected; not deleting.")
    elseif pickup.Touched == false then -- We don't want to delete a head that we are swapping for something else
      -- This is a naturally spawned Krampus item
      pickup:Remove()
      Isaac.DebugString("Removed a naturally spawned Krampus item.")
      return
    end
  end

  -- Check to see if this is a natural Key Piece 1 or Key Piece 2
  -- (we want to remove it because we spawn key pieces manually to speed it up)
  if pickup.SubType == CollectibleType.COLLECTIBLE_KEY_PIECE_1 or -- 238
     pickup.SubType == CollectibleType.COLLECTIBLE_KEY_PIECE_2 then -- 239

    if RPGlobals.run.spawningKeyPiece then
      -- This is a manually spawned key piece with a seed of 0,
      -- so proceed with the replacement and change the flag to false
      RPGlobals.run.spawningKeyPiece = false
    else
      -- This is a naturally spawned Key Piece
      pickup:Remove()
      Isaac.DebugString("Removed a naturally spawned Key Piece.")
      return
    end
  end

  -- Check to see if this is a special Basement 1 diversity reroll
  -- (these custom placeholder items are removed in all non-diveristy runs)
  local specialReroll = 0
  if stage == 1 and
     roomType == RoomType.ROOM_TREASURE and -- 4
     RPGlobals.race.rFormat == "diversity" then

    if pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1 then
      specialReroll = CollectibleType.COLLECTIBLE_INCUBUS -- 360
    elseif pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2 then
      specialReroll = CollectibleType.COLLECTIBLE_SACRED_HEART -- 182
    elseif pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3 then
      specialReroll = CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT -- 415
    end

  elseif pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1 or
         pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2 or
         pickup.SubType == CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3 then

    -- If the player is on a diversity race and gets a Treasure pool item on basement 1,
    -- then there is a chance that they could get a placeholder item
    pickup.SubType = 0
  end

  -- Check to see if this is a banned item on the "Unseeded (Lite)" ruleset
  local big4Reroll = false
  if stage == 1 and
     roomType == RoomType.ROOM_TREASURE and -- 4
     RPGlobals.race.rFormat == "unseeded-lite" and
     (pickup.SubType == CollectibleType.COLLECTIBLE_MOMS_KNIFE or -- 114
      pickup.SubType == CollectibleType.COLLECTIBLE_IPECAC or -- 149
      pickup.SubType == CollectibleType.COLLECTIBLE_EPIC_FETUS or -- 168
      pickup.SubType == CollectibleType.COLLECTIBLE_TECH_X) then -- 395

    big4Reroll = true
  end

  -- Check to see if this item should go into a Schoolbag
  local putInSchoolbag = RPSchoolbag:CheckSecondItem(pickup)
  if putInSchoolbag then
    return
  end

  -- Replace the pedestal
  RPGlobals.run.usedButterFrame = 0
  -- If we are replacing a pedestal, make sure this is reset to avoid the bug where
  -- it takes two item touches to re-enable the Schoolbag
  local randomItem = false
  local newPedestal
  if offLimits then
    -- Change the item to Off Limits (5.100.235)
    newPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pickup.Position,
                             pickup.Velocity, pickup.Parent, CollectibleType.COLLECTIBLE_OFF_LIMITS, newSeed)

    -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
    game:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0)
    Isaac.DebugString("Made an Off Limits pedestal using seed: " .. tostring(newSeed))

  elseif specialReroll ~= 0 then
    -- Change the item to the special reroll
    newPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pickup.Position,
                             pickup.Velocity, pickup.Parent, specialReroll, newSeed)

    -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
    game:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0)
    RPGlobals.run.changeFartColor = true -- Change it to a bright red fart to distinguish that it is a special reroll
    Isaac.DebugString("Item " .. tostring(pickup.SubType) .. " is special, " ..
                      "made a new " .. tostring(specialReroll) .. " pedestal using seed: " .. tostring(newSeed))

  elseif big4Reroll then
    -- Make a new random item pedestal
    -- (the new random item generated will automatically be decremented from item pools properly on sight)
    newPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pickup.Position,
                             pickup.Velocity, pickup.Parent, 0, newSeed)
    randomItem = true -- We need to set this so that banned items don't reroll into other banned items

    -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
    game:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0)
    Isaac.DebugString("Rerolled a big 4 item: " .. tostring(pickup.SubType))

  else
    -- Code in the MC_POST_PICKUP_SELECTION callback will prevent The Polaroid or The Negative from spawning,
    -- so let it know that we are explicitly spawning it using Lua code
    if pickup.SubType == CollectibleType.COLLECTIBLE_POLAROID or -- 327
       pickup.SubType == CollectibleType.COLLECTIBLE_NEGATIVE then -- 328

      RPGlobals.run.spawningPhoto = true
    end

    -- Make a new copy of this item
    newPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pickup.Position,
                             pickup.Velocity, pickup.Parent, pickup.SubType, newSeed)

    -- We don't need to make a fart noise because the swap will be completely transparent to the user
    -- (the sprites of the two items will obviously be identical)
    -- We don't need to add this item to the ban list because since it already existed, it was properly
    -- decremented from the pools on sight
    Isaac.DebugString("Made a copied " .. tostring(pickup.SubType) ..
                      " pedestal using seed " .. tostring(newSeed) .. " (on frame " .. tostring(gameFrameCount) .. ").")
  end
  newPedestal = newPedestal:ToPickup()

  -- We don't want to replicate the charge if this is a brand new item
  if specialReroll == 0 then
    -- If we don't do this, the item will be fully recharged every time the player swaps it out
    newPedestal.Charge = pickup.Charge
  end

  -- If we don't do this, shop and Devil Room items will become automatically bought
  newPedestal.Price = pickup.Price

  -- We need to keep track of touched items for banned item exception purposes
  newPedestal.Touched = pickup.Touched

  -- If we don't do this, shop items will reroll into consumables and
  -- shop items that are on sale will no longer be on sale
  newPedestal.ShopItemId = pickup.ShopItemId

  -- If we don't do this, you can take both of the pedestals in a double Treasure Room
  newPedestal.TheresOptionsPickup = pickup.TheresOptionsPickup

  -- Also reduce the vanilla delay that is imposed upon newly spawned collectible items
  -- (this is commented out because people were accidentally taking items)
  --newPedestal.Wait = 15 -- On vanilla, all pedestals get a 20 frame delay

  -- We never need to worry about players accidentally picking up Checkpoint
  if pickup.SubType == CollectibleType.COLLECTIBLE_CHECKPOINT then
    newPedestal.Wait = 0 -- On vanilla, all pedestals get a 20 frame delay
  end

  -- Add it to the tracking table so that we don't replace it again
  -- (and don't add random items to the index in case a banned item rolls into another banned item)
  if randomItem == false then
    RPGlobals.run.replacedPedestals[#RPGlobals.run.replacedPedestals + 1] = {
      room = roomIndex,
      X    = pickup.Position.X,
      Y    = pickup.Position.Y,
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
  pickup:Remove()
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

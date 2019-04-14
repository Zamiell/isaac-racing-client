local CheckEntities = {}

-- Includes
local g                  = require("src/globals")
local UseItem            = require("src/useitem")
local RPPedestals        = require("src/pedestals")
local FastTravel         = require("src/fasttravel")
local Race               = require("src/race")
local Speedrun           = require("src/speedrun")
local ChangeCharOrder    = require("src/changecharorder")
local SpeedrunPostUpdate = require("src/speedrunpostupdate")
local Samael             = require("src/samael")

-- Check all the grid entities in the room
-- (called from the PostUpdate callback)
function CheckEntities:Grid()
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
        FastTravel:ReplaceTrapdoor(gridEntity, i)

      elseif saveState.Type == GridEntityType.GRID_STAIRS then -- 18
        FastTravel:ReplaceCrawlspace(gridEntity, i)

      elseif saveState.Type == GridEntityType.GRID_PRESSURE_PLATE then -- 20
        ChangeCharOrder:CheckButtonPressed(gridEntity)
        SpeedrunPostUpdate:CheckVetoButton(gridEntity)
      end
    end
  end
end

-- Check all the non-grid entities in the room
-- (called from the PostUpdate callback)
function CheckEntities:NonGrid()
  -- Local variables
  local sfx = SFXManager()

  -- Go through all the entities
  CheckEntities.fireworkActive = false
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_BOMBDROP then -- 4
      CheckEntities:Entity4(entity:ToBomb())

    elseif entity.Type == EntityType.ENTITY_PICKUP then -- 5
      CheckEntities:Entity5(entity:ToPickup())

    elseif entity.Type == EntityType.ENTITY_SLOT then -- 6
      CheckEntities:Entity6(entity) -- There is no "entity:ToSlot()" function

    elseif entity.Type == EntityType.ENTITY_ATTACKFLY then -- 18
      CheckEntities:Entity18(entity:ToNPC())

    elseif entity.Type == EntityType.ENTITY_THE_HAUNT then -- 260
      CheckEntities:Entity260(entity:ToNPC())

    elseif entity.Type == EntityType.ENTITY_EFFECT then -- 1000
      CheckEntities:Entity1000(entity:ToEffect())

    elseif entity.Type == Isaac.GetEntityTypeByName("Race Trophy") and -- 1001
           entity.Variant == Isaac.GetEntityVariantByName("Race Trophy") then -- 0

      CheckEntities:EntityRaceTrophy(entity)
    end
  end

  -- Make Fireworks quieter
  if CheckEntities.fireworkActive then
    if sfx:IsPlaying(SoundEffect.SOUND_BOSS1_EXPLOSIONS) then -- 182
      sfx:AdjustVolume(SoundEffect.SOUND_BOSS1_EXPLOSIONS, 0.2)
    end
  end
end

-- EntityType.ENTITY_BOMBDROP (4)
function CheckEntities:Entity4(bomb)
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
function CheckEntities:Entity5(pickup)
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
      Samael:CheckRechargeWraithSkull()
    end
  end

  if pickup.Variant == PickupVariant.PICKUP_SPIKEDCHEST or -- 52
     pickup.Variant == PickupVariant.PICKUP_MIMICCHEST then -- 54

    -- Check to see if we are in a specific room where a Spiked Chest or Mimic will cause unavoidable damage
    local roomDataVariant = roomData.Variant
    while roomDataVariant >= 10000 do
      -- The 3 flipped versions of room #1 would be #10001, #20001, and #30001
      roomDataVariant = roomDataVariant - 10000
    end

    -- roomData.StageID always returns 0 for some reason, so just use stage and stageType as a workaround
    if ((stage == 1 or stage == 2) and stageType == 0 and roomDataVariant == 716) or -- Basement
       ((stage == 1 or stage == 2) and stageType == 1 and roomDataVariant == 716) or -- Cellar
       ((stage == 1 or stage == 2) and stageType == 2 and roomDataVariant == 716) or -- Burning Basement
       ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 12) or -- Caves
       ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 19) or
       ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 125) or
       ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 244) or
       ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 518) or
       ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 519) or
       ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 19) or -- Catacombs
       ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 285) or
       ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 518) or
       ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 12) or -- Flooded Caves
       ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 19) or
       ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 125) or
       ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 244) or
       ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 518) or
       ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 519) or
       ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 1008) or
       ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 1014) or
       ((stage == 5 or stage == 6) and stageType == 1 and roomDataVariant == 936) or -- Necropolis
       ((stage == 5 or stage == 6) and stageType == 1 and roomDataVariant == 973) or
       ((stage == 7 or stage == 8) and stageType == 0 and roomDataVariant == 458) or -- Womb
       ((stage == 7 or stage == 8) and stageType == 0 and roomDataVariant == 489) or
       ((stage == 7 or stage == 8) and stageType == 1 and roomDataVariant == 458) or -- Utero
       ((stage == 7 or stage == 8) and stageType == 1 and roomDataVariant == 489) or
       ((stage == 7 or stage == 8) and stageType == 2 and roomDataVariant == 458) or -- Scarred Womb
       ((stage == 7 or stage == 8) and stageType == 2 and roomDataVariant == 489) then

      -- Change it to a normal chest
      pickup.Variant = 50
      pickup:GetSprite():Load("gfx/005.050_chest.anm2", true)
      pickup:GetSprite():Play("Appear", false)
      -- (we have to play an animation for the new sprite to actually appear)
      Isaac.DebugString("Replaced a Spiked Chest / Mimic with a normal chest (for an unavoidable damage room).")

      -- Mark it so that other mods are aware of the replacement
      local data = pickup:GetData()
      data.unavoidableReplacement = true
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
    CheckEntities:Entity5_100(pickup)

  elseif pickup.Variant == PickupVariant.PICKUP_TRINKET then -- 350
    if g.run.roomsEntered <= 1 and
       g.race.rFormat == "pageant" then

      -- Delete Pageant Boy starting trinkets
      pickup:Remove()
    end

  elseif pickup.Variant == PickupVariant.PICKUP_BIGCHEST then -- 340
    CheckEntities:Entity5_340(pickup)

  elseif pickup.Variant == PickupVariant.PICKUP_TROPHY then -- 370
    CheckEntities:Entity5_370(pickup)
  end

  -- We want to check all pickups
  if pickup.Touched == false then
    -- Pickups will still exist for 15 frames after being picked up since they will be playing the "Collect" animation
    -- So we don't want to move a pickup that is already collected, or it will duplicate it
    -- ("Touched" was manually set to true by the mod earlier)

    -- Alternatively, we could check for "entity.EntityCollisionClass ~= 0",
    -- but this is bad because the collision is 0 during the long "Appear" animation

    -- Make sure that pickups are not overlapping with trapdoors / beams of light / crawlspaces
    FastTravel:CheckPickupOverHole(pickup)
  end
end

-- PickupVariant.PICKUP_COLLECTIBLE (5.100)
function CheckEntities:Entity5_100(pickup)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  -- We manually manage the seed of all collectible items
  if gameFrameCount >= g.run.itemReplacementDelay then
    -- We need to delay after using a Void (in case the player has consumed a D6)
    RPPedestals:Replace(pickup)
  end
end

-- PickupVariant.PICKUP_BIGCHEST (5.340)
function CheckEntities:Entity5_340(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local room = game:GetRoom()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
  local player = game:GetPlayer(0)
  local challenge = Isaac.GetChallenge()

  -- Check to see if we already determined that we should leave this big chest
  if pickup.Touched then
    return
  end

  Isaac.DebugString("Big Chest detected.")
  CheckEntities.bigChestAction = "leave" -- Leave the big chest there by default
  if stage == LevelStage.STAGE5 then -- 10
    if stageType == StageType.STAGETYPE_ORIGINAL and -- 10.0 (Sheol)
       player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328

      CheckEntities.bigChestAction = "down"

    elseif stageType == StageType.STAGETYPE_WOTL and -- 10.1 (Cathedral)
           player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327

      CheckEntities.bigChestAction = "up"
    end
  end
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") then
    CheckEntities:Entity5_340_S1R9(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
    CheckEntities:Entity5_340_S1R14(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") then
    CheckEntities:Entity5_340_S2(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") then
    CheckEntities:Entity5_340_S3(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") then
    CheckEntities:Entity5_340_S4(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
    CheckEntities:Entity5_340_S5(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 6 Beta)") then
    CheckEntities:Entity5_340_S6(pickup)
  elseif Speedrun.inSeededSpeedrun then
    CheckEntities:Entity5_340_SS(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then
    CheckEntities:Entity5_340_S0(pickup)
  elseif g.raceVars.finished then
    CheckEntities.bigChestAction = "victorylap"
  elseif g.race.rFormat == "pageant" then
    CheckEntities:Entity5_340_Pageant(pickup)
  elseif g.race.goal == "Blue Baby" and g.raceVars.started then
    CheckEntities:Entity5_340_BlueBaby(pickup)
  elseif g.race.goal == "The Lamb" and g.raceVars.started  then
    CheckEntities:Entity5_340_TheLamb(pickup)
  elseif g.race.goal == "Mega Satan" and g.raceVars.started then
    CheckEntities:Entity5_340_MegaSatan(pickup)
  elseif g.race.goal == "Everything" and g.raceVars.started then
    CheckEntities:Entity5_340_Everything(pickup)
  elseif stage == LevelStage.STAGE5 and stageType == StageType.STAGETYPE_ORIGINAL and -- 10.0 (Sheol)
         player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328
    CheckEntities.bigChestAction = "down" -- Leave the big chest there by default
  elseif stage == LevelStage.STAGE5 and stageType == StageType.STAGETYPE_WOTL and -- 10.1 (Cathedral)
         player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327
    CheckEntities.bigChestAction = "up" -- Leave the big chest there by default
  end

  -- Now that we know what to do with the big chest, do it
  if CheckEntities.bigChestAction == "leave" then
    -- Set a flag so that we leave it alone on the next frame
    pickup.Touched = true

  elseif CheckEntities.bigChestAction == "up" then
    -- Delete the chest and replace it with a beam of light so that we can fast-travel normally
    FastTravel:ReplaceHeavenDoor(pickup, -1)
    -- A -1 indicates that we are replacing an entity instead of a grid entity

  elseif CheckEntities.bigChestAction == "down" then
    -- Delete the chest and replace it with a trapdoor so that we can fast-travel normally
    FastTravel:ReplaceTrapdoor(pickup, -1)
    -- A -1 indicates that we are replacing an entity instead of a grid entity

  elseif CheckEntities.bigChestAction == "remove" then
    pickup:Remove()

  elseif CheckEntities.bigChestAction == "checkpoint" then
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, room:GetCenterPos(), Vector(0, 0),
               nil, CollectibleType.COLLECTIBLE_CHECKPOINT, roomSeed)
    Speedrun.spawnedCheckpoint = true
    g.run.endOfRunText = true -- Show the run summary
    if Speedrun.averageTime == 0 then
      -- This will be in milliseconds, so we divide by 1000
      local elapsedTime = (Isaac.GetTime() - Speedrun.startedTime) / 1000
      Speedrun.averageTime = elapsedTime
    else
      -- This will be in milliseconds, so we divide by 1000
      local elapsedTime = (Isaac.GetTime() - Speedrun.finishTimeCharacter) / 1000
      Speedrun.averageTime = ((Speedrun.charNum - 1) * Speedrun.averageTime + elapsedTime) / Speedrun.charNum
    end
    Speedrun.finishTimeCharacter = Isaac.GetTime()
    Isaac.DebugString("Spawned a Checkpoint in the center of the room.")
    pickup:Remove()

  elseif CheckEntities.bigChestAction == "trophy" then
    if challenge ~= 0 or
       Speedrun.inSeededSpeedrun or
       g.race.status ~= "none" then

      -- We only want to spawn a trophy if we are on a custom speedrun challenge or currently in a race
      game:Spawn(Isaac.GetEntityTypeByName("Race Trophy"), Isaac.GetEntityVariantByName("Race Trophy"),
                 pickup.Position, pickup.Velocity, nil, 0, 0)
      Isaac.DebugString("Spawned the end of race/speedrun trophy.")
      pickup:Remove()

    else
      -- Set a flag so that we leave it alone on the next frame
      pickup.Touched = true
      Isaac.DebugString("Avoiding spawning the Trophy since we are not in a speedrun or race.")
    end

  elseif CheckEntities.bigChestAction == "victorylap" then
    -- Spawn a Victory Lap (a custom item that emulates Forget Me Now) in the center of the room
    local victoryLapPosition = room:GetCenterPos()
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, victoryLapPosition, Vector(0, 0),
               nil, CollectibleType.COLLECTIBLE_VICTORY_LAP, roomSeed)
    Isaac.DebugString("Spawned a Victory Lap in the center of the room.")
    pickup:Remove()
  end
end

function CheckEntities:Entity5_340_S1R9(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  if stage == 11 and stageType == 1 then -- The Chest
    if Speedrun.charNum == 9 then
      CheckEntities.bigChestAction = "trophy"
    else
      CheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function CheckEntities:Entity5_340_S1R14(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  if stage == 11 and stageType == 1 then -- The Chest
    if Speedrun.charNum == 14 then
      CheckEntities.bigChestAction = "trophy"
    else
      CheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function CheckEntities:Entity5_340_S2(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  if stage == 10 and stageType == 0 then -- Sheol
    -- The Negative is optional in this season
    CheckEntities.bigChestAction = "down"

  elseif stage == 11 and stageType == 0 then -- Dark Room
    -- For custom Dark Room challenges, sometimes the vanilla end of challenge trophy does not appear
    -- Thus, we need to handle replacing both the trophy and the big chest
    -- So replace the big chest with either a checkpoint flag or a custom trophy,
    -- depending on if we are on the last character or not
    if Speedrun.charNum == 7 then
      CheckEntities.bigChestAction = "trophy"
    else
      CheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function CheckEntities:Entity5_340_S3(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  -- Season 3 runs alternate between directions, so we need to make sure we only handle the intended direction
  local direction = Speedrun.charNum % 2 -- 1 is up, 2 is down
  if direction == 0 then
    direction = 2
  end

  -- The Polaroid / The Negative is optional in this season
  if stage == 10 and stageType == 1 and -- Cathedral
     direction == 1 then

    CheckEntities.bigChestAction = "up"

  elseif stage == 10 and stageType == 0 and -- Sheol
         direction == 2 then

    CheckEntities.bigChestAction = "down"

  elseif (stage == 11 and stageType == 1 and -- The Chest
          direction == 1) or
         (stage == 11 and stageType == 0 and -- Dark Room
          direction == 2) then

    -- Sometimes the vanilla end of challenge trophy does not appear
    -- Thus, we need to handle replacing both the trophy and the big chest
    -- So replace the big chest with either a checkpoint flag or a custom trophy,
    -- depending on if we are on the last character or not
    if Speedrun.charNum == 7 then
      CheckEntities.bigChestAction = "trophy"
    else
      CheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function CheckEntities:Entity5_340_S4(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  if stage == 10 and stageType == 1 then -- Cathedral
    -- The Polaroid / The Negative is optional in this season
    CheckEntities.bigChestAction = "up"

  elseif stage == 11 and stageType == 1 then -- The Chest
    if Speedrun.charNum == 7 then
      CheckEntities.bigChestAction = "trophy"
    else
      CheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function CheckEntities:Entity5_340_S5(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  if stage == 10 and stageType == 1 then -- Cathedral
    -- The Polaroid / The Negative is optional in this season
    CheckEntities.bigChestAction = "up"

  elseif stage == 11 and stageType == 1 then -- The Chest
    if Speedrun.charNum == 7 then
      CheckEntities.bigChestAction = "trophy"
    else
      CheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function CheckEntities:Entity5_340_S6(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  -- Season 6 runs alternate between directions, so we need to make sure we only handle the intended direction
  local direction = Speedrun.charNum % 2 -- 1 is up, 2 is down
  if direction == 0 then
    direction = 2
  end

  -- The Polaroid / The Negative is optional in this season
  if stage == 10 and stageType == 1 and -- Cathedral
     direction == 1 then

    CheckEntities.bigChestAction = "up"

  elseif stage == 10 and stageType == 0 and -- Sheol
         direction == 2 then

    CheckEntities.bigChestAction = "down"

  elseif (stage == 11 and stageType == 1 and -- The Chest
          direction == 1) or
         (stage == 11 and stageType == 0 and -- Dark Room
          direction == 2) then

    -- Sometimes the vanilla end of challenge trophy does not appear
    -- Thus, we need to handle replacing both the trophy and the big chest
    -- So replace the big chest with either a checkpoint flag or a custom trophy,
    -- depending on if we are on the last character or not
    if Speedrun.charNum == 7 then
      CheckEntities.bigChestAction = "trophy"
    else
      CheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function CheckEntities:Entity5_340_SS(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  if stage == 11 and stageType == 1 then -- The Chest
    if Speedrun.charNum == 7 then
      CheckEntities.bigChestAction = "trophy"
    else
      CheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function CheckEntities:Entity5_340_S0(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  if stage == 11 and stageType == 1 then -- The Chest
    if Speedrun.charNum == 15 then
      CheckEntities.bigChestAction = "trophy"
    else
      CheckEntities.bigChestAction = "checkpoint"
    end
  end
end

function CheckEntities:Entity5_340_Pageant(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()

  if stage == 11 then -- The Chest or the Dark Room
    -- We want to delete all big chests on the Pageant Boy ruleset so that
    -- you don't accidently end your run before you can show off your build to the judges
    CheckEntities.bigChestAction = "remove"
  end
end

function CheckEntities:Entity5_340_BlueBaby(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end

  if stage == 11 and stageType == 1 and -- The Chest
     roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    CheckEntities.bigChestAction = "trophy"
  end
end

function CheckEntities:Entity5_340_TheLamb(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end

  if stage == 11 and stageType == 0 and -- Dark Room
     roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    CheckEntities.bigChestAction = "trophy"
  end
end

function CheckEntities:Entity5_340_Everything(pickup)
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
    CheckEntities.bigChestAction = "down"

  elseif stage == 10 and stageType == 0 then
    -- Sheol goes to The Chest
    CheckEntities.bigChestAction = "up"

  elseif stage == 11 and stageType == 1 then -- 7
    -- The Chest goes to the Dark Room
    CheckEntities.bigChestAction = "down"

  elseif stage == 11 and stageType == 0 then
    if roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
      CheckEntities.bigChestAction = "remove"
    else
      CheckEntities.bigChestAction = "trophy"
    end
  end
end

function CheckEntities:Entity5_340_MegaSatan(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local stage = level:GetStage()

  if stage == 11 and -- The Chest or the Dark Room
     roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    -- We want to delete the big chest after Blue Baby or The Lamb
    -- to remind the player that they have to go to Mega Satan
    CheckEntities.bigChestAction = "remove"

  elseif stage == 11 and -- The Chest or the Dark Room
        roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    CheckEntities.bigChestAction = "trophy"
  end
end

-- PickupVariant.PICKUP_TROPHY (5.370)
function CheckEntities:Entity5_370(pickup)
  -- Local variables
  local game = Game()

  -- Do nothing if we are not on a custom speedrun challenge
  -- (otherwise we would mess with the normal challenges)
  if Speedrun:InSpeedrun() == false then
    return
  end

  -- It can be unpredicable whether a big chest or a trophy will spawn;
  -- so funnel all decision making through the Big Chest code
  Isaac.DebugString("Vanilla trophy detected; replacing it with a Big Chest.")
  game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, -- 5.340
             pickup.Position, pickup.Velocity, nil, 0, 0)
  pickup:Remove()
end

-- EntityType.ENTITY_SLOT (6)
function CheckEntities:Entity6(entity)
  -- Ensure that Donation Machines are removed
  -- (even with the BLCK CNDL Easter Egg, they can still be created by Greed Plates in certain circumstances
  -- due to the save file validation code)
  if entity.Variant == 8 then -- Donation Machine
    entity:Remove()
    Isaac.DebugString("Manually removed a Donation Machine (from the PostUpdate callback).")
  end
end

-- EntityType.ENTITY_ATTACKFLY (18)
function CheckEntities:Entity18(npc)
  -- There is a weird bug where an Attack Fly will get set to a NaN position and
  -- will appear in the bottom-right hand corner of the room but will not be able to be damaged
  -- This might be a vanilla bug where the game runs out of memory and cannot create the fly properly
  -- This has mostly happened on the Blue Baby fight, although it can happen in other places as well
  -- Attempt to fix this bug in Racing+
  if npc.Position.X ~= npc.Position.X then -- Kilburn says that NaN isn't equal to itself
    npc:Remove()
    Isaac.DebugString("Error: Manually removed a null position fly.")
  end
end

-- EntityType.ENTITY_THE_HAUNT (260)
function CheckEntities:Entity260(npc)
  -- We only care about Lil' Haunts (260.10)
  if npc.Variant ~= 10 then
    return
  end

  -- Add them to the table so that we can track them
  local index = GetPtrHash(npc)
  if g.run.currentLilHaunts[index] == nil then
    -- This can't be in the NPC_UPDATE callback because it does not fire during the "Appear" animation
    -- This can't be in the MC_POST_NPC_INIT callback because the position is always equal to (0, 0) there
    g.run.currentLilHaunts[index] = {
      index = npc.Index, -- We could have this just be table index instead, but it's safer to use the hash
      pos = npc.Position,
      ptr = EntityPtr(npc),
    }
    local string = "Added a Lil' Haunt with index " .. tostring(index) .. " to the table (with "
    if npc.Parent == nil then
      string = string .. "no"
    else
      string = string .. "a"
      g.run.currentLilHaunts[index].parentIndex = npc.Parent.Index
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

    npc.Position = g.run.currentLilHaunts[index].pos
    npc.Velocity = Vector(0, 0)
  end
end

-- EntityType.ENTITY_EFFECT (1000)
function CheckEntities:Entity1000(effect)
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  if effect.Variant == EffectVariant.FART and -- 34
     g.run.changeFartColor == true then

    -- We want special rolls to have a different fart color to distinguish them
    g.run.changeFartColor = false
    local color = Color(5.5, 0.2, 0.2, 1, 0, 0, 0) -- Bright red
    effect:SetColor(color, 0, 0, false, false)

  elseif effect.Variant == EffectVariant.HEAVEN_LIGHT_DOOR then -- 39
    FastTravel:ReplaceHeavenDoor(effect)

  elseif effect.Variant == EffectVariant.DICE_FLOOR then -- 76
    -- We need to keep track of when the player uses a 5-pip Dice Room so that we can seed the floor appropriately
    if g.run.diceRoomActivated == false and
       effect.SubType == 4 and -- 5-pip Dice Room
       g:InsideSquare(player.Position, effect.Position, 75) then -- Determined through trial and error

      g.run.diceRoomActivated = true
      UseItem:Item127() -- Forget Me Now
    end

  elseif effect.Variant == EffectVariant.FIREWORKS then -- 104
    -- Check for fireworks so that we can reduce the volume
    CheckEntities.fireworkActive = true

  elseif effect.Variant == Isaac.GetEntityVariantByName("Trapdoor (Fast-Travel)") or -- 201
         effect.Variant == Isaac.GetEntityVariantByName("Womb Trapdoor (Fast-Travel)") or -- 203
         effect.Variant == Isaac.GetEntityVariantByName("Blue Womb Trapdoor (Fast-Travel)") then -- 204

    FastTravel:CheckTrapdoorCrawlspaceOpen(effect)
    FastTravel:CheckTrapdoorEnter(effect, false) -- The second argument is "upwards"

  elseif effect.Variant == Isaac.GetEntityVariantByName("Crawlspace (Fast-Travel)") then -- 202
    FastTravel:CheckTrapdoorCrawlspaceOpen(effect)
    FastTravel:CheckCrawlspaceEnter(effect)

  elseif effect.Variant == Isaac.GetEntityVariantByName("Heaven Door (Fast-Travel)") then -- 205
    FastTravel:CheckTrapdoorEnter(effect, true) -- The second argument is "upwards"
  end
end

function CheckEntities:EntityRaceTrophy(entity)
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local challenge = Isaac.GetChallenge()

  if g.raceVars.finished or Speedrun.finished then
    return
  end

  -- We should not be able to finish the race while we are in ghost form
  if g.run.seededDeath.state == 3 then
    return
  end

  -- Check to see if we are touching the trophy
  if g:InsideSquare(player.Position, entity.Position, 24) == false then -- 25 is a touch too big
    return
  end

  entity:Remove()
  player:AnimateCollectible(CollectibleType.COLLECTIBLE_TROPHY, "Pickup", "PlayerPickupSparkle2")

  if challenge == Challenge.CHALLENGE_NULL and -- 0
     Speedrun.inSeededSpeedrun == false then

    Race:Finish()

  else
    Speedrun:Finish()
  end
end

return CheckEntities

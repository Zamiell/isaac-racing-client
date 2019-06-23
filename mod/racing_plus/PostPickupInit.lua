local PostPickupInit = {}

-- Note: Position, SpawnerType, SpawnerVariant, and Price are not initialized yet in this callback

-- Includes
local g          = require("racing_plus/globals")
local FastTravel = require("racing_plus/fasttravel")
local Speedrun   = require("racing_plus/speedrun")

-- Variables
PostPickupInit.bigChestAction = false

-- PickupVariant.PICKUP_TAROTCARD (300)
function PostPickupInit:Pickup300(pickup)
  if pickup.SubType == Card.RUNE_BLANK or -- 40
     pickup.SubType == Card.RUNE_BLACK then -- 41

   -- Give an alternate rune sprite (one that isn't tilted left or right)
   local sprite = pickup:GetSprite()
   sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/pickup_unique_generic_rune.png")

   -- The black rune will now glow black; remove this from the blank rune
   sprite:ReplaceSpritesheet(1, "gfx/items/pick ups/pickup_unique_generic_rune.png")

   sprite:LoadGraphics()
   return

 elseif pickup.SubType == Card.CARD_CHAOS or -- 42
        -- Credit Card (43) has a unique card back in vanilla
        pickup.SubType == Card.CARD_RULES or -- 44
        -- A Card Against Humanity (45) has a unique card back in vanilla
        pickup.SubType == Card.CARD_SUICIDE_KING or -- 46
        pickup.SubType == Card.CARD_GET_OUT_OF_JAIL or -- 47
        -- (Get out of Jail Free Card has a unique card back in vanilla, but this one looks better)
        pickup.SubType == Card.CARD_QUESTIONMARK or -- 48
        -- Dice Shard (49) has a unique card back in vanilla
        -- Emergency Contact (50) has a unique card back in vanilla
        -- Holy Card (51) has a unique card back in vanilla
        (pickup.SubType >= Card.CARD_HUGE_GROWTH and -- 52
         pickup.SubType <= Card.CARD_ERA_WALK) then -- 54

    -- Make some cards face-up
    local sprite = pickup:GetSprite()
    sprite:ReplaceSpritesheet(0, "gfx/cards/" .. tostring(pickup.SubType) .. ".png")
    sprite:LoadGraphics()
   end
end

-- PickupVariant.PICKUP_BIGCHEST (340)
function PostPickupInit:Pickup340(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"
  local challenge = Isaac.GetChallenge()

  Isaac.DebugString("Big Chest detected.")

  -- Since the chest's position is not initialized yet in this callback,
  -- manually set it to the center of the room for use in subsequent functions
  pickup.Position = g.r:GetCenterPos()

  -- By default, leave the big chest there
  PostPickupInit.bigChestAction = "leave"

  -- Determine if we should replace the big chest with something else
  if stage == LevelStage.STAGE5 then -- 10
    if stageType == StageType.STAGETYPE_ORIGINAL and -- 10.0 (Sheol)
       g.p:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328

      PostPickupInit.bigChestAction = "down"

    elseif stageType == StageType.STAGETYPE_WOTL and -- 10.1 (Cathedral)
           g.p:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327

      PostPickupInit.bigChestAction = "up"
    end
  end
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") then
    PostPickupInit:Pickup340_S1R9(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
    PostPickupInit:Pickup340_S1R14(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") then
    PostPickupInit:Pickup340_S2(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") then
    PostPickupInit:Pickup340_Speedrun_Alternate(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") then
    PostPickupInit:Pickup340_Speedrun_Up(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
    PostPickupInit:Pickup340_Speedrun_Up(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") then
    PostPickupInit:Pickup340_Speedrun_Alternate(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)") then
    PostPickupInit:Pickup340_Speedrun_Alternate(pickup)
  elseif Speedrun.inSeededSpeedrun then
    PostPickupInit:Pickup340_SS(pickup)
  elseif challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then
    PostPickupInit:Pickup340_S0(pickup)
  elseif g.raceVars.finished then
    PostPickupInit.bigChestAction = "victorylap"
  elseif g.race.rFormat == "pageant" then
    PostPickupInit:Pickup340_Pageant(pickup)
  elseif g.race.goal == "Blue Baby" and g.raceVars.started then
    PostPickupInit:Pickup340_BlueBaby(pickup)
  elseif g.race.goal == "The Lamb" and g.raceVars.started then
    PostPickupInit:Pickup340_TheLamb(pickup)
  elseif g.race.goal == "Mega Satan" and g.raceVars.started then
    PostPickupInit:Pickup340_MegaSatan(pickup)
  elseif g.race.goal == "Hush" and g.raceVars.started then
    PostPickupInit:Pickup340_Hush(pickup)
  elseif g.race.goal == "Delirium" and g.raceVars.started then
    PostPickupInit:Pickup340_Delirium(pickup)
  elseif g.race.goal == "Boss Rush" and g.raceVars.started then
    PostPickupInit:Pickup340_BossRush(pickup)
  elseif g.race.goal == "Everything" and g.raceVars.started then
    PostPickupInit:Pickup340_Everything(pickup)
  elseif stage == LevelStage.STAGE5 and stageType == StageType.STAGETYPE_ORIGINAL and -- 10.0 (Sheol)
         g.p:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328
    PostPickupInit.bigChestAction = "down" -- Leave the big chest there by default
  elseif stage == LevelStage.STAGE5 and stageType == StageType.STAGETYPE_WOTL and -- 10.1 (Cathedral)
         g.p:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327
    PostPickupInit.bigChestAction = "up" -- Leave the big chest there by default
  end

  -- Now that we know what to do with the big chest, do it
  if PostPickupInit.bigChestAction == "leave" then
    -- Set a flag so that we leave it alone on the next frame
    pickup.Touched = true

  elseif PostPickupInit.bigChestAction == "up" then
    -- Delete the chest and replace it with a beam of light so that we can fast-travel normally
    pickup.SpawnerType = EntityType.ENTITY_PLAYER -- 1
    FastTravel:ReplaceHeavenDoor(pickup)

  elseif PostPickupInit.bigChestAction == "down" then
    -- Delete the chest and replace it with a trapdoor so that we can fast-travel normally
    FastTravel:ReplaceTrapdoor(pickup, -1)
    -- A -1 indicates that we are replacing an entity instead of a grid entity

  elseif PostPickupInit.bigChestAction == "remove" then
    pickup:Remove()

  elseif PostPickupInit.bigChestAction == "checkpoint" then
    g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, g.r:GetCenterPos(), g.zeroVector,
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

  elseif PostPickupInit.bigChestAction == "trophy" then
    if challenge ~= 0 or
       Speedrun.inSeededSpeedrun or
       g.race.status ~= "none" then

      -- We only want to spawn a trophy if we are on a custom speedrun challenge or currently in a race
      g.g:Spawn(EntityType.ENTITY_RACE_TROPHY, 0, g.r:GetCenterPos(), g.zeroVector, nil, 0, 0)
      Isaac.DebugString("Spawned the end of race/speedrun trophy.")
      pickup:Remove()

    else
      -- Set a flag so that we leave it alone on the next frame
      pickup.Touched = true
      Isaac.DebugString("Avoiding spawning the Trophy since we are not in a speedrun or race.")
    end

  elseif PostPickupInit.bigChestAction == "victorylap" then
    -- Spawn a Victory Lap (a custom item that emulates Forget Me Now) in the center of the room
    g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 5.100
              g.r:GetCenterPos(), g.zeroVector, nil, CollectibleType.COLLECTIBLE_VICTORY_LAP, roomSeed)
    Isaac.DebugString("Spawned a Victory Lap in the center of the room.")
    pickup:Remove()
  end
end

function PostPickupInit:Pickup340_S1R9(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  if stage == 11 and stageType == 1 then -- The Chest
    if Speedrun.charNum == 9 then
      PostPickupInit.bigChestAction = "trophy"
    else
      PostPickupInit.bigChestAction = "checkpoint"
    end
  end
end

function PostPickupInit:Pickup340_S1R14(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  if stage == 11 and stageType == 1 then -- The Chest
    if Speedrun.charNum == 14 then
      PostPickupInit.bigChestAction = "trophy"
    else
      PostPickupInit.bigChestAction = "checkpoint"
    end
  end
end

function PostPickupInit:Pickup340_S2(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  if stage == 10 and stageType == 0 then -- Sheol
    -- The Negative is optional in this season
    PostPickupInit.bigChestAction = "down"

  elseif stage == 11 and stageType == 0 then -- Dark Room
    -- Sometimes the vanilla end of challenge trophy does not appear
    -- Thus, we need to handle replacing both the trophy and the big chest
    -- So replace the big chest with either a checkpoint flag or a custom trophy,
    -- depending on if we are on the last character or not
    if Speedrun.charNum == 7 then
      PostPickupInit.bigChestAction = "trophy"
    else
      PostPickupInit.bigChestAction = "checkpoint"
    end
  end
end

function PostPickupInit:Pickup340_Speedrun_Alternate(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  -- Season 3 runs alternate between directions, so we need to make sure we only handle the intended direction
  local direction = Speedrun.charNum % 2 -- 1 is up, 2 is down
  if direction == 0 then
    direction = 2
  end

  -- The Polaroid / The Negative is optional in this season
  if stage == 10 and stageType == 1 and -- Cathedral
     direction == 1 then

    PostPickupInit.bigChestAction = "up"

  elseif stage == 10 and stageType == 0 and -- Sheol
         direction == 2 then

    PostPickupInit.bigChestAction = "down"

  elseif (stage == 11 and stageType == 1 and -- The Chest
          direction == 1) or
         (stage == 11 and stageType == 0 and -- Dark Room
          direction == 2) then

    -- Sometimes the vanilla end of challenge trophy does not appear
    -- Thus, we need to handle replacing both the trophy and the big chest
    -- So replace the big chest with either a checkpoint flag or a custom trophy,
    -- depending on if we are on the last character or not
    if Speedrun.charNum == 7 then
      PostPickupInit.bigChestAction = "trophy"
    else
      PostPickupInit.bigChestAction = "checkpoint"
    end
  end
end

function PostPickupInit:Pickup340_Speedrun_Up(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  if stage == 10 and stageType == 1 then -- Cathedral
    -- The Polaroid / The Negative is optional in this season
    PostPickupInit.bigChestAction = "up"

  elseif stage == 11 and stageType == 1 then -- The Chest
    if Speedrun.charNum == 7 then
      PostPickupInit.bigChestAction = "trophy"
    else
      PostPickupInit.bigChestAction = "checkpoint"
    end
  end
end

function PostPickupInit:Pickup340_SS(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  if stage == 11 and stageType == 1 then -- The Chest
    if Speedrun.charNum == 7 then
      PostPickupInit.bigChestAction = "trophy"
    else
      PostPickupInit.bigChestAction = "checkpoint"
    end
  end
end

function PostPickupInit:Pickup340_S0(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  if stage == 11 and stageType == 1 then -- The Chest
    if Speedrun.charNum == 15 then
      PostPickupInit.bigChestAction = "trophy"
    else
      PostPickupInit.bigChestAction = "checkpoint"
    end
  end
end

function PostPickupInit:Pickup340_Pageant(pickup)
  -- Local variables
  local stage = g.l:GetStage()

  if stage == 11 then -- The Chest or the Dark Room
    -- We want to delete all big chests on the Pageant Boy ruleset so that
    -- you don't accidently end your run before you can show off your build to the judges
    PostPickupInit.bigChestAction = "remove"
  end
end

function PostPickupInit:Pickup340_BlueBaby(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end

  if stage == 11 and stageType == 1 and -- The Chest
     roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    PostPickupInit.bigChestAction = "trophy"
  end
end

function PostPickupInit:Pickup340_TheLamb(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end

  if stage == 11 and stageType == 0 and -- Dark Room
     roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    PostPickupInit.bigChestAction = "trophy"
  end
end

function PostPickupInit:Pickup340_Everything(pickup)
  -- Local variables
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  if stage == 10 and stageType == 1 then
    -- Cathedral goes to Sheol
    PostPickupInit.bigChestAction = "down"

  elseif stage == 10 and stageType == 0 then
    -- Sheol goes to The Chest
    PostPickupInit.bigChestAction = "up"

  elseif stage == 11 and stageType == 1 then -- 7
    -- The Chest goes to the Dark Room
    PostPickupInit.bigChestAction = "down"

  elseif stage == 11 and stageType == 0 then
    if roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
      PostPickupInit.bigChestAction = "remove"
    else
      PostPickupInit.bigChestAction = "trophy"
    end
  end
end

function PostPickupInit:Pickup340_MegaSatan(pickup)
  -- Local variables
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end
  local stage = g.l:GetStage()

  if stage == 11 and -- The Chest or the Dark Room
     roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    -- We want to delete the big chest after Blue Baby or The Lamb
    -- to remind the player that they have to go to Mega Satan
    PostPickupInit.bigChestAction = "remove"

  elseif stage == 11 and -- The Chest or the Dark Room
        roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    PostPickupInit.bigChestAction = "trophy"
  end
end

function PostPickupInit:Pickup340_Hush(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  if stage == 9 then
    PostPickupInit.bigChestAction = "trophy"
  end
end

function PostPickupInit:Pickup340_Delirium(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  if stage == 14 then
    PostPickupInit.bigChestAction = "trophy"
  end
end

function PostPickupInit:Pickup340_BossRush(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  if stage == 6 then
    PostPickupInit.bigChestAction = "trophy"
  end
end

-- PickupVariant.PICKUP_TROPHY (370)
function PostPickupInit:Pickup370(pickup)
  -- Do nothing if we are not on a custom speedrun challenge
  -- (otherwise we would mess with the normal challenges)
  if not Speedrun:InSpeedrun() then
    return
  end

  -- It can be unpredicable whether a big chest or a trophy will spawn;
  -- so funnel all decision making through the Big Chest code
  Isaac.DebugString("Vanilla trophy detected; replacing it with a Big Chest.")
  g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, -- 5.340
            g.r:GetCenterPos(), g.zeroVector, nil, 0, 0)
  pickup:Remove()
end

function PostPickupInit:CheckSpikedChestUnavoidable(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomData = g.l:GetCurrentRoomDesc().Data

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
     ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 119) or
     ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 125) or
     ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 244) or
     ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 518) or
     ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 519) or
     ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 19) or -- Catacombs
     ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 119) or
     ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 285) or
     ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 518) or
     ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 12) or -- Flooded Caves
     ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 19) or
     ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 119) or
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
end

return PostPickupInit

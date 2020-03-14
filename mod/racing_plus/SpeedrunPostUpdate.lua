local SpeedrunPostUpdate = {}

-- Includes
local g        = require("racing_plus/globals")
local Speedrun = require("racing_plus/speedrun")
local Season8  = require("racing_plus/season8")

function SpeedrunPostUpdate:Main()
  if not Speedrun:InSpeedrun() then
    return
  end

  if RacingPlusData == nil then
    return
  end

  -- Check to see if we need to start the timers
  if Speedrun.startedTime == 0 then
    -- We want to start the timer on the first game frame (as opposed to when the screen is fading in)
    -- Thus, we must check for this on every frame
    -- This is to keep the timing consistent with historical timing of speedruns
    Speedrun.startedTime = Isaac.GetTime()
    Speedrun.startedFrame = Isaac.GetFrameCount()
    Speedrun.startedCharTime = Isaac.GetTime()
  end

  SpeedrunPostUpdate:CheckCheckpointTouched()
  SpeedrunPostUpdate:Season7CheckUltraGreedSpawned()
  Season8:PostUpdate()
end

-- Check to see if the player just picked up the "Checkpoint" custom item
-- Pass true to this function to force going to the next character
function SpeedrunPostUpdate:CheckCheckpointTouched(force)
  -- Local variables
  local isaacFrameCount = Isaac.GetFrameCount()

  if force == nil and
     (g.p.QueuedItem.Item == nil or
      g.p.QueuedItem.Item.ID ~= CollectibleType.COLLECTIBLE_CHECKPOINT or
      g.run.seededDeath.state ~= 0) then

    return
  end

  if Speedrun.spawnedCheckpoint then
    Speedrun.spawnedCheckpoint = false
  elseif force == nil then
    return
  end

  -- Give them the Checkpoint custom item
  -- (this is used by the AutoSplitter to know when to split)
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_CHECKPOINT, 0, false)
  Isaac.DebugString("Checkpoint custom item given (" .. tostring(CollectibleType.COLLECTIBLE_CHECKPOINT) .. ").")

  -- Freeze the player
  g.p.ControlsEnabled = false

  -- Mark to fade out after the "Checkpoint" text has displayed on the screen for a little bit
  Speedrun.fadeFrame = isaacFrameCount + 30

  -- Record how long this run took
  local elapsedTime = Isaac.GetTime() - Speedrun.startedCharTime
  Speedrun.charRunTimes[#Speedrun.charRunTimes + 1] = elapsedTime

  -- Mark our current time as the starting time for the next character
  Speedrun.startedCharTime = Isaac.GetTime()

  -- Show the run summary (including the average time per character for the run so far)
  g.run.endOfRunText = true

  -- Perform some additional actions for Season 7 speedruns
  SpeedrunPostUpdate:Season7CheckpointTouched()

  -- Perform some additional adtions for Season 8 speedruns
  Season8:PostCheckpointTouched()
end

-- For season 5, we need to record the starting item on the first character
-- so that we can avoid duplicate starting items later on
-- Called form the "PostUpdate:CheckItemPickup()" function
function SpeedrunPostUpdate:CheckFirstCharacterStartingItem()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 5)") or
     #g.run.passiveItems ~= 1 or
     Speedrun.charNum ~= 1 or
     g.run.roomsEntered < 2 then
     -- Characters can start with a starting item, so we want to make sure that we enter at least one room

    return
  end

  for i, remainingItem in ipairs(Speedrun.remainingItemStarts) do
    if remainingItem == g.run.passiveItems[1] then
      table.remove(Speedrun.remainingItemStarts, i)
      break
    end
  end
  Speedrun.selectedItemStarts[1] = g.run.passiveItems[1]
  Isaac.DebugString("Starting item " .. tostring(Speedrun.selectedItemStarts[1]) ..
                    " on the first character of an insta-start speedrun.")
end

-- For season 6, we need to handle the "Veto" button
-- Called from the "CheckEntities:Grid()" function
function SpeedrunPostUpdate:Season6CheckVetoButton(gridEntity)
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)") or
     Speedrun.charNum ~= 1 or
     g.run.roomsEntered ~= 1 or
     gridEntity:GetSaveState().State ~= 3 then

    return
  end

  -- Add the item to the veto list
  Speedrun.vetoList[#Speedrun.vetoList + 1] = Speedrun.lastBuildItem
  if #Speedrun.vetoList > 5 then
    table.remove(Speedrun.vetoList, 1)
  end

  -- Add the sprite to the sprite list
  Speedrun.vetoSprites = {}
  for i, veto in ipairs(Speedrun.vetoList) do
    Speedrun.vetoSprites[i] = Sprite()
    Speedrun.vetoSprites[i]:Load("gfx/schoolbag_item.anm2", false)
    local fileName = g.itemConfig:GetCollectible(veto).GfxFileName
    Speedrun.vetoSprites[i]:ReplaceSpritesheet(0, fileName)
    Speedrun.vetoSprites[i]:LoadGraphics()
    Speedrun.vetoSprites[i]:SetFrame("Default", 1)
    Speedrun.vetoSprites[i].Scale = Vector(0.75, 0.75)
  end

  -- Play a poop sound
  g.sfx:Play(SoundEffect.SOUND_FART, 1, 0, false, 1) -- 37

  -- Reset the timer and restart the game
  Speedrun.vetoTimer = Isaac.GetTime() + 5 * 1000 * 60 -- 5 minutes
  Speedrun.timeItemAssigned = 0
  g.run.restart = true
  Isaac.DebugString("Restarting because we vetoed item: " .. tostring(Speedrun.lastBuildItem))
end

-- For season 7, we need to remove goals
function SpeedrunPostUpdate:Season7CheckpointTouched()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    return
  end

  -- Show the remaining goals
  g.run.showGoalsFrame = gameFrameCount + 60

  --
  -- Remove the goal that we just completed
  --

  local roomType = g.r:GetType()
  if roomType == RoomType.ROOM_BOSSRUSH then -- 17
    g:TableRemove(Speedrun.remainingGoals, "Boss Rush")
    return
  end

  local roomIndexUnsafe = g.l:GetCurrentRoomIndex()
  if roomIndexUnsafe == GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
    g:TableRemove(Speedrun.remainingGoals, "Mega Satan")
    return
  end

  local stage = g.l:GetStage()
  if stage == 8 then
    g:TableRemove(Speedrun.remainingGoals, "It Lives!")
    return
  end

  if stage == 9 then
    g:TableRemove(Speedrun.remainingGoals, "Hush")
    return
  end

  local stageType = g.l:GetStageType()
  if stage == 11 and stageType == 1 then
    g:TableRemove(Speedrun.remainingGoals, "Blue Baby")
    return
  end

  if stage == 11 and stageType == 0 then
    g:TableRemove(Speedrun.remainingGoals, "The Lamb")
    return
  end

  if stage == 12 then
    g:TableRemove(Speedrun.remainingGoals, "Ultra Greed")
    return
  end
end

-- For season 7, we have to handle going into Ultra Greed with Door Stop
function SpeedrunPostUpdate:Season7CheckUltraGreedSpawned()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    return
  end

  if not g.run.spawnedUltraGreed then
    return
  end
  g.run.spawnedUltraGreed = false

  -- If a door is open (e.g. if a player has Door Stop),
  -- we want to delete the overlapping Ultra Greed Door
  for i = 0, 7 do
    local door = g.r:GetDoor(i)
    if door ~= nil and
       door:IsOpen() then

      -- Find the Ultra Greed Door that overlaps with this open door
      local ultraGreedDoors = Isaac.FindByType(EntityType.ENTITY_ULTRA_DOOR, -1, -1, false, false) -- 294
      for j, ultraGreedDoor in ipairs(ultraGreedDoors) do
        if ultraGreedDoor.Position:Distance(door.Position) < 25 then
          ultraGreedDoor:Remove()
        end
      end
    end
  end
end

return SpeedrunPostUpdate

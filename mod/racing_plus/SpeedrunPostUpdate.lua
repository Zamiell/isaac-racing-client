local SpeedrunPostUpdate = {}

-- Includes
local g        = require("racing_plus/globals")
local Speedrun = require("racing_plus/speedrun")
local Season7  = require("racing_plus/season7")
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
  Season7:CheckUltraGreedSpawned()
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

  -- Perform some additional actions for some specific seasons
  Season7:CheckpointTouched()
  Season8:CheckpointTouched()
end

return SpeedrunPostUpdate

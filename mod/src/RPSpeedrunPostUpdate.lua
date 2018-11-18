local RPSpeedrunPostUpdate = {}

-- Includes
local RPGlobals  = require("src/rpglobals")
local RPSpeedrun = require("src/rpspeedrun")

function RPSpeedrunPostUpdate:Main()
  if RPSpeedrun:InSpeedrun() == false then
    return
  end

  -- Check to see if we need to start the timers
  if RPSpeedrun.startedTime == 0 then
    -- We want to start the timer on the first game frame (as opposed to when the screen is fading in)
    -- Thus, we must check for this on every frame
    -- This is to keep the timing consistent with historical timing of speedruns
    RPSpeedrun.startedTime = Isaac.GetTime()
    RPSpeedrun.startedFrame = Isaac.GetFrameCount()
  end

  RPSpeedrunPostUpdate:TrackPassives()
  RPSpeedrunPostUpdate:CheckLilithExtraIncubus()
  RPSpeedrunPostUpdate:CheckCheckpoint()
end

-- Keep track of our passive items over the course of the run
function RPSpeedrunPostUpdate:TrackPassives()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  if player:IsItemQueueEmpty() == false and
     RPGlobals.run.queuedItems == false then

    RPGlobals.run.queuedItems = true
    if player.QueuedItem.Item.Type ~= ItemType.ITEM_ACTIVE then -- 3
      RPGlobals.run.passiveItems[#RPGlobals.run.passiveItems + 1] = player.QueuedItem.Item.ID
      if player.QueuedItem.Item.ID == CollectibleType.COLLECTIBLE_MUTANT_SPIDER_INNER_EYE then
        Isaac.DebugString("Adding collectible 3001 (Mutant Spider's Inner Eye)")
      end
      RPSpeedrunPostUpdate:CheckSeason5Start()
    end
  end
end

-- We need to record the starting item on the first character so that we can avoid duplicate starting items later on
function RPSpeedrunPostUpdate:CheckSeason5Start()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 5 Beta)") or
     #RPGlobals.run.passiveItems ~= 1 or
     RPSpeedrun.charNum ~= 1 or
     RPGlobals.run.roomsEntered < 2 then
     -- Babies can start with a starting item, so we want to make sure that we enter at least one room

    return
  end

  for i = 1, #RPSpeedrun.remainingItemStarts do
    if RPSpeedrun.remainingItemStarts[i] == RPGlobals.run.passiveItems[1] then
      table.remove(RPSpeedrun.remainingItemStarts, i)
      break
    end
  end
  RPSpeedrun.selectedItemStarts[1] = RPGlobals.run.passiveItems[1]
  Isaac.DebugString("Starting item " .. tostring(RPSpeedrun.selectedItemStarts[1]) ..
                    " on the first character of a season 5 run.")
end

-- In R+7 Season 4, we want to remove the Lilith's extra Incubus if they attempt to switch characters
function RPSpeedrunPostUpdate:CheckLilithExtraIncubus()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  if RPGlobals.run.extraIncubus and
     character ~= PlayerType.PLAYER_LILITH then -- 13

    RPGlobals.run.extraIncubus = false
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_INCUBUS) -- 360
    Isaac.DebugString("Removed the extra Incubus (for R+7 Season 4).")
  end
end

-- Check to see if the player just picked up the "Checkpoint" custom item
function RPSpeedrunPostUpdate:CheckCheckpoint()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local isaacFrameCount = Isaac.GetFrameCount()

  if player.QueuedItem.Item == nil or
     player.QueuedItem.Item.ID ~= CollectibleType.COLLECTIBLE_CHECKPOINT then

    return
  end

  if RPSpeedrun.spawnedCheckpoint then
    RPSpeedrun.spawnedCheckpoint = false
  else
    return
  end

  -- Give them the Checkpoint custom item
  -- (this is used by the AutoSplitter to know when to split)
  player:AddCollectible(CollectibleType.COLLECTIBLE_CHECKPOINT, 0, false)
  Isaac.DebugString("Checkpoint custom item given (" .. tostring(CollectibleType.COLLECTIBLE_CHECKPOINT) .. ").")

  -- Freeze the player
  player.ControlsEnabled = false

  -- Mark to fade out after the "Checkpoint" text has displayed on the screen for a little bit
  RPSpeedrun.fadeFrame = isaacFrameCount + 30
end

return RPSpeedrunPostUpdate

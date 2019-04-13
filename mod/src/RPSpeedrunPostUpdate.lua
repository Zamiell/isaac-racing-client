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

  RPSpeedrunPostUpdate:CheckLilithExtraIncubus()
  RPSpeedrunPostUpdate:CheckCheckpoint()
end

-- For season 5,
-- we need to record the starting item on the first character so that we can avoid duplicate starting items later on
function RPSpeedrunPostUpdate:CheckFirstCharacterStartingItem()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 5)") or
     #RPGlobals.run.passiveItems ~= 1 or
     RPSpeedrun.charNum ~= 1 or
     RPGlobals.run.roomsEntered < 2 then
     -- Characters can start with a starting item, so we want to make sure that we enter at least one room

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
                    " on the first character of an insta-start speedrun.")
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
-- Pass true to this function to force going to the next character
function RPSpeedrunPostUpdate:CheckCheckpoint(force)
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local isaacFrameCount = Isaac.GetFrameCount()

  if force == nil and
     (player.QueuedItem.Item == nil or
      player.QueuedItem.Item.ID ~= CollectibleType.COLLECTIBLE_CHECKPOINT) then

    return
  end

  if RPSpeedrun.spawnedCheckpoint then
    RPSpeedrun.spawnedCheckpoint = false
  elseif force == nil then
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

-- Called from the "RPCheckEntities:Grid()" function
function RPSpeedrunPostUpdate:CheckVetoButton(gridEntity)
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6 Beta)") or
     RPSpeedrun.charNum ~= 1 or
     RPGlobals.run.roomsEntered ~= 1 or
     gridEntity:GetSaveState().State ~= 3 then

    return
  end

  -- Add the item to the veto list
  RPSpeedrun.vetoList[#RPSpeedrun.vetoList + 1] = RPSpeedrun.lastItemStart
  if #RPSpeedrun.vetoList > 5 then
    table.remove(RPSpeedrun.vetoList, 1)
  end

  -- Add the sprite to the sprite list
  local itemConfig = Isaac.GetItemConfig()
  RPSpeedrun.vetoSprites = {}
  for i = 1, #RPSpeedrun.vetoList do
    RPSpeedrun.vetoSprites[i] = Sprite()
    RPSpeedrun.vetoSprites[i]:Load("gfx/schoolbag_item.anm2", false)
    local itemNum = RPSpeedrun.vetoList[i]
    local fileName = itemConfig:GetCollectible(itemNum).GfxFileName
    RPSpeedrun.vetoSprites[i]:ReplaceSpritesheet(0, fileName)
    RPSpeedrun.vetoSprites[i]:LoadGraphics()
    RPSpeedrun.vetoSprites[i]:SetFrame("Default", 1)
    RPSpeedrun.vetoSprites[i].Scale = Vector(0.75, 0.75)
  end

  -- Play a poop sound
  local sfx = SFXManager()
  sfx:Play(SoundEffect.SOUND_FART, 1, 0, false, 1) -- 37

  -- Reset the timer and restart the game
  RPSpeedrun.vetoTimer = Isaac.GetTime() + 5 * 1000 * 60 -- 5 minutes
  RPSpeedrun.timeItemAssigned = 0
  RPGlobals.run.restart = true
end

return RPSpeedrunPostUpdate

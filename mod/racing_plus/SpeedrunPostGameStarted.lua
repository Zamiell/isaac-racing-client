local SpeedrunPostGameStarted = {}

-- Includes
local g         = require("racing_plus/globals")
local Speedrun  = require("racing_plus/speedrun")
local Season1   = require("racing_plus/season1")
local Season2   = require("racing_plus/season2")
local Season3   = require("racing_plus/season3")
local Season4   = require("racing_plus/season4")
local Season5   = require("racing_plus/season5")
local Season6   = require("racing_plus/season6")
local Season7   = require("racing_plus/season7")
local Season8   = require("racing_plus/season8")

-- Called from the "PostGameStarted:Main()" function
function SpeedrunPostGameStarted:Main()
  -- Local variables
  local character = g.p:GetPlayerType()
  local challenge = Isaac.GetChallenge()

  -- Reset some per-run variables
  Speedrun.spawnedCheckpoint = false
  Speedrun.fadeFrame = 0
  Speedrun.resetFrame = 0

  -- Reset some variables if they are changing characters / items
  if challenge == Isaac.GetChallengeIdByName("Change Char Order") then
    Speedrun.charNum = 1
    Season6.vetoList = {}
  end

  if Speedrun.liveSplitReset then
    Speedrun.liveSplitReset = false
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_OFF_LIMITS, 0, false)
    Isaac.DebugString("Reset the LiveSplit AutoSplitter by giving \"Off Limits\", item ID " ..
                      tostring(CollectibleType.COLLECTIBLE_OFF_LIMITS) .. ".")
    Isaac.DebugString("Removing collectible " .. tostring(CollectibleType.COLLECTIBLE_OFF_LIMITS) .. " (Off Limits)")
  end

  -- Move to the first character if we finished
  -- (this has to be above the challenge name check so that the fireworks won't carry over to another run)
  if Speedrun.finished then
    Speedrun.charNum = 1
    Speedrun.finished = false
    Speedrun.finishedTime = 0
    Speedrun.finishedFrames = 0
    Speedrun.fastReset = false
    g.run.restart = true
    Isaac.DebugString("Restarting to go back to the first character (since we finished the speedrun).")
    return
  end

  if not Speedrun:InSpeedrun() then
    return
  end

  if RacingPlusData == nil then
    return
  end

  -- Don't do anything if the player has not submitted a character order
  -- (we will display an error later on in the PostRender callback)
  if not Speedrun:CheckValidCharOrder() then
    return
  end

  -- Check to see if we are on the correct character
  local correctCharacter = Speedrun:GetCurrentChar()
  if character ~= correctCharacter then
    Speedrun.fastReset = true
    g.run.restart = true
    Isaac.DebugString("Restarting because we are on character " .. tostring(character) ..
                      " and we need to be on character " .. tostring(correctCharacter))
    return
  end

  -- Check if they want to go back to the first character
  if Speedrun.fastReset then
    Speedrun.fastReset = false

  elseif not Speedrun.fastReset and
         Speedrun.charNum ~= 1 then

    -- They held R, and they are not on the first character, so they want to restart from the first character
    Speedrun.charNum = 1
    Speedrun.selectedItemStarts = {}
    g.run.restart = true
    Isaac.DebugString("Restarting because we want to start from the first character again.")

    -- Tell the LiveSplit AutoSplitter to reset
    Speedrun.liveSplitReset = true
    return
  end

  -- Reset variables for the first character
  if Speedrun.charNum == 1 then
    Speedrun.startedTime = 0
    Speedrun.startedFrame = 0
    Speedrun.startedCharTime = 0
    Speedrun.charRunTimes = {}

    if challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
      Season5:PostGameStartedFirstCharacter()
    elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") then
      Season6:PostGameStartedFirstCharacter()
    elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") then
      Season7:PostGameStartedFirstCharacter()
    elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 8 Beta)") then
      Season8:PostGameStartedFirstCharacter()
    end
  end

  -- The first character of the speedrun always gets More Options to speed up the process of getting a run going
  -- (but Season 4 and Season 6 never get it, since there is no resetting involved)
  if Speedrun.charNum == 1 and
     (challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 4)") and
      challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)")) then

    g.p:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
    g.p:RemoveCostume(g.itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS))
    -- We don't want the costume to show
    Isaac.DebugString("Removing collectible 414 (More Options)")
    -- We don't need to show this on the item tracker to reduce clutter
    g.run.removeMoreOptions = true
    -- More Options will be removed upon entering the first Treasure Room
  end

  -- Do actions based on the specific challenge
  if challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then
    return -- Do nothing for the vanilla challenge
  elseif challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") then
    Season1:PostGameStarted9()
  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
    Season1:PostGameStarted14()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") then
    Season2:PostGameStarted()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") then
    Season3:PostGameStarted()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") then
    Season4:PostGameStarted()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
    Season5:PostGameStarted()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") then
    Season6:PostGameStarted()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    Season7:PostGameStarted()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 8 Beta)") then
    Season8:PostGameStarted()
  else
    Isaac.DebugString("Error: Unknown challenge.")
  end
end

return SpeedrunPostGameStarted

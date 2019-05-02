local Speedrun = {}

-- Includes
local g               = require("racing_plus/globals")
local Sprites         = require("racing_plus/sprites")
local ChangeCharOrder = require("racing_plus/changecharorder")

-- Constants
Speedrun.itemStartsS5 = {
  CollectibleType.COLLECTIBLE_MOMS_KNIFE, -- 114
  CollectibleType.COLLECTIBLE_TECH_X, -- 395
  CollectibleType.COLLECTIBLE_EPIC_FETUS, -- 168
  CollectibleType.COLLECTIBLE_IPECAC, -- 149
  CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER, -- 172
  CollectibleType.COLLECTIBLE_20_20, -- 245
  CollectibleType.COLLECTIBLE_PROPTOSIS, -- 261
  CollectibleType.COLLECTIBLE_LIL_BRIMSTONE, -- 275
  CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM, -- 12
  CollectibleType.COLLECTIBLE_TECH_5, -- 244
  CollectibleType.COLLECTIBLE_POLYPHEMUS, -- 169
  CollectibleType.COLLECTIBLE_MAXS_HEAD, -- 4
  CollectibleType.COLLECTIBLE_DEATHS_TOUCH, -- 237
  CollectibleType.COLLECTIBLE_DEAD_EYE, -- 373
  CollectibleType.COLLECTIBLE_CRICKETS_BODY, -- 224
  CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT, -- 415
  CollectibleType.COLLECTIBLE_INCUBUS, -- 360
  CollectibleType.COLLECTIBLE_SACRED_HEART, -- 182
  CollectibleType.COLLECTIBLE_MUTANT_SPIDER_INNER_EYE, -- Custom
}

Speedrun.itemStartsS6 = {
  { CollectibleType.COLLECTIBLE_MOMS_KNIFE }, -- 114
  { CollectibleType.COLLECTIBLE_TECH_X }, -- 395
  { CollectibleType.COLLECTIBLE_EPIC_FETUS }, -- 168
  { CollectibleType.COLLECTIBLE_IPECAC }, -- 149
  { CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER }, -- 172
  { CollectibleType.COLLECTIBLE_20_20 }, -- 245
  { CollectibleType.COLLECTIBLE_PROPTOSIS }, -- 261
  { CollectibleType.COLLECTIBLE_LIL_BRIMSTONE }, -- 275
  { CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM }, -- 12
  { CollectibleType.COLLECTIBLE_TECH_5 }, -- 244
  { CollectibleType.COLLECTIBLE_POLYPHEMUS }, -- 169
  { CollectibleType.COLLECTIBLE_MAXS_HEAD }, -- 4
  { CollectibleType.COLLECTIBLE_DEATHS_TOUCH }, -- 237
  { CollectibleType.COLLECTIBLE_DEAD_EYE }, -- 373
  { CollectibleType.COLLECTIBLE_CRICKETS_BODY }, -- 224
  { CollectibleType.COLLECTIBLE_DR_FETUS }, -- 52
  { CollectibleType.COLLECTIBLE_MONSTROS_LUNG }, -- 229
  { CollectibleType.COLLECTIBLE_JUDAS_SHADOW }, -- 311
  {
    CollectibleType.COLLECTIBLE_CHOCOLATE_MILK, -- 69
    CollectibleType.COLLECTIBLE_STEVEN, -- 50
  },
  {
    CollectibleType.COLLECTIBLE_JACOBS_LADDER, -- 494
    CollectibleType.COLLECTIBLE_THERES_OPTIONS, -- 249
  },
  { CollectibleType.COLLECTIBLE_BRIMSTONE }, -- 118
  { CollectibleType.COLLECTIBLE_INCUBUS }, -- 360
  { CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT }, -- 415
  { CollectibleType.COLLECTIBLE_SACRED_HEART }, -- 182
  {
    CollectibleType.COLLECTIBLE_MUTANT_SPIDER, -- 153
    CollectibleType.COLLECTIBLE_INNER_EYE, -- 2
  },
  {
    CollectibleType.COLLECTIBLE_TECHNOLOGY, -- 68
    CollectibleType.COLLECTIBLE_LUMP_OF_COAL, -- 132
  },
  {
    CollectibleType.COLLECTIBLE_FIRE_MIND, -- 257
    CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID, -- 317
    CollectibleType.COLLECTIBLE_13_LUCK, -- Custom
  },
}

Speedrun.big4 = {
  CollectibleType.COLLECTIBLE_MOMS_KNIFE, -- 114
  CollectibleType.COLLECTIBLE_TECH_X, -- 395
  CollectibleType.COLLECTIBLE_EPIC_FETUS, -- 168
  CollectibleType.COLLECTIBLE_IPECAC, -- 149
}

-- In Season 6, this is how long the randomly-selected item start be "locked-in"
Speedrun.itemLockTime = 60 * 1000 -- 1 minute

-- In Season 6, this is how often the special "Veto" button can be used
Speedrun.vetoButtonLength = 5 * 60 * 1000 -- 5 minutes

Speedrun.R7SeededName = "R+7 Seeded (Q4 2018)"
Speedrun.R7SeededSeeds = {
  "4PME M424",
  "JFSC 2WW7",
  "WEFG XQ6F",
  "4FAH GTDX",
  "3J46 P8BJ",
  "9YHG YKXH",
  "BQ9S MATW",
}
Speedrun.R7SeededB1 = { -- These are the floor 1 stage types for the above seeds
  "b",
  "",
  "a",
  "a",
  "b",
  "",
  "a",
}

-- Variables
Speedrun.sprites = {} -- Reset at the beginning of a new run (in the PostGameStarted callback)
Speedrun.charNum = 1 -- Reset expliticly from a long-reset and on the first reset after a finish
Speedrun.startedTime = 0 -- Reset expliticly if we are on the first character
Speedrun.startedFrame = 0 -- Reset expliticly if we are on the first character
Speedrun.finishTimeCharacter = 0 -- Reset expliticly if we are on the first character
Speedrun.averageTime = 0 -- Reset expliticly if we are on the first character
Speedrun.finished = false -- Reset at the beginning of every run
Speedrun.finishedTime = 0 -- Reset at the beginning of every run
Speedrun.finishedFrames = 0 -- Reset at the beginning of every run
Speedrun.fastReset = false -- Reset expliticly when we detect a fast reset
Speedrun.spawnedCheckpoint = false -- Reset after we touch the checkpoint and at the beginning of a new run
Speedrun.fadeFrame = 0 -- Reset after we touch the checkpoint and at the beginning of a new run
Speedrun.resetFrame = 0 -- Reset after we execute the "restart" command and at the beginning of a new run
Speedrun.liveSplitReset = false
Speedrun.remainingItemStarts = {} -- Reset at the beginning of a new run
Speedrun.selectedItemStarts = {} -- Reset at the beginning of a new run (for seasons 5 and 6)
Speedrun.lastItemStart = 0 -- Set when a new item is assigned (for season 6)
Speedrun.inSeededSpeedrun = false -- Reset when the "Finished" custom item is touched
Speedrun.timeItemAssigned = 0 -- Reset when the time limit elapses
Speedrun.vetoList = {} -- Used for Season 6
Speedrun.vetoSprites = {} -- Used for Season 6
Speedrun.vetoTimer = 0

-- Called from the PostRender callback
function Speedrun:CheckRestart()
  -- Local variables
  local isaacFrameCount = Isaac.GetFrameCount()

  -- We grabbed the checkpoint, so fade out the screen before we reset
  if Speedrun.fadeFrame ~= 0 and isaacFrameCount >= Speedrun.fadeFrame then
    Speedrun.fadeFrame = 0
    g.g:Fadeout(0.0275, g.FadeoutTarget.FADEOUT_RESTART_RUN) -- 3
    Speedrun.resetFrame = isaacFrameCount + 70 -- 72 restarts as the current character, and we want a frame of leeway
    -- (this is necessary because we don't want the player to be able to reset to skip having to watch the fade out)
    return
  end

  -- The screen is now black, so move us to the next character for the speedrun
  if Speedrun.resetFrame ~= 0 and isaacFrameCount >= Speedrun.resetFrame then
    Speedrun.resetFrame = 0
    Speedrun.fastReset = true -- Set this so that we don't go back to the beginning again
    Speedrun.charNum = Speedrun.charNum + 1
    g.run.restart = true

    Isaac.DebugString("Switching to the next character for the speedrun.")
    return
  end
end

-- Called from the PostUpdate callback (the "CheckEntities:NonGrid()" function)
function Speedrun:Finish()
  -- Give them the Checkpoint custom item
  -- (this is used by the AutoSplitter to know when to split)
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_CHECKPOINT, 0, false)

  -- Finish the speedrun
  Speedrun.finished = true
  Speedrun.finishedTime = Isaac.GetTime() - Speedrun.startedTime
  Speedrun.finishedFrames = Isaac.GetFrameCount() - Speedrun.startedFrame
  g.run.endOfRunText = true -- Show the run summary

  -- This will be in milliseconds, so we divide by 1000
  local elapsedTime = (Isaac.GetTime() - Speedrun.finishTimeCharacter) / 1000
  Speedrun.averageTime = ((Speedrun.charNum - 1) * Speedrun.averageTime + elapsedTime) / Speedrun.charNum

  -- Play a sound effect
  g.sfx:Play(SoundEffect.SOUND_SPEEDRUN_FINISH, 1.5, 0, false, 1) -- ID, Volume, FrameDelay, Loop, Pitch

  -- Fireworks will play on the next frame (from the PostUpdate callback)
end

-- Don't move to the first character of the speedrun if we die
function Speedrun:PostGameEnd(gameOver)
  if not gameOver then
    return
  end

  if not Speedrun:InSpeedrun() then
    return
  end

  Speedrun.fastReset = true
  Isaac.DebugString("Game over detected.")
end

-- Called from the "PostRender:Main()" function
function Speedrun:DisplayCharProgress()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  -- Don't show the progress if we are not in the custom challenge
  if not Speedrun:InSpeedrun() then
    return
  end

  if g.seeds:HasSeedEffect(SeedEffect.SEED_NO_HUD) then --- 10
    return
  end

  -- Don't show the progress if the player has not set an order yet
  if not Speedrun:CheckValidCharOrder() then
    -- Load the sprites
    if Speedrun.sprites.needToSet1 == nil then
      Speedrun.sprites.needToSet1 = Sprite()
      Speedrun.sprites.needToSet1:Load("gfx/speedrun/need-to-set1.anm2", true)
      Speedrun.sprites.needToSet1:SetFrame("Default", 0)
      Speedrun.sprites.needToSet2 = Sprite()
      Speedrun.sprites.needToSet2:Load("gfx/speedrun/need-to-set2.anm2", true)
      Speedrun.sprites.needToSet2:SetFrame("Default", 0)
      Speedrun.sprites.needToSet3 = Sprite()
      Speedrun.sprites.needToSet3:Load("gfx/speedrun/need-to-set3.anm2", true)
      Speedrun.sprites.needToSet3:SetFrame("Default", 0)
    end

    -- Display the sprites
    local pos = Sprites:GetScreenCenterPosition()
    pos.Y = pos.Y - 80
    Speedrun.sprites.needToSet1:RenderLayer(0, pos)
    pos.Y = pos.Y + 30
    Speedrun.sprites.needToSet2:RenderLayer(0, pos)
    pos.Y = pos.Y + 40
    Speedrun.sprites.needToSet3:RenderLayer(0, pos)
    return
  end

  -- Load the sprites for the multi-character speedrun progress
  if Speedrun.sprites.slash == nil then
    Speedrun.sprites.digit = {}
    for i = 1, 4 do
      Speedrun.sprites.digit[i] = Sprite()
      Speedrun.sprites.digit[i]:Load("gfx/timer/timer.anm2", true)
      Speedrun.sprites.digit[i].Scale = Vector(0.9, 0.9)
      -- Make the numbers a bit smaller than the ones used for the timer
      Speedrun.sprites.digit[i]:SetFrame("Default", 0)
    end
    Speedrun.sprites.slash = Sprite()
    Speedrun.sprites.slash:Load("gfx/timer/slash.anm2", true)
    Speedrun.sprites.slash:SetFrame("Default", 0)
  end

  -- Local variables
  local digitLength = 7.25
  local startingX = 23
  if Speedrun.inSeededSpeedrun then
    startingX = startingX + 4 -- We have to shift it to the right because the challenge icon will not appear
  end
  local startingY = 79
  local adjustment1 = 0
  local adjustment2 = 0
  if Speedrun.charNum > 9 then
    adjustment1 = digitLength - 2
    adjustment2 = adjustment1 - 1
  end

  -- Display the sprites
  local digit1 = Speedrun.charNum
  local digit2 = -1
  if Speedrun.charNum > 9 then
    digit1 = 1
    digit2 = Speedrun.charNum - 10
  end
  local digit3 = 7 -- Assume a 7 character speedrun by default
  local digit4 = -1
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") then
    digit3 = 9
  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
    digit3 = 1
    digit4 = 4
  elseif challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then
    digit3 = 1
    digit4 = 5
  end

  local posDigit1 = Vector(startingX, startingY)
  Speedrun.sprites.digit[1]:SetFrame("Default", digit1)
  Speedrun.sprites.digit[1]:RenderLayer(0, posDigit1)

  if digit2 ~= -1 then
    local posDigit2 = Vector(startingX + digitLength - 1, startingY)
    Speedrun.sprites.digit[2]:SetFrame("Default", digit2)
    Speedrun.sprites.digit[2]:RenderLayer(0, posDigit2)
  end

  local posSlash = Vector(startingX + digitLength -1 + adjustment1, startingY)
  Speedrun.sprites.slash:RenderLayer(0, posSlash)

  local posDigit3 = Vector(startingX + digitLength + adjustment2 + 5 , startingY)
  Speedrun.sprites.digit[3]:SetFrame("Default", digit3)
  Speedrun.sprites.digit[3]:RenderLayer(0, posDigit3)

  if digit4 ~= -1 then
    local posDigit4 = Vector(startingX + digitLength + adjustment2 + 3 + digitLength, startingY)
    Speedrun.sprites.digit[3]:SetFrame("Default", digit4)
    Speedrun.sprites.digit[3]:RenderLayer(0, posDigit4)
  end
end

function Speedrun:InSpeedrun()
  local challenge = Isaac.GetChallenge()
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") or
     challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") or
     Speedrun.inSeededSpeedrun or
     challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then

    return true
  else
    return false
  end
end

function Speedrun:CheckValidCharOrder()
  local challenge = Isaac.GetChallenge()

  if g.race.charOrder == nil then
    return false
  end
  local charOrderType = g.race.charOrder[1]
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") and
     (charOrderType ~= "R9S1" or
      #g.race.charOrder ~= 10) then

    return false

  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") and
         (charOrderType ~= "R14S1" or
          #g.race.charOrder ~= 15) then

    return false

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") and
         (charOrderType ~= "R7S2" or
          #g.race.charOrder ~= 8) then

    return false

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") and
         (charOrderType ~= "R7S3" or
          #g.race.charOrder ~= 8) then

    return false

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") and
         (charOrderType ~= "R7S4" or
          #g.race.charOrder ~= 15) then -- 7 characters + 7 starting items

    return false

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
    -- There is no character order in season 5
    return true

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") and
         (charOrderType ~= "R7S6" or
          #g.race.charOrder ~= 1 + 7 + 1 + ChangeCharOrder.seasons.R7S6.itemBans) then

    return false

  elseif Speedrun.inSeededSpeedrun and
         (charOrderType ~= "R7SS" or
          #g.race.charOrder ~= 8) then

    return false

  elseif challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") and
         (charOrderType ~= "R15V" or
          #g.race.charOrder ~= 16) then

    return false
  end

  return true
end

function Speedrun:GetCurrentChar()
  local challenge = Isaac.GetChallenge()
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
    local randomBabyType = Isaac.GetPlayerTypeByName("Random Baby")
    if randomBabyType == -1 then
      return 0
    end
    return randomBabyType
  end
  return g.race.charOrder[Speedrun.charNum + 1]
  -- We add one since the first element is the type of multi-character speedrun
end

function Speedrun:IsOnFinalCharacter()
  local challenge = Isaac.GetChallenge()
  if challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then
    return Speedrun.charNum == 15
  elseif challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") then
    return Speedrun.charNum == 9
  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
    return Speedrun.charNum == 14
  end
  return Speedrun.charNum == 7
end

function Speedrun:GetAverageTimePerCharacter()
  local timeTable = g:ConvertTimeToString(Speedrun.averageTime)
  -- e.g. [minute1][minute2]:[second1][second2]
  return tostring(timeTable[2]) .. tostring(timeTable[3]) .. ":" .. tostring(timeTable[4]) .. tostring(timeTable[5])
end

-- Called from the PostRender callback
function Speedrun:CheckSeason5Mod()
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 5)") then
    return
  end

  if SinglePlayerCoopBabies ~= nil then
    return
  end

  local x = 115
  local y = 70
  Isaac.RenderText("Error: You must subscribe to and enable", x, y, 2, 2, 2, 2)
  x = x + 42
  y = y + 10
  Isaac.RenderText("\"The Babies Mod\" on the Steam Workshop", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("in order for the Racing+ season 5 custom", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("challenge to work correctly.", x, y, 2, 2, 2, 2)
end

-- Called from the PostRender callback
function Speedrun:CheckSeason5ModOther()
  local challenge = Isaac.GetChallenge()
  if not Speedrun:InSpeedrun() or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then

    return
  end

  if SinglePlayerCoopBabies == nil then
    return
  end

  local x = 115
  local y = 70
  Isaac.RenderText("Error: You must disable The Babies Mod", x, y, 2, 2, 2, 2)
  x = x + 42
  y = y + 10
  Isaac.RenderText("in order for this custom challenge to", x, y, 2, 2, 2, 2)
  y = y + 10
  Isaac.RenderText("work correctly.", x, y, 2, 2, 2, 2)
end

-- Called from the PostRender callback
function Speedrun:DrawVetoButtonText()
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)") or
     Speedrun.charNum ~= 1 or
     g.run.roomsEntered ~= 1 then

    return
  end

  -- Draw the sprites that correspond to the items that are currently on the veto list
  local x = -45
  for i = 1, #Speedrun.vetoList do
    local itemPosGame = g:GridToPos(11, 7)
    local itemPos = Isaac.WorldToRenderPosition(itemPosGame)
    x = x + 15
    itemPos = Vector(itemPos.X + x, itemPos.Y)
    Speedrun.vetoSprites[i]:Render(itemPos, Vector(0, 0), Vector(0, 0))
  end

  if Speedrun.vetoTimer == 0 then
    -- Draw the "Veto" text
    local posGame = g:GridToPos(11, 5)
    local pos = Isaac.WorldToRenderPosition(posGame)
    local f = Font()
    f:Load("font/droid.fnt")
    local color = KColor(1, 1, 1, 1, 0, 0, 0)
    local string = "Veto"
    local length = f:GetStringWidthUTF8(string)
    f:DrawString(string, pos.X - (length / 2), pos.Y, color, 0, true)
  end
end

-- ModCallbacks.MC_USE_ITEM (23)
-- CollectibleType.COLLECTIBLE_D6 (105)
function Speedrun:PreventD6()
  -- Local variables
  local stage = g.l:GetStage()
  local currentIndex = g.l:GetCurrentRoomIndex()
  local startingRoomIndex = g.l:GetStartingRoomIndex()

  -- Prevent re-rolling the "Finished" custom item that is spawned in the first room of the first character
  if not Speedrun.inSeededSpeedrun or
     Speedrun.charNum ~= 1 or
     stage ~= 1 or
     currentIndex ~= startingRoomIndex then

    return
  end

  return true
end

return Speedrun

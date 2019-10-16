local Speedrun = {}

-- Includes
local g               = require("racing_plus/globals")
local ChangeCharOrder = require("racing_plus/changecharorder")

--
-- Constants
--

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

Speedrun.goalsS7 = {
  "Boss Rush",
  "It Lives!",
  "Hush",
  "Blue Baby",
  "The Lamb",
  "Mega Satan",
  "Mahalath",
}

Speedrun.big4 = {
  CollectibleType.COLLECTIBLE_MOMS_KNIFE, -- 114
  CollectibleType.COLLECTIBLE_TECH_X, -- 395
  CollectibleType.COLLECTIBLE_EPIC_FETUS, -- 168
  CollectibleType.COLLECTIBLE_IPECAC, -- 149
}

-- Season 6 constants
Speedrun.itemLockTime = 60 * 1000 -- 1 minute
-- (this is how long the randomly-selected item start be "locked-in")
Speedrun.vetoButtonLength = 5 * 60 * 1000 -- 5 minutes
-- (this is how often the special "Veto" button can be used)

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

--
-- Variables
--

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

-- Season 5, 6, & 7 variables
Speedrun.remainingItemStarts = {} -- Reset at the beginning of a new run on the first character
Speedrun.selectedItemStarts = {} -- Reset at the beginning of a new run on the first character

-- Season 6 variables
Speedrun.timeItemAssigned = 0 -- Reset when the time limit elapses
Speedrun.lastBuildItem = 0 -- Set when a new build is assigned
Speedrun.lastBuildItemOnFirstChar = 0 -- Set when a new build is assigned on the first character
Speedrun.vetoList = {}
Speedrun.vetoSprites = {}
Speedrun.vetoTimer = 0

-- Season 7 variables
Speedrun.remainingGoals = {} -- Reset at the beginning of a new run on the first character
Speedrun.completedGoals = {} -- Reset at the beginning of a new run on the first character

-- Seeded season variables
Speedrun.inSeededSpeedrun = false -- Reset when the "Finished" custom item is touched

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

function Speedrun:PostNewLevel()
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)") then
    return
  end

  local stage = g.l:GetStage()
  if stage ~= 12 then
    return
  end

  -- Put Mahalath in the first 1x1 boss room
  local rooms = g.l:GetRooms()
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local roomDesc = rooms:Get(i)
    local roomIndex = roomDesc.SafeGridIndex -- This is always the top-left index
    local roomData = roomDesc.Data
    local roomType = roomData.Type
    local roomShape = roomData.Shape

    if roomType == RoomType.ROOM_BOSS then -- 5
      local room = g.l:GetRoomByIdx(roomIndex) -- We have use this function in order to modify the DisplayFlags
      if g.run.mahalathRoomIndex == -1000 and
         roomShape == RoomShape.ROOMSHAPE_1x1 then -- 1

        g.run.mahalathRoomIndex = roomIndex
        Isaac.DebugString("Set the Mahalath room to: " .. tostring(g.run.mahalathRoomIndex))
        room.DisplayFlags = 1 << 2 -- Show the icon

      else
        room.DisplayFlags = 1 << -1 -- Remove the icon (in case we have the Compass or The Mind)
      end
    end
  end
  g.l:UpdateVisibility()
end

function Speedrun:RoomCleared()
  -- Local variables
  local stage = g.l:GetStage()
  local roomIndexUnsafe = g.l:GetCurrentRoomIndex()
  local challenge = Isaac.GetChallenge()

  -- Check to see if we just defeated Mahalath on a Season 7 speedrun
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)") and
     stage == 12 and
     roomIndexUnsafe == g.run.mahalathRoomIndex then

    -- Delete the collectible that spawns as a reward
    local collectibles = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 5.100
                                          -1, false, false)
    for _, collectible in ipairs(collectibles) do
      collectible:Remove()
    end

    -- Spawn a big chest (which will get replaced with either a checkpoint or a trophy on the next frame)
    g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, -- 5.340
              g.zeroVector, g.zeroVector, nil, 0, 0) -- It does not matter where we spawn it
  end
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

function Speedrun:InSpeedrun()
  local challenge = Isaac.GetChallenge()
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") or
     challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)") or
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

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)") and
         (charOrderType ~= "R7S7" or
          #g.race.charOrder ~= 8) then

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

-- ModCallbacks.MC_USE_ITEM (23)
-- CollectibleType.COLLECTIBLE_D6 (105)
function Speedrun:PreventD6()
  -- Local variables
  local stage = g.l:GetStage()
  local roomIndexUnsafe = g.l:GetCurrentRoomIndex()
  local startingRoomIndex = g.l:GetStartingRoomIndex()

  -- Prevent re-rolling the "Finished" custom item that is spawned in the first room of the first character
  if not Speedrun.inSeededSpeedrun or
     Speedrun.charNum ~= 1 or
     stage ~= 1 or
     roomIndexUnsafe ~= startingRoomIndex then

    return
  end

  return true
end

return Speedrun

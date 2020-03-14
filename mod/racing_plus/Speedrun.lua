local Speedrun = {}

-- Includes
local g = require("racing_plus/globals")

--
-- Constants
--

-- The challenge table maps challenge names to abbreviations and
-- the number of elements in the "character order" table
Speedrun.challengeTable = {
  [Isaac.GetChallengeIdByName("R+9 (Season 1)")]  = {"R9S1",  9},
  [Isaac.GetChallengeIdByName("R+14 (Season 1)")] = {"R14S1", 14},
  [Isaac.GetChallengeIdByName("R+7 (Season 2)")]  = {"R7S2",  7},
  [Isaac.GetChallengeIdByName("R+7 (Season 3)")]  = {"R7S3",  7},
  [Isaac.GetChallengeIdByName("R+7 (Season 4)")]  = {"R7S4",  14}, -- (7 characters + 7 starting items)
  -- (there is no character order for season 5)
  [Isaac.GetChallengeIdByName("R+7 (Season 6)")]  = {"R7S6",  11}, -- (7 characters + 3 item bans + 1 big 4 item ban)
  [Isaac.GetChallengeIdByName("R+7 (Season 7)")]  = {"R7S7",  7},
  [Isaac.GetChallengeIdByName("R+7 (Season 8 Beta)")]  = {"R7S8",  7},
  [Isaac.GetChallengeIdByName("R+15 (Vanilla)")]  = {"R15V",  15},
}

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
  "Ultra Greed",
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

-- Season 8 constants
Speedrun.S8PillEffects = {
  PillEffect.PILLEFFECT_BALLS_OF_STEEL, -- 2
  PillEffect.PILLEFFECT_BOMBS_ARE_KEYS, -- 3
  PillEffect.PILLEFFECT_EXPLOSIVE_DIARRHEA, -- 4,
  PillEffect.PILLEFFECT_HEALTH_DOWN, -- 6
  PillEffect.PILLEFFECT_HEALTH_UP, -- 7
  PillEffect.PILLEFFECT_PRETTY_FLY, -- 10
  PillEffect.PILLEFFECT_SPEED_DOWN, -- 13
  PillEffect.PILLEFFECT_SPEED_UP, -- 14
  PillEffect.PILLEFFECT_TEARS_DOWN, -- 15
  PillEffect.PILLEFFECT_TEARS_UP, -- 16
  PillEffect.PILLEFFECT_TELEPILLS, -- 19
  PillEffect.PILLEFFECT_48HOUR_ENERGY, -- 20
  PillEffect.PILLEFFECT_SEE_FOREVER, -- 23
  PillEffect.PILLEFFECT_LEMON_PARTY, -- 26
  PillEffect.PILLEFFECT_PERCS, -- 28
  PillEffect.PILLEFFECT_POWER, -- 36
  PillEffect.PILLEFFECT_IM_DROWSY, -- 41
  PillEffect.PILLEFFECT_GULP, -- 43
}

--
-- Variables
--

Speedrun.sprites = {} -- Reset at the beginning of a new run (in the PostGameStarted callback)
Speedrun.charNum = 1 -- Reset expliticly from a long-reset and on the first reset after a finish
Speedrun.startedTime = 0 -- Reset expliticly if we are on the first character
Speedrun.startedFrame = 0 -- Reset expliticly if we are on the first character
Speedrun.startedCharTime = 0 -- Reset expliticly if we are on the first character and when we touch a Checkpoint
Speedrun.charRunTimes = {} -- Reset expliticly if we are on the first character
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

-- Season 8 variables
Speedrun.S8TouchedItems = {} -- Reset at the beginning of a new run on the first character
Speedrun.S8TouchedTrinkets = {} -- Reset at the beginning of a new run on the first character
Speedrun.S8RemainingCards = {} -- Reset at the beginning of a new run on the first character
Speedrun.S8RunPillEffects = {} -- Reset at the beginning of a new run on the first character
Speedrun.S8IdentifiedPills = {} -- Reset at the beginning of a new run on the first character

-- Called from the PostUpdate callback (the "CheckEntities:NonGrid()" function)
function Speedrun:Finish()
  -- Give them the Checkpoint custom item
  -- (this is used by the AutoSplitter to know when to split)
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_CHECKPOINT, 0, false)

  -- Record how long this run took
  local elapsedTime = Isaac.GetTime() - Speedrun.startedCharTime
  Speedrun.charRunTimes[#Speedrun.charRunTimes + 1] = elapsedTime

  -- Show the run summary (including the average time per character)
  g.run.endOfRunText = true

  -- Finish the speedrun
  Speedrun.finished = true
  Speedrun.finishedTime = Isaac.GetTime() - Speedrun.startedTime
  Speedrun.finishedFrames = Isaac.GetFrameCount() - Speedrun.startedFrame

  -- Play a sound effect
  g.sfx:Play(SoundEffect.SOUND_SPEEDRUN_FINISH, 1.5, 0, false, 1) -- ID, Volume, FrameDelay, Loop, Pitch

  -- Fireworks will play on the next frame (from the PostUpdate callback)
end

function Speedrun:PostNewLevel()
  -- Local variables
  local stage = g.l:GetStage()
  local rooms = g.l:GetRooms()
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    return
  end

  if stage ~= 12 then
    return
  end

  -- Set the custom boss room to be the first 1x1 boss room
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local roomDesc = rooms:Get(i)
    local roomIndex = roomDesc.SafeGridIndex -- This is always the top-left index
    local roomData = roomDesc.Data
    local roomType = roomData.Type
    local roomShape = roomData.Shape

    if roomType == RoomType.ROOM_BOSS and -- 5
       roomShape == RoomShape.ROOMSHAPE_1x1 then -- 1

      g.run.customBossRoomIndex = roomIndex
      Isaac.DebugString("Set the custom boss room to: " .. tostring(g.run.customBossRoomIndex))
      break
    end
  end
end

function Speedrun:RoomCleared()
  -- Local variables
  local stage = g.l:GetStage()
  local roomIndexUnsafe = g.l:GetCurrentRoomIndex()
  local centerPos = g.r:GetCenterPos()
  local challenge = Isaac.GetChallenge()

  -- Check to see if we just defeated the custom boss on a Season 7 speedrun
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") and
     stage == 12 and
     roomIndexUnsafe == g.run.customBossRoomIndex then

    -- Spawn a big chest (which will get replaced with either a checkpoint or a trophy on the next frame)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, 0, -- 5.340
                centerPos, g.zeroVector, nil)
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
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 8 Beta)") or
     challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then

    return true
  else
    return false
  end
end

function Speedrun:CheckValidCharOrder()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  -- There is no character order for season 5
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
    return true
  end

  -- Otherwise, we get the character order from the Racing+ Data mod's "save#.dat" file
  if RacingPlusData == nil then
    return false
  end
  local abbreviation = Speedrun.challengeTable[challenge][1]
  local numElements = Speedrun.challengeTable[challenge][2]
  if abbreviation == nil then
    Isaac.DebugString("Error: Failed to find challenge \"" .. challenge .. "\" in the challengeTable.")
    return false
  end
  local charOrder = RacingPlusData:Get("charOrder-" .. abbreviation)
  if charOrder == nil then
    return false
  end
  if type(charOrder) ~= "table" then
    return false
  end
  if #charOrder ~= numElements then
    return false
  end

  return true
end

function Speedrun:GetCurrentChar()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  -- In season 5, we always return the character ID of "Random Baby"
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
    local randomBabyType = Isaac.GetPlayerTypeByName("Random Baby")
    if randomBabyType == -1 then
      return 0
    end
    return randomBabyType
  end

  -- Otherwise, we get the value from the Racing+ Data mod's "save#.dat" file
  if RacingPlusData == nil then
    return 0
  end
  local abbreviation = Speedrun.challengeTable[challenge][1]
  if abbreviation == nil then
    Isaac.DebugString("Error: Failed to find challenge \"" .. challenge .. "\" in the challengeTable.")
    return false
  end
  local charOrder = RacingPlusData:Get("charOrder-" .. abbreviation)
  if charOrder == nil then
    return 0
  end
  if type(charOrder) ~= "table" then
    return 0
  end
  local charNum = charOrder[Speedrun.charNum]
  if charNum == nil then
    return 0
  end
  return charNum
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
  local totalMilliseconds = 0
  for _, milliseconds in ipairs(Speedrun.charRunTimes) do
    totalMilliseconds = totalMilliseconds + milliseconds
  end
  local averageMilliseconds = totalMilliseconds / #Speedrun.charRunTimes
  local averageSeconds = averageMilliseconds / 1000
  local timeTable = g:ConvertTimeToString(averageSeconds)

  -- e.g. [minute1][minute2]:[second1][second2]
  return tostring(timeTable[2]) .. tostring(timeTable[3]) .. ":" .. tostring(timeTable[4]) .. tostring(timeTable[5])
end

return Speedrun

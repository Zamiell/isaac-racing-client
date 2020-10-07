local Season9 = {}

-- Includes
local g = require("racing_plus/globals")
local Speedrun = require("racing_plus/speedrun")
local Schoolbag = require("racing_plus/schoolbag")

--
-- Constants
--

-- This is how long the randomly-selected item start is "locked-in"
Season9.itemLockTime = 60 * 1000 -- 1 minute
Season9.historyDataLabel = "s9hbi"

-- Variables
Season9.selectedBuildIndexes = {}
Season9.timeBuildAssigned = 0 -- Reset when the time limit elapses
Season9.loadedSaveDat = false
Season9.historicalBuildIndexes = {}

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season9:PostGameStartedFirstCharacter()
  if Isaac.GetTime() - Season9.timeBuildAssigned >= Season9.itemLockTime then
    Season9.selectedBuildIndexes = {}
  end

  if not Season9.loadedSaveDat then
    Season9.loadedSaveDat = true
    Season9.historicalBuildIndexes = RacingPlusData:Get(Season9.historyDataLabel)
    if Season9.historicalBuildIndexes == nil then
      Season9.historicalBuildIndexes = {}
      RacingPlusData:Set(Season9.historyDataLabel, Season9.historicalBuildIndexes)
    else
      local lastStartedBuildIndex = Season9.historicalBuildIndexes[#Season9.historicalBuildIndexes]
      Season9.selectedBuildIndexes = { lastStartedBuildIndex }
    end
  end
end

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season9:PostGameStarted()
  -- Local variables
  local character = g.p:GetPlayerType()

  Isaac.DebugString("In the R+7 (Season 9) challenge.")

  -- Character-specific items
  if character == PlayerType.PLAYER_ISAAC then -- 0
    Schoolbag:Put(CollectibleType.COLLECTIBLE_CLOCKWORK_ASSEMBLY, 6)
  elseif character == PlayerType.PLAYER_JUDAS then -- 3
    g.p:AddHearts(1)
  elseif character == PlayerType.PLAYER_XXX then -- 4
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SPIRIT_NIGHT, 0, false) -- 159
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SPIRIT_NIGHT) -- 159
  elseif character == PlayerType.PLAYER_LAZARUS then -- 8
    g.p:SetPill(0, PillColor.PILL_NULL) -- 0
  end

  -- Everyone starts with a random passive item / build
  -- Check to see if a start is already assigned for this character number
  -- (dying and resetting should not reassign the selected starting item)
  local startingBuildIndex = Season9.selectedBuildIndexes[Speedrun.charNum]
  if startingBuildIndex == nil then
    startingBuildIndex = Season9:GetRandomStartingBuildIndex()
    Isaac.DebugString("Assigned build #" .. tostring(startingBuildIndex) .. ".")

    -- Keep track of what builds we start
    Season9.selectedBuildIndexes[Speedrun.charNum] = startingBuildIndex

    -- Mark down the time that we assigned this item
    Season9.timeBuildAssigned = Isaac.GetTime()

    -- Record it for historical purposes (but only keep track of the past X builds)
    Season9.historicalBuildIndexes[#Season9.historicalBuildIndexes + 1] = startingBuildIndex
    while #Season9.historicalBuildIndexes > math.floor(#RacingPlusRebalanced.itemStarts / 2) do
      table.remove(Season9.historicalBuildIndexes, 1)
    end
    RacingPlusData:Set(Season9.historyDataLabel, Season9.historicalBuildIndexes)
    Isaac.DebugString("Current historical builds:")
    for i, build in ipairs(Season9.historicalBuildIndexes) do
      Isaac.DebugString(tostring(i) .. ") " .. tostring(build))
    end
  else
    Isaac.DebugString("Already assigned build #" .. tostring(startingBuildIndex) .. ".")
  end

  -- Give the items to the player (and remove the items from the pools)
  local startingBuild = RacingPlusRebalanced.itemStarts[startingBuildIndex]
  for _, item in ipairs(startingBuild) do
    g.p:AddCollectible(item, 0, false)
    g.itemPool:RemoveCollectible(item)

    -- (the PostItemPickup function will be called because the Racing+ POST_GAME_STARTED callback
    -- runs before the Racing+ Rebalanced one)
  end
end

function Season9:GetRandomStartingBuildIndex()
  -- Local variables
  local seed = g.seeds:GetStartSeed()

  -- Build a list of build indexes that we have not started yet in past runs
  local unplayedStartingBuildIndexes = Season9:MakeValidStartingBuildIndexes()

  if #unplayedStartingBuildIndexes == 0 then
    -- We have played every item (with the potential exception of a character-banned item),
    -- so delete the history (with the exception of the last started item)
    local lastStartedBuildIndex = Season9.historicalBuildIndexes[#Season9.historicalBuildIndexes]
    Season9.historicalBuildIndexes = { lastStartedBuildIndex }
    RacingPlusData:Set(Season9.historyDataLabel, Season9.historicalBuildIndexes)

    -- Re-get the valid starting build indexes
    -- This will always have a size greater than 0 now
    unplayedStartingBuildIndexes = Season9:MakeValidStartingBuildIndexes()
  end

  math.randomseed(seed)
  local randomIndexOfIndexArray = math.random(1, #unplayedStartingBuildIndexes)
  local randomIndex = unplayedStartingBuildIndexes[randomIndexOfIndexArray]

  return randomIndex
end

function Season9:MakeValidStartingBuildIndexes()
  local unplayedStartingBuildIndexes = {}

  for i = 1, #RacingPlusRebalanced.itemStarts  do
    if (
      -- If we have not started this build already on this 7-character run
      not g:TableContains(Season9.selectedBuildIndexes, i)
      -- And we have not started this build recently on a previous 7-character run
      and not g:TableContains(Season9.historicalBuildIndexes, i)
      -- And this build is not banned on this character
      and not Season9:BuildIsBannedOnThisCharacter(i)
    ) then
      unplayedStartingBuildIndexes[#unplayedStartingBuildIndexes + 1] = i
    end
  end

  return unplayedStartingBuildIndexes
end

function Season9:BuildIsBannedOnThisCharacter(buildIndex)
  -- Local variables
  local character = g.p:GetPlayerType()
  local build = RacingPlusRebalanced.itemStarts[buildIndex]
  local item = build[1]

  if character == PlayerType.PLAYER_JUDAS then -- 3
    if item == CollectibleType.COLLECTIBLE_JUDAS_SHADOW then -- 311
      return true
    end
  elseif character == PlayerType.PLAYER_EVE then -- 5
    if item == CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT then -- 415
      return true
    end
  elseif character == PlayerType.PLAYER_AZAZEL then -- 7
    if (
      item == CollectibleType.COLLECTIBLE_IPECAC -- 149
      or item == CollectibleType.COLLECTIBLE_MUTANT_SPIDER -- 153
      or item == CollectibleType.COLLECTIBLE_CRICKETS_BODY -- 224
      or item == CollectibleType.COLLECTIBLE_DEAD_EYE -- 373
      or item == CollectibleType.COLLECTIBLE_JUDAS_SHADOW -- 331
      or item == CollectibleType.COLLECTIBLE_FIRE_MIND -- 257
      or item == CollectibleType.COLLECTIBLE_JACOBS_LADDER -- 494
    ) then
      return true
    end
  elseif character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
    if (
      item == CollectibleType.COLLECTIBLE_DEATHS_TOUCH -- 237
      or item == CollectibleType.COLLECTIBLE_FIRE_MIND -- 257
      or item == CollectibleType.COLLECTIBLE_LIL_BRIMSTONE -- 275
      or item == CollectibleType.COLLECTIBLE_JUDAS_SHADOW -- 311
      or item == CollectibleType.COLLECTIBLE_INCUBUS -- 350
    ) then
      return true
    end
  end

  return false
end

-- Reset the starting item timer if we just killed the Basement 2 boss
function Season9:PostClearRoom()
  -- Local variables
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()
  local challenge = Isaac.GetChallenge()

  if (
    challenge == Isaac.GetChallengeIdByName("R+7 (Season 9 Beta)")
    and stage == 2
    and roomType == RoomType.ROOM_BOSS -- 5
  ) then
    Season9.timeBuildAssigned = 0
  end
end

function Season9:Debug()
  Isaac.DebugString("Season9.selectedBuildIndexes:")
  for i, index in ipairs(Season9.selectedBuildIndexes) do
    Isaac.DebugString(tostring(i) .. " - " .. tostring(index))
  end

  Isaac.DebugString("Season9.historicalBuildIndexes:")
  for i, index in ipairs(Season9.historicalBuildIndexes) do
    Isaac.DebugString(tostring(i) .. " - " .. tostring(index))
  end
end

return Season9

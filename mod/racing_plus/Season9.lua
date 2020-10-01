local Season9 = {}

-- Includes
local g = require("racing_plus/globals")
local Speedrun = require("racing_plus/speedrun")

--
-- Constants
--

-- This is how long the randomly-selected item start is "locked-in"
Season9.itemLockTime = 60 * 1000 -- 1 minute

-- Variables
Season9.timeItemAssigned = 0 -- Reset when the time limit elapses
Season9.lastBuildItem = 0 -- Set when a new build is assigned
Season9.lastBuildItemOnFirstChar = 0 -- Set when a new build is assigned on the first character

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season9:PostGameStartedFirstCharacter()
  Speedrun.remainingItemStarts = g:TableClone(RacingPlusRebalanced.itemStarts)
  if Isaac.GetTime() - Season9.timeItemAssigned >= Season9.itemLockTime then
    Speedrun.selectedItemStarts = {}
  end
end

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season9:PostGameStarted()
  -- Local variables
  local character = g.p:GetPlayerType()

  Isaac.DebugString("In the R+7 (Season 9) challenge.")

  -- Character-specific items
  if character == PlayerType.PLAYER_JUDAS then -- 3
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
  Isaac.DebugString(
    "Number of builds that we have already started: " .. tostring(#Speedrun.selectedItemStarts)
  )
  local startingBuild = Speedrun.selectedItemStarts[Speedrun.charNum]
  if startingBuild == nil then
    -- Get a random start
    local seed = g.seeds:GetStartSeed()
    local randomAttempts = 0
    while true do
      seed = g:IncrementRNG(seed)
      math.randomseed(seed)
      local startingBuildIndex = math.random(1, #Speedrun.remainingItemStarts)
      startingBuild = Speedrun.remainingItemStarts[startingBuildIndex]

      local valid = Season9:CheckValidStartingBuild(startingBuild)

      -- Just in case, prevent the possibility of having an infinite loop here
      if randomAttempts >= 100 then
        valid = true
      end

      if valid then
        -- Keep track of what item we start so that we don't get the same two starts in a row
        Season9.lastBuildItem = startingBuild[1]
        if Speedrun.charNum == 1 then
          Season9.lastBuildItemOnFirstChar = startingBuild[1]
        end
        Isaac.DebugString("Set the last starting build to: " .. tostring(Season9.lastBuildItem))

        -- Remove it from the remaining item pool
        table.remove(Speedrun.remainingItemStarts, startingBuildIndex)

        -- Keep track of what item we are supposed to be starting on this character / run
        Speedrun.selectedItemStarts[#Speedrun.selectedItemStarts + 1] = startingBuild

        -- Mark down the time that we assigned this item
        Season9.timeItemAssigned = Isaac.GetTime()

        -- Break out of the infinite loop
        Isaac.DebugString("Assigned a starting item of: " .. tostring(startingBuild[1]))
        break
      end

      randomAttempts = randomAttempts + 1
    end

  else
    Isaac.DebugString("Already assigned an item: " .. tostring(startingBuild[1]))
  end

  -- Give the items to the player (and remove the items from the pools)
  for _, item in ipairs(startingBuild) do
    g.p:AddCollectible(item, 0, false)
    g.itemPool:RemoveCollectible(item)

    -- (the PostItemPickup function will be called because the Racing+ POST_GAME_STARTED callback
    -- runs before the Racing+ Rebalanced one)
  end
end

function Season9:CheckValidStartingBuild(startingBuild)
  -- Local variables
  local character = g.p:GetPlayerType()

  -- If we are on the first character,
  -- we do not want to play a build that we have already played recently
  if (
    Speedrun.charNum == 1
    and (
      startingBuild[1] == Season9.lastBuildItem
      or startingBuild[1] == Season9.lastBuildItemOnFirstChar
    )
  ) then

    return false
  end

  -- Check to see if we already started this item
  for _, startedBuild in ipairs(Speedrun.selectedItemStarts) do
    if startedBuild[1] == startingBuild[1] then
      return false
    end
  end

  -- Check to see if we banned this item
  local charOrder = RacingPlusData:Get("charOrder-R7S6")
  for i = 8, #charOrder do
    local item = charOrder[i]

    -- Convert builds to the primary item
    if item == 1006 then
      item = CollectibleType.COLLECTIBLE_CHOCOLATE_MILK -- 69
    elseif item == 1005 then
      item = CollectibleType.COLLECTIBLE_JACOBS_LADDER -- 494
    elseif item == 1001 then
      item = CollectibleType.COLLECTIBLE_MUTANT_SPIDER -- 153
    elseif item == 1002 then
      item = CollectibleType.COLLECTIBLE_TECHNOLOGY -- 68
    elseif item == 1003 then
      item = CollectibleType.COLLECTIBLE_FIRE_MIND -- 257
    end

    if startingBuild[1] == item then
      return false
    end
  end

  -- Check to see if this start synergizes with this character (character/item bans)
  if character == PlayerType.PLAYER_JUDAS then -- 3
    if startingBuild[1] == CollectibleType.COLLECTIBLE_JUDAS_SHADOW then -- 311
      return false
    end

  elseif character == PlayerType.PLAYER_EVE then -- 5
    if startingBuild[1] == CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT then -- 415
      return false
    end

  elseif character == PlayerType.PLAYER_AZAZEL then -- 7
    if (
      startingBuild[1] == CollectibleType.COLLECTIBLE_IPECAC -- 149
      or startingBuild[1] == CollectibleType.COLLECTIBLE_MUTANT_SPIDER -- 153
      or startingBuild[1] == CollectibleType.COLLECTIBLE_CRICKETS_BODY -- 224
      or startingBuild[1] == CollectibleType.COLLECTIBLE_DEAD_EYE -- 373
      or startingBuild[1] == CollectibleType.COLLECTIBLE_JUDAS_SHADOW -- 331
      or startingBuild[1] == CollectibleType.COLLECTIBLE_FIRE_MIND -- 257
      or startingBuild[1] == CollectibleType.COLLECTIBLE_JACOBS_LADDER -- 494
    ) then
      return false
    end

  elseif character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
    if (
      startingBuild[1] == CollectibleType.COLLECTIBLE_DEATHS_TOUCH -- 237
      or startingBuild[1] == CollectibleType.COLLECTIBLE_FIRE_MIND -- 257
      or startingBuild[1] == CollectibleType.COLLECTIBLE_LIL_BRIMSTONE -- 275
      or startingBuild[1] == CollectibleType.COLLECTIBLE_JUDAS_SHADOW -- 311
      or startingBuild[1] == CollectibleType.COLLECTIBLE_INCUBUS -- 350
    ) then
      return false
    end
  end

  return true
end

-- Reset the starting item timer if we just killed the Basement 2 boss
function Season9:PostClearRoom()
  -- Local variables
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()
  local challenge = Isaac.GetChallenge()

  if (
    challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)")
    and stage == 2
    and roomType == RoomType.ROOM_BOSS -- 5
  ) then
    Season9.timeItemAssigned = 0
  end
end

return Season9

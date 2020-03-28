local Season5 = {}

-- Includes
local g        = require("racing_plus/globals")
local Speedrun = require("racing_plus/speedrun")

--
-- Constants
--

Season5.itemStarts = {
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

Season5.big4 = {
  CollectibleType.COLLECTIBLE_MOMS_KNIFE, -- 114
  CollectibleType.COLLECTIBLE_TECH_X, -- 395
  CollectibleType.COLLECTIBLE_EPIC_FETUS, -- 168
  CollectibleType.COLLECTIBLE_IPECAC, -- 149
}

-- We need to record the starting item on the first character
-- so that we can avoid duplicate starting items later on
-- Called from the "PostUpdate:CheckItemPickup()" function
function Season5:PostItemPickup()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 5)") or
     #g.run.passiveItems ~= 1 or
     Speedrun.charNum ~= 1 or
     g.run.roomsEntered < 2 then
     -- (characters can start with a starting item,
     -- so we want to make sure that we enter at least one room)

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

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season5:PostGameStartedFirstCharacter()
  Speedrun.remainingItemStarts = g:TableClone(Season5.itemStarts)
  Speedrun.selectedItemStarts = {}
end

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season5:PostGameStarted()
  Isaac.DebugString("In the R+7 (Season 5) challenge.")

  -- (Random Baby automatically starts with the Schoolbag)

  -- Change the starting health from 3 red hearts to 1 red heart and 1 half soul heart
  g.p:AddMaxHearts(-4)
  g.p:AddSoulHearts(1)

  -- On the first character, we will start an item normally
  -- On the second character and beyond, a start will be randomly assigned
  if Speedrun.charNum < 2 then
    return
  end

  -- As a safety measure, check to see if the "selectedItemStarts" table has a value in it for the first character
  -- (it should contain one item, equal to the item that was started on the first character)
  if #Speedrun.selectedItemStarts < 1 then
    -- Just assume that they started the Sad Onion
    Speedrun.selectedItemStarts[1] = CollectibleType.COLLECTIBLE_SAD_ONION -- 1
    Isaac.DebugString("Error: No starting item was recorded for the first character.")
  end

  -- Check to see if the player has played a run with one of the big 4
  local alreadyStartedBig4 = false
  for _, big4Item in ipairs(Season5.big4) do
    for _, startedItem in ipairs(Speedrun.selectedItemStarts) do
      if big4Item == startedItem then
        alreadyStartedBig4 = true
        break
      end
    end
  end
  Isaac.DebugString("Already started a run with the big 4: " .. tostring(alreadyStartedBig4))

  -- Check to see if a start is already assigned for this character number
  -- (dying and resetting should not reassign the selected starting item)
  local startingItem = Speedrun.selectedItemStarts[Speedrun.charNum]
  if startingItem == nil then
    -- Get a random start
    local seed = g.seeds:GetStartSeed()
    while true do
      seed = g:IncrementRNG(seed)
      math.randomseed(seed)
      local startingItemIndex
      if alreadyStartedBig4 then
        startingItemIndex = math.random(5, #Speedrun.remainingItemStarts)
      elseif Speedrun.charNum == 7 then
        -- Guarantee at least one big 4 start
        startingItemIndex = math.random(1, 4)
      else
        startingItemIndex = math.random(1, #Speedrun.remainingItemStarts)
      end
      startingItem = Speedrun.remainingItemStarts[startingItemIndex]

      -- Check to see if we already started this item
      local alreadyStarted = false
      for _, startedItem in ipairs(Speedrun.selectedItemStarts) do
        if startedItem == startingItem then
          alreadyStarted = true
          break
        end
      end
      if not alreadyStarted then
        -- Remove it from the starting item pool
        table.remove(Speedrun.remainingItemStarts, startingItemIndex)

        -- Keep track of what item we are supposed to be starting on this character / run
        Speedrun.selectedItemStarts[#Speedrun.selectedItemStarts + 1] = startingItem

        -- Break out of the infinite loop
        break
      end
    end
  end

  -- Give it to the player and remove it from item pools
  g.p:AddCollectible(startingItem, 0, false)
  g.itemPool:RemoveCollectible(startingItem)

  -- Also remove the additional soul hearts from Crown of Light
  if startingItem == CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT then -- 415
    g.p:AddSoulHearts(-4)
  end
end

return Season5

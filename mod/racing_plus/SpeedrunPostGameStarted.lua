local SpeedrunPostGameStarted = {}

-- Includes
local g               = require("racing_plus/globals")
local Speedrun        = require("racing_plus/speedrun")
local Schoolbag       = require("racing_plus/schoolbag")

function SpeedrunPostGameStarted:Main()
  -- Local variables
  local character = g.p:GetPlayerType()
  local challenge = Isaac.GetChallenge()

  -- Reset some per-run variables
  Speedrun.spawnedCheckpoint = false
  Speedrun.fadeFrame = 0
  Speedrun.resetFrame = 0

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

  if challenge == Isaac.GetChallengeIdByName(Speedrun.R7SeededName) then
    Speedrun.inSeededSpeedrun = true
    g:ExecuteCommand("challenge 0")
    g:ExecuteCommand("seed " .. Speedrun.R7SeededSeeds[1])
    -- We need to set a seed before restarting the game to enable "seeded mode"
    g.run.restart = true
    return
  end

  if Speedrun.inSeededSpeedrun and
     challenge ~= Challenge.CHALLENGE_NULL then -- 0

    Speedrun.inSeededSpeedrun = false
  end

  if not Speedrun:InSpeedrun() then
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
    Speedrun.finishTimeCharacter = 0
    Speedrun.averageTime = 0
    if challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
      Speedrun.remainingItemStarts = g:TableClone(Speedrun.itemStartsS5)
      Speedrun.selectedItemStarts = {}
    elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") then
      Speedrun.remainingItemStarts = g:TableClone(Speedrun.itemStartsS6)
      if Isaac.GetTime() - Speedrun.timeItemAssigned >= Speedrun.itemLockTime then
        Speedrun.selectedItemStarts = {}
      end
    end
  end

  -- The first character of the speedrun always gets More Options to speed up the process of getting a run going
  -- (but Season 4 and Seeded never get it, since there is no resetting involved)
  if Speedrun.charNum == 1 and
     (challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 4)") and
      not Speedrun.inSeededSpeedrun) then

    g.p:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
    g.p:RemoveCostume(g.itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS))
    -- We don't want the costume to show
    Isaac.DebugString("Removing collectible 414 (More Options)")
    -- We don't need to show this on the item tracker to reduce clutter
    g.run.removeMoreOptions = true
    -- More Options will be removed upon entering the first Treasure Room
  end

  -- Do actions based on the specific challenge
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") then
    SpeedrunPostGameStarted:R9S1()
  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
    SpeedrunPostGameStarted:R14S1()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") then
    SpeedrunPostGameStarted:R7S2()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") then
    SpeedrunPostGameStarted:R7S3()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") then
    SpeedrunPostGameStarted:R7S4()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
    SpeedrunPostGameStarted:R7S5()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") then
    SpeedrunPostGameStarted:R7S6()
  elseif Speedrun.inSeededSpeedrun then
    SpeedrunPostGameStarted:R7SS()
  elseif challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then
    return -- Do nothing for the vanilla challenge
  else
    Isaac.DebugString("Error: Unknown challenge.")
  end
end

function SpeedrunPostGameStarted:R9S1()
  -- Local variables
  local character = g.p:GetPlayerType()

  Isaac.DebugString("In the R+9 (Season 1) challenge.")

  -- Give extra items to characters for the R+9 speedrun category (Season 1)
  if character == PlayerType.PLAYER_KEEPER then -- 14
    -- Add the items
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET, 0, false) -- 501
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET) -- 501
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_DUALITY, 0, false) -- 498
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DUALITY) -- 498

    -- Grant an extra coin/heart container
    g.p:AddCoins(24) -- Keeper starts with 1 coin so we only need to give 24
    g.p:AddCoins(1) -- This fills in the new heart container
    g.p:AddCoins(25) -- Add a 2nd container
    g.p:AddCoins(1) -- This fills in the new heart container
  end
end

function SpeedrunPostGameStarted:R14S1()
  -- Local variables
  local character = g.p:GetPlayerType()

  Isaac.DebugString("In the R+14 (Season 1) challenge.")

  -- Give extra items to characters for the R+14 speedrun category (Season 1)
  if character == PlayerType.PLAYER_ISAAC then -- 0
    -- Add the Battery
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_BATTERY, 0, false) -- 63
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BATTERY) -- 63

    -- Make Isaac start with a double charge instead of a single charge
    g.p:SetActiveCharge(12)
    g.sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170

  elseif character == PlayerType.PLAYER_MAGDALENA then -- 1
    -- Add the Soul Jar
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR, 0, false)
    -- (the Soul Jar does not appear in any pools)

  elseif character == PlayerType.PLAYER_LILITH then -- 13
    -- Lilith starts with the Schoolbag by default
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    Schoolbag:Put(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS, "max") -- 357

    -- Reorganize the items on the item tracker
    Isaac.DebugString("Removing collectible 412 (Cambion Conception)")
    Isaac.DebugString("Adding collectible 412 (Cambion Conception)")

  elseif character == PlayerType.PLAYER_KEEPER then -- 14
    -- Add the items
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET, 0, false) -- 501
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET) -- 501
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_DUALITY, 0, false) -- 498
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DUALITY) -- 498

    -- Grant an extra coin/heart container
    g.p:AddCoins(24) -- Keeper starts with 1 coin so we only need to give 24
    g.p:AddCoins(1) -- This fills in the new heart container
    g.p:AddCoins(25) -- Add a 2nd container
    g.p:AddCoins(1) -- This fills in the new heart container

  elseif character == PlayerType.PLAYER_APOLLYON then -- 15
    -- Apollyon starts with the Schoolbag by default
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    Schoolbag:Put(CollectibleType.COLLECTIBLE_VOID, "max") -- 477
  end
end

function SpeedrunPostGameStarted:R7S2()
  -- Local variables
  local character = g.p:GetPlayerType()

  Isaac.DebugString("In the R+7 (Season 2) challenge.")

  -- Give extra items to characters for the R+7 speedrun category (Season 2)
  if character == PlayerType.PLAYER_ISAAC then -- 0
    -- Add the Battery
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_BATTERY, 0, false) -- 63
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BATTERY) -- 63

    -- Make Isaac start with a double charge instead of a single charge
    g.p:SetActiveCharge(12)
    g.sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170

  elseif character == PlayerType.PLAYER_APOLLYON then -- 15
    -- Apollyon starts with the Schoolbag by default
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    Schoolbag:Put(CollectibleType.COLLECTIBLE_VOID, "max") -- 477
  end
end

function SpeedrunPostGameStarted:R7S3()
  -- Local variables
  local character = g.p:GetPlayerType()

  Isaac.DebugString("In the R+7 (Season 3) challenge.")

  -- Everyone starts with the Schoolbag in this season
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)

  -- Give extra items to characters for the R+7 speedrun category (Season 3)
  if character == PlayerType.PLAYER_ISAAC then -- 0
    Schoolbag:Put(CollectibleType.COLLECTIBLE_MOVING_BOX, "max") -- 523
  elseif character == PlayerType.PLAYER_MAGDALENA then -- 1
    Schoolbag:Put(CollectibleType.COLLECTIBLE_HOW_TO_JUMP, "max") -- 282
  elseif character == PlayerType.PLAYER_JUDAS then -- 3
    Schoolbag:Put(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL, "max") -- 34
  elseif character == PlayerType.PLAYER_EVE then -- 5
    Schoolbag:Put(CollectibleType.COLLECTIBLE_CANDLE, "max") -- 164
  elseif character == PlayerType.PLAYER_SAMSON then -- 6
    Schoolbag:Put(CollectibleType.COLLECTIBLE_MR_ME, "max") -- 527
  elseif character == PlayerType.PLAYER_LAZARUS then -- 8
    Schoolbag:Put(CollectibleType.COLLECTIBLE_VENTRICLE_RAZOR, "max") -- 396
  elseif character == PlayerType.PLAYER_THELOST then -- 10
    Schoolbag:Put(CollectibleType.COLLECTIBLE_GLASS_CANNON, "max") -- 352
  end
end

function SpeedrunPostGameStarted:R7S4()
  -- Local variables
  local character = g.p:GetPlayerType()

  Isaac.DebugString("In the R+7 (Season 4) challenge.")

  -- Everyone starts with the Schoolbag in this season
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)

  -- Give extra items to characters for the R+7 speedrun category (Season 4)
  if character == PlayerType.PLAYER_LAZARUS then -- 8
    -- Lazarus does not start with a pill to prevent players resetting for a good pill
    g.p:SetPill(0, 0)

  elseif character == PlayerType.PLAYER_LILITH then -- 13
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_INCUBUS, 0, false) -- 360
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_INCUBUS) -- 360

    -- Don't show it on the item tracker
    Isaac.DebugString("Removing collectible 360 (Incubus)")

    -- If we switch characters, we want to remove the extra Incubus
    g.run.extraIncubus = true
  end

  -- Give the additional (chosen) starting item/build
  -- (the item choice is stored in the second half of the "charOrder" variable)
  local itemID = g.race.charOrder[Speedrun.charNum + 8]
  if itemID < 1000 then
    -- This is a single item build
    g.p:AddCollectible(itemID, 0, false)
    g.itemPool:RemoveCollectible(itemID)
  else
    -- This is a build with two items
    if itemID == 1001 then
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER, 0, false) -- 153
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) -- 153
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_INNER_EYE, 0, false) -- 2
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) -- 2

    elseif itemID == 1002 then
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY, 0, false) -- 68
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) -- 68
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL, 0, false) -- 132
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) -- 132

    elseif itemID == 1003 then
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_FIRE_MIND, 0, false) -- 257
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_FIRE_MIND) -- 257
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_13_LUCK, 0, false)
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID, 0, false) -- 317
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID) -- 317

    elseif itemID == 1004 then
      -- Start with the Kamikaze in the active slot for quality of life purposes
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_KAMIKAZE, 0, false) -- 40
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_KAMIKAZE) -- 40
      Schoolbag:Put(CollectibleType.COLLECTIBLE_D6, "max") -- 105
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_HOST_HAT, 0, false) -- 375
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_HOST_HAT) -- 375

    elseif itemID == 1005 then
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_JACOBS_LADDER, 0, false) -- 494
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_JACOBS_LADDER) -- 494
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS, 0, false) -- 249
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS) -- 249

    elseif itemID == 1006 then
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK, 0, false) -- 69
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) -- 69
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_STEVEN, 0, false) -- 50
      g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_STEVEN) -- 50
    end
  end
end

function SpeedrunPostGameStarted:R7S5()
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
  for _, big4Item in ipairs(Speedrun.big4) do
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

function SpeedrunPostGameStarted:R7S6()
  -- Local variables
  local character = g.p:GetPlayerType()

  Isaac.DebugString("In the R+7 (Season 6) challenge.")

  -- Everyone starts with the Schoolbag in this season
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)

  -- Everyone starts with the Compass in this season
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_COMPASS, 0, false) -- 21
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_COMPASS) -- 21
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_CAINS_EYE) -- 59

  -- Everyone starts with a random passive item / build
  -- Check to see if the player has played a run with one of the big 4
  local alreadyStartedBig4 = false
  for _, startedItem in ipairs(Speedrun.selectedItemStarts) do
    for _, big4Item in ipairs(Speedrun.big4) do
      if startedItem[1] == big4Item then
        alreadyStartedBig4 = true
        break
      end
    end
  end
  Isaac.DebugString("Already started a run with the big 4: " .. tostring(alreadyStartedBig4))

  -- Disable starting a big 4 item on the first character
  if Speedrun.charNum == 1 then
    alreadyStartedBig4 = true
  end

  -- Check to see if a start is already assigned for this character number
  -- (dying and resetting should not reassign the selected starting item)
  Isaac.DebugString("Number of items that we have already started: " .. tostring(#Speedrun.selectedItemStarts))
  local startingItems = Speedrun.selectedItemStarts[Speedrun.charNum]
  if startingItems == nil then
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
      startingItems = Speedrun.remainingItemStarts[startingItemIndex]

      local valid = true

      -- Check to see if we started this item last time
      if startingItems[1] == Speedrun.lastItemStart then
        valid = false
      end

      -- Check to see if we already started this item
      for _, startedItem in ipairs(Speedrun.selectedItemStarts) do
        if startedItem == startingItems[1] then
          valid = false
          break
        end
      end

      -- Check to see if we banned this item
      for i = 9, #g.race.charOrder do
        local item = g.race.charOrder[i]

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

        if startingItems[1] == item then
          valid = false
          break
        end
      end

      -- Check to see if this start synergizes with this character (character/item bans)
      if character == PlayerType.PLAYER_EVE then -- 5
        if startingItems[1] == CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT then -- 415
          valid = false
        end

      elseif character == PlayerType.PLAYER_AZAZEL then -- 7
        if startingItems[1] == CollectibleType.COLLECTIBLE_MUTANT_SPIDER or -- 153
           startingItems[1] == CollectibleType.COLLECTIBLE_CRICKETS_BODY or -- 224
           startingItems[1] == CollectibleType.COLLECTIBLE_DEAD_EYE or -- 373
           startingItems[1] == CollectibleType.COLLECTIBLE_JUDAS_SHADOW or -- 331
           startingItems[1] == CollectibleType.COLLECTIBLE_FIRE_MIND or -- 257
           startingItems[1] == CollectibleType.COLLECTIBLE_JACOBS_LADDER then -- 494

          valid = false
        end

      elseif character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
        if startingItems[1] == CollectibleType.COLLECTIBLE_DEATHS_TOUCH or -- 237
           startingItems[1] == CollectibleType.COLLECTIBLE_FIRE_MIND or -- 257
           startingItems[1] == CollectibleType.COLLECTIBLE_LIL_BRIMSTONE or -- 275
           startingItems[1] == CollectibleType.COLLECTIBLE_JUDAS_SHADOW then -- 311

          valid = false
        end
      end

      -- Check to see if we vetoed this item and we are on the first character
      if Speedrun.charNum == 1 then
        for _, veto in ipairs(Speedrun.vetoList) do
          if veto == startingItems[1] then
            valid = false
            break
          end
        end
      end

      if valid then
        -- Keep track of what item we start so that we don't get the same two starts in a row
        Speedrun.lastItemStart = startingItems[1]

        -- Remove it from the remaining item pool
        table.remove(Speedrun.remainingItemStarts, startingItemIndex)

        -- Keep track of what item we are supposed to be starting on this character / run
        Speedrun.selectedItemStarts[#Speedrun.selectedItemStarts + 1] = startingItems

        -- Mark down the time that we assigned this item
        Speedrun.timeItemAssigned = Isaac.GetTime()

        -- Break out of the infinite loop
        Isaac.DebugString("Assigned a starting item of: " .. tostring(startingItems[1]))
        break
      end
    end

  else
    Isaac.DebugString("Already assigned an item: " .. tostring(startingItems[1]))
  end

  -- Give the items to the player (and remove the items from the pools)
  for _, item in ipairs(startingItems) do
    g.p:AddCollectible(item, 0, false)
    g.itemPool:RemoveCollectible(item)

    if item == CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT then -- 415
      -- Also remove the additional soul hearts from Crown of Light
      g.p:AddSoulHearts(-4)

      -- Re-heal Judas back to 1 red heart so that they can properly use the Crown of Light
      -- (this should do nothing on all of the other characters)
      g.p:AddHearts(1)
    end
  end

  -- Spawn a "Veto" button on the first character
  if Speedrun.vetoTimer ~= 0 and
     Isaac.GetTime() >= Speedrun.vetoTimer then

      Speedrun.vetoTimer = 0
  end
  if Speedrun.charNum == 1 and
     Speedrun.vetoTimer == 0 then

    local pos = g:GridToPos(11, 6)
    Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, pos, true) -- 20
  end
end

function SpeedrunPostGameStarted:R7SS()
  -- Local variables
  local startSeedString = g.seeds:GetStartSeedString()

  Isaac.DebugString("In the R+7 Seeded challenge.")

  -- Make sure that we are on the correct seed
  if startSeedString ~= Speedrun.R7SeededSeeds[Speedrun.charNum] then
    -- Doing a "seed #### ####" here does not work for some reason, so mark to reset on the next frame
    g.run.restart = true
    Isaac.DebugString("Restarting because we were not on the right seed.")
    return
  end

  -- Everyone starts with the Mind in this custom challenge
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_MIND, 0, false) -- 333
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MIND) -- 333
  g.p:RemoveCostume(g.itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_MIND)) -- 333
  -- We don't want the costume to show

  -- Remove certain trinkets from the game that affect floor generation
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_SILVER_DOLLAR) -- 110
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_BLOODY_CROWN) -- 111

  if Speedrun.charNum == 1 then
    -- Spawn a "Finished" custom item in the corner of the room (which takes you to the main menu)
    local finishedPosition = g:GridToPos(1, 1)
    g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, finishedPosition, Vector(0, 0),
              nil, CollectibleType.COLLECTIBLE_FINISHED, 0)
  end
end

return SpeedrunPostGameStarted

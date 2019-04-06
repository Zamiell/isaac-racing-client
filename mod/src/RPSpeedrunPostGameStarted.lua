local RPSpeedrunPostGameStarted = {}

-- Includes
local RPGlobals         = require("src/rpglobals")
local RPSpeedrun        = require("src/rpspeedrun")
local RPChangeCharOrder = require("src/rpchangecharorder")
local RPSchoolbag       = require("src/rpschoolbag")

function RPSpeedrunPostGameStarted:Main()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()
  local challenge = Isaac.GetChallenge()
  local itemConfig = Isaac.GetItemConfig()

  -- Reset some per-run variables
  RPSpeedrun.spawnedCheckpoint = false
  RPSpeedrun.fadeFrame = 0
  RPSpeedrun.resetFrame = 0

  if RPSpeedrun.liveSplitReset then
    RPSpeedrun.liveSplitReset = false
    player:AddCollectible(CollectibleType.COLLECTIBLE_OFF_LIMITS, 0, false)
    Isaac.DebugString("Reset the LiveSplit AutoSplitter by giving \"Off Limits\", item ID " ..
                      tostring(CollectibleType.COLLECTIBLE_OFF_LIMITS) .. ".")
    Isaac.DebugString("Removing collectible " .. tostring(CollectibleType.COLLECTIBLE_OFF_LIMITS) .. " (Off Limits)")
  end

  -- Move to the first character if we finished
  -- (this has to be above the challenge name check so that the fireworks won't carry over to another run)
  if RPSpeedrun.finished then
    RPSpeedrun.charNum = 1
    RPSpeedrun.finished = false
    RPSpeedrun.finishedTime = 0
    RPSpeedrun.finishedFrames = 0
    RPSpeedrun.fastReset = false
    RPGlobals.run.restart = true
    Isaac.DebugString("Restarting to go back to the first character (since we finished the speedrun).")
    return
  end

  if challenge == Isaac.GetChallengeIdByName("Change Char Order") then
    -- Make sure that some speedrun related variables are reset
    RPSpeedrun.charNum = 1
    RPSpeedrun.fastReset = false
    RPSpeedrun.inSeededSpeedrun = false

    -- Prepare the player for the button room and teleport them there
    RPChangeCharOrder:PostGameStarted()
    return
  end

  if challenge == Isaac.GetChallengeIdByName(RPSpeedrun.R7SeededName) then
    RPSpeedrun.inSeededSpeedrun = true
    RPGlobals:ExecuteCommand("challenge 0")
    RPGlobals:ExecuteCommand("seed " .. RPSpeedrun.R7SeededSeeds[1])
    -- We need to set a seed before restarting the game to enable "seeded mode"
    RPGlobals.run.restart = true
    return
  end

  if RPSpeedrun.inSeededSpeedrun and
     challenge ~= Challenge.CHALLENGE_NULL then -- 0

    RPSpeedrun.inSeededSpeedrun = false
  end

  if RPSpeedrun:InSpeedrun() == false then
    return
  end

  -- Don't do anything if the player has not submitted a character order
  -- (we will display an error later on in the PostRender callback)
  if RPSpeedrun:CheckValidCharOrder() == false then
    return
  end

  -- Check to see if we are on the correct character
  local correctCharacter = RPSpeedrun:GetCurrentChar()
  if character ~= correctCharacter then
    RPGlobals.run.restart = true
    Isaac.DebugString("Restarting because we are on character " .. tostring(character) ..
                      " and we need to be on character " .. tostring(correctCharacter))
    return
  end

  -- Check if they want to go back to the first character
  if RPSpeedrun.fastReset then
    RPSpeedrun.fastReset = false

  elseif RPSpeedrun.fastReset == false and
         RPSpeedrun.charNum ~= 1 then

    -- They held R, and they are not on the first character, so they want to restart from the first character
    RPSpeedrun.charNum = 1
    RPGlobals.run.restart = true
    Isaac.DebugString("Restarting because we want to start from the first character again.")

    -- Tell the LiveSplit AutoSplitter to reset
    RPSpeedrun.liveSplitReset = true
    return
  end

  -- Reset variables for the first character
  if RPSpeedrun.charNum == 1 then
    RPSpeedrun.startedTime = 0
    RPSpeedrun.startedFrame = 0
    RPSpeedrun.finishTimeCharacter = 0
    RPSpeedrun.averageTime = 0
    if challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
      RPSpeedrun.remainingItemStarts = RPGlobals:TableClone(RPSpeedrun.itemStartsS5)
      RPSpeedrun.selectedItemStarts = {}
    elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 6 Beta)") then
      RPSpeedrun.remainingItemStarts = RPGlobals:TableClone(RPSpeedrun.itemStartsS6)
      if Isaac.GetTime() - RPSpeedrun.timeItemAssigned >= RPSpeedrun.itemLockTime then
        RPSpeedrun.selectedItemStarts = {}
      end
    end
  end

  -- The first character of the speedrun always gets More Options to speed up the process of getting a run going
  -- (but Season 4 and Seeded never get it, since there is no resetting involved)
  if RPSpeedrun.charNum == 1 and
     (challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 4)") and
      RPSpeedrun.inSeededSpeedrun == false) then

    player:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
    player:RemoveCostume(itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS))
    -- We don't want the costume to show
    Isaac.DebugString("Removing collectible 414 (More Options)")
    -- We don't need to show this on the item tracker to reduce clutter
    RPGlobals.run.removeMoreOptions = true
    -- More Options will be removed upon entering the first Treasure Room
  end

  -- Do actions based on the specific challenge
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") then
    RPSpeedrunPostGameStarted:R9S1()
  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
    RPSpeedrunPostGameStarted:R14S1()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") then
    RPSpeedrunPostGameStarted:R7S2()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") then
    RPSpeedrunPostGameStarted:R7S3()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") then
    RPSpeedrunPostGameStarted:R7S4()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
    RPSpeedrunPostGameStarted:R7S5()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 6 Beta)") then
    RPSpeedrunPostGameStarted:R7S6()
  elseif RPSpeedrun.inSeededSpeedrun then
    RPSpeedrunPostGameStarted:R7SS()
  else
    Isaac.DebugString("Error: Unknown challenge.")
  end
end

function RPSpeedrunPostGameStarted:R9S1()
  -- Local variables
  local game = Game()
  local itemPool = game:GetItemPool()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  Isaac.DebugString("In the R+9 (Season 1) challenge.")

  -- Give extra items to characters for the R+9 speedrun category (Season 1)
  if character == PlayerType.PLAYER_KEEPER then -- 14
    -- Add the items
    player:AddCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET, 0, false) -- 501
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET) -- 501
    player:AddCollectible(CollectibleType.COLLECTIBLE_DUALITY, 0, false) -- 498
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DUALITY) -- 498

    -- Grant an extra coin/heart container
    player:AddCoins(24) -- Keeper starts with 1 coin so we only need to give 24
    player:AddCoins(1) -- This fills in the new heart container
    player:AddCoins(25) -- Add a 2nd container
    player:AddCoins(1) -- This fills in the new heart container
  end
end

function RPSpeedrunPostGameStarted:R14S1()
  -- Local variables
  local game = Game()
  local itemPool = game:GetItemPool()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()
  local sfx = SFXManager()

  Isaac.DebugString("In the R+14 (Season 1) challenge.")

  -- Give extra items to characters for the R+14 speedrun category (Season 1)
  if character == PlayerType.PLAYER_ISAAC then -- 0
    -- Add the Battery
    player:AddCollectible(CollectibleType.COLLECTIBLE_BATTERY, 0, false) -- 63
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BATTERY) -- 63

    -- Make Isaac start with a double charge instead of a single charge
    player:SetActiveCharge(12)
    sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170

  elseif character == PlayerType.PLAYER_MAGDALENA then -- 1
    -- Add the Soul Jar
    player:AddCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR, 0, false)
    -- (the Soul Jar does not appear in any pools)

  elseif character == PlayerType.PLAYER_LILITH then -- 13
    -- Lilith starts with the Schoolbag by default
    player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    RPSchoolbag:Put(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS, "max") -- 357

    -- Reorganize the items on the item tracker
    Isaac.DebugString("Removing collectible 412 (Cambion Conception)")
    Isaac.DebugString("Adding collectible 412 (Cambion Conception)")

  elseif character == PlayerType.PLAYER_KEEPER then -- 14
    -- Add the items
    player:AddCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET, 0, false) -- 501
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET) -- 501
    player:AddCollectible(CollectibleType.COLLECTIBLE_DUALITY, 0, false) -- 498
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DUALITY) -- 498

    -- Grant an extra coin/heart container
    player:AddCoins(24) -- Keeper starts with 1 coin so we only need to give 24
    player:AddCoins(1) -- This fills in the new heart container
    player:AddCoins(25) -- Add a 2nd container
    player:AddCoins(1) -- This fills in the new heart container

  elseif character == PlayerType.PLAYER_APOLLYON then -- 15
    -- Apollyon starts with the Schoolbag by default
    player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    RPSchoolbag:Put(CollectibleType.COLLECTIBLE_VOID, "max") -- 477
  end
end

function RPSpeedrunPostGameStarted:R7S2()
  -- Local variables
  local game = Game()
  local itemPool = game:GetItemPool()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()
  local sfx = SFXManager()

  Isaac.DebugString("In the R+7 (Season 2) challenge.")

  -- Give extra items to characters for the R+7 speedrun category (Season 2)
  if character == PlayerType.PLAYER_ISAAC then -- 0
    -- Add the Battery
    player:AddCollectible(CollectibleType.COLLECTIBLE_BATTERY, 0, false) -- 63
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BATTERY) -- 63

    -- Make Isaac start with a double charge instead of a single charge
    player:SetActiveCharge(12)
    sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170

  elseif character == PlayerType.PLAYER_APOLLYON then -- 15
    -- Apollyon starts with the Schoolbag by default
    player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    RPSchoolbag:Put(CollectibleType.COLLECTIBLE_VOID, "max") -- 477
  end
end

function RPSpeedrunPostGameStarted:R7S3()
  -- Local variables
  local game = Game()
  local itemPool = game:GetItemPool()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  Isaac.DebugString("In the R+7 (Season 3) challenge.")

  -- Everyone starts with the Schoolbag in this season
  player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)

  -- Give extra items to characters for the R+7 speedrun category (Season 3)
  if character == PlayerType.PLAYER_ISAAC then -- 0
    RPSchoolbag:Put(CollectibleType.COLLECTIBLE_MOVING_BOX, "max") -- 523
  elseif character == PlayerType.PLAYER_MAGDALENA then -- 1
    RPSchoolbag:Put(CollectibleType.COLLECTIBLE_HOW_TO_JUMP, "max") -- 282
  elseif character == PlayerType.PLAYER_JUDAS then -- 3
    RPSchoolbag:Put(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL, "max") -- 34
  elseif character == PlayerType.PLAYER_EVE then -- 5
    RPSchoolbag:Put(CollectibleType.COLLECTIBLE_CANDLE, "max") -- 164
  elseif character == PlayerType.PLAYER_SAMSON then -- 6
    RPSchoolbag:Put(CollectibleType.COLLECTIBLE_MR_ME, "max") -- 527
  elseif character == PlayerType.PLAYER_LAZARUS then -- 8
    RPSchoolbag:Put(CollectibleType.COLLECTIBLE_VENTRICLE_RAZOR, "max") -- 396
  elseif character == PlayerType.PLAYER_THELOST then -- 10
    RPSchoolbag:Put(CollectibleType.COLLECTIBLE_GLASS_CANNON, "max") -- 352
  end
end

function RPSpeedrunPostGameStarted:R7S4()
  -- Local variables
  local game = Game()
  local itemPool = game:GetItemPool()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  Isaac.DebugString("In the R+7 (Season 4) challenge.")

  -- Everyone starts with the Schoolbag in this season
  player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)

  -- Give extra items to characters for the R+7 speedrun category (Season 4)
  if character == PlayerType.PLAYER_LAZARUS then -- 8
    -- Lazarus does not start with a pill to prevent players resetting for a good pill
    player:SetPill(0, 0)

  elseif character == PlayerType.PLAYER_LILITH then -- 13
    player:AddCollectible(CollectibleType.COLLECTIBLE_INCUBUS, 0, false) -- 360
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_INCUBUS) -- 360

    -- Don't show it on the item tracker
    Isaac.DebugString("Removing collectible 360 (Incubus)")

    -- If we switch characters, we want to remove the extra Incubus
    RPGlobals.run.extraIncubus = true
  end

  -- Give the additional (chosen) starting item/build
  -- (the item choice is stored in the second half of the "charOrder" variable)
  local itemID = RPGlobals.race.charOrder[RPSpeedrun.charNum + 8]
  if itemID < 1000 then
    -- This is a single item build
    player:AddCollectible(itemID, 0, false)
    itemPool:RemoveCollectible(itemID)
  else
    -- This is a build with two items
    if itemID == 1001 then
      player:AddCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER, 0, false) -- 153
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) -- 153
      player:AddCollectible(CollectibleType.COLLECTIBLE_INNER_EYE, 0, false) -- 2
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) -- 2

    elseif itemID == 1002 then
      player:AddCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY, 0, false) -- 68
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) -- 68
      player:AddCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL, 0, false) -- 132
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) -- 132

    elseif itemID == 1003 then
      player:AddCollectible(CollectibleType.COLLECTIBLE_FIRE_MIND, 0, false) -- 257
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_FIRE_MIND) -- 257
      player:AddCollectible(CollectibleType.COLLECTIBLE_13_LUCK, 0, false)
      player:AddCollectible(CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID, 0, false) -- 317
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID) -- 317

    elseif itemID == 1004 then
      -- Start with the Kamikaze in the active slot for quality of life purposes
      player:AddCollectible(CollectibleType.COLLECTIBLE_KAMIKAZE, 0, false) -- 40
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_KAMIKAZE) -- 40
      RPSchoolbag:Put(CollectibleType.COLLECTIBLE_D6, "max") -- 105
      player:AddCollectible(CollectibleType.COLLECTIBLE_HOST_HAT, 0, false) -- 375
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_HOST_HAT) -- 375

    elseif itemID == 1005 then
      player:AddCollectible(CollectibleType.COLLECTIBLE_JACOBS_LADDER, 0, false) -- 494
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_JACOBS_LADDER) -- 494
      player:AddCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS, 0, false) -- 249
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS) -- 249

    elseif itemID == 1006 then
      player:AddCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK, 0, false) -- 69
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) -- 69
      player:AddCollectible(CollectibleType.COLLECTIBLE_STEVEN, 0, false) -- 50
      itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_STEVEN) -- 50
    end
  end
end

function RPSpeedrunPostGameStarted:R7S5()
  -- Local variables
  local game = Game()
  local itemPool = game:GetItemPool()
  local seeds = game:GetSeeds()
  local player = game:GetPlayer(0)

  Isaac.DebugString("In the R+7 (Season 5) challenge.")

  -- (Random Baby automatically starts with the Schoolbag)

  -- Change the starting health from 3 red hearts to 1 red heart and 1 half soul heart
  player:AddMaxHearts(-4)
  player:AddSoulHearts(1)

  -- On the first character, we will start an item normally
  -- On the second character and beyond, a start will be randomly assigned
  if RPSpeedrun.charNum < 2 then
    return
  end

  -- As a safety measure, check to see if the "selectedItemStarts" table has a value in it for the first character
  -- (it should contain one item, equal to the item that was started on the first character)
  if #RPSpeedrun.selectedItemStarts < 1 then
    -- Just assume that they started the Sad Onion
    RPSpeedrun.selectedItemStarts[1] = CollectibleType.COLLECTIBLE_SAD_ONION -- 1
    Isaac.DebugString("Error: No starting item was recorded for the first character.")
  end

  -- Check to see if the player has played a run with one of the big 4
  local alreadyStartedBig4 = false
  for i = 1, #RPSpeedrun.big4 do
    for j = 1, #RPSpeedrun.selectedItemStarts do
      if RPSpeedrun.selectedItemStarts[j] == RPSpeedrun.big4[i] then
        alreadyStartedBig4 = true
        break
      end
    end
  end
  Isaac.DebugString("Already started a run with the big 4: " .. tostring(alreadyStartedBig4))

  -- Check to see if a start is already assigned for this character number
  -- (dying and resetting should not reassign the selected starting item)
  local startingItem = RPSpeedrun.selectedItemStarts[RPSpeedrun.charNum]
  if startingItem == nil then
    -- Get a random start
    local seed = seeds:GetStartSeed()
    while true do
      seed = RPGlobals:IncrementRNG(seed)
      math.randomseed(seed)
      local startingItemIndex
      if alreadyStartedBig4 then
        startingItemIndex = math.random(5, #RPSpeedrun.remainingItemStarts)
      elseif RPSpeedrun.charNum == 7 then
        -- Guarantee at least one big 4 start
        startingItemIndex = math.random(1, 4)
      else
        startingItemIndex = math.random(1, #RPSpeedrun.remainingItemStarts)
      end
      startingItem = RPSpeedrun.remainingItemStarts[startingItemIndex]

      -- Check to see if we already started this item
      local alreadyStarted = false
      for i = 1, #RPSpeedrun.selectedItemStarts do
        if RPSpeedrun.selectedItemStarts[i] == startingItem then
          alreadyStarted = true
          break
        end
      end
      if alreadyStarted == false then
        -- Remove it from the starting item pool
        table.remove(RPSpeedrun.remainingItemStarts, startingItemIndex)

        -- Keep track of what item we are supposed to be starting on this character / run
        RPSpeedrun.selectedItemStarts[#RPSpeedrun.selectedItemStarts + 1] = startingItem

        -- Break out of the infinite loop
        break
      end
    end
  end

  -- Give it to the player and remove it from item pools
  player:AddCollectible(startingItem, 0, false)
  itemPool:RemoveCollectible(startingItem)

  -- Also remove the additional soul hearts from Crown of Light
  if startingItem == CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT then -- 415
    player:AddSoulHearts(-4)
  end
end

function RPSpeedrunPostGameStarted:R7S6()
  -- Local variables
  local game = Game()
  local itemPool = game:GetItemPool()
  local seeds = game:GetSeeds()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  Isaac.DebugString("In the R+7 (Season 6) challenge.")

  -- Everyone starts with the Schoolbag in this season
  player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)

  -- Everyone starts with the Compass in this season
  player:AddCollectible(CollectibleType.COLLECTIBLE_COMPASS, 0, false) -- 21
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_COMPASS) -- 21
  itemPool:RemoveTrinket(TrinketType.TRINKET_CAINS_EYE) -- 59

  -- Everyone starts with a random passive item / build
  -- Check to see if the player has played a run with one of the big 4
  local alreadyStartedBig4 = false
  for i = 1, #RPSpeedrun.selectedItemStarts do
    for j = 1, #RPSpeedrun.big4 do
      if RPSpeedrun.selectedItemStarts[i][1] == RPSpeedrun.big4[j] then
        alreadyStartedBig4 = true
        break
      end
    end
  end
  Isaac.DebugString("Already started a run with the big 4: " .. tostring(alreadyStartedBig4))

  -- Disable starting a big 4 item on the first character
  if RPSpeedrun.charNum == 1 then
    alreadyStartedBig4 = true
  end

  -- Check to see if a start is already assigned for this character number
  -- (dying and resetting should not reassign the selected starting item)
  Isaac.DebugString("Number of items that we have already started: " .. tostring(#RPSpeedrun.selectedItemStarts))
  local startingItems = RPSpeedrun.selectedItemStarts[RPSpeedrun.charNum]
  if startingItems == nil then
    -- Get a random start
    local seed = seeds:GetStartSeed()
    while true do
      seed = RPGlobals:IncrementRNG(seed)
      math.randomseed(seed)
      local startingItemIndex
      if alreadyStartedBig4 then
        startingItemIndex = math.random(5, #RPSpeedrun.remainingItemStarts)
      elseif RPSpeedrun.charNum == 7 then
        -- Guarantee at least one big 4 start
        startingItemIndex = math.random(1, 4)
      else
        startingItemIndex = math.random(1, #RPSpeedrun.remainingItemStarts)
      end
      startingItems = RPSpeedrun.remainingItemStarts[startingItemIndex]

      local valid = true

      -- Check to see if we started this item last time
      if startingItems[1] == RPSpeedrun.lastItemStart then
        valid = false
      end

      -- Check to see if we already started this item
      for i = 1, #RPSpeedrun.selectedItemStarts do
        if RPSpeedrun.selectedItemStarts[i] == startingItems[1] then
          valid = false
          break
        end
      end

      -- Check to see if we banned this item
      for i = 9, #RPGlobals.race.charOrder do
        local item = RPGlobals.race.charOrder[i]

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
      if RPSpeedrun.charNum == 1 then
        for i = 1, #RPSpeedrun.vetoList do
          if RPSpeedrun.vetoList[i] == startingItems[1] then
            valid = false
            break
          end
        end
      end

      if valid then
        -- Keep track of what item we start so that we don't get the same two starts in a row
        RPSpeedrun.lastItemStart = startingItems[1]

        -- Remove it from the remaining item pool
        table.remove(RPSpeedrun.remainingItemStarts, startingItemIndex)

        -- Keep track of what item we are supposed to be starting on this character / run
        RPSpeedrun.selectedItemStarts[#RPSpeedrun.selectedItemStarts + 1] = startingItems

        -- Mark down the time that we assigned this item
        RPSpeedrun.timeItemAssigned = Isaac.GetTime()

        -- Break out of the infinite loop
        Isaac.DebugString("Assigned a starting item of: " .. tostring(startingItems[1]))
        break
      end
    end

  else
    Isaac.DebugString("Already assigned an item: " .. tostring(startingItems[1]))
  end

  -- Give the items to the player (and remove the items from the pools)
  for i, item in ipairs(startingItems) do
    player:AddCollectible(item, 0, false)
    itemPool:RemoveCollectible(item)

    if item == CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT then -- 415
      -- Also remove the additional soul hearts from Crown of Light
      player:AddSoulHearts(-4)

      -- Re-heal Judas back to 1 red heart so that they can properly use the Crown of Light
      -- (this should do nothing on all of the other characters)
      player:AddHearts(1)
    end
  end

  -- Spawn a "Veto" button on the first character
  if RPSpeedrun.vetoTimer ~= 0 and
     Isaac.GetTime() >= RPSpeedrun.vetoTimer then

      RPSpeedrun.vetoTimer = 0
  end
  if RPSpeedrun.charNum == 1 and
     RPSpeedrun.vetoTimer == 0 then

    local pos = RPGlobals:GridToPos(11, 6)
    Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, pos, true) -- 20
  end
end

function RPSpeedrunPostGameStarted:R7SS()
  -- Local variables
  local game = Game()
  local itemPool = game:GetItemPool()
  local seeds = game:GetSeeds()
  local startSeedString = seeds:GetStartSeedString()
  local player = game:GetPlayer(0)
  local itemConfig = Isaac.GetItemConfig()

  Isaac.DebugString("In the R+7 Seeded challenge.")

  -- Make sure that we are on the correct seed
  if startSeedString ~= RPSpeedrun.R7SeededSeeds[RPSpeedrun.charNum] then
    -- Doing a "seed #### ####" here does not work for some reason, so mark to reset on the next frame
    RPGlobals.run.restart = true
    Isaac.DebugString("Restarting because we were not on the right seed.")
    return
  end

  -- Everyone starts with the Mind in this custom challenge
  player:AddCollectible(CollectibleType.COLLECTIBLE_MIND, 0, false) -- 333
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MIND) -- 333
  player:RemoveCostume(itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_MIND)) -- 333
  -- We don't want the costume to show

  -- Remove certain trinkets from the game that affect floor generation
  itemPool:RemoveTrinket(TrinketType.TRINKET_SILVER_DOLLAR) -- 110
  itemPool:RemoveTrinket(TrinketType.TRINKET_BLOODY_CROWN) -- 111

  if RPSpeedrun.charNum == 1 then
    -- Spawn a "Finished" custom item in the corner of the room (which takes you to the main menu)
    local finishedPosition = RPGlobals:GridToPos(1, 1)
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, finishedPosition, Vector(0, 0),
               nil, CollectibleType.COLLECTIBLE_FINISHED, 0)
  end
end

return RPSpeedrunPostGameStarted

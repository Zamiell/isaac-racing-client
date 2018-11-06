local RPSpeedrun = {}

-- Includes
local RPGlobals         = require("src/rpglobals")
local RPSprites         = require("src/rpsprites")
local RPChangeCharOrder = require("src/rpchangecharorder")
local RPSchoolbag       = require("src/rpschoolbag")

-- Constants
RPSpeedrun.itemStarts = {
  CollectibleType.COLLECTIBLE_MOMS_KNIFE, -- 114
  CollectibleType.COLLECTIBLE_TECH_X, -- 395
  CollectibleType.COLLECTIBLE_EPIC_FETUS, -- 168
  CollectibleType.COLLECTIBLE_IPECAC, -- 149
  CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER, -- 172
  CollectibleType.COLLECTIBLE_20_20, -- 245
  CollectibleType.COLLECTIBLE_MUTANT_SPIDER_INNER_EYE, -- Custom
  CollectibleType.COLLECTIBLE_PROPTOSIS, -- 261
  CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT, -- 415
  CollectibleType.COLLECTIBLE_INCUBUS, -- 360
  CollectibleType.COLLECTIBLE_LIL_BRIMSTONE, -- 275
  CollectibleType.COLLECTIBLE_SACRED_HEART, -- 182
  CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM, -- 12
  CollectibleType.COLLECTIBLE_TECH_5, -- 244
  CollectibleType.COLLECTIBLE_POLYPHEMUS, -- 169
  CollectibleType.COLLECTIBLE_MAXS_HEAD, -- 4
  CollectibleType.COLLECTIBLE_DEATHS_TOUCH, -- 237
  CollectibleType.COLLECTIBLE_DEAD_EYE, -- 373
  CollectibleType.COLLECTIBLE_CRICKETS_BODY, -- 224
}

RPSpeedrun.big4 = {
  CollectibleType.COLLECTIBLE_MOMS_KNIFE, -- 114
  CollectibleType.COLLECTIBLE_TECH_X, -- 395
  CollectibleType.COLLECTIBLE_EPIC_FETUS, -- 168
  CollectibleType.COLLECTIBLE_IPECAC, -- 149
}

RPSpeedrun.R7SeededName = "R+7 Seeded (Q4 2018)"
RPSpeedrun.R7SeededSeeds = {
  "4PME M424",
  "JFSC 2WW7",
  "WEFG XQ6F",
  "4FAH GTDX",
  "3J46 P8BJ",
  "9YHG YKXH",
  "BQ9S MATW",
}
RPSpeedrun.R7SeededB1 = { -- These are the floor 1 stage types for the above seeds
  "b",
  "",
  "a",
  "a",
  "b",
  "",
  "a",
}

-- Variables
RPSpeedrun.charNum = 1 -- Reset expliticly from a long-reset and on the first reset after a finish
RPSpeedrun.startedTime = 0 -- Reset expliticly if we are on the first character
RPSpeedrun.startedFrame = 0 -- Reset expliticly if we are on the first character
RPSpeedrun.finishTimeCharacter = 0 -- Reset expliticly if we are on the first character
RPSpeedrun.averageTime = 0 -- Reset expliticly if we are on the first character
RPSpeedrun.finished = false -- Reset at the beginning of every run
RPSpeedrun.finishedTime = 0 -- Reset at the beginning of every run
RPSpeedrun.finishedFrames = 0 -- Reset at the beginning of every run
RPSpeedrun.fastReset = false -- Reset expliticly when we detect a fast reset
RPSpeedrun.spawnedCheckpoint = false -- Reset after we touch the checkpoint and at the beginning of a new run
RPSpeedrun.fadeFrame = 0 -- Reset after we touch the checkpoint and at the beginning of a new run
RPSpeedrun.resetFrame = 0 -- Reset after we execute the "restart" command and at the beginning of a new run
RPSpeedrun.liveSplitReset = false
RPSpeedrun.remainingItemStarts = {} -- Reset at the beginning of a new run
RPSpeedrun.selectedItemStarts = {} -- Reset at the beginning of a new run
RPSpeedrun.inSeededSpeedrun = false -- Reset ???
RPSpeedrun.trinketPool = {} -- Reset at the beginning of a new run
RPSpeedrun.trinketPoolNum = 0 -- Reset at the beginning of a new run

-- Called from the PostGameStarted callback
function RPSpeedrun:PostGameStarted()
  -- Local variables
  local game = Game()
  local seeds = game:GetSeeds()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()
  local challenge = Isaac.GetChallenge()
  local itemConfig = Isaac.GetItemConfig()

  -- Reset some per-run variables
  RPSpeedrun.spawnedCheckpoint = false
  RPSpeedrun.fadeFrame = 0
  RPSpeedrun.resetFrame = 0
  RPSpeedrun.trinketPool = {}
  RPSpeedrun.trinketPoolNum = 0

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

    -- Prepare the player for the button room and teleport them there
    RPChangeCharOrder:PostGameStarted()
    return
  end

  if challenge == Isaac.GetChallengeIdByName(RPSpeedrun.R7SeededName) then
    RPSpeedrun.inSeededSpeedrun = true
    seeds:SetStartSeed("WBY4 RS81") -- We need to set a seed to activate the "seeded" mode; it can be any seed at all
    RPGlobals:ExecuteCommand("challenge 0")
    return
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
    RPSpeedrun.remainingItemStarts = RPGlobals:TableClone(RPSpeedrun.itemStarts)
    RPSpeedrun.selectedItemStarts = {}
  end

  -- Do actions based on the specific challenge
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") then
    RPSpeedrun:StartR9S1()
  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
    RPSpeedrun:StartR14S1()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") then
    RPSpeedrun:StartR7S2()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") then
    RPSpeedrun:StartR7S3()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") then
    RPSpeedrun:StartR7S4()
  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 5 Beta)") then
    RPSpeedrun:StartR7S5()
  elseif RPSpeedrun.inSeededSpeedrun then
    RPSpeedrun:StartR7SS()
  end

  -- The first character of the speedrun always gets More Options to speed up the process of getting a run going
  -- (but Season 4 and Seeded never get it, since there is no resetting involved)
  if RPSpeedrun.charNum == 1 and
     (challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 4)") and
      challenge ~= Isaac.GetChallengeIdByName(RPSpeedrun.R7SeededName)) then

    player:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
    player:RemoveCostume(itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS))
    -- We don't want the costume to show
    Isaac.DebugString("Removing collectible 414 (More Options)")
    -- We don't need to show this on the item tracker to reduce clutter
    RPGlobals.run.removeMoreOptions = true
    -- More Options will be removed upon entering the first Treasure Room
  end
end

function RPSpeedrun:StartR9S1()
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

function RPSpeedrun:StartR14S1()
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

function RPSpeedrun:StartR7S2()
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

function RPSpeedrun:StartR7S3()
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

function RPSpeedrun:StartR7S4()
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

function RPSpeedrun:StartR7S5()
  -- Local variables
  local game = Game()
  local itemPool = game:GetItemPool()
  local seeds = game:GetSeeds()
  local player = game:GetPlayer(0)

  Isaac.DebugString("In the R+7 (Season 5) challenge.")

  -- Everyone starts with the Schoolbag in this season
  player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)

  -- On the second character and beyond, a start will be randomly assigned
  if RPSpeedrun.charNum >= 2 then
    -- As a safety measure, check to see if the "selectedItemStarts" table has a value in it for the first character
    -- (it should contain one item, equal to the item that was started on the first character)
    if #RPSpeedrun.selectedItemStarts < 1 then
      -- Just assume that they started the Sad Onion
      RPSpeedrun.selectedItemStarts[1] = CollectibleType.COLLECTIBLE_SAD_ONION -- 1
      Isaac.DebugString("Error: No starting item was recorded for the first character.")
    end

    -- Check to see if a start is already assigned for this character number
    -- (dying and resetting should not reassign the selected starting item)
    local startingItem = RPSpeedrun.selectedItemStarts[RPSpeedrun.charNum]
    if startingItem == nil then
      -- Check to see if the player has played a run with one of the big 4
      local big4remaining = 0
      for i = 1, #RPSpeedrun.big4 do
        for j = 1, #RPSpeedrun.remainingItemStarts do
          if RPSpeedrun.remainingItemStarts[j] == RPSpeedrun.big4[i] then
            big4remaining = big4remaining + 1
            break
          end
        end
      end
      local alreadyStartedBig4 = true
      if big4remaining == 4 then
        alreadyStartedBig4 = false
      end

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
end

function RPSpeedrun:StartR7SS()
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

  -- We also need to initialize the seeded trinket pool with 100 trinkets
  -- (trinkets are bugged with this method of manually setting the seed without restarting the game)
  -- (if they get more than 100 trinkets in the run, then they will no longer be seeded,
  -- but that would probably never happen)
  local seed = seeds:GetStartSeed()
  for i = 1, 100 do
    local trinket
    while true do
      -- Get a new random trinket
      seed = RPGlobals:IncrementRNG(seed)
      math.randomseed(seed)
      trinket = math.random(1, TrinketType.NUM_TRINKETS - 1)

      -- Check to see if we have this one already
      local found = false
      for j = 1, #RPSpeedrun.trinketPool do
        if RPSpeedrun.trinketPool[j] == trinket then
          found = true
          break
        end
      end
      if found == false then
        break
      end
    end

    -- Add it to the pool
    RPSpeedrun.trinketPool[i] = trinket
  end
end

-- Called from the the PostUpdate callback
function RPSpeedrun:StartTimer()
  if RPSpeedrun:InSpeedrun() == false then
    return
  end

  -- We want to start the timer on the first game frame
  -- (as opposed to when the screen is fading in)
  -- Thus, we must check for this on every frame
  -- This is to keep the timing consistent with historical timing of speedruns
  if RPSpeedrun.startedTime == 0 then
    RPSpeedrun.startedTime = Isaac.GetTime()
    RPSpeedrun.startedFrame = Isaac.GetFrameCount()
  end
end

-- Called from the PostUpdate callback (RPCheckEntities:NonGrid)
function RPSpeedrun:CheckpointTouched()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local isaacFrameCount = Isaac.GetFrameCount()

  if RPSpeedrun.spawnedCheckpoint then
    RPSpeedrun.spawnedCheckpoint = false
  else
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

-- Called from the PostUpdate callback
function RPSpeedrun:CheckRemoveIncubus()
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  -- In R+7 Season 4, we want to remove the Lilith's extra Incubus if they attempt to switch characters
  if RPGlobals.run.extraIncubus and
     character ~= PlayerType.PLAYER_LILITH then -- 13

    RPGlobals.run.extraIncubus = false
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_INCUBUS) -- 360
    Isaac.DebugString("Removed the extra Incubus (for R+7 Season 4).")
  end
end

-- Called from the PostRender callback
function RPSpeedrun:CheckRestart()
  -- Local variables
  local game = Game()
  local isaacFrameCount = Isaac.GetFrameCount()

  -- We grabbed the checkpoint, so fade out the screen before we reset
  if RPSpeedrun.fadeFrame ~= 0 and isaacFrameCount >= RPSpeedrun.fadeFrame then
    RPSpeedrun.fadeFrame = 0
    game:Fadeout(0.0275, RPGlobals.FadeoutTarget.FADEOUT_RESTART_RUN) -- 3
    RPSpeedrun.resetFrame = isaacFrameCount + 70 -- 72 restarts as the current character, and we want a frame of leeway
    -- (this is necessary because we don't want the player to be able to reset to skip having to watch the fade out)
    return
  end

  -- The screen is now black, so move us to the next character for the speedrun
  if RPSpeedrun.resetFrame ~= 0 and isaacFrameCount >= RPSpeedrun.resetFrame then
    RPSpeedrun.resetFrame = 0
    RPSpeedrun.fastReset = true -- Set this so that we don't go back to the beginning again
    RPSpeedrun.charNum = RPSpeedrun.charNum + 1
    RPGlobals.run.restart = true

    Isaac.DebugString("Switching to the next character for the speedrun.")
    return
  end
end

-- Called from the PostUpdate callback (RPCheckEntities:NonGrid)
function RPSpeedrun:Finish()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local sfx = SFXManager()

  -- Give them the Checkpoint custom item
  -- (this is used by the AutoSplitter to know when to split)
  player:AddCollectible(CollectibleType.COLLECTIBLE_CHECKPOINT, 0, false)

  -- Finish the speedrun
  RPSpeedrun.finished = true
  RPSpeedrun.finishedTime = Isaac.GetTime() - RPSpeedrun.startedTime
  RPSpeedrun.finishedFrames = Isaac.GetFrameCount() - RPSpeedrun.startedFrame
  RPGlobals.run.endOfRunText = true -- Show the run summary

  -- This will be in milliseconds, so we divide by 1000
  local elapsedTime = (Isaac.GetTime() - RPSpeedrun.finishTimeCharacter) / 1000
  RPSpeedrun.averageTime = ((RPSpeedrun.charNum - 1) * RPSpeedrun.averageTime + elapsedTime) / RPSpeedrun.charNum

  -- Play a sound effect
  sfx:Play(SoundEffect.SOUND_SPEEDRUN_FINISH, 1.5, 0, false, 1) -- ID, Volume, FrameDelay, Loop, Pitch

  -- Fireworks will play on the next frame (from the PostUpdate callback)
end

function RPSpeedrun:PostNewRoom()
  if RPSpeedrun:InSpeedrun() == false then
    return
  end

  RPSpeedrun:PostNewRoomWomb2Error()
  RPSpeedrun:PostNewRoomReplaceBosses()
  RPSpeedrun:PostNewRoomCheckCurseRoom()
  RPSpeedrun:PostNewRoomCheckSacrificeRoom()
end

-- Fix the bug where the "correct" exit always appears in the I AM ERROR room in custom challenges (1/2)
function RPSpeedrun:PostNewRoomWomb2Error()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
  local gridSize = room:GetGridSize()

  if stage ~= LevelStage.STAGE4_2 then -- 8
    return
  end

  if roomType ~= RoomType.ROOM_ERROR then -- 3
    return
  end

  -- Find out whether we should spawn a passage up or down, depending on the room seed
  math.randomseed(roomSeed)
  local direction = math.random(1, 2)
  if direction == 1 then
    Isaac.DebugString("Randomly decided that the I AM ERROR room direction should be up.")
  elseif direction == 2 then
    Isaac.DebugString("Randomly decided that the I AM ERROR room direction should be down.")
  end

  -- Find any existing trapdoors
  local pos
  for i = 1, gridSize do
    local gridEntity = room:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState()
      if saveState.Type == GridEntityType.GRID_TRAPDOOR then -- 17
        if direction == 1 then
          -- We need to remove it since we are going up
          pos = gridEntity.Position
          room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work

          -- Spawn a Heaven Door (1000.39) (it will get replaced with the fast-travel version on this frame)
          game:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, pos, Vector(0, 0), nil, 0, 0)
          Isaac.DebugString("Replaced a trapdoor with a beam of light.")
          return
        elseif direction == 2 then
          -- If we are going down and there is already a trapdoor, we don't need to do anything
          return
        end
      end
    end
  end

  -- Find any existing beams of light
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_EFFECT and -- 1000
       entity.Variant == EffectVariant.HEAVEN_LIGHT_DOOR then -- 39

      if direction == 1 then
        -- If we are going up and there is already a beam of light, we don't need to do anything
        return
      elseif direction == 2 then
        -- We need to remove it since we are going down
        pos = entity.Position
        entity:Remove()

        -- Spawn a trapdoor (it will get replaced with the fast-travel version on this frame)
        Isaac.GridSpawn(GridEntityType.GRID_TRAPDOOR, 0, pos, true) -- 17
        Isaac.DebugString("Replaced a beam of light with a trapdoor.")
        return
      end
    end
  end
end

-- In R+7 Season 3, replace the two final bosses
function RPSpeedrun:PostNewRoomReplaceBosses()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomClear = room:IsClear()
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 3)") then
    return
  end

  if stage ~= 10 and
     stage ~= 11 then

    return
  end

  if roomType ~= RoomType.ROOM_BOSS then -- 5
    return
  end

  if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
    return
  end

  if roomClear then
    return
  end

  -- Don't do anything if we have somehow gone the wrong direction
  -- (via We Need to Go Deeper!, Undefined, etc.)
  local direction = RPSpeedrun.charNum % 2 -- 1 is up, 2 is down
  if direction == 0 then
    direction = 2
  end
  if stageType == 1 and -- Cathedral or The Chest
     direction == 2 then

    return
  end
  if stageType == 0 and -- Sheol or Dark Room
     direction == 1 then

    return
  end

  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if stageType == 1 and -- Cathedral
       entity.Type == EntityType.ENTITY_ISAAC then -- 273

      entity:Remove()

    elseif stageType == 0 and -- Sheol
           entity.Type == EntityType.ENTITY_SATAN then -- 84

        entity:Remove()

    elseif stageType == 1 and -- The Chest
           entity.Type == EntityType.ENTITY_ISAAC then -- 102

        entity:Remove()

      elseif stageType == 0 and -- Dark Room
             entity.Type == EntityType.ENTITY_THE_LAMB  then -- 273

        entity:Remove()
      end
    end

    -- Spawn the replacement boss
    if stage == 10 then
      Isaac.Spawn(838, 0, 0, room:GetCenterPos(), Vector(0, 0), nil)
      Isaac.DebugString("Spawned Jr. Fetus (for season 3).")
    elseif stage == 11 then
      Isaac.Spawn(777, 0, 0, room:GetCenterPos(), Vector(0, 0), nil)
      Isaac.DebugString("Spawned Mahalath (for season 3).")
    end
end

-- In R+7 Season 4, prevent people from resetting for a Curse Room
function RPSpeedrun:PostNewRoomCheckCurseRoom()
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local challenge = Isaac.GetChallenge()
  local player = game:GetPlayer(0)

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 4)") or
     stage ~= 1 or
     roomType ~= RoomType.ROOM_CURSE or -- 10
     room:IsFirstVisit() == false then

    return
  end

  -- Check to see if there are any pickups in the room
  local pickups = false
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_PICKUP or -- 5
       entity.Type == EntityType.ENTITY_SLOT then -- 6

      pickups = true
      break
    end
  end
  if pickups == false then
    return
  end

  player:AnimateSad()
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_PICKUP or -- 5
       entity.Type == EntityType.ENTITY_SLOT then -- 6

      entity:Remove()
    end
  end
  Isaac.DebugString("Deleted all of the pickups in a Curse Room (during a R+7 Season 4 run).")
end

-- In R+7 Season 4, prevent people from resetting for a Sacrifice Room
function RPSpeedrun:PostNewRoomCheckSacrificeRoom()
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local gridSize = room:GetGridSize()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local challenge = Isaac.GetChallenge()
  local player = game:GetPlayer(0)

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 4)") or
     stage ~= 1 or
     roomType ~= RoomType.ROOM_SACRIFICE then -- 13

    return
  end

  if room:IsFirstVisit() then
    -- On the first visit to a Sacrifice Room, give a sign to the player that the spikes were intentionally deleted
    -- Note that the spikes need to be deleted every time we enter the room, as they will respawn once the player leaves
    player:AnimateSad()
  end
  for i = 1, gridSize do
    local gridEntity = room:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState()
      if saveState.Type == GridEntityType.GRID_SPIKES then -- 8
        room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
      end

    end
  end
  Isaac.DebugString("Deleted the spikes in a Sacrifice Room (during a R+7 Season 4 run).")
end

-- Don't move to the first character of the speedrun if we die
function RPSpeedrun:PostGameEnd(gameOver)
  if gameOver == false then
    return
  end

  if RPSpeedrun:InSpeedrun() == false then
    return
  end

  RPSpeedrun.fastReset = true
  Isaac.DebugString("Game over detected.")
end

-- Called from the "RPPostRender:Main()" function
function RPSpeedrun:DisplayCharProgress()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  -- Don't show the progress if we are not in the custom challenge
  if RPSpeedrun:InSpeedrun() == false then
    return
  end

  -- Local variables
  local game = Game()
  local seeds = game:GetSeeds()

  if seeds:HasSeedEffect(SeedEffect.SEED_NO_HUD) then --- 10
    return
  end

  -- Don't show the progress if the player has not set an order yet
  if RPSpeedrun:CheckValidCharOrder() == false then
    -- Load the sprites
    if RPSpeedrun.sprites.needToSet1 == nil then
      RPSpeedrun.sprites.needToSet1 = Sprite()
      RPSpeedrun.sprites.needToSet1:Load("gfx/speedrun/need-to-set1.anm2", true)
      RPSpeedrun.sprites.needToSet1:SetFrame("Default", 0)
      RPSpeedrun.sprites.needToSet2 = Sprite()
      RPSpeedrun.sprites.needToSet2:Load("gfx/speedrun/need-to-set2.anm2", true)
      RPSpeedrun.sprites.needToSet2:SetFrame("Default", 0)
      RPSpeedrun.sprites.needToSet3 = Sprite()
      RPSpeedrun.sprites.needToSet3:Load("gfx/speedrun/need-to-set3.anm2", true)
      RPSpeedrun.sprites.needToSet3:SetFrame("Default", 0)
    end

    -- Display the sprites
    local pos = RPSprites:GetScreenCenterPosition()
    pos.Y = pos.Y - 80
    RPSpeedrun.sprites.needToSet1:RenderLayer(0, pos)
    pos.Y = pos.Y + 30
    RPSpeedrun.sprites.needToSet2:RenderLayer(0, pos)
    pos.Y = pos.Y + 40
    RPSpeedrun.sprites.needToSet3:RenderLayer(0, pos)
    return
  end

  -- Load the sprites for the multi-character speedrun progress
  if RPSpeedrun.sprites.slash == nil then
    RPSpeedrun.sprites.digit = {}
    for i = 1, 4 do
      RPSpeedrun.sprites.digit[i] = Sprite()
      RPSpeedrun.sprites.digit[i]:Load("gfx/timer/timer.anm2", true)
      RPSpeedrun.sprites.digit[i].Scale = Vector(0.9, 0.9)
      -- Make the numbers a bit smaller than the ones used for the timer
      RPSpeedrun.sprites.digit[i]:SetFrame("Default", 0)
    end
    RPSpeedrun.sprites.slash = Sprite()
    RPSpeedrun.sprites.slash:Load("gfx/timer/slash.anm2", true)
    RPSpeedrun.sprites.slash:SetFrame("Default", 0)
  end

  -- Local variables
  local digitLength = 7.25
  local startingX = 23
  local startingY = 79
  local adjustment1 = 0
  local adjustment2 = 0
  if RPSpeedrun.charNum > 9 then
    adjustment1 = digitLength - 2
    adjustment2 = adjustment1 - 1
  end

  -- Display the sprites
  local digit1 = RPSpeedrun.charNum
  local digit2 = -1
  if RPSpeedrun.charNum > 9 then
    digit1 = 1
    digit2 = RPSpeedrun.charNum - 10
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
  RPSpeedrun.sprites.digit[1]:SetFrame("Default", digit1)
  RPSpeedrun.sprites.digit[1]:RenderLayer(0, posDigit1)

  if digit2 ~= -1 then
    local posDigit2 = Vector(startingX + digitLength - 1, startingY)
    RPSpeedrun.sprites.digit[2]:SetFrame("Default", digit2)
    RPSpeedrun.sprites.digit[2]:RenderLayer(0, posDigit2)
  end

  local posSlash = Vector(startingX + digitLength -1 + adjustment1, startingY)
  RPSpeedrun.sprites.slash:RenderLayer(0, posSlash)

  local posDigit3 = Vector(startingX + digitLength + adjustment2 + 5 , startingY)
  RPSpeedrun.sprites.digit[3]:SetFrame("Default", digit3)
  RPSpeedrun.sprites.digit[3]:RenderLayer(0, posDigit3)

  if digit4 ~= -1 then
    local posDigit4 = Vector(startingX + digitLength + adjustment2 + 3 + digitLength, startingY)
    RPSpeedrun.sprites.digit[3]:SetFrame("Default", digit4)
    RPSpeedrun.sprites.digit[3]:RenderLayer(0, posDigit4)
  end
end

function RPSpeedrun:InSpeedrun()
  local challenge = Isaac.GetChallenge()
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") or
     challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 5 Beta)") or
     RPSpeedrun.inSeededSpeedrun or
     challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then

    return true
  else
    return false
  end
end

function RPSpeedrun:CheckValidCharOrder()
  local challenge = Isaac.GetChallenge()

  if RPGlobals.race.charOrder == nil then
    return false
  end
  local charOrderType = RPGlobals.race.charOrder[1]
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") and
     (charOrderType ~= "R9S1" or
      #RPGlobals.race.charOrder ~= 10) then

    return false

  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") and
         (charOrderType ~= "R14S1" or
          #RPGlobals.race.charOrder ~= 15) then

    return false

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") and
         (charOrderType ~= "R7S2" or
          #RPGlobals.race.charOrder ~= 8) then

    return false

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") and
         (charOrderType ~= "R7S3" or
          #RPGlobals.race.charOrder ~= 8) then

    return false

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") and
         (charOrderType ~= "R7S4" or
          #RPGlobals.race.charOrder ~= 15) then -- 7 characters + 7 starting items

    return false

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 5 Beta)") then
    -- There is no character order in season 5
    return true

  elseif RPSpeedrun.inSeededSpeedrun and
         (charOrderType ~= "R7SS" or
          #RPGlobals.race.charOrder ~= 8) then

    return false

  elseif challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") and
         (charOrderType ~= "R15V" or
          #RPGlobals.race.charOrder ~= 16) then

    return false
  end

  return true
end

function RPSpeedrun:GetCurrentChar()
  local challenge = Isaac.GetChallenge()
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 5 Beta)") then
    local randomBabyType = Isaac.GetPlayerTypeByName("Random Baby")
    if randomBabyType == -1 then
      return 0
    end
    return randomBabyType
  end
  return RPGlobals.race.charOrder[RPSpeedrun.charNum + 1]
  -- We add one since the first element is the type of multi-character speedrun
end

function RPSpeedrun:IsOnFinalCharacter()
  local challenge = Isaac.GetChallenge()
  if challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then
    return RPSpeedrun.charNum == 15
  elseif challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") then
    return RPSpeedrun.charNum == 9
  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
    return RPSpeedrun.charNum == 14
  end
  return RPSpeedrun.charNum == 7
end

function RPSpeedrun:GetAverageTimePerCharacter()
  local timeTable = RPGlobals:ConvertTimeToString(RPSpeedrun.averageTime)
  -- e.g. [minute1][minute2]:[second1][second2]
  return tostring(timeTable[2]) .. tostring(timeTable[3]) .. ":" .. tostring(timeTable[4]) .. tostring(timeTable[5])
end

function RPSpeedrun:CheckSeason5Mod()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 5 Beta)") then
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

-- We need to record the starting item on the first character so that we can avoid duplicate starting items later on
function RPSpeedrun:CheckSeason5Start()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 5 Beta)") or
     #RPGlobals.run.passiveItems ~= 1 or
     RPSpeedrun.charNum ~= 1 or
     RPGlobals.run.roomsEntered < 2 then
     -- Babies can start with a starting item, so we want to make sure that we enter at least one room

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
                    " on the first character of a season 5 run.")
end

return RPSpeedrun

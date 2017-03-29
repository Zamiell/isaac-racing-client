local RPPostGameStarted = {}

--
-- Includes
--

local RPGlobals   = require("src/rpglobals")
local RPCallbacks = require("src/rpcallbacks")
local RPSprites   = require("src/rpsprites")
local RPSchoolbag = require("src/rpschoolbag")

--
-- Initialization functions
--

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function RPPostGameStarted:Main(saveState)
  -- We don't need to do anything extra if they quit and continued in the middle of a run
  if saveState then
    return
  end

  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local seed = level:GetDungeonPlacementSeed()
  local curses = level:GetCurses()
  local seeds = game:GetSeeds()
  local sfx = SFXManager()

  Isaac.DebugString("MC_POST_GAME_STARTED")

  -- Stop the sound effect from playing at the beginning of a run for characters with a fully charged active item
  if sfx:IsPlaying(SoundEffect.SOUND_BATTERYCHARGE) then -- 170
    sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE)
  end

  -- Make sure that the "Total Curse Immunity" easter egg is on (the "BLCK CNDL" seed)
  if seeds:HasSeedEffect(SeedEffect.SEED_PREVENT_ALL_CURSES) == false and -- 70
     Isaac.GetChallenge() == 0 then
     -- If we don't check for challenges, this can cause an infinite loop when entering Challenge #1, for example

    seeds:AddSeedEffect(SeedEffect.SEED_PREVENT_ALL_CURSES)
    Isaac.DebugString("Added the \"Total Curse Immunity\" easter egg.")

    -- We only need to restart the game if there is a curse on B1 already
    if curses ~= 0 then
      -- Doing a "restart" here does not work for some reason, so mark to reset on the next frame
      RPGlobals.run.restartFrame = Isaac.GetFrameCount() + 1
      Isaac.DebugString("Restarting because there was a curse on Basement 1.")
      return
    end
  end

  -- Make sure that all other Easter Eggs are disabled
  local validEasterEggs = true
  for i = 0, SeedEffect.NUM_SEEDS do
    if seeds:HasSeedEffect(i) and i ~= SeedEffect.SEED_PREVENT_ALL_CURSES then -- 70
      validEasterEggs = false
      break
    end
  end
  if validEasterEggs == false then
    seeds:ClearSeedEffects()
    seeds:AddSeedEffect(SeedEffect.SEED_PREVENT_ALL_CURSES) -- 70

    -- Doing a "restart" here does not work for some reason, so mark to reset on the next frame
    RPGlobals.run.restartFrame = Isaac.GetFrameCount() + 1
    Isaac.DebugString("Restarting because the Easter eggs were invalid.")
    return
  end

  -- Log the run beginning
  Isaac.DebugString("A new run has begun.")

  -- Reset some global variables that we keep track of per run
  RPGlobals:InitRun()

  -- Reset some race variables that we keep track of per run
  -- (loadOnNextFrame does not need to be reset because it should be already set to false)
  -- (difficulty and challenge are set in the "RPPostGameStarted:Race()" function)
  -- (character is set in the "RPPostGameStarted:Character()" function)
  RPGlobals.raceVars.itemBanList = {}
  RPGlobals.raceVars.trinketBanList = {}
  RPGlobals.raceVars.resetEnabled = true
  -- (started and startedTime are handled independently of runs)
  RPGlobals.raceVars.finished = false
  RPGlobals.raceVars.finishedTime = 0
  RPGlobals.raceVars.fireworks = 0
  RPGlobals.raceVars.removedMoreOptions = false
  RPGlobals.raceVars.placedJailCard = false
  RPGlobals.raceVars.victoryLaps = 0

  -- Reset some RNG counters to the floor RNG of Basement 1
  -- (future drops will be based on the RNG from this initial random value)
  RPGlobals.RNGCounter.InitialSeed = seed
  RPGlobals.RNGCounter.BookOfSin = seed
  RPGlobals.RNGCounter.CrystalBall = seed
  -- Skip resetting Teleport, Undefined, and Telepills, because those are seeded per floor
  RPGlobals.RNGCounter.SackOfPennies = seed
  RPGlobals.RNGCounter.BombBag = seed
  RPGlobals.RNGCounter.JuicySack = seed
  RPGlobals.RNGCounter.MysterySack = seed
  RPGlobals.RNGCounter.LilChest = seed
  RPGlobals.RNGCounter.RuneBag = seed
  RPGlobals.RNGCounter.AcidBaby = seed
  RPGlobals.RNGCounter.SackOfSacks = seed

  -- Reset the sprite table
  -- (this is needed to prevent a bug where the "Race Start" room graphics
  -- will flash on the screen before the room is actually entered)
  RPGlobals.spriteTable = {}

  -- Give us custom racing items, depending on the character (mostly just the D6)
  RPPostGameStarted:Character()

  -- Do more run initialization things specifically pertaining to races
  RPPostGameStarted:Race()

  -- Call PostNewLevel manually (they get naturally called out of order)
  RPCallbacks:PostNewLevel2()
end

-- This is done when a run is started
function RPPostGameStarted:Character()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  -- Mark what character we are on for later
  if character == PlayerType.PLAYER_ISAAC then -- 0
    RPGlobals.raceVars.character = "Isaac"
  elseif character == PlayerType.PLAYER_MAGDALENA then -- 1
    RPGlobals.raceVars.character = "Magdalene"
  elseif character == PlayerType.PLAYER_CAIN then -- 2
    RPGlobals.raceVars.character = "Cain"
  elseif character == PlayerType.PLAYER_JUDAS then -- 3
    RPGlobals.raceVars.character = "Judas"
  elseif character == PlayerType.PLAYER_XXX then -- 4
    RPGlobals.raceVars.character = "Blue Baby"
  elseif character == PlayerType.PLAYER_EVE then -- 5
    RPGlobals.raceVars.character = "Eve"
  elseif character == PlayerType.PLAYER_SAMSON then -- 6
    RPGlobals.raceVars.character = "Samson"
  elseif character == PlayerType.PLAYER_AZAZEL then -- 7
    RPGlobals.raceVars.character = "Azazel"
  elseif character == PlayerType.PLAYER_LAZARUS then -- 8
    RPGlobals.raceVars.character = "Lazarus"
  elseif character == PlayerType.PLAYER_EDEN then  -- 9
    RPGlobals.raceVars.character = "Eden"
  elseif character == PlayerType.PLAYER_THELOST then -- 10
    RPGlobals.raceVars.character = "The Lost"
  elseif character == PlayerType.PLAYER_LILITH then -- 13
    RPGlobals.raceVars.character = "Lilith"
  elseif character == PlayerType.PLAYER_KEEPER then -- 14
    RPGlobals.raceVars.character = "Keeper"
  elseif character == PlayerType.PLAYER_APOLLYON then -- 15
    RPGlobals.raceVars.character = "Apollyon"
  end

  -- Do character-specific actions
  if character == PlayerType.PLAYER_MAGDALENA then -- 1
    -- Add the Soul Jar
    player:AddCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR, 0, false) -- 61

  elseif character == PlayerType.PLAYER_JUDAS then -- 3
    -- Judas needs to be at half of a red heart
    player:AddHearts(-1)

  elseif character == PlayerType.PLAYER_EVE then -- 5
    -- Remove the Razor Blade from the item tracker
    -- (this is given via an achivement and not from the "players.xml file")
    Isaac.DebugString("Removing collectible 126")

    -- Add the D6 (to replace the Razor Blade)
    player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105

  elseif character == PlayerType.PLAYER_AZAZEL then -- 7
    -- Decrease his red hearts
    player:AddHearts(-1)

  elseif character == PlayerType.PLAYER_EDEN then -- 9
    -- Swap the random active item with the D6
    local activeItem = player:GetActiveItem()
    player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105

    -- Find out what the passive item is
    local passiveItem
    for i = 1, CollectibleType.NUM_COLLECTIBLES do
      if player:HasCollectible(i) and
         i ~= activeItem and
         i ~= CollectibleType.COLLECTIBLE_D6 then -- 105

        passiveItem = i
        break
      end
    end

    -- Make the D6 come first on the item tracker
    Isaac.DebugString("Removing collectible " .. activeItem)
    Isaac.DebugString("Removing collectible " .. passiveItem)
    Isaac.DebugString("Adding collectible " .. activeItem)
    Isaac.DebugString("Adding collectible " .. passiveItem)

    -- Update the cache (in case we had an active item that granted stats, like A Pony)
    player:AddCacheFlags(CacheFlag.CACHE_ALL)
    player:EvaluateItems()

    -- Remove the costume, if any (some items give a costume, like A Pony)
    local configItem = RPGlobals:GetConfigItem(activeItem) -- This will crash the game with an item ID of 0
    player:RemoveCostume(configItem)

    -- Eden starts with the Schoolbag by default
    player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
    RPGlobals.run.schoolbag.item = activeItem

    -- Manually fix any custom passive items
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BETRAYAL) then -- 391
      player:RemoveCollectible(CollectibleType.COLLECTIBLE_BETRAYAL) -- 391
      player:AddCollectible(CollectibleType.COLLECTIBLE_BETRAYAL_NOANIM)
    end

    -- Manually fix any custom active items
    if RPGlobals.run.schoolbag.item == CollectibleType.COLLECTIBLE_BOOK_OF_SIN then -- 97
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_BOOK_OF_SIN_SEEDED
    elseif RPGlobals.run.schoolbag.item == CollectibleType.COLLECTIBLE_CRYSTAL_BALL then -- 158
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_CRYSTAL_BALL_SEEDED
    elseif RPGlobals.run.schoolbag.item == CollectibleType.COLLECTIBLE_SMELTER then -- 479
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_SMELTER_LOGGER
    end

  elseif character == PlayerType.PLAYER_LILITH then -- 13
    -- Lilith starts with the Schoolbag by default
    player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
    RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS -- 357

    -- Reorganize the items on the item tracker
    Isaac.DebugString("Removing collectible 357") -- Box of Friends
    Isaac.DebugString("Removing collectible 412") -- Cambion Conception
    Isaac.DebugString("Adding collectible 357") -- Box of Friends
    Isaac.DebugString("Adding collectible 412") -- Cambion Conception

  elseif character == PlayerType.PLAYER_KEEPER then -- 14
    -- Remove the Wooden Nickel from the item tracker
    -- (this is given via an achivement and not from the "players.xml file")
    Isaac.DebugString("Removing collectible 349")

    -- Add the D6 (to replace the Wooden Nickel)
    player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105

    -- Grant an extra coin/heart container
    player:AddCoins(24) -- Keeper starts with 1 coin so we only need to give 24
    player:AddCoins(1) -- This fills in the new heart container
    player:AddCoins(25) -- Add a 2nd container
    player:AddCoins(1) -- This fills in the new heart container

  elseif character == PlayerType.PLAYER_APOLLYON then -- 15
    -- Apollyon starts with the Schoolbag by default
    player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
    RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_VOID -- 477

    -- Reorganize the items on the item tracker
    Isaac.DebugString("Removing collectible 477") -- Void
    Isaac.DebugString("Adding collectible 477") -- Void
  end

  if RPGlobals.run.schoolbag.item ~= 0 then
    -- Make sure that the Schoolbag item is fully charged
    RPGlobals.run.schoolbag.charges = RPGlobals:GetActiveCollectibleMaxCharges(RPGlobals.run.schoolbag.item)
    RPSchoolbag.sprites.item = nil
  end
end

-- This occurs when first going into the game and after a reset occurs mid-race
function RPPostGameStarted:Race()
  -- Do Pageant Boy related initiailization first
  -- (we want to be able to do Pageant Boy runs without using the R+ client)
  if RPGlobals.race.rFormat == "pageant" then
    RPPostGameStarted:Pageant()
  end

  --
  -- Race validation
  --

  -- If we are not in a race, don't do anything special
  if RPGlobals.race.status == "none" then
    Isaac.DebugString("Not in a race.")
    return
  end

  -- Local variables
  local game = Game()
  local seeds = game:GetSeeds()

  -- Validate the difficulty (hard mode / Greed mode) for races
  RPGlobals.raceVars.difficulty = game.Difficulty
  if RPGlobals.raceVars.difficulty ~= 0 then
    Isaac.DebugString("Race error: Wrong mode.")
    return
  end

  -- Validate that we are not on a challenge
  RPGlobals.raceVars.challenge = Isaac.GetChallenge()
  if RPGlobals.raceVars.challenge ~= 0 then
    Isaac.DebugString("Race error: On a challenge.")
    return
  end

  -- Validate the character for races
  if RPGlobals.raceVars.character ~= RPGlobals.race.character then
    Isaac.DebugString("Race error: Wrong character.")
    return
  end

  if RPGlobals.race.rFormat == "seeded" and
     RPGlobals.race.status == "in progress" then

    -- Validate that we are on the intended seed
    if seeds:GetStartSeedString() ~= RPGlobals.race.seed then
      -- Change the seed
      seeds:SetStartSeed(RPGlobals.race.seed)

      -- Let the Racing+ client (and the item tracker) know about the new seed
      Isaac.DebugString("RNG Start Seed: " .. RPGlobals.race.seed .. " ")

      -- We have to reload the first floor for the new seed to take effect
      local stageCommand = "stage 1"
      local newStageType = RPGlobals:DetermineStageType(1)
      if newStageType == 1 then
        stageCommand = stageCommand .. "a"
      elseif newStageType == 2 then
        stageCommand = stageCommand .. "b"
      end
      Isaac.ExecuteCommand(stageCommand)
    end

  else
    -- Validate that we are not on a set seed
    -- (this will be true if we are on a set seed or on a challenge,
    -- but we won't get this far if we are on a challenge)
    if seeds:IsCustomRun() then
      -- If the run started with a set seed, this will change the reset behavior to that of an unseeded run
      seeds:Reset()

      -- Doing a "restart" here does not work for some reason, so mark to reset on the next frame
      RPGlobals.run.restartFrame = Isaac.GetFrameCount() + 1
      Isaac.DebugString("Restarting because we were on a set seed.")
      return
    end
  end

  --
  -- Race validation succeeded
  --

  -- Give extra items depending on the format
  if RPGlobals.race.rFormat == "seeded" then
    RPPostGameStarted:Seeded()

  elseif RPGlobals.race.rFormat == "diversity" then
    -- If the diversity race has not started yet, don't give the items
    if RPGlobals.raceVars.started then
      RPPostGameStarted:Diversity()
    end
  end

  -- Go to the custom "Race Start" room
  if RPGlobals.race.status == "open" then
    Isaac.ExecuteCommand("goto s.boss.9999")
    -- We can't use an existing boss room because after the boss is removed, a pedestal will spawn
    Isaac.DebugString("Going to the race room.")
    -- We do more things in the "PostNewRoom" callback
  end
end

function RPPostGameStarted:Seeded()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  -- Give the player extra starting items (for seeded races)
  local replacedD6 = false
  for i = 1, #RPGlobals.race.startingItems do
    -- The 13 luck is a special case
    local itemID = RPGlobals.race.startingItems[i]
    if itemID == 600 then
      itemID = CollectibleType.COLLECTIBLE_13_LUCK
    end

    -- Give the item; the second argument is charge amount, and the third argument is "AddConsumables"
    player:AddCollectible(itemID, RPGlobals:GetActiveCollectibleMaxCharges(RPGlobals.race.startingItems[i]), true)

    -- Giving the player the item does not actually remove it from any of the pools,
    -- so we have to expliticly add it to the ban list
    RPGlobals:AddItemBanList(RPGlobals.race.startingItems[i])

    -- Find out if Crown of Light is one of the starting items
    if RPGlobals.race.startingItems[i] == 415 then
      -- Remove the 2 soul hearts that it gives
      player:AddSoulHearts(-4)

      -- Re-heal Judas and Azazel back to 1 red heart so that they can properly use the Crown of Light
      -- (this should do nothing on all of the other characters)
      player:AddHearts(1)
      break
    end

    -- Find out if we replaced the D6
    local newActiveItem = player:GetActiveItem()
    if newActiveItem ~= CollectibleType.COLLECTIBLE_D6 then -- 105
      -- We replaced the D6 with an active item, so put the D6 back and put this item in the Schoolbag
      replacedD6 = true
      player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105
      RPGlobals.run.schoolbag.item = newActiveItem
    end
  end

  -- Give the player extra Schoolbag items, depending on the character
  if replacedD6 == false then
    local newSchoolBagItem = 0
    if character == PlayerType.PLAYER_MAGDALENA then -- 1
      newSchoolBagItem = CollectibleType.COLLECTIBLE_YUM_HEART -- 45
      RPGlobals.run.schoolbag.item = newSchoolBagItem

    elseif character == PlayerType.PLAYER_JUDAS then -- 3
      newSchoolBagItem = CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL -- 34
      RPGlobals.run.schoolbag.item = newSchoolBagItem

    elseif character == PlayerType.PLAYER_XXX then -- 4
      newSchoolBagItem = CollectibleType.COLLECTIBLE_POOP -- 36
      RPGlobals.run.schoolbag.item = newSchoolBagItem

    elseif character == PlayerType.PLAYER_EVE then -- 5
      newSchoolBagItem = CollectibleType.COLLECTIBLE_RAZOR_BLADE -- 126
      RPGlobals.run.schoolbag.item = newSchoolBagItem

    elseif character == PlayerType.PLAYER_THELOST then -- 10
      newSchoolBagItem = CollectibleType.COLLECTIBLE_D4 -- 284
      RPGlobals.run.schoolbag.item = newSchoolBagItem
    end

    -- Reorganize the items on the item tracker so that the Schoolbag item comes first
    if newSchoolBagItem ~= 0 then
      Isaac.DebugString("Adding collectible " .. newSchoolBagItem) -- Make it show up on the item tracker
      for i = 1, #RPGlobals.race.startingItems do
        if RPGlobals.race.startingItems[i] == 600 then
          local itemID = tostring(CollectibleType.COLLECTIBLE_13_LUCK)
          Isaac.DebugString("Removing collectible " .. itemID .. " (13 Luck)")
          Isaac.DebugString("Adding collectible " .. itemID .. " (13 Luck)")
        else
          Isaac.DebugString("Removing collectible " .. RPGlobals.race.startingItems[i])
          Isaac.DebugString("Adding collectible " .. RPGlobals.race.startingItems[i])
        end
      end
    end
  end

  -- Enable the Schoolbag
  -- (this has to be after setting the Schoolbag item)
  player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
  if RPGlobals.run.schoolbag.item ~= 0 then
    RPGlobals.run.schoolbag.charges = RPGlobals:GetActiveCollectibleMaxCharges(RPGlobals.run.schoolbag.item)
    RPSchoolbag.sprites.item = nil

    -- Also make sure that the Schoolbag item is removed from all of the pools
    RPGlobals:AddItemBanList(RPGlobals.run.schoolbag.item)
  end

  -- Add item bans for seeded mode
  RPGlobals:AddTrinketBanList(TrinketType.TRINKET_CAINS_EYE) -- 59

  -- Initialize the sprites for the starting room
  -- (don't show these graphics until the race starts)
  if RPGlobals.race.status == "in progress" then
    if #RPGlobals.race.startingItems == 2 then
      RPSprites:Init("seeded-starting-item", "seeded-starting-item")
      RPSprites:Init("seeded-item1", tostring(RPGlobals.race.startingItems[2]))
      -- The first item is The Compass, and we don't need to display that
    elseif #RPGlobals.race.startingItems == 3 then
      RPSprites:Init("seeded-starting-build", "seeded-starting-build")
      RPSprites:Init("seeded-item2", tostring(RPGlobals.race.startingItems[2]))
      RPSprites:Init("seeded-item3", tostring(RPGlobals.race.startingItems[3]))
    elseif #RPGlobals.race.startingItems == 5 then
      -- Only the Mega Blast build has 5 starting items
      RPSprites:Init("seeded-starting-build", "seeded-starting-build")
      RPSprites:Init("seeded-item2", tostring(RPGlobals.race.startingItems[3]))
      RPSprites:Init("seeded-item3", tostring(RPGlobals.race.startingItems[4]))
      RPSprites:Init("seeded-item4", tostring(RPGlobals.race.startingItems[2])) -- This will be to the left of 2
      RPSprites:Init("seeded-item5", tostring(RPGlobals.race.startingItems[5])) -- This will be to the right of 3
    end
  end

  Isaac.DebugString("Added seeded items.")
end

function RPPostGameStarted:Diversity()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local trinket1 = player:GetTrinket(0) -- This will be 0 if there is no trinket

  -- Give the player their five extra starting items
  for i = 1, #RPGlobals.race.startingItems do
    if i == 1 then
      -- Ttem 1 is the active
      player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
      RPGlobals.run.schoolbag.item = RPGlobals.race.startingItems[i]
      if RPGlobals.run.schoolbag.item == CollectibleType.COLLECTIBLE_EDENS_SOUL then -- 490
        RPGlobals.run.schoolbag.charges = 0 -- Eden's Soul should start on an empty charge
      else
        RPGlobals.run.schoolbag.charges = RPGlobals:GetActiveCollectibleMaxCharges(RPGlobals.run.schoolbag.item)
      end
      RPSchoolbag.sprites.item = nil

      -- Giving the player the item does not actually remove it from any of the pools,
      -- so we have to expliticly add it to the ban list
      RPGlobals:AddItemBanList(RPGlobals.race.startingItems[i])

      -- Give them the item so that the player gets any inital pickups (e.g. Remote Detonator)
      player:AddCollectible(RPGlobals.race.startingItems[i], 0, true)

      -- Swap back for the D6
      player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false)

      -- Update the cache (in case we had an active item that granted stats, like A Pony)
      player:AddCacheFlags(CacheFlag.CACHE_ALL)
      player:EvaluateItems()

      -- Remove the costume, if any (some items give a costume, like A Pony)
      local configItem = RPGlobals:GetConfigItem(RPGlobals.race.startingItems[i])
      -- This will crash the game with an item ID of 0
      player:RemoveCostume(configItem)

    elseif i == 2 or i == 3 or i == 4 then
      -- Items 2, 3, and 4 are the passives
      -- Give the item; the second argument is charge amount, and the third argument is "AddConsumables"
      player:AddCollectible(RPGlobals.race.startingItems[i],
                            RPGlobals:GetActiveCollectibleMaxCharges(RPGlobals.race.startingItems[i]), true)

      -- Giving the player the item does not actually remove it from any of the pools,
      -- so we have to expliticly add it to the ban list
      RPGlobals:AddItemBanList(RPGlobals.race.startingItems[i])

    elseif i == 5 then
      -- Item 5 is the trinket
      player:TryRemoveTrinket(trinket1) -- It is safe to feed 0 to this function
      player:AddTrinket(RPGlobals.race.startingItems[i])
      player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER_LOGGER, false, false, false, false)
      -- Use the custom Smelter so that the item tracker knows about the trinket we consumed

      -- Regive Paper Clip to Cain, for example
      if trinket1 ~= 0 then
        player:AddTrinket(trinket1) -- The game crashes if 0 is fed to this function
      end

      -- Giving the player the trinket does not actually remove it from the trinket pool,
      -- so we have to expliticly add it to the ban list
      RPGlobals:AddTrinketBanList(RPGlobals.race.startingItems[i])
    end
  end

  -- Diversity races also start with More Options to reduce resetting
  player:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
  Isaac.DebugString("Removing collectible 414")
  -- We don't need to show this on the item tracker to reduce clutter

  -- Add item bans for diversity races
  RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_MOMS_KNIFE) -- 114
  RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_EPIC_FETUS) -- 168
  RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_TECH_X) -- 395
  RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_D4) -- 284
  RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_D100) -- 283
  RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_DINF) -- 489

  -- Initialize the sprites for the starting room
  RPSprites:Init("diversity-active", "diversity-active")
  RPSprites:Init("diversity-passives", "diversity-passives")
  RPSprites:Init("diversity-trinket", "diversity-trinket")
  RPSprites:Init("diversity-item1", tostring(RPGlobals.race.startingItems[1]))
  RPSprites:Init("diversity-item2", tostring(RPGlobals.race.startingItems[2]))
  RPSprites:Init("diversity-item3", tostring(RPGlobals.race.startingItems[3]))
  RPSprites:Init("diversity-item4", tostring(RPGlobals.race.startingItems[4]))
  RPSprites:Init("diversity-item5", tostring(RPGlobals.race.startingItems[5]))

  Isaac.DebugString("Added diversity items.")
end

function RPPostGameStarted:Pageant()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- Add the extra items
  player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
  RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_D6 -- 105
  RPGlobals.run.schoolbag.charges = 6
  RPSchoolbag.sprites.item = nil
  player:AddCollectible(CollectibleType.COLLECTIBLE_MAXS_HEAD, 0, false) -- 4
  player:AddCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS, 0, false) -- 246
  player:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
  player:AddCollectible(CollectibleType.COLLECTIBLE_BELLY_BUTTON, 0, false) -- 458
  -- The extra luck is handled in the EvaluateCache callback

  -- Giving the player these items does not actually remove them from any pools,
  -- so we have to expliticly add them to the ban list
  RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_MAXS_HEAD) -- 4
  RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_THERES_OPTIONS) -- 246
  RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_MORE_OPTIONS) -- 414
  RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_BELLY_BUTTON) -- 458

  Isaac.DebugString("Added pageant items.")
end

return RPPostGameStarted

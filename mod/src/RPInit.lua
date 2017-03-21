local RPInit = {}

--
-- Includes
--

local RPGlobals   = require("src/rpglobals")
local RPSprites   = require("src/rpsprites")
local RPSchoolbag = require("src/rpschoolbag")

--
-- Initialization functions
--

-- Called when starting a new run
-- (from the PostRender callback)
function RPInit:Run()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local seed = level:GetDungeonPlacementSeed()

  -- Log the run beginning
  Isaac.DebugString("A new run has begun.")

  -- Reset some global variables that we keep track of per run
  RPGlobals:InitRun()

  -- Reset some race variables that we keep track of per run
  -- loadOnNextFrame does not need to be reset because it should be already set to false and
  -- we should have already read the "save.dat" file before getting here
  -- blckCndlOn, difficulty, and character are checked in the "RPCallbacks:PostPlayerInit()" function
  RPGlobals.raceVars.freshRun = true
  RPGlobals.raceVars.itemBanList = {}
  RPGlobals.raceVars.trinketBanList = {}
  RPGlobals.raceVars.resetEnabled = true
  -- started and startedTime are handled independently of runs
  RPGlobals.raceVars.startedWarp = false
  RPGlobals.raceVars.finished = false
  RPGlobals.raceVars.finishedTime = 0
  RPGlobals.raceVars.fireworks = 0
  RPGlobals.raceVars.removedMoreOptions = false
  RPGlobals.raceVars.placedJailCard = false
  RPGlobals.raceVars.victoryLaps = 0

  -- Reset some RNG counters to the floor RNG of B1 for this seed
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

  -- Give us custom racing items, depending on the character (mostly just the D6)
  RPInit:Character()

  -- Do more run initialization things specifically pertaining to races
  RPInit:Race()
end

-- This is done when a run is started
function RPInit:Character()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

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
    player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, true) -- 105

    -- Find out what the passive item is
    local passiveItem
    for i = 1, 510 do
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
function RPInit:Race()
  -- Local variables
  local game = Game()

  -- Do Pageant Boy related initiailization first
  -- (we want to be able to do Pageant Boy runs without using the R+ client)
  if RPGlobals.race.rFormat == "pageant" then
    RPInit:Pageant()
  end

  --
  -- Race validation
  --

  -- If we are not in a race, don't do anything special
  if RPGlobals.race.status == "none" then
    Isaac.DebugString("Not in a race.")
    return
  end

  -- Validate BLCK CNDL for races
  if RPGlobals.raceVars.blckCndlOn == false then
    Isaac.DebugString("Race error: BLCK CNDL not enabled.")
    return
  end

  -- Validate difficulty (hard mode) for races
  if RPGlobals.raceVars.difficulty ~= 0 then
    Isaac.DebugString("Race error: On the wrong difficulty (hard mode or Greed mode).")
    return
  end

  -- Validate character for races
  if RPGlobals.raceVars.character ~= RPGlobals.race.character then
    Isaac.DebugString("Race error: On the wrong character.")
    return
  end

  -- Validate that we are on the right seed for the race
  -- (if this is an unseeded race, the seed with be "-")
  if RPGlobals.race.seed ~= "-" and RPGlobals.race.seed ~= RPGlobals.race.currentSeed then
    Isaac.DebugString("Race error: On the wrong seed.")
    return
  end

  --
  -- Race validation succeeded
  --

  if RPGlobals.race.status == "in progress" then
    if RPGlobals.raceVars.started == false then
      -- The race has already started (we are late, or restarted the game in the middle of the run)
      RPInit:RaceStart()
    end

    -- Set that we don't have to do the starting warp
    RPGlobals.raceVars.startedWarp = true
  else
    -- Spawn two Gaping Maws (235.0)
    game:Spawn(EntityType.ENTITY_GAPING_MAW, 0, Vector(280, 360), Vector(0,0), nil, 0, 0)
    game:Spawn(EntityType.ENTITY_GAPING_MAW, 0, Vector(360, 360), Vector(0,0), nil, 0, 0)
    Isaac.DebugString("Spawned 2 Gaping Maws.")
  end

  if RPGlobals.race.rFormat == "seeded" then
    RPInit:Seeded()

  elseif RPGlobals.race.rFormat == "diversity" then
    -- Give the player extra starting items (for diversity races)
    -- (this is not in the "RPInit:RaceStart()" function because we want the pickup animations
    -- to play for items like Latch Key)
    if RPGlobals.raceVars.started then -- If the diversity race has not started yet, don't give the items
      RPInit:Diversity()
    end
  end
end

function RPInit:Seeded()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  -- Give the player extra starting items (for seeded races)
  local replacedD6 = false
  for i = 1, #RPGlobals.race.startingItems do
    -- Give the item; the second argument is charge amount, and the third argument is "AddConsumables"
    player:AddCollectible(RPGlobals.race.startingItems[i],
                          RPGlobals:GetActiveCollectibleMaxCharges(RPGlobals.race.startingItems[i]), true)

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
          Isaac.DebugString("Removing collectible " .. RPGlobals.race.startingItems[i])
          Isaac.DebugString("Adding collectible " .. RPGlobals.race.startingItems[i])
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
  -- (this will only show if we are resetting in the middle of the race,
  -- otherwise they will only show once the race has begun)
  RPInit:SeededSprites()

  Isaac.DebugString("Added seeded items.")
end

function RPInit:SeededSprites()
  -- Initialize the sprites for the starting room
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

function RPInit:Diversity()
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

function RPInit:Pageant()
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
  -- The +14 luck is handled in the EvaluateCache callback

  -- Giving the player these items does not actually remove them from any pools,
  -- so we have to expliticly add them to the ban list
  RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_MAXS_HEAD) -- 4
  RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_THERES_OPTIONS) -- 246
  RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_MORE_OPTIONS) -- 414
  RPGlobals:AddItemBanList(CollectibleType.COLLECTIBLE_BELLY_BUTTON) -- 458

  Isaac.DebugString("Added pageant items.")
end

-- Only do these actions once per race
function RPInit:RaceStart()
  Isaac.DebugString("Starting the race! (" .. tostring(RPGlobals.race.rFormat) .. ")")
  RPGlobals.raceVars.started = true

  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- Re-enable holding R to reset
  RPGlobals.raceVars.resetEnabled = true

  -- Reset the Dead Eye multiplier
  for i = 1, 100 do
    -- This function is analogous to missing a shot,
    -- so let's miss 100 shots to be sure that the multiplier is actually cleared
    player:ClearDeadEyeCharge()
  end

  -- Load the clock sprite for the timer
  if RPGlobals.raceVars.startedTime ~= 0 then
    RPSprites:Init("clock", "clock")
  end

  -- Now that the "RPGlobals.raceVars.started" variable is set to true,
  -- a warp will happen on the next game frame (PostUpdate) to delete the Gaping Maws
  -- and give diversity items if necessary
end

return RPInit

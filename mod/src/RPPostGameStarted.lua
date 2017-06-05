local RPPostGameStarted = {}

--
-- Includes
--

local RPGlobals    = require("src/rpglobals")
local RPCallbacks  = require("src/rpcallbacks")
local RPSprites    = require("src/rpsprites")
local RPSchoolbag  = require("src/rpschoolbag")
local RPSoulJar    = require("src/rpsouljar")
local RPFastClear  = require("src/rpfastclear")
local RPFastTravel = require("src/rpfasttravel")
local RPSpeedrun   = require("src/rpspeedrun")
local RPTimer      = require("src/rptimer")

--
-- Variables
--

RPPostGameStarted.diversity = false

--
-- Initialization functions
--

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function RPPostGameStarted:Main(saveState)
  -- Local variables
  local game = Game()
  local itemPool = game:GetItemPool()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local levelSeed = level:GetDungeonPlacementSeed()
  local curses = level:GetCurses()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local seeds = game:GetSeeds()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()
  local isaacFrameCount = Isaac.GetFrameCount()
  local sfx = SFXManager()

  Isaac.DebugString("MC_POST_GAME_STARTED")

  if saveState then
    -- Fix the bug where the mod won't know what floor they are on if they exit the game and continue
    RPGlobals.run.currentFloor = stage
    Isaac.DebugString("New floor: " .. tostring(RPGlobals.run.currentFloor) .. " (from S+Q)")

    -- Fix the bug where the Gaping Maws will not respawn in the "Race Room"
    if roomIndex == GridRooms.ROOM_DEBUG_IDX and -- -3
       (RPGlobals.race.status == "open" or RPGlobals.race.status == "starting") then

      -- Spawn two Gaping Maws (235.0)
      game:Spawn(EntityType.ENTITY_GAPING_MAW, 0, RPGlobals:GridToPos(5, 5), Vector(0, 0), nil, 0, 0)
      game:Spawn(EntityType.ENTITY_GAPING_MAW, 0, RPGlobals:GridToPos(7, 5), Vector(0, 0), nil, 0, 0)
      Isaac.DebugString("Respawned 2 Gaping Maws.")
    end

    -- We don't need to do the long series of checks if they quit and continued in the middle of a run
    return
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
      RPGlobals.run.restartFrame = isaacFrameCount + 1
      Isaac.DebugString("Restarting because there was a curse on Basement 1.")
      return
    end
  end

  -- Make sure that all other Easter Eggs are disabled
  local validEasterEggs = true
  for i = 0, SeedEffect.NUM_SEEDS do
    if seeds:HasSeedEffect(i) and
       i ~= SeedEffect.SEED_PREVENT_ALL_CURSES and -- 70
       i ~= SeedEffect.SEED_ALL_CHAMPIONS then -- 13
       -- (make an exception for seeds that have no beneficial effect and are used for testing purposes)

      validEasterEggs = false
      break
    end
  end
  if validEasterEggs == false then
    seeds:ClearSeedEffects()
    seeds:AddSeedEffect(SeedEffect.SEED_PREVENT_ALL_CURSES) -- 70

    -- Doing a "restart" here does not work for some reason, so mark to reset on the next frame
    RPGlobals.run.restartFrame = isaacFrameCount + 1
    Isaac.DebugString("Restarting because the Easter eggs were invalid.")
    return
  end

  -- Log the run beginning
  Isaac.DebugString("A new run has begun.")

  -- Reset some global variables that we keep track of per run
  RPGlobals:InitRun()
  RPFastClear.checkedFrame = 0

  -- Reset some race variables that we keep track of per run
  -- (loadOnNextFrame does not need to be reset because it should be already set to false)
  -- (difficulty and challenge are set in the "RPPostGameStarted:Race()" function)
  -- (character is set in the "RPPostGameStarted:Character()" function)
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
  RPGlobals.RNGCounter.BookOfSin = levelSeed
  -- Skip resetting Teleport, Undefined, and Telepills, because those are seeded per floor

  -- Reset some RNG counters for familiars
  RPFastClear:InitRun()

  -- Reset all graphics
  -- (this is needed to prevent a bug where the "Race Start" room graphics
  -- will flash on the screen before the room is actually entered)
  -- (it also prevents the bug where if you reset during the stage animation, it will permanently stay on the screen)
  RPSprites.sprites = {}
  RPFastTravel.sprites = {}
  RPSchoolbag.sprites = {}
  RPSoulJar.sprites = {}
  RPSpeedrun.sprites = {}
  RPTimer.sprites = {}

  -- Keep track of whether this is a diversity race or not
  RPPostGameStarted.diversity = false

  -- Racing+ replaces some vanilla items; remove them from all the pools
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_SIN) -- 97
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BETRAYAL) -- 391
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SMELTER) -- 497

  -- Give us custom racing items, depending on the character (mostly just the D6)
  RPPostGameStarted:Character()

  -- Do more run initialization things specifically pertaining to speedruns
  RPSpeedrun:Init()

  -- Do more run initialization things specifically pertaining to races
  RPPostGameStarted:Race()

  -- Remove the 3 placeholder items if this is not a diversity race
  if RPPostGameStarted.diversity == false then
    itemPool:RemoveCollectible(Isaac.GetItemIdByName("Diversity Placeholder #1"))
    itemPool:RemoveCollectible(Isaac.GetItemIdByName("Diversity Placeholder #2"))
    itemPool:RemoveCollectible(Isaac.GetItemIdByName("Diversity Placeholder #3"))
  end

  -- Call PostNewLevel manually (they get naturally called out of order)
  RPCallbacks:PostNewLevel2()

  -- Silence the recharge noise for Lilith
  -- (this is normally done in the PostPlayerInit callback, but we need to handle it here for Lilith to avoid a crash)
  if character == PlayerType.PLAYER_LILITH and -- 13
     sfx:IsPlaying(SoundEffect.SOUND_BATTERYCHARGE) then

    sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE)
  end
end

-- This is done when a run is started
function RPPostGameStarted:Character()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  -- Do character-specific actions
  if character == PlayerType.PLAYER_JUDAS then -- 3
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
      passiveItem = CollectibleType.COLLECTIBLE_BETRAYAL_NOANIM
    end

    -- Manually fix any custom active items
    if RPGlobals.run.schoolbag.item == CollectibleType.COLLECTIBLE_BOOK_OF_SIN then -- 97
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_BOOK_OF_SIN_SEEDED
    elseif RPGlobals.run.schoolbag.item == CollectibleType.COLLECTIBLE_SMELTER then -- 479
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_SMELTER_LOGGER
    end

    -- Make sure that the Schoolbag item is fully charged
    RPGlobals.run.schoolbag.charges = RPGlobals:GetItemMaxCharges(RPGlobals.run.schoolbag.item)
    RPSchoolbag.sprites.item = nil

    -- Reorganize the items on the item tracker
    Isaac.DebugString("Removing collectible " .. activeItem)
    Isaac.DebugString("Removing collectible " .. passiveItem)
    Isaac.DebugString("Adding collectible " .. activeItem)
    Isaac.DebugString("Adding collectible " .. passiveItem)

  elseif character == PlayerType.PLAYER_KEEPER then -- 14
    -- Remove the Wooden Nickel from the item tracker
    -- (this is given via an achivement and not from the "players.xml file")
    Isaac.DebugString("Removing collectible 349")

    -- Add the D6 (to replace the Wooden Nickel)
    player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105

  elseif character == 16 then -- Samael
    -- Give him the Schoolbag with the Wraith Skull
    player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
    RPGlobals.run.schoolbag.item = Isaac.GetItemIdByName("Wraith Skull")
    RPSchoolbag.sprites.item = nil
    Isaac.DebugString("Adding collectible " .. tostring(Isaac.GetItemIdByName("Wraith Skull")) .. " (Wraith Skull)")

    -- Decrease his red hearts
    player:AddHearts(-1)

  end
end

-- This occurs when first going into the game and after a reset occurs mid-race
function RPPostGameStarted:Race()
  -- Do special ruleset related initiailization first
  -- (we want to be able to do runs of them without using the R+ client)
  if RPGlobals.race.rFormat == "pageant" then
    RPPostGameStarted:Pageant()
  elseif RPGlobals.race.rFormat == "beginner" then
    RPPostGameStarted:Beginner()
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
  local isaacFrameCount = Isaac.GetFrameCount()

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

  if RPGlobals.race.rFormat == "seeded" and
     RPGlobals.race.status == "in progress" then

    -- Validate that we are on the intended seed
    if seeds:GetStartSeedString() ~= RPGlobals.race.seed then
      -- Doing a "seed #### ####" here does not work for some reason, so mark to reset on the next frame
      RPGlobals.run.restartFrame = isaacFrameCount + 1
      Isaac.DebugString("Restarting because we were not on the right seed.")
      return
    end

  else
    -- Validate that we are not on a set seed
    -- (this will be true if we are on a set seed or on a challenge,
    -- but we won't get this far if we are on a challenge)
    if seeds:IsCustomRun() then
      -- If the run started with a set seed, this will change the reset behavior to that of an unseeded run
      seeds:Reset()

      -- Doing a "restart" here does not work for some reason, so mark to reset on the next frame
      RPGlobals.run.restartFrame = isaacFrameCount + 1
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

  elseif RPGlobals.race.rFormat == "seededMO" then
    RPPostGameStarted:SeededMO()
  end

  -- Go to the custom "Race Start" room
  if RPGlobals.race.status == "open" or RPGlobals.race.status == "starting" then
    Isaac.ExecuteCommand("goto s.boss.9999")
    -- We can't use an existing boss room because after the boss is removed, a pedestal will spawn
    Isaac.DebugString("Going to the race room.")
    -- We do more things in the "PostNewRoom" callback
  end
end

function RPPostGameStarted:Seeded()
  -- Local variables
  local game = Game()
  local itemPool = game:GetItemPool()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  -- Give the player extra starting items (for seeded races)
  player:AddCollectible(CollectibleType.COLLECTIBLE_COMPASS, 0, false) -- 21
  player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)

  -- Give the player the "Instant Start" item(s)
  local replacedD6 = false
  for i = 1, #RPGlobals.race.startingItems do
    local itemID = RPGlobals.race.startingItems[i]
    if itemID == 600 then
      -- The 13 luck is a special case
      player:AddCollectible(CollectibleType.COLLECTIBLE_13_LUCK, 0, false)
    else
      -- Give the item; the second argument is charge amount, and the third argument is "AddConsumables"
      player:AddCollectible(itemID, RPGlobals:GetItemMaxCharges(itemID), true)

      -- Remove it from all the pools
      itemPool:RemoveCollectible(itemID)

      -- Find out if Crown of Light is one of the starting items
      if itemID == 415 then
        -- Remove the 2 soul hearts that it gives
        player:AddSoulHearts(-4)

        -- Re-heal Judas and Azazel back to 1 red heart so that they can properly use the Crown of Light
        -- (this should do nothing on all of the other characters)
        player:AddHearts(1)
        break
      end
    end
  end

  -- Find out if we replaced the D6
  local newActiveItem = player:GetActiveItem()
  if newActiveItem ~= CollectibleType.COLLECTIBLE_D6 then -- 105
    -- We replaced the D6 with an active item, so put the D6 back and put this item in the Schoolbag
    replacedD6 = true
    player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105
    RPGlobals.run.schoolbag.item = newActiveItem
  end

  -- Give the player extra Schoolbag items, depending on the character
  if replacedD6 == false then
    if character == PlayerType.PLAYER_MAGDALENA then -- 1
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_YUM_HEART -- 45
    elseif character == PlayerType.PLAYER_JUDAS then -- 3
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL -- 34
    elseif character == PlayerType.PLAYER_XXX then -- 4
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_POOP -- 36
    elseif character == PlayerType.PLAYER_EVE then -- 5
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_RAZOR_BLADE -- 126
    elseif character == PlayerType.PLAYER_THELOST then -- 10
      RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_D4 -- 284
    end
  end

  -- Enable the Schoolbag item
  if RPGlobals.run.schoolbag.item ~= 0 then
    Isaac.DebugString("Adding collectible " .. RPGlobals.run.schoolbag.item)
    RPGlobals.run.schoolbag.charges = RPGlobals:GetItemMaxCharges(RPGlobals.run.schoolbag.item)
    RPSchoolbag.sprites.item = nil

    -- Also make sure that the Schoolbag item is removed from all of the pools
    itemPool:RemoveCollectible(RPGlobals.run.schoolbag.item)
  end

  -- Reorganize the items on the item tracker so that the "Instant Start" item comes after the Schoolbag item
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

  -- Add item bans for seeded mode
  itemPool:RemoveTrinket(TrinketType.TRINKET_CAINS_EYE) -- 59

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
  local itemPool = game:GetItemPool()
  local player = game:GetPlayer(0)
  local trinket1 = player:GetTrinket(0) -- This will be 0 if there is no trinket

  -- This is a diversity race, so mark to not remove the 3 placeholder items later on
  RPPostGameStarted.diversity = true

  -- Give the player extra starting items (for diversity races)
  player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
  player:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
  Isaac.DebugString("Removing collectible 414") -- We don't need to show this on the item tracker to reduce clutter

  -- Give the player their five random diversity starting items
  for i = 1, #RPGlobals.race.startingItems do
    if i == 1 then
      -- Item 1 is the active
      RPGlobals.run.schoolbag.item = RPGlobals.race.startingItems[i]
      if RPGlobals.run.schoolbag.item == CollectibleType.COLLECTIBLE_EDENS_SOUL then -- 490
        RPGlobals.run.schoolbag.charges = 0 -- Eden's Soul should start on an empty charge
      else
        RPGlobals.run.schoolbag.charges = RPGlobals:GetItemMaxCharges(RPGlobals.run.schoolbag.item)
      end
      RPSchoolbag.sprites.item = nil

      -- Remove it from all of the item pools
      itemPool:RemoveCollectible(RPGlobals.race.startingItems[i])

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
                            RPGlobals:GetItemMaxCharges(RPGlobals.race.startingItems[i]), true)

      -- Remove it from all of the item pools
      -- (make an exception for items that you can normally get duplicates of)
      if RPGlobals.race.startingItems[i] ~= CollectibleType.COLLECTIBLE_CUBE_OF_MEAT and -- 73
         RPGlobals.race.startingItems[i] ~= CollectibleType.COLLECTIBLE_BALL_OF_BANDAGES then -- 207

        itemPool:RemoveCollectible(RPGlobals.race.startingItems[i])
        if RPGlobals.race.startingItems[i] == CollectibleType.COLLECTIBLE_INCUBUS then -- 360
          itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1)
        elseif RPGlobals.race.startingItems[i] == CollectibleType.COLLECTIBLE_SACRED_HEART then -- 182
          itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2)
        elseif RPGlobals.race.startingItems[i] == CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT then -- 415
          itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3)
        end
      end

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

      -- Remove it from the trinket pool
      itemPool:RemoveTrinket(RPGlobals.race.startingItems[i])
    end
  end

  -- Add item bans for diversity races
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) -- 114
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) -- 168
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_TECH_X) -- 395
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_D4) -- 284
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_D100) -- 283
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DINF) -- 489

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
  local itemPool = game:GetItemPool()
  local player = game:GetPlayer(0)

  -- Add the extra items
  player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)
  RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_MOVING_BOX -- 523
  RPGlobals.run.schoolbag.charges = 6
  RPSchoolbag.sprites.item = nil
  player:AddCollectible(CollectibleType.COLLECTIBLE_MAXS_HEAD, 0, false) -- 4
  player:AddCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS, 0, false) -- 246
  player:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
  player:AddCollectible(CollectibleType.COLLECTIBLE_BELLY_BUTTON, 0, false) -- 458
  -- The extra luck is handled in the EvaluateCache callback

  -- Giving the player these items does not actually remove them from any pools,
  -- so we have to expliticly add them to the ban list
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MOVING_BOX) -- 523
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MAXS_HEAD) -- 4
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS) -- 246
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) -- 414
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BELLY_BUTTON) -- 458

  Isaac.DebugString("Added pageant items.")
end

function RPPostGameStarted:Beginner()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  if character == PlayerType.PLAYER_JUDAS then -- 3
    -- Add the extra items
    player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)

    -- Add the extra health
    player:AddHearts(1)
    player:AddSoulHearts(1)
  end
end

function RPPostGameStarted:SeededMO()
  -- Local variables
  local game = Game()
  local itemPool = game:GetItemPool()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  -- Give the player extra starting items (for seeded races)
  player:AddCollectible(CollectibleType.COLLECTIBLE_COMPASS, 0, false) -- 21
  player:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG, 0, false)

  -- Give the player extra Schoolbag items, depending on the character
  if character == PlayerType.PLAYER_MAGDALENA then -- 1
    RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_YUM_HEART -- 45
  elseif character == PlayerType.PLAYER_JUDAS then -- 3
    RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL -- 34
  elseif character == PlayerType.PLAYER_XXX then -- 4
    RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_POOP -- 36
  elseif character == PlayerType.PLAYER_EVE then -- 5
    RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_RAZOR_BLADE -- 126
  elseif character == PlayerType.PLAYER_THELOST then -- 10
    RPGlobals.run.schoolbag.item = CollectibleType.COLLECTIBLE_D4 -- 284
  end

  -- Enable the Schoolbag item
  if RPGlobals.run.schoolbag.item ~= 0 then
    Isaac.DebugString("Adding collectible " .. RPGlobals.run.schoolbag.item)
    RPGlobals.run.schoolbag.charges = RPGlobals:GetItemMaxCharges(RPGlobals.run.schoolbag.item)
    RPSchoolbag.sprites.item = nil

    -- Also make sure that the Schoolbag item is removed from all of the pools
    itemPool:RemoveCollectible(RPGlobals.run.schoolbag.item)
  end

  -- Add item bans for seeded mode
  itemPool:RemoveTrinket(TrinketType.TRINKET_CAINS_EYE) -- 59

  -- Seeded MO specific things
  player:RemoveCollectible(CollectibleType.COLLECTIBLE_D6) -- 105
  itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DINF) -- 59

  Isaac.DebugString("Added seeded MO items.")
end

return RPPostGameStarted

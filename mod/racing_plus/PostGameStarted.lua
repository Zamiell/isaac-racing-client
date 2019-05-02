local PostGameStarted = {}

-- Includes
local g                       = require("racing_plus/globals")
local PostNewLevel            = require("racing_plus/postnewlevel")
local Sprites                 = require("racing_plus/sprites")
local Schoolbag               = require("racing_plus/schoolbag")
local SoulJar                 = require("racing_plus/souljar")
local FastClear               = require("racing_plus/fastclear")
local Speedrun                = require("racing_plus/speedrun")
local SpeedrunPostGameStarted = require("racing_plus/speedrunpostgamestarted")
local Timer                   = require("racing_plus/timer")

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function PostGameStarted:Main(saveState)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local curses = g.l:GetCurses()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end
  local startSeed = g.seeds:GetStartSeed()
  local startSeedString = g.seeds:GetStartSeedString()
  local customRun = g.seeds:IsCustomRun()
  local challenge = Isaac.GetChallenge()

  Isaac.DebugString("MC_POST_GAME_STARTED - " .. tostring(startSeedString))
  Isaac.DebugString(Isaac.ExecuteCommand("luamem"))

  if PostGameStarted:CheckCorruptMod() or
     PostGameStarted:CheckFullyUnlockedSave() then

    return
  end
  g.saveFile.fullyUnlocked = true

  if saveState then
    -- Fix the bug where the mod won't know what floor they are on if they exit the game and continue
    g.run.currentFloor = stage
    g.run.currentFloorType = stageType
    Isaac.DebugString("New floor: " .. tostring(g.run.currentFloor) .. "-" ..
                      tostring(g.run.currentFloorType) .. " (from S+Q)")

    -- Fix the bug where the Gaping Maws will not respawn in the "Race Room"
    if roomIndex == GridRooms.ROOM_DEBUG_IDX and -- -3
       (g.race.status == "open" or g.race.status == "starting") then

      -- Spawn two Gaping Maws (235.0)
      g.g:Spawn(EntityType.ENTITY_GAPING_MAW, 0, g:GridToPos(5, 5), Vector(0, 0), nil, 0, 0)
      g.g:Spawn(EntityType.ENTITY_GAPING_MAW, 0, g:GridToPos(7, 5), Vector(0, 0), nil, 0, 0)
      Isaac.DebugString("Respawned 2 Gaping Maws.")
    end

    -- We don't need to do the long series of checks if they quit and continued in the middle of a run
    return
  end

  -- Make sure that the "Total Curse Immunity" easter egg is on (the "BLCK CNDL" seed)
  if not g.seeds:HasSeedEffect(SeedEffect.SEED_PREVENT_ALL_CURSES) and -- 70
     Isaac.GetChallenge() == 0 then
     -- If we don't check for challenges, this can cause an infinite loop when entering Challenge #1, for example

    g.seeds:AddSeedEffect(SeedEffect.SEED_PREVENT_ALL_CURSES) -- 70
    Isaac.DebugString("Added the \"Total Curse Immunity\" easter egg.")

    -- We only need to restart the game if there is a curse on B1 already
    if curses ~= 0 then
      -- Doing a "restart" here does not work for some reason, so mark to reset on the next frame
      g.run.restart = true
      Isaac.DebugString("Restarting because there was a curse on Basement 1.")
      return
    end
  end

  -- Log the run beginning
  Isaac.DebugString("A new run has begun on seed: " .. g.seeds:GetStartSeedString())

  -- Reset some global variables that we keep track of per run
  g:InitRun()

  -- Reset some RNG counters for familiars
  FastClear:InitRun()

  -- Reset some race variables that we keep track of per run
  -- (loadOnNextFrame does not need to be reset because it should be already set to false)
  -- (difficulty and challenge are set in the "PostGameStarted:Race()" function)
  -- (character is set in the "PostGameStarted:Character()" function)
  -- (started and startedTime are handled independently of runs)
  g.raceVars.finished = false
  g.raceVars.finishedTime = 0
  g.raceVars.fireworks = 0
  g.raceVars.victoryLaps = 0

  -- Reset some RNG counters to the start RNG of the seed
  -- (future drops will be based on the RNG from this initial random value)
  g.run.playerGenPedSeeds = { startSeed }
  g.RNGCounter.BookOfSin = startSeed
  g.RNGCounter.DeadSeaScrolls = startSeed
  g.RNGCounter.DevilRoomItem = startSeed
  g.RNGCounter.AngelRoomItem = startSeed
  -- Skip resetting Teleport, Undefined, and Telepills, because those are seeded per floor

  -- Reset all graphics
  -- (this is needed to prevent a bug where the "Race Start" room graphics
  -- will flash on the screen before the room is actually entered)
  -- (it also prevents the bug where if you reset during the stage animation, it will permanently stay on the screen)
  Sprites.sprites = {}
  Schoolbag.sprites = {}
  SoulJar.sprites = {}
  Speedrun.sprites = {}
  Timer.sprites = {}
  if g.corrupted then
    -- We want to check for corruption at the beginning of the MC_POST_GAME_STARTED callback,
    -- but we have to initialize the sprite after the sprite table is reset
    Sprites:Init("corrupt1", "corrupt1")
    Sprites:Init("corrupt2", "corrupt2")
  end

  -- Keep track of whether this is a diversity race or not
  PostGameStarted.diversity = false

  -- Racing+ replaces some vanilla items; remove them from all the pools
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BETRAYAL) -- 391
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) -- 534

  -- Racing+ removes the Karma trinket from the game
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_KARMA) -- 85

  if challenge == 0 and
     customRun then

    -- Racing+ also removes certain trinkets that mess up floor generation when playing on a set seed
    g.itemPool:RemoveTrinket(TrinketType.TRINKET_SILVER_DOLLAR) -- 110
    g.itemPool:RemoveTrinket(TrinketType.TRINKET_BLOODY_CROWN) -- 111

    -- Racing+ also removes certain items and trinkets that change room drop calculation when playing on a set seed
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_LUCKY_FOOT) -- 46
    g.itemPool:RemoveTrinket(TrinketType.TRINKET_DAEMONS_TAIL) -- 22
    g.itemPool:RemoveTrinket(TrinketType.TRINKET_CHILDS_HEART) -- 34
    g.itemPool:RemoveTrinket(TrinketType.TRINKET_RUSTED_KEY) -- 36
    g.itemPool:RemoveTrinket(TrinketType.TRINKET_MATCH_STICK) -- 41
    g.itemPool:RemoveTrinket(TrinketType.TRINKET_LUCKY_TOE) -- 42
    g.itemPool:RemoveTrinket(TrinketType.TRINKET_SAFETY_CAP) -- 44
    g.itemPool:RemoveTrinket(TrinketType.TRINKET_ACE_SPADES) -- 45
    g.itemPool:RemoveTrinket(TrinketType.TRINKET_WATCH_BATTERY) -- 72
  end

  -- By default, the player starts near the bottom door
  -- Instead, put the player in the middle of the room
  g.p.Position = g.r:GetCenterPos()

  -- Also, put familiars in the middle of the room, if any
  local familiars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, -1, -1, false, false) -- 3
  for _, familiar in ipairs(familiars) do
    familiar.Position = g.r:GetCenterPos()
  end

  -- Give us custom racing items, depending on the character (mostly just the D6)
  PostGameStarted:Character()

  -- Do more run initialization things specifically pertaining to speedruns
  SpeedrunPostGameStarted:Main()

  -- Do more run initialization things specifically pertaining to races
  PostGameStarted:Race()

  -- Remove the 3 placeholder items if this is not a diversity race
  if not PostGameStarted.diversity then
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3)
  end

  -- Make sure that the festive hat shows
  --g.p:AddNullCostume(NullItemID.ID_CHRISTMAS) -- 16
  -- (this corresponds to "n016_Christmas.anm2" in the "costumes2.xml" file)

  -- Call PostNewLevel manually (they get naturally called out of order)
  PostNewLevel:NewLevel()
end

-- If Racing+ is turned on from the mod menu and then the user immediately tries to play,
-- it won't work properly; some things like boss cutscenes will still be enabled
-- In order to fix this, the game needs to be completely restarted
-- One way to detect this corrupted state is to get how many frames there are
-- in the currently loaded boss cutscene animation file (located at "gfx/ui/boss/versusscreen.anm2")
-- Racing+ removes boss cutscenes, so this value should be 0
-- This function returns true if the MC_POST_GAME_STARTED callback should halt
function PostGameStarted:CheckCorruptMod()
  local sprite = Sprite()
  sprite:Load("gfx/ui/boss/versusscreen.anm2", true)
  sprite:SetFrame("Scene", 0)
  sprite:SetLastFrame()
  local lastFrame = sprite:GetFrame()
  if lastFrame ~= 0 then
    Isaac.DebugString("Corrupted Racing+ instantiation detected.")
    g.corrupted = true
  end
  return g.corrupted
end

-- We can verify that the player is playing on a fully unlocked save by file by
-- going to a specific seed on Eden and checking to see if the items are accurate
-- This function returns true if the MC_POST_GAME_STARTED callback should halt
function PostGameStarted:CheckFullyUnlockedSave()
  -- Local variables
  local character = g.p:GetPlayerType()
  local activeItem = g.p:GetActiveItem()
  local startSeedString = g.seeds:GetStartSeedString()
  local customRun = g.seeds:IsCustomRun()
  local challenge = Isaac.GetChallenge()

  -- Finished checking
  if g.saveFile.state == g.saveFileState.FINISHED then
    return false
  end

  -- Not checked
  if g.saveFile.state == g.saveFileState.NOT_CHECKED then
    -- Store what the old run was like
    g.saveFile.old.challenge = challenge
    g.saveFile.old.character = character
    if challenge == 0 and
       customRun then

      g.saveFile.old.seededRun = true
      g.saveFile.old.seed = startSeedString
    end

    g.saveFile.state = g.saveFileState.GOING_TO_EDEN
  end

  -- Going to the set seed with Eden
  if g.saveFile.state == g.saveFileState.GOING_TO_EDEN then
    local valid = true
    if challenge ~= Challenge.CHALLENGE_NULL then -- 0
      valid = false
    end
    if character ~= PlayerType.PLAYER_EDEN then -- 9
      valid = false
    end
    if startSeedString ~= g.saveFile.seed then
      valid = false
    end
    if not valid then
      -- Doing a "restart" here does not work for some reason, so mark to reset on the next frame
      g.run.restart = true
      return true
    end

    -- We are on the specific Eden seed, so check to see if our items are correct
    -- The items will be different depending on whether or not we have The Babies Mod enabled
    if SinglePlayerCoopBabies == nil then
      if activeItem == g.saveFile.activeItem and
         g.p:HasCollectible(g.saveFile.passiveItem) then

        g.saveFile.fullyUnlocked = true
      end
    else
      if activeItem == g.saveFile.activeItem2 and
         g.p:HasCollectible(g.saveFile.passiveItem2) then

        g.saveFile.fullyUnlocked = true
      end
    end

    g.saveFile.state = g.saveFileState.GOING_BACK
  end

  -- Going back to the old challenge/character/seed
  if g.saveFile.state == g.saveFileState.GOING_BACK then
    local valid = true
    if challenge ~= g.saveFile.old.challenge then
      valid = false
    end
    if character ~= g.saveFile.old.character then
      valid = false
    end
    if customRun ~= g.saveFile.old.seededRun then
      valid = false
    end
    if g.saveFile.old.seededRun and
       startSeedString ~= g.saveFile.old.seed then

      valid = false
    end
    if not valid then
      -- Doing a "restart" here does not work for some reason, so mark to reset on the next frame
      g.run.restart = true
      return true
    end

    g.saveFile.state = g.saveFileState.FINISHED
    Isaac.DebugString("Valid save file detected.")
  end
end

-- This is done when a run is started
function PostGameStarted:Character()
  -- Local variables
  local character = g.p:GetPlayerType()
  local activeItem = g.p:GetActiveItem()
  local activeCharge = g.p:GetActiveCharge()

  -- If they started with the vanilla Schoolbag, it will cause bugs with swapping the active item later on
  -- (this should be only possible on Eden; we will give Eden the custom Schoolbag below)
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) then -- 534
    g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) -- 534

    -- Give Sad Onion as a replacement for the passive item
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SAD_ONION, 0, false) -- 1
    Isaac.DebugString("Eden has started with the vanilla Schoolbag; removing it.")
    Isaac.DebugString("Removing collectible 534 (Schoolbag)")
  end

  -- If they started with the Karma trinket, we need to delete it, since it is supposed to be removed from the game
  -- (this should be only possible on Eden)
  if g.p:HasTrinket(TrinketType.TRINKET_KARMA) then -- 85
    g.p:TryRemoveTrinket(TrinketType.TRINKET_KARMA) -- 85
  end

  -- Give all characters the D6
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_D6) -- 105
  g.sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170

  -- Do character-specific actions
  if character == PlayerType.PLAYER_CAIN then -- 2
    -- Make the D6 appear first on the item tracker
    Isaac.DebugString("Removing collectible 46 (Lucky Foot)")
    Isaac.DebugString("Adding collectible 46 (Lucky Foot)")

  elseif character == PlayerType.PLAYER_JUDAS then -- 3
    -- Judas needs to be at half of a red heart
    g.p:AddHearts(-1)

  elseif character == PlayerType.PLAYER_EVE then -- 5
    -- Remove the Razor Blade from the item tracker
    -- (this is given via an achivement and not from the "players.xml file")
    Isaac.DebugString("Removing collectible 126 (Razor Blade)")

    -- Make the D6 appear first on the item tracker
    Isaac.DebugString("Removing collectible 122 (Whore of Babylon)")
    Isaac.DebugString("Adding collectible 122 (Whore of Babylon)")
    Isaac.DebugString("Removing collectible 117 (Dead Bird)")
    Isaac.DebugString("Adding collectible 117 (Dead Bird)")

  elseif character == PlayerType.PLAYER_SAMSON then -- 6
    -- Make the D6 appear first on the item tracker
    Isaac.DebugString("Removing collectible 157 (Bloody Lust)")
    Isaac.DebugString("Adding collectible 157 (Bloody Lust)")

    -- Remove the trinket, since everyone just drops it anyway
    g.p:TryRemoveTrinket(TrinketType.TRINKET_CHILDS_HEART) -- 34

  elseif character == PlayerType.PLAYER_AZAZEL then -- 7
    -- Give him an additional half soul heart
    g.p:AddSoulHearts(1)

  elseif character == PlayerType.PLAYER_LAZARUS then -- 8
    -- Make the D6 appear first on the item tracker
    Isaac.DebugString("Removing collectible 214 (Anemic)")
    Isaac.DebugString("Adding collectible 214 (Anemic)")

  elseif character == PlayerType.PLAYER_EDEN then -- 9
    -- Find out what the passive item is
    local passiveItem
    for i = 1, g:GetTotalItemCount() do
      if g.p:HasCollectible(i) and
         i ~= activeItem and
         i ~= CollectibleType.COLLECTIBLE_D6 then -- 105

        passiveItem = i
        break
      end
    end

    -- Update the cache (in case we had an active item that granted stats, like A Pony)
    g.p:AddCacheFlags(CacheFlag.CACHE_ALL) -- 0xFFFFFFFF
    g.p:EvaluateItems()

    -- Remove the costume, if any (some items give a costume, like A Pony)
    g.p:RemoveCostume(g.itemConfig:GetCollectible(activeItem))

    -- Eden starts with the Schoolbag by default
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    Schoolbag:Put(activeItem, activeCharge)

    -- Manually fix any custom items
    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_BETRAYAL) then -- 391
      g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_BETRAYAL) -- 391
      g.p:AddCollectible(Isaac.GetItemIdByName("Betrayal"), 0, false)
      passiveItem = Isaac.GetItemIdByName("Betrayal")
    end
    -- (the Schoolbag was manually fixed earlier)

    -- Make the D6 appear first on the item tracker
    Isaac.DebugString("Removing collectible " .. activeItem)
    Isaac.DebugString("Removing collectible " .. passiveItem)
    Isaac.DebugString("Adding collectible " .. activeItem)
    Isaac.DebugString("Adding collectible " .. passiveItem)

  elseif character == PlayerType.PLAYER_THELOST then -- 10
    -- Make the D6 appear first on the item tracker
    Isaac.DebugString("Removing collectible 313 (Holy Mantle)")
    Isaac.DebugString("Adding collectible 313 (Holy Mantle)")

  elseif character == PlayerType.PLAYER_LILITH then -- 13
    -- Make the D6 appear first on the item tracker
    Isaac.DebugString("Removing collectible 412 (Cambion Conception)")
    Isaac.DebugString("Adding collectible 412 (Cambion Conception)")

  elseif character == PlayerType.PLAYER_KEEPER then -- 14
    -- Remove the Wooden Nickel from the item tracker
    -- (this is given via an achivement and not from the "players.xml file")
    Isaac.DebugString("Removing collectible 349 (Wooden Nickel)")

  elseif character == Isaac.GetPlayerTypeByName("Samael") then
    -- Give him the Schoolbag with the Wraith Skull
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    Schoolbag:Put(Isaac.GetItemIdByName("Wraith Skull"), 0)
  end
end

-- This occurs when first going into the game and after a reset occurs mid-race
function PostGameStarted:Race()
  -- Do special ruleset related initialization first
  -- (we want to be able to do runs of them without using the R+ client)
  if g.race.rFormat == "pageant" then
    PostGameStarted:Pageant()
    return
  end

  --
  -- Race validation
  --

  -- If we are not in a race, don't do anything special
  if g.race.status == "none" then
    return
  end

  -- Local variables
  local character = g.p:GetPlayerType()
  local customRun = g.seeds:IsCustomRun()
  local challenge = Isaac.GetChallenge()

  -- Validate that we are not on a custom challenge
  if challenge ~= 0 and
     g.race.rFormat ~= "custom" then

    g.g:Fadeout(0.05, g.FadeoutTarget.FADEOUT_MAIN_MENU) -- 1
    Isaac.DebugString("We are in a race but also in a custom challenge; fading out back to the menu.")
    return
  end

  -- Validate the difficulty (hard mode / Greed mode) for races
  if g.race.hard and
     g.g.Difficulty ~= Difficulty.DIFFICULTY_HARD and -- 1
     g.race.rFormat ~= "custom" then

    Isaac.DebugString("Race error: Supposed to be on hard mode (currently on " .. tostring(g.g.Difficulty) .. ").")
    return

  elseif not g.race.hard and
         g.g.Difficulty ~= Difficulty.DIFFICULTY_NORMAL and -- 0
         g.race.rFormat ~= "custom" then

    Isaac.DebugString("Race error: Supposed to be on easy mode (currently on " .. tostring(g.g.Difficulty) .. ").")
    return
  end

  if g.race.rFormat == "seeded" and
     g.race.status == "in progress" then

    -- Validate that we are on the intended seed
    if g.seeds:GetStartSeedString() ~= g.race.seed then
      -- Doing a "seed #### ####" here does not work for some reason, so mark to reset on the next frame
      g.run.restart = true
      Isaac.DebugString("Restarting because we were not on the right seed.")
      return
    end

  elseif g.race.rFormat == "unseeded" or
          g.race.rFormat == "diversity" or
          g.race.rFormat == "unseeded-lite" or
          g.race.rFormat == "pageant" then

    -- Validate that we are not on a set seed
    -- (this will be true if we are on a set seed or on a challenge,
    -- but we won't get this far if we are on a challenge)
    if customRun and
       not g.debug then -- Make an exception if we are trying to debug something on a certain seed

      -- If the run started with a set seed, this will change the reset behavior to that of an unseeded run
      g.seeds:Reset()

      -- Doing a "restart" here does not work for some reason, so mark to reset on the next frame
      g.run.restart = true
      Isaac.DebugString("Restarting because we were on a set seed.")
      return
    end
  end

  -- Validate that we are on the right character
  if character ~= g.race.character and
     g.race.rFormat ~= "custom" then

    -- Doing a "restart" here does not work for some reason, so mark to reset on the next frame
    g.run.restart = true
    Isaac.DebugString("Restarting because we were not on the right character.")
    return
  end

  -- The Racing+ client will look for this message to determine that
  -- the user has successfully downloaded and is running the Racing+ Lua mod
  Isaac.DebugString("Race validation succeeded.")

  -- Give extra items depending on the format
  if g.race.rFormat == "unseeded" then
    if g.race.ranked and g.race.solo then
      PostGameStarted:UnseededRankedSolo()
    else
      PostGameStarted:Unseeded()
    end

  elseif g.race.rFormat == "seeded" then
    PostGameStarted:Seeded()

  elseif g.race.rFormat == "diversity" then
    -- If the diversity race has not started yet, don't give the items
    if g.raceVars.started then
      PostGameStarted:Diversity()
    end

  elseif g.race.rFormat == "seededMO" then
    PostGameStarted:SeededMO()

  elseif g.race.rFormat == "unseeded-lite" then
    PostGameStarted:UnseededLite()
  end
end

function PostGameStarted:Unseeded()
  -- Unseeded is like vanilla, but the player will still start with More Options to reduce resetting time
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
  g.p:RemoveCostume(g.itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS))
  -- We don't want the costume to show
  Isaac.DebugString("Removing collectible 414 (More Options)")
  -- We don't need to show this on the item tracker to reduce clutter
  g.run.removeMoreOptions = true
  -- More Options will be removed upon entering the first Treasure Room
end

function PostGameStarted:Seeded()
  -- Local variables
  local character = g.p:GetPlayerType()

  -- Give the player extra starting items (for seeded races)
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_COMPASS) then -- 21
    -- Eden can start with The Compass
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_COMPASS, 0, false) -- 21
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_COMPASS) -- 21
  end
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) then
    -- Eden and Samael start with the Schoolbag
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
  end

  -- Give the player the "Instant Start" item(s)
  local replacedD6 = false
  for _, itemID in ipairs(g.race.startingItems) do
    if itemID == 600 then
      -- The 13 luck is a special case
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_13_LUCK, 0, false)
    else
      -- Give the item; the second argument is charge amount, and the third argument is "AddConsumables"
      g.p:AddCollectible(itemID, g:GetItemMaxCharges(itemID), true)

      -- Remove it from all the pools
      g.itemPool:RemoveCollectible(itemID)

      -- Find out if Crown of Light is one of the starting items
      if itemID == 415 then
        -- Remove the 2 soul hearts that it gives
        g.p:AddSoulHearts(-4)

        -- Re-heal Judas back to 1 red heart so that they can properly use the Crown of Light
        -- (this should do nothing on all of the other characters)
        g.p:AddHearts(1)
      end
    end
  end

  -- Find out if we replaced the D6
  local newActiveItem = g.p:GetActiveItem()
  local newActivecharge = g.p:GetActiveCharge()
  if newActiveItem ~= CollectibleType.COLLECTIBLE_D6 then -- 105
    -- We replaced the D6 with an active item, so put the D6 back and put this item in the Schoolbag
    replacedD6 = true
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105
    Schoolbag:Put(newActiveItem, newActivecharge)
  end

  -- Give the player extra Schoolbag items, depending on the character
  if not replacedD6 then
    if character == PlayerType.PLAYER_MAGDALENA then -- 1
      Schoolbag:Put(CollectibleType.COLLECTIBLE_YUM_HEART, "max") -- 45
    elseif character == PlayerType.PLAYER_JUDAS then -- 3
      Schoolbag:Put(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL, "max") -- 34
    elseif character == PlayerType.PLAYER_XXX then -- 4
      Schoolbag:Put(CollectibleType.COLLECTIBLE_POOP, "max") -- 36
    elseif character == PlayerType.PLAYER_EVE then -- 5
      Schoolbag:Put(CollectibleType.COLLECTIBLE_RAZOR_BLADE, "max") -- 126
    elseif character == PlayerType.PLAYER_THELOST then -- 10
      Schoolbag:Put(CollectibleType.COLLECTIBLE_D4, "max") -- 284
    elseif character == PlayerType.PLAYER_LILITH then -- 13
      Schoolbag:Put(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS, "max") -- 357
    elseif character == PlayerType.PLAYER_KEEPER then -- 14
      Schoolbag:Put(CollectibleType.COLLECTIBLE_WOODEN_NICKEL, "max") -- 349
    elseif character == PlayerType.PLAYER_APOLLYON then -- 15
      Schoolbag:Put(CollectibleType.COLLECTIBLE_VOID, "max") -- 477
    end
  end

  -- Reorganize the items on the item tracker so that the "Instant Start" item comes after the Schoolbag item
  for _, itemID in ipairs(g.race.startingItems) do
    if itemID == 600 then
      itemID = tostring(CollectibleType.COLLECTIBLE_13_LUCK)
      Isaac.DebugString("Removing collectible " .. itemID .. " (13 Luck)")
      Isaac.DebugString("Adding collectible " .. itemID .. " (13 Luck)")
    else
      Isaac.DebugString("Removing collectible " .. itemID)
      Isaac.DebugString("Adding collectible " .. itemID)
    end
  end

  -- Add item bans for seeded mode
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_CAINS_EYE) -- 59

  -- Initialize the sprites for the starting room
  -- (don't show these graphics until the race starts)
  if g.race.status == "in progress" then
    if #g.race.startingItems == 1 then
      Sprites:Init("seeded-starting-item", "seeded-starting-item")
      Sprites:Init("seeded-item1", tostring(g.race.startingItems[1]))
    elseif #g.race.startingItems == 2 then
      Sprites:Init("seeded-starting-build", "seeded-starting-build")
      Sprites:Init("seeded-item2", tostring(g.race.startingItems[1]))
      Sprites:Init("seeded-item3", tostring(g.race.startingItems[2]))
    elseif #g.race.startingItems == 4 then
      -- Only the Mega Blast build has 4 starting items
      Sprites:Init("seeded-starting-build", "seeded-starting-build")
      Sprites:Init("seeded-item2", tostring(g.race.startingItems[2]))
      Sprites:Init("seeded-item3", tostring(g.race.startingItems[3]))
      Sprites:Init("seeded-item4", tostring(g.race.startingItems[1])) -- This will be to the left of 2
      Sprites:Init("seeded-item5", tostring(g.race.startingItems[4])) -- This will be to the right of 3
    end
  end

  Isaac.DebugString("Added seeded items.")
end

function PostGameStarted:Diversity()
  -- Local variables
  local trinket1 = g.p:GetTrinket(0) -- This will be 0 if there is no trinket

  -- This is a diversity race, so mark to not remove the 3 placeholder items later on
  PostGameStarted.diversity = true

  -- Give the player extra starting items (for diversity races)
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) then
    -- Eden and Samael start with the Schoolbag already
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
  end
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
  g.p:RemoveCostume(g.itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS))
  -- We don't want the costume to show
  Isaac.DebugString("Removing collectible 414 (More Options)")
  -- We don't need to show this on the item tracker to reduce clutter
  g.run.removeMoreOptions = true
  -- More Options will be removed upon entering the first Treasure Room

  -- Give the player their five random diversity starting items
  for i, itemID in ipairs(g.race.startingItems) do
    -- Replace the custom items
    if i ~= 5 then -- We don't want to replace trinkets
      if itemID == CollectibleType.COLLECTIBLE_BETRAYAL then-- 391
        itemID = Isaac.GetItemIdByName("Betrayal")
      end
    end

    if i == 1 then
      -- Item 1 is the active
      Schoolbag:Put(itemID, "max")
      if g.run.schoolbag.item == CollectibleType.COLLECTIBLE_EDENS_SOUL then -- 490
        g.run.schoolbag.charge = 0 -- This is the only item that does not start with any charges
      end

      -- Give them the item so that the player gets any inital pickups (e.g. Remote Detonator)
      g.p:AddCollectible(itemID, 0, true)

      -- Swap back for the D6
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false)

      -- Update the cache (in case we had an active item that granted stats, like A Pony)
      g.p:AddCacheFlags(CacheFlag.CACHE_ALL)
      g.p:EvaluateItems()

      -- Remove the costume, if any (some items give a costume, like A Pony)
      g.p:RemoveCostume(g.itemConfig:GetCollectible(itemID))

    elseif i == 2 or i == 3 or i == 4 then
      -- Items 2, 3, and 4 are the passives
      -- Give the item; the second argument is charge amount, and the third argument is "AddConsumables"
      g.p:AddCollectible(itemID, g:GetItemMaxCharges(itemID), true)

      -- Remove it from all of the item pools
      -- (make an exception for items that you can normally get duplicates of)
      if itemID ~= CollectibleType.COLLECTIBLE_CUBE_OF_MEAT and -- 73
         itemID ~= CollectibleType.COLLECTIBLE_BALL_OF_BANDAGES then -- 207

        g.itemPool:RemoveCollectible(itemID)
        if itemID == CollectibleType.COLLECTIBLE_INCUBUS then -- 360
          g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1)
        elseif itemID == CollectibleType.COLLECTIBLE_SACRED_HEART then -- 182
          g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2)
        elseif itemID == CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT then -- 415
          g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3)
        end
      end

    elseif i == 5 then
      -- Item 5 is the trinket
      g.p:TryRemoveTrinket(trinket1) -- It is safe to feed 0 to this function
      g.p:AddTrinket(itemID)
      g.p:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, false, false, false, false)
      -- Use the custom Smelter so that the item tracker knows about the trinket we consumed

      -- Regive Paper Clip to Cain, for example
      if trinket1 ~= 0 then
        g.p:AddTrinket(trinket1) -- The game crashes if 0 is fed to this function
      end

      -- Remove it from the trinket pool
      g.itemPool:RemoveTrinket(itemID)
    end
  end

  -- Add item bans for diversity races
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) -- 114
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) -- 168
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_TECH_X) -- 395
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_D4) -- 284
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_D100) -- 283
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DINF) -- 489
  if g.run.schoolbag.item == CollectibleType.COLLECTIBLE_BLOOD_RIGHTS then -- 186
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_ISAACS_HEART) -- 276
  end
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_ISAACS_HEART) then -- 276
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BLOOD_RIGHTS) -- 186
  end

  -- Initialize the sprites for the starting room
  Sprites:Init("diversity-active", "diversity-active")
  Sprites:Init("diversity-passives", "diversity-passives")
  Sprites:Init("diversity-trinket", "diversity-trinket")
  Sprites:Init("diversity-item1", tostring(g.race.startingItems[1]))
  Sprites:Init("diversity-item2", tostring(g.race.startingItems[2]))
  Sprites:Init("diversity-item3", tostring(g.race.startingItems[3]))
  Sprites:Init("diversity-item4", tostring(g.race.startingItems[4]))
  Sprites:Init("diversity-item5", tostring(g.race.startingItems[5]))

  Isaac.DebugString("Added diversity items.")
end

function PostGameStarted:Pageant()
  -- Add the extra items
  -- (the extra luck is handled in the EvaluateCache callback)
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
  Schoolbag:Put(CollectibleType.COLLECTIBLE_DADS_KEY, "max") -- 175
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_MAXS_HEAD, 0, false) -- 4
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MAXS_HEAD) -- 4
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS, 0, false) -- 246
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_THERES_OPTIONS) -- 246
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) -- 414
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_BELLY_BUTTON, 0, false) -- 458
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BELLY_BUTTON) -- 458
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_CANCER, 0, false) -- 301
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_CANCER) -- 301
  g.p:AddTrinket(TrinketType.TRINKET_CANCER) -- 39
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_CANCER) -- 39

  Isaac.DebugString("Added Pageant Boy ruleset items.")
end

function PostGameStarted:UnseededRankedSolo()
  -- The client will populate the starting items for the current season into the "startingItems" variable
  for _, itemID in ipairs(g.race.startingItems) do
    g.p:AddCollectible(itemID, 12, true)
    g.itemPool:RemoveCollectible(itemID)
  end
end

function PostGameStarted:SeededMO()
  -- Local variables
  local character = g.p:GetPlayerType()

  -- Give the player extra starting items (for seeded races)
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_COMPASS) then -- 21
    -- Eden can start with The Compass
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_COMPASS, 0, false) -- 21
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_COMPASS) -- 21
  end
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) then
    -- Eden and Samael start with the Schoolbag
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
  end

  -- Give the player extra Schoolbag items, depending on the character
  if character == PlayerType.PLAYER_MAGDALENA then -- 1
    Schoolbag:Put(CollectibleType.COLLECTIBLE_YUM_HEART, "max") -- 45
  elseif character == PlayerType.PLAYER_JUDAS then -- 3
    Schoolbag:Put(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL, "max") -- 34
  elseif character == PlayerType.PLAYER_XXX then -- 4
    Schoolbag:Put(CollectibleType.COLLECTIBLE_POOP, "max") -- 36
  elseif character == PlayerType.PLAYER_EVE then -- 5
    Schoolbag:Put(CollectibleType.COLLECTIBLE_RAZOR_BLADE, "max") -- 126
  elseif character == PlayerType.PLAYER_THELOST then -- 10
    Schoolbag:Put(CollectibleType.COLLECTIBLE_D4, "max") -- 284
  elseif character == PlayerType.PLAYER_LILITH then -- 13
    Schoolbag:Put(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS, "max") -- 357
  elseif character == PlayerType.PLAYER_KEEPER then -- 14
    Schoolbag:Put(CollectibleType.COLLECTIBLE_WOODEN_NICKEL, "max") -- 349
  elseif character == PlayerType.PLAYER_APOLLYON then -- 15
    Schoolbag:Put(CollectibleType.COLLECTIBLE_VOID, "max") -- 477
  end

  -- Add item bans for seeded mode
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_CAINS_EYE) -- 59

  -- Seeded MO specific things
  g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_D6) -- 105
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DINF) -- 59

  Isaac.DebugString("Added seeded MO items.")
end

function PostGameStarted:UnseededLite()
  -- Give the player extra starting items
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS, 0, false) -- 414
  g.p:RemoveCostume(g.itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS))
  -- We don't want the costume to show
  Isaac.DebugString("Removing collectible 414 (More Options)")
  -- We don't need to show this on the item tracker to reduce clutter
  g.run.removeMoreOptions = true
  -- More Options will be removed upon entering the first Treasure Room

  Isaac.DebugString("Added unseeded-lite items.")
end

return PostGameStarted

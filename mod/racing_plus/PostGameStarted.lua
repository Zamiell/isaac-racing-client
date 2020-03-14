local PostGameStarted = {}

-- Includes
local g                       = require("racing_plus/globals")
local PostNewLevel            = require("racing_plus/postnewlevel")
local Sprites                 = require("racing_plus/sprites")
local Schoolbag               = require("racing_plus/schoolbag")
local SoulJar                 = require("racing_plus/souljar")
local FastClear               = require("racing_plus/fastclear")
local Speedrun                = require("racing_plus/speedrun")
local RacePostGameStarted     = require("racing_plus/racepostgamestarted")
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
  local isaacFrameCount = Isaac.GetFrameCount()

  Isaac.DebugString("MC_POST_GAME_STARTED - " ..
                    "Seed: " .. tostring(startSeedString) .. " - " ..
                    "Frame: " .. tostring(isaacFrameCount))
  Isaac.DebugString(Isaac.ExecuteCommand("luamem"))

  if saveState then
    -- Fix the bug where the mod won't know what floor they are on if they exit the game and continue
    g.run.currentFloor = stage
    g.run.currentFloorType = stageType
    Isaac.DebugString("New floor: " .. tostring(g.run.currentFloor) .. "-" ..
                      tostring(g.run.currentFloorType) .. " (from S+Q)")

    -- Fix the bug where the Gaping Maws will not respawn in the "Race Room"
    if roomIndex == GridRooms.ROOM_DEBUG_IDX and -- -3
       (g.race.status == "open" or
        g.race.status == "starting") then

      -- Spawn two Gaping Maws (235.0)
      Isaac.Spawn(EntityType.ENTITY_GAPING_MAW, 0, 0, g:GridToPos(5, 5), g.zeroVector, nil)
      Isaac.Spawn(EntityType.ENTITY_GAPING_MAW, 0, 0, g:GridToPos(7, 5), g.zeroVector, nil)
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
    if curses ~= LevelCurse.CURSE_NONE then -- 0
      -- Doing a "restart" command here does not work for some reason, so mark to restart on the next frame
      g.run.restart = true
      g.run.b1HasCurse = true
      Isaac.DebugString("Restarting because there was a curse on Basement 1.")
      return
    end
  end

  -- Log the run beginning
  Isaac.DebugString("A new run has begun on seed: " .. g.seeds:GetStartSeedString())

  -- Initialize run-based variables
  g:InitRun()

  -- Reset some RNG counters for familiars
  FastClear:InitRun()

  -- Reset some race variables that we keep track of per run
  -- (loadOnNextFrame does not need to be reset because it should be already set to false)
  -- (difficulty and challenge are set in the "RacePostGameStarted:Main()" function)
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
  g.RNGCounter.GuppysCollar = startSeed
  g.RNGCounter.ButterBean = startSeed
  g.RNGCounter.DevilRoomKrampus = startSeed
  g.RNGCounter.DevilRoomChoice = startSeed
  g.RNGCounter.DevilRoomItem = startSeed
  g.RNGCounter.DevilRoomBeggar = startSeed
  g.RNGCounter.AngelRoomChoice = startSeed
  g.RNGCounter.AngelRoomItem = startSeed
  g.RNGCounter.AngelRoomMisc = startSeed
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

  if PostGameStarted:CheckCorruptMod() or
     PostGameStarted:CheckFullyUnlockedSave() then

    return
  end

  -- Racing+ replaces some vanilla items; remove them from all the pools
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
  if g.g.Difficulty == Difficulty.DIFFICULTY_NORMAL or -- 0
     g.g.Difficulty == Difficulty.DIFFICULTY_HARD then -- 1

    -- Don't do this in Greed Mode, since if the player starts at the center of the room,
    -- they they will immediately touch the trigger button
    g.p.Position = g.r:GetCenterPos()
  end

  -- Also, put familiars in the middle of the room, if any
  local familiars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, -1, -1, false, false) -- 3
  for _, familiar in ipairs(familiars) do
    familiar.Position = g.r:GetCenterPos()
  end

  -- Give us custom racing items, depending on the character (mostly just the D6)
  if PostGameStarted:Character() then
    return
  end

  -- Do more run initialization things specifically pertaining to speedruns
  SpeedrunPostGameStarted:Main()

  -- Do more run initialization things specifically pertaining to races
  if RacePostGameStarted:Main() then
    return
  end

  -- Remove the 3 placeholder items if this is not a diversity race
  if not g.run.diversity and
     challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7)") then

    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3)
  end

  -- Make sure that the festive hat shows
  -- (this is commented out if it is not currently a holiday)
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
    Isaac.DebugString("Error: Corrupted Racing+ instantiation detected. " ..
                      "(The last frame of the \"Scene\" animation is frame " .. tostring(lastFrame) .. ".)")
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
      -- Doing a "restart" command here does not work for some reason, so mark to restart on the next frame
      g.run.restart = true
      Isaac.DebugString("Going to Eden for the save file check.")
      return true
    end

    -- We are on the specific Eden seed, so check to see if our items are correct
    -- The items will be different depending on whether or not we have The Babies Mod enabled
    local neededActiveItem = g.saveFile.activeItem
    local neededPassiveItem = g.saveFile.passiveItem
    if SinglePlayerCoopBabies ~= nil then
      neededActiveItem = g.saveFile.activeItem2
      neededPassiveItem = g.saveFile.passiveItem2
    elseif RacingPlusRebalanced ~= nil then
      neededActiveItem = g.saveFile.activeItem3
      neededPassiveItem = g.saveFile.passiveItem3
    end

    local string = "Error: On seed \"" .. tostring(g.saveFile.seed) .. "\", Eden needs "
    if activeItem ~= neededActiveItem then
      string = string .. "an active item of " .. tostring(g.saveFile.activeItem2) ..
              " (they have an active item of " .. tostring(activeItem) .. ")."
      Isaac.DebugString(string)
    elseif not g.p:HasCollectible(neededPassiveItem) then
      string = string .. "a passive item of " .. tostring(g.saveFile.passiveItem2) .. "."
      Isaac.DebugString(string)
    else
      g.saveFile.fullyUnlocked = true
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
      -- Doing a "restart" command here does not work for some reason, so mark to restart on the next frame
      g.run.restart = true
      Isaac.DebugString("Save file check complete; going back to where we came from.")
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
  local customRun = g.seeds:IsCustomRun()
  local challenge = Isaac.GetChallenge()

  -- Since Eden starts with the Schoolbag in Racing+,
  -- Eden will "miss out" on a passive item if they happen to start with the vanilla Schoolbag
  -- Reset the game if this is the case
  if character == PlayerType.PLAYER_EDEN and -- 9
     g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) then -- 534

    if (challenge == Challenge.CHALLENGE_NULL and -- 0
        customRun) then

      -- In the unlikely event that they are playing on a specific seed with Eden,
      -- the below code will cause the game to infinitely restart
      -- Instead, just take away the vanilla Schoolbag and give them the Sad Onion as a replacement for the passive item
      g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) -- 534
      g.p:AddCollectible(CollectibleType.COLLECTIBLE_SAD_ONION, 0, false) -- 1
      Isaac.DebugString("Eden has started with the vanilla Schoolbag; removing it.")
      Isaac.DebugString("Removing collectible 534 (Schoolbag)")

    else
      g.run.restart = true
      Speedrun.fastReset = true
      Isaac.DebugString("Restarting because we started as Eden and got a vanilla Schoolbag.")
      return true
    end
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
  if character == PlayerType.PLAYER_MAGDALENA then -- 1
    -- Automatically use Maggy's Speed Up pill
    local pillColor = g.p:GetPill(0)
    g.p:UsePill(PillEffect.PILLEFFECT_SPEED_UP, pillColor) -- 14

    -- We also have to update the speed cache
    g.p:AddCacheFlags(CacheFlag.CACHE_SPEED) -- 16
    g.p:EvaluateItems()

    -- Mute the sound effects
    g.sfx:Stop(SoundEffect.SOUND_POWERUP_SPEWER) -- 132
    g.sfx:Stop(SoundEffect.SOUND_THUMBSUP) -- 268
    g.sfx:Stop(SoundEffect.SOUND_SPEED_UP) -- 364

    -- Delete the starting pill
    g.p:SetPill(0, PillColor.PILL_NULL) -- 0

  elseif character == PlayerType.PLAYER_CAIN then -- 2
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

  elseif character == PlayerType.PLAYER_SAMAEL then
    -- Give him the Schoolbag with the Wraith Skull
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    Schoolbag:Put(CollectibleType.COLLECTIBLE_WRAITH_SKULL, 0)
  end
end

return PostGameStarted

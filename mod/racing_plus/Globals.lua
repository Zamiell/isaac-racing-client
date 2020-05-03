
local g  = {}

--
-- Global variables
--

g.version = "v0.52.0"
g.debug = false
g.corrupted = false -- Checked in the MC_POST_GAME_STARTED callback
g.resumedOldRun = false
g.saveFileState = {
  NOT_CHECKED   = 0,
  GOING_TO_EDEN = 1, -- Going to the set seed with Eden
  GOING_BACK    = 2, -- Going back to the old challenge/character/seed
  FINISHED      = 3,
}
g.saveFile = { -- Checked in the MC_POST_GAME_STARTED callback
  state         = g.saveFileState.NOT_CHECKED, -- See the "g.saveFileState" enum below
  fullyUnlocked = false,
  seed          = "P8Q3 MRKZ", -- A randomly chosen seed that contains a BP5 item
  activeItem    = CollectibleType.COLLECTIBLE_BOOK_OF_THE_DEAD, -- 545
  passiveItem   = CollectibleType.COLLECTIBLE_MYSTERY_EGG, -- 539
  -- Eden's items will change if we have The Babies Mod enabled
  activeItem2  = CollectibleType.COLLECTIBLE_MYSTERY_GIFT, -- 515
  passiveItem2 = CollectibleType.COLLECTIBLE_ABEL, -- 188
  -- Eden's items will change if we have Racing+ Rebalanced enabled
  activeItem3  = CollectibleType.COLLECTIBLE_D6, -- 105
  passiveItem3 = CollectibleType.COLLECTIBLE_FOREVER_ALONE, -- 128
  old = {
    challenge = 0,
    character = 0,
    seededRun = false,
    seed      = "",
  },
}

-- These are variables that are reset at the beginning of every run
-- (defaults are set below in the "g:InitRun()" function)
g.run = {}

-- This is the table that gets updated from the "save.dat" file
g.race = {
  id                = 0,           -- 0 if a race is not going on
  status            = "none",      -- Can be "none", "open", "starting", "in progress"
  myStatus          = "not ready", -- Can be either "not ready", "ready", or "racing"
  ranked            = false,       -- Can be true or false
  solo              = false,       -- Can be true or false
  rFormat           = "unseeded",  -- Can be "unseeded", "seeded", "diversity", or "custom"
  -- Unofficially this can also be "pageant"
  difficulty        = "normal",    -- Can be "normal" or "hard"
  character         = 3,           -- 3 is Judas; can be 0 to 15 (the "PlayerType" Lua enumeration)
  goal              = "Blue Baby", -- Can be "Blue Baby", "The Lamb", "Mega Satan", "Hush", or "Everything"
  seed              = "-",         -- Corresponds to the seed that is the race goal
  startingItems     = {},          -- The starting items for this race
  countdown         = -1,          -- This corresponds to the graphic to draw on the screen
  placeMid          = 0,           -- This is either the number of people ready, or the non-fnished place
  place             = 1,           -- This is the final place
  numEntrants       = 1,           -- The number of people in the race
}

-- These are things that pertain to the race but are not read from the "save.dat" file
g.raceVars = {
  loadOnNextFrame    = false,
  started            = false,
  startedTime        = 0,
  startedFrame       = 0,
  finished           = false,
  finishedTime       = 0,
  finishedFrames     = 0,
  fireworks          = 0,
  victoryLaps        = 0,
}

g.RNGCounter = {
  -- Seeded at the beginning of the run
  BookOfSin       = 0, -- 97
  DeadSeaScrolls  = 0, -- 124
  GuppysCollar    = 0, -- 212
  ButterBean      = 0, -- 294
  -- Devil Rooms and Angel Rooms go in order on seeded races
  DevilRoomKrampus = 0,
  DevilRoomChoice  = 0,
  DevilRoomItem    = 0,
  DevilRoomBeggar  = 0,
  AngelRoomChoice  = 0,
  AngelRoomItem    = 0,
  AngelRoomMisc    = 0,

  -- Seeded at the beginning of the floor
  Teleport      = 0, -- 44 (Broken Remote also uses this)
  Undefined     = 0, -- 324
  Telepills     = 0, -- 19
}

-- The contents of the "Racing+ Data" mod save.dat file is cached in memory
g.saveData = {}

--
-- Cached API functions
--

g.g = Game()
g.l = g.g:GetLevel()
g.r = g.g:GetRoom()
g.p = nil -- This is set in the PostPlayerInit callback
g.seeds = g.g:GetSeeds()
g.itemPool = g.g:GetItemPool()
g.itemConfig = Isaac.GetItemConfig()
g.sfx = SFXManager()
g.zeroVector = Vector(0, 0)
g.font = Font()
g.font:Load("font/droid.fnt")
g.color = Color(1, 1, 1, 1, 0, 0, 0)
g.kcolor = KColor(1, 1, 1, 1)

--
-- Extra enumerations
--

-- Entities
EntityType.ENTITY_RACE_TROPHY                = Isaac.GetEntityTypeByName("Race Trophy")
EntityType.ENTITY_ROOM_CLEAR_DELAY_NPC       = Isaac.GetEntityTypeByName("Room Clear Delay NPC")
EntityType.ENTITY_SAMAEL_SCYTHE              = Isaac.GetEntityTypeByName("Samael Scythe")
EntityType.ENTITY_SAMAEL_SPECIAL_ANIMATIONS  = Isaac.GetEntityTypeByName("Samael Special Animations")
TearVariant.MAGIC_SCYTHE                     = Isaac.GetEntityVariantByName("Magic Scythe")
FamiliarVariant.SCYTHE_HITBOX                = Isaac.GetEntityVariantByName("Scythe Hitbox")
PlayerType.PLAYER_SAMAEL                     = Isaac.GetPlayerTypeByName("Samael")
PickupVariant.INVISIBLE_PICKUP               = Isaac.GetEntityVariantByName("Invisible Pickup")
EffectVariant.TRAPDOOR_FAST_TRAVEL           = Isaac.GetEntityVariantByName("Trapdoor (Fast-Travel)")
EffectVariant.CRAWLSPACE_FAST_TRAVEL         = Isaac.GetEntityVariantByName("Crawlspace (Fast-Travel)")
EffectVariant.WOMB_TRAPDOOR_FAST_TRAVEL      = Isaac.GetEntityVariantByName("Womb Trapdoor (Fast-Travel)")
EffectVariant.BLUE_WOMB_TRAPDOOR_FAST_TRAVEL = Isaac.GetEntityVariantByName("Blue Womb Trapdoor (Fast-Travel)")
EffectVariant.HEAVEN_DOOR_FAST_TRAVEL        = Isaac.GetEntityVariantByName("Heaven Door (Fast-Travel)")
EffectVariant.VOID_PORTAL_FAST_TRAVEL        = Isaac.GetEntityVariantByName("Void Portal (Fast-Travel)")
EffectVariant.MEGA_SATAN_TRAPDOOR            = Isaac.GetEntityVariantByName("Mega Satan Trapdoor")
EffectVariant.PITFALL_CUSTOM                 = Isaac.GetEntityVariantByName("Pitfall (Custom)")
EffectVariant.ROOM_CLEAR_DELAY               = Isaac.GetEntityVariantByName("Room Clear Delay")
EffectVariant.CRACK_THE_SKY_BASE             = Isaac.GetEntityVariantByName("Crack the Sky Base")
EffectVariant.STICKY_NICKEL                  = Isaac.GetEntityVariantByName("Sticky Nickel Effect")

-- Collectibles
CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM        = Isaac.GetItemIdByName("Schoolbag")
CollectibleType.COLLECTIBLE_SOUL_JAR                = Isaac.GetItemIdByName("Soul Jar")
CollectibleType.COLLECTIBLE_TROPHY                  = Isaac.GetItemIdByName("Trophy")
CollectibleType.COLLECTIBLE_VICTORY_LAP             = Isaac.GetItemIdByName("Victory Lap")
CollectibleType.COLLECTIBLE_FINISHED                = Isaac.GetItemIdByName("Finished")
CollectibleType.COLLECTIBLE_OFF_LIMITS              = Isaac.GetItemIdByName("Off Limits")
CollectibleType.COLLECTIBLE_13_LUCK                 = Isaac.GetItemIdByName("13 Luck")
CollectibleType.COLLECTIBLE_CHECKPOINT              = Isaac.GetItemIdByName("Checkpoint")
CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1 = Isaac.GetItemIdByName("Diversity Placeholder 1")
CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2 = Isaac.GetItemIdByName("Diversity Placeholder 2")
CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3 = Isaac.GetItemIdByName("Diversity Placeholder 3")
CollectibleType.COLLECTIBLE_MUTANT_SPIDER_INNER_EYE = Isaac.GetItemIdByName("Mutant Spider's Inner Eye")
CollectibleType.COLLECTIBLE_MEGA_SATAN_TELEPORT     = Isaac.GetItemIdByName("Mega Satan Teleport")
CollectibleType.COLLECTIBLE_DEBUG                   = Isaac.GetItemIdByName("Debug")
CollectibleType.COLLECTIBLE_SAMAEL_DEAD_EYE         = Isaac.GetItemIdByName("Samael Dead Eye")
CollectibleType.COLLECTIBLE_SAMAEL_CHOCOLATE_MILK   = Isaac.GetItemIdByName("Samael Chocolate Milk")
CollectibleType.COLLECTIBLE_SAMAEL_DR_FETUS         = Isaac.GetItemIdByName("Samael Dr. Fetus")
CollectibleType.COLLECTIBLE_SAMAEL_MARKED           = Isaac.GetItemIdByName("Samael Marked")
CollectibleType.COLLECTIBLE_WRAITH_SKULL            = Isaac.GetItemIdByName("Wraith Skull")

-- Sounds
SoundEffect.SOUND_SPEEDRUN_FINISH = Isaac.GetSoundIdByName("Speedrun Finish")
SoundEffect.SOUND_WALNUT          = Isaac.GetSoundIdByName("Walnut")

-- Transformations
PlayerForm.PLAYERFORM_STOMPY = PlayerForm.PLAYERFORM_SPIDERBABY + 1
PlayerForm.NUM_PLAYER_FORMS  = PlayerForm.PLAYERFORM_STOMPY + 1

g.LaserVariant = {
  LASER_THICK_RED      = 1, -- Brimstone
  LASER_THIN_RED       = 2, -- Technology
  LASER_SHOOP_DA_WHOOP = 3,
  LASER_PRIDE          = 4, -- (looks like a squiggly line)
  LASER_LIGHT_BEAM     = 5, -- Angel lasers
  LASER_GIANT_RED      = 6, -- Mega Blast
  LASER_TRACTOR_BEAM   = 7,
  LASER_LIGHT_RING     = 8, -- (not sure, looks like a thinner Angel laser)
  LASER_BRIMTECH       = 9, -- Brimstone + Technology
}

-- Spaded by ilise rose (@yatboim)
g.RoomTransition = {
  TRANSITION_NONE              = 0,
  TRANSITION_DEFAULT           = 1,
  TRANSITION_STAGE             = 2,
  TRANSITION_TELEPORT          = 3,
  TRANSITION_ANKH              = 5,
  TRANSITION_DEAD_CAT          = 6,
  TRANSITION_1UP               = 7,
  TRANSITION_GUPPYS_COLLAR     = 8,
  TRANSITION_JUDAS_SHADOW      = 9,
  TRANSITION_LAZARUS_RAGS      = 10,
  TRANSITION_GLOWING_HOURGLASS = 12,
  TRANSITION_D7                = 13,
  TRANSITION_MISSING_POSTER    = 14,
}

g.FadeoutTarget = {
  -- -1 and lower result in a black screen
  FADEOUT_FILE_SELECT     = 0,
  FADEOUT_MAIN_MENU       = 1,
  FADEOUT_TITLE_SCREEN    = 2,
  FADEOUT_RESTART_RUN     = 3,
  FADEOUT_RESTART_RUN_LAP = 4,
  -- 5 and higher result in a black screen
}

g.Transformations = {
  "Guppy",
  "Beelzebub",
  "Fun Guy",
  "Seraphim",
  "Bob",
  "Spun",
  "Yes Mother?",
  "Conjoined",
  "Leviathan",
  "Oh Crap",
  "Bookworm",
  "Adult",
  "Spider Baby",
  "Stompy",
}

--
-- Miscellaneous subroutines
--

function g:InitRun()
  -- Tracking per run
  g.run.startedTime       = 0
  g.run.erasedFadeIn      = false
  g.run.roomsEntered      = 0
  g.run.roomIDs           = {}
  g.run.pills             = {} -- We want to track all pills taken for identification purposes
  g.run.metKrampus        = false
  g.run.movingBoxOpen     = true
  g.run.killedLamb        = false -- Used for the "Everything" race goal
  g.run.removeMoreOptions = false -- Used to give only one double item Treasure Room
  g.run.PHDPills          = false -- Used to determine when to change the pill text
  g.run.haveWishbone      = false
  g.run.haveWalnut        = false
  g.run.debugDamage       = false
  g.run.debugTears        = false
  g.run.debugSpeed        = false
  g.run.debugChaosCard    = false

  -- Tracking per level
  g.run.currentFloor        = 0
  -- (start at 0 so that we can trigger the PostNewRoom callback after the PostNewLevel callback)
  g.run.currentFloorType    = 0 -- We need to track this because we can go from Cathedral to Sheol, for example
  g:InitLevel()

  -- Tracking per room
  g:InitRoom()

  -- Temporary tracking
  g.run.restart               = false -- If set, we restart the run on the next frame
  g.run.currentRoomClearState = true
  g.run.diversity             = false -- Whether or not this is a diversity race
  g.run.reseededFloor         = false
  g.run.usedStrengthChar      = 0
  g.run.goingToDebugRoom      = false
  g.run.forgetMeNow           = false
  g.run.consoleOpened         = false -- If set, fast-resetting is disabled
  g.run.streakText            = "" -- Text that appears after players touch an item, reach a new level, etc.
  g.run.streakText2           = "" -- Secondary streak text that will only show if there is no primary streak text
  g.run.streakFrame           = 0
  g.run.streakForce           = false
  g.run.streakIgnore          = false
  g.run.usedD6Frame           = 0 -- Set when the D6 is used; used to prevent bugs with The Void + D6
  g.run.usedVoidFrame         = 0 -- Set when Void is used; used to prevent bugs with The Void + D6
  g.run.usedTelepills         = false -- Used to replace the "use" animation
  g.run.usedBlankCard         = false -- Used to replace the "use" animation
  g.run.giveExtraCharge       = false -- Used to fix The Battery + 9 Volt synergy
  g.run.droppedButterItem     = 0 -- Needed to fix a bug with the Schoolbag and the Butter! trinket
  g.run.fastResetFrame        = 0 -- Set when the user presses the reset button on the keyboard
  g.run.dualityCheckFrame     = 0
  g.run.momDied               = false -- Used to fix bugs with fast-clear and killing Mom
  g.run.photosSpawning        = false -- Used when replacing The Polaroid and The Negative
  g.run.playerGenPedSeeds     = {} -- Used so that we properly seed player-generated pedestals (1/2)
  g.run.playerGenPedFrame     = 0 -- Used so that we properly seed player-generated pedestals (2/2)
  g.run.itLivesKillFrame      = 0 -- Used to delete the trapdoor and beam of light after It Lives! and Hush
  g.run.speedLilHauntsFrame   = 0 -- Used to speed up The Haunt fight (1/2)
  g.run.speedLilHauntsBlack   = false -- Used to speed up The Haunt fight (2/2)
  g.run.rechargeItemFrame     = 0 -- Used to recharge the D6 / Void after a failed attempt
  g.run.killAttackFly         = false -- Used to prevent a bug with trapdoors/crawlspaces and Corny Poop
  g.run.extraIncubus          = false -- Used in Racing+ Season 4
  g.run.removedCrownHearts    = false -- Used to remove health after taking Crown of Light from a fart-reroll
  g.run.passiveItems          = {} -- Used to keep track of the currently collected passive items
  g.run.pickingUpItem         = 0 -- Equal to the ID of the currently queued item
  g.run.pickingUpItemRoom     = 0 -- Equal to the room that we picked up the currently queued item
  g.run.pickingUpItemType     = 0 -- Equal to the "QueuedItem.Item.Type" (the "ItemType" enum)
  g.run.knifeDirection        = {} -- A 2-dimensional array that stores the directions held on past frames
  g.run.lastDDLevel           = 0 -- Used by the Soul Jar
  g.run.switchForgotten       = false -- Used to manually switch the player between The Forgotten and The Soul
  g.run.currentCharacter      = 0
  g.run.fadeForgottenFrame    = 0 -- Used to fix a bug with seeded death
  g.run.showVersionFrame      = 0
  g.run.bombKeyPressed        = false
  g.run.spawningAngel         = false -- Used to prevent unavoidable damage on the Isaac fight
  g.run.bossCommand           = false -- Used in Racing+ Rebalanced
  g.run.questionMarkCard      = 0 -- Equal to the last game frame that one was used
  g.run.gettingCollectible    = false
  g.run.dealingExtraDamage    = false -- Used for Hush
  g.run.firingExtraTear       = false -- Used for Hush
  g.run.customBossRoomIndex   = -1000 -- Used in Season 7
  g.run.pencilCounter         = 0 -- Used for tracking the number of tears fired (for Lead Pencil)
  g.run.spamButtons           = false -- Used to spam Blood Rights
  g.run.startingRoomGraphics  = false -- Used to toggle off the controls graphic in some race types
  g.run.usedTeleport          = false -- Used to reposition the player (if they appear at a non-existent entrance)
  g.run.spawnedUltraGreed     = false -- Used in Season 7

  -- Trophy
  g.run.trophy = { -- Used to know when to respawn the trophy
    spawned   = false,
    stage     = 0,
    roomIndex = 0,
    position  = g.zeroVector,
  }

  -- Transformations
  g.run.transformations = {}
  for i = 0, PlayerForm.NUM_PLAYER_FORMS - 1 do
    g.run.transformations[i] = false
  end

  -- Trapdoor tracking
  g.run.trapdoor = {
    state      = 0, -- See FastTravel.state for enum definitions
    upwards    = false,
    floor      = 0,
    frame      = 0,
    scale      = {}, -- Needs to be a table in order to handle multiple players
    voidPortal = false,
    megaSatan  = false,
    reseeding  = false, -- True if we will reseed the floor after getting there
  }

  -- Crawlspace tracking
  g.run.crawlspace = {
    prevRoom    = 0,
    direction   = -1, -- Used to fix nested room softlocks
    blackMarket = false,
  }

  -- Keeper + Greed's Gullet tracking
  g.run.keeper = {
    baseHearts       = 4, -- Either 4 (for base), 2, 0, -2, -4, -6, etc.
    healthUpItems    = {},
    coins            = 50,
    usedHealthUpPill = false,
  }
  for _, itemID in ipairs(g.healthUpItems) do
    g.run.keeper.healthUpItems[itemID] = 0
  end

  -- Schoolbag tracking
  g.run.schoolbag = {
    present              = false, -- Corresponds to whether or not they have the Schoolbag collectible
    item                 = 0,
    charge               = 0,
    chargeBattery        = 0,
    pressed              = false, -- Used for keeping track of whether the "Switch" button is held down or not
    usedGlowingHourGlass = 0, -- 0 is not used, 1 is just used, 2 is entered the next room
    last                 = { -- Used for handling the Glowing Hour Glass
      active = {
        item = 0,
        charge = 0,
        chargeBattery = 0,
      },
      schoolbag = {
        item = 0,
        charge = 0,
        chargeBattery = 0,
      },
    },
  }

  -- Soul Jar tracking
  g.run.soulJarSouls = 0

  -- Special death handling for seeded races
  g.run.seededDeath = {
    state           = 0, -- See the "SeededDeath.state" enum
    stage           = 0,
    reviveFrame     = 0,
    guppysCollar    = false,
    position        = g.zeroVector,
    debuffEndTime   = 0,
    frameOfLastDD   = 0,
    items           = {},
    charge          = 0,
    spriteScale     = g.zeroVector,
    goldenBomb      = false,
    goldenKey       = false,
    sbItem          = 0,
    sbCharge        = 0,
    sbChargeBattery = 0,
  }

  -- Custom Boss Rush tracking
  g.run.bossRush = {
    started        = false,
    finished       = false,
    bosses         = {},
    currentWave    = 0,
    spawnWaveFrame = 0,
  }

  -- Special room seeding
  g.run.seededSwap = {
    swapping     = false,
    devilVisited = false,
    bookTouched  = false,
    coins        = 0,
    keys         = 0,
    heartTable   = {},
  }
end

function g:InitLevel()
  -- Tracking per floor
  g.run.replacedPedestals   = {}
  g.run.replacedTrapdoors   = {}
  g.run.replacedCrawlspaces = {}
  g.run.replacedHeavenDoors = {}
  g.run.reseedCount         = 0
  g.run.tempHolyMantle      = false -- Used to give Keeper 2 hits upon revival in a seeded race

  -- Custom Challenge Room tracking
  g.run.challengeRoom = {
    started        = false,
    finished       = false,
    waves          = {},
    currentWave    = 0,
    spawnWaveFrame = 0,
  }
end

function g:InitRoom()
  -- Tracking per room
  g.run.fastCleared           = false
  g.run.currentGlobins        = {} -- Used for softlock prevention
  g.run.currentLilHaunts      = {} -- Used to delete invulnerability frames
  g.run.currentHoppers        = {} -- Used to prevent softlocks
  g.run.usedStrength          = false
  g.run.handsDelay            = 0 -- Used to speed up Mom's Hands
  g.run.handPositions         = {} -- Used to play an "Appear" animation for Mom's Hands
  g.run.naturalTeleport       = false
  g.run.diceRoomActivated     = false
  g.run.megaSatanDead         = false
  g.run.endOfRunText          = false -- Shown when the run is completed but only for one room
  g.run.teleportSubverted     = false -- Used for repositioning the player on It Lives! / Gurdy (1/2)
  g.run.teleportSubvertScale  = Vector(1, 1) -- Used for repositioning the player on It Lives! / Gurdy (2/2)
  g.run.forceMomStomp         = false
  g.run.forceMomStompPos      = nil
  g.run.spawningLight         = false -- For the custom Crack the Sky effect
  g.run.spawningExtraLight    = false -- For the custom Crack the Sky effect
  g.run.lightPositions        = {} -- For the custom Crack the Sky effect
  -- Used to fix the bug where multiple black hearts can drop from the same multi-segment enemy
  g.run.blackHeartNPCs  = {} -- Indexed by NPC index
  g.run.blackHeartCount = {} -- Indexed by NPC init seed
  g.run.touchedPickup   = false -- Used for Challenge Rooms
  g.run.matriarch       = { -- Used to rebalance The Matriarch
    spawned   = false,
    chubIndex = -1,
    stunFrame = 0,
  }
end

function g:IncrementRNG(seed)
  -- The game expects seeds in the range of 0 to 4294967295
  local rng = RNG()
  rng:SetSeed(seed, 35)
  -- This is the ShiftIdx that blcd recommended after having reviewing the game's internal functions
  rng:Next()
  local newSeed = rng:GetSeed()
  return newSeed
end

function g:GridToPos(x, y)
  x = x + 1
  y = y + 1
  return g.r:GetGridPosition(y * g.r:GetGridWidth() + x)
end

-- From: http://lua-users.org/wiki/SimpleRound
function g:Round(num, numDecimalPlaces)
  local mult = 10 ^ (numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function g:TableEqual(table1, table2)
  -- First, find out if they are nil
  if table1 == nil and table2 == nil then
    return true
  end
  if table1 == nil then
    table1 = {}
  end
  if table2 == nil then
    table2 = {}
  end

  -- First, compare their size
  if #table1 ~= #table2 then
    return false
  end

  -- Compare each element
  for i = 1, #table1 do
    if table1[i] ~= table2[i] then
      return false
    end
  end
  return true
end

-- From: http://lua-users.org/wiki/TableUtils
function g:TableValToStr(v)
  if "string" == type(v) then
    v = string.gsub(v, "\n", "\\n")
    if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v, '"', '\\"') .. '"'
  else
    return "table" == type(v) and g.TableToString(v) or tostring(v)
  end
end

function g:TableKeyToStr(k)
  if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
    return k
  else
    return "[" .. g:TableValToStr(k) .. "]"
  end
end

function g:TableToString(tbl)
  local result, done = {}, {}
  for k, v in ipairs(tbl) do
    table.insert(result, g:TableValToStr(v))
    done[k] = true
  end
  for k, v in pairs(tbl) do
    if not done[k] then
      table.insert(result, g:TableKeyToStr(k) .. "=" .. g:TableValToStr(v))
    end
  end
  return "{" .. table.concat(result, ",") .. "}"
end

-- From: http://lua-users.org/wiki/CopyTable
function g:TableClone(tbl)
  return {table.unpack(tbl)}
end

-- From: https://stackoverflow.com/questions/1410862/concatenation-of-tables-in-lua
function g:TableConcat(t1, t2)
  for i = 1, #t2 do
    t1[#t1 + 1] = t2[i]
  end
  return t1
end

-- From: https://stackoverflow.com/questions/2705793/how-to-get-number-of-entries-in-a-lua-table/2705804
function g:TableLen(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

function g:TableContains(t, v2)
  for _, v in pairs(t) do
    if v == v2 then
      return true
    end
  end
  return false
end

function g:TableFind(t, el)
  for index, value in pairs(t) do
    if value == el then
      return index
    end
  end
end

function g:TableRemove(t, el)
  local index = g:TableFind(t, el)
  table.remove(t, index)
end

function g:GetTotalItemCount()
  -- Racing+ adds a bunch of items
  -- Furthermore, we need to account for if the user has other items added from other mods
  -- Start with the highest vanilla item ID and iterate upwards
  local i = CollectibleType.NUM_COLLECTIBLES - 1
  local totalItems = i
  while true do
    i = i + 1
    if g.itemConfig:GetCollectible(i) ~= nil then
      totalItems = i
    else
      return totalItems
    end
  end
end

-- Find out how many charges this item has
function g:GetItemMaxCharges(itemID)
  if itemID == 0 then
    return 0
  else
    return g.itemConfig:GetCollectible(itemID).MaxCharges
  end
end

function g:ExecuteCommand(command)
  Isaac.DebugString("Executing command: " .. command)
  Isaac.ExecuteCommand(command)
  Isaac.DebugString("Finished executing command: " .. command)
end

function g:ConvertTimeToString(time) -- time is given in seconds
  -- Calcuate the hours digit
  local hours = math.floor(time / 3600)

  -- Calcuate the minutes digits
  local minutes = math.floor(time / 60)
  if hours > 0 then
    minutes = minutes - hours * 60
  end
  if minutes < 10 then
    minutes = "0" .. tostring(minutes)
  else
    minutes = tostring(minutes)
  end
  local minute1 = string.sub(minutes, 1, 1) -- The first character
  local minute2 = string.sub(minutes, 2, 2) -- The second character

  -- Calcuate the seconds digits
  local seconds = math.floor(time % 60)
  if seconds < 10 then
    seconds = "0" .. tostring(seconds)
  else
    seconds = tostring(seconds)
  end
  local second1 = string.sub(seconds, 1, 1) -- The first character
  local second2 = string.sub(seconds, 2, 2) -- The second character

  -- Calculate the tenths digit
  local rawSeconds = time % 60 -- 0.000 to 59.999
  local decimals = rawSeconds - math.floor(rawSeconds)
  local tenths = math.floor(decimals * 10)

  return {
    hours,
    minute1,
    minute2,
    second1,
    second2,
    tenths,
  }
end

-- From piber20 Helper
-- https://steamcommunity.com/workshop/filedetails/?id=1553455339
function g:GetPlayerVisibleHearts()
  local maxHearts = math.max(g.p:GetEffectiveMaxHearts(), g.p:GetBoneHearts() * 2)
  local visibleHearts = math.ceil((maxHearts + g.p:GetSoulHearts()) / 2)
  if visibleHearts < 1 then
      visibleHearts = 1
  end
  return visibleHearts
end

-- Kilburn's function (pinned in the Isaac Discord server)
function g:GetScreenSize()
  local pos = g.r:WorldToScreenPosition(g.zeroVector) - g.r:GetRenderScrollOffset() - g.g.ScreenShakeOffset

  local rx = pos.X + 60 * 26 / 40
  local ry = pos.Y + 140 * (26 / 40)

  return { rx * 2 + 13 * 26, ry * 2 + 7 * 26 }
end

-- This is used for the Victory Lap feature that spawns multiple bosses
g.bossArray = {
  {19, 0, 0}, -- Larry Jr.
  {19, 0, 1}, -- Larry Jr. (green)
  {19, 0, 2}, -- Larry Jr. (blue)
  {19, 1, 0}, -- The Hollow
  {19, 1, 1}, -- The Hollow (green)
  {19, 1, 2}, -- The Hollow (grey)
  {19, 1, 3}, -- The Hollow (yellow)
  {20, 0, 0}, -- Monstro
  {20, 0, 1}, -- Monstro (double red)
  {20, 0, 2}, -- Monstro (grey)
  {28, 0, 0}, -- Chub
  {28, 0, 1}, -- Chub (green)
  {28, 0, 2}, -- Chub (yellow)
  {28, 1, 0}, -- C.H.A.D.
  {28, 2, 0}, -- Carrion Queen
  {28, 2, 1}, -- Carrion Queen (pink)
  {36, 0, 0}, -- Gurdy
  {36, 0, 1}, -- Gurdy (dark)
  {43, 0, 0}, -- Monstro II
  {43, 0, 1}, -- Monstro II (red)
  {43, 1, 0}, -- Gish
  {62, 0, 0}, -- Pin
  {62, 1, 0}, -- Scolex
  {62, 1, 1}, -- Scolex (black)
  {62, 2, 0}, -- Frail
  {62, 2, 1}, -- Frail (black)
  {63, 0, 0}, -- Famine
  {63, 0, 1}, -- Famine (blue)
  {64, 0, 0}, -- Pestilence
  {64, 0, 1}, -- Pestilence (white)
  {65, 0, 0}, -- War
  {65, 0, 1}, -- War (dark)
  {65, 1, 0}, -- Conquest
  {66, 0, 0}, -- Death
  {66, 0, 1}, -- Death (black)
  {67, 0, 0}, -- The Duke of Flies
  {67, 0, 1}, -- The Duke of Flies (green)
  {67, 0, 2}, -- The Duke of Flies (peach)
  {67, 1, 0}, -- The Husk
  {67, 1, 1}, -- The Husk (black)
  {67, 1, 2}, -- The Husk (grey)
  {68, 0, 0}, -- Peep
  {68, 0, 1}, -- Peep (yellow)
  {68, 0, 2}, -- Peep (green)
  {68, 1, 0}, -- The Bloat
  {68, 1, 1}, -- The Bloat (green)
  {69, 0, 0}, -- Loki
  {69, 1, 0}, -- Lokii
  {71, 0, 0}, -- Fistula
  {71, 0, 1}, -- Fistula (black)
  {71, 1, 0}, -- Teratoma
  {74, 0, 0}, -- Blastocyst
  {79, 0, 0}, -- Gemini
  {79, 0, 1}, -- Gemini (green, disattached)
  {79, 0, 2}, -- Gemini (blue)
  {79, 1, 0}, -- Steven
  {79, 2, 0}, -- The Blighted Ovum
  {81, 0, 0}, -- The Fallen
  --{81, 1, 0}, -- Krampus
  -- (don't include Krampus since is he too common and he spawns an item)
  {82, 0, 0}, -- The Headless Horseman
  {97, 0, 0}, -- Mask of Infamy
  {99, 0, 0}, -- Gurdy Jr.
  {99, 0, 1}, -- Gurdy Jr. (double blue)
  {99, 0, 2}, -- Gurdy Jr. (orange)
  {100, 0, 0}, -- Widow
  {100, 0, 1}, -- Widow (black)
  {100, 0, 2}, -- Widow (pink)
  {100, 1, 0}, -- The Wretched
  {101, 0, 0}, -- Daddy Long Legs
  {101, 1, 0}, -- Triachnid
  {237, 1, 0}, -- Gurglings
  {237, 1, 1}, -- Gurglings (double yellow)
  {237, 1, 2}, -- Gurglings (black)
  {237, 2, 0}, -- Turdling
  {260, 0, 0}, -- The Haunt
  {260, 0, 1}, -- The Haunt (black)
  {260, 0, 2}, -- The Haunt (pink)
  {261, 0, 0}, -- Dingle
  {261, 0, 1}, -- Dingle (red)
  {261, 0, 2}, -- Dingle (black)
  {261, 1, 0}, -- Dangle
  {262, 0, 0}, -- Mega Maw
  {262, 0, 1}, -- Mega Maw (red)
  {262, 0, 2}, -- Mega Maw (black)
  {263, 0, 0}, -- The Gate
  {263, 0, 1}, -- The Gate (red)
  {263, 0, 2}, -- The Gate (black)
  {264, 0, 0}, -- Mega Fatty
  {264, 0, 1}, -- Mega Fatty (red)
  {264, 0, 2}, -- Mega Fatty (yellow)
  {265, 0, 0}, -- The Cage
  {265, 0, 1}, -- The Cage (green)
  {265, 0, 2}, -- The Cage (double pink)
  {266, 0, 0}, -- Mama Gurdy
  {267, 0, 0}, -- Dark One
  {268, 0, 0}, -- The Adversary
  {269, 0, 0}, -- Polycephalus
  {269, 0, 1}, -- Polycephalus (red)
  {269, 0, 2}, -- Polycephalus (double pink)
  {270, 0, 0}, -- Mr. Fred
  {271, 0, 0}, -- Uriel
  {271, 1, 0}, -- Uriel (fallen)
  {272, 0, 0}, -- Gabriel
  {272, 1, 0}, -- Gabriel (fallen)
  {401, 0, 0}, -- The Stain
  {401, 0, 1}, -- The Stain (dark)
  {402, 0, 0}, -- Brownie
  {402, 0, 1}, -- Brownie (dark)
  {403, 0, 0}, -- The Forsaken
  {403, 0, 1}, -- The Forsaken (black)
  {404, 0, 0}, -- Little Horn
  {404, 0, 1}, -- Little Horn (grey)
  {404, 0, 2}, -- Little Horn (black)
  {405, 0, 0}, -- Rag Man
  {405, 0, 1}, -- Rag Man (orange)
  {405, 0, 2}, -- Rag Man (black)
  {409, 0, 0}, -- Rag Mega
  {410, 0, 0}, -- Sisters Vis
  {411, 0, 0}, -- Big Horn
  {413, 0, 0}, -- The Matriarch
}

g.splittingBosses = {
  EntityType.ENTITY_LARRYJR, -- 19
  EntityType.ENTITY_FISTULA_BIG, -- 71
  EntityType.ENTITY_FISTULA_MEDIUM, -- 72
  EntityType.ENTITY_FISTULA_SMALL, -- 73
  EntityType.ENTITY_BLASTOCYST_BIG, -- 74
  EntityType.ENTITY_BLASTOCYST_MEDIUM, -- 75
  EntityType.ENTITY_BLASTOCYST_SMALL, -- 76
  EntityType.ENTITY_FALLEN, -- 81
  EntityType.ENTITY_BROWNIE, -- 402
}

-- Used to fix Greed's Gullet bugs
g.healthUpItems = {
  12, -- Magic Mushroom (already has range cache)
  15, -- <3
  16, -- Raw Liver (gives 2 containers)
  22, -- Lunch
  23, -- Dinner
  24, -- Dessert
  25, -- Breakfast
  26, -- Rotten Meat
  81, -- Dead Cat
  92, -- Super Bandage
  101, -- The Halo (already has range cache)
  119, -- Blood Bag
  121, -- Odd Mushroom (Thick) (already has range cache)
  129, -- Bucket of Lard (gives 2 containers)
  138, -- Stigmata
  176, -- Stem Cells
  182, -- Sacred Heart (already has range cache)
  184, -- Holy Grail
  189, -- SMB Super Fan (already has range cache)
  193, -- Meat!
  218, -- Placenta
  219, -- Old Bandage
  226, -- Black Lotus
  230, -- Abaddon
  253, -- Magic Scab
  307, -- Capricorn (already has range cache)
  312, -- Maggy's Bow
  314, -- Thunder Theighs
  334, -- The Body (gives 3 containers)
  342, -- Blue Cap
  346, -- A Snack
  354, -- Crack Jacks
  456, -- Moldy Bread
  1000, -- Health Up (pill)
}

return g

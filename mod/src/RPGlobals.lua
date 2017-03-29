local RPGlobals = {}

--
-- Global variables
--

-- These are per run
-- (defaults are set below in the "RPGlobals:InitRun()" function)
RPGlobals.run = {}

-- This is the table that gets updated from the "save.dat" file
RPGlobals.race = {
  status          = "none",      -- Can be "none", "open", "starting", "in progress"
  rType           = "unranked",  -- Can be "unranked", "ranked" (this is not currently used)
  rFormat         = "unseeded",  -- Can be "unseeded", "seeded", "diveristy", "custom"
  character       = "Judas",     -- Can be the name of any character
  goal            = "Blue Baby", -- Can be "Blue Baby", "The Lamb", "Mega Satan"
  seed            = "-",         -- Corresponds to the seed that is the race goal
  startingItems   = {},          -- The starting items for this race
  countdown       = -1,          -- This corresponds to the graphic to draw on the screen
}

-- These are things that pertain to the race but are not read from the "save.dat" file
RPGlobals.raceVars = {
  loadOnNextFrame    = false,
  difficulty         = 0,
  challenge          = 0,
  character          = "Isaac",
  itemBanList        = {},
  trinketBanList     = {},
  resetEnabled       = true,
  started            = false,
  startedTime        = 0,
  finished           = false,
  finishedTime       = 0,
  showPlaceGraphic   = true,
  fireworks          = 0,
  removedMoreOptions = false,
  placedJailCard     = false,
  victoryLaps        = 0,
}

RPGlobals.RNGCounter = {
  InitialSeed   = 0,
  BookOfSin     = 0,
  CrystalBall   = 0,
  Teleport      = 0, -- Broken Remote also uses this
  Undefined     = 0,
  Telepills     = 0,
  SackOfPennies = 0,
  BombBag       = 0,
  JuicySack     = 0,
  MysterySack   = 0,
  LilChest      = 0,
  RuneBag       = 0,
  AcidBaby      = 0,
  SackOfSacks   = 0,
}

RPGlobals.spriteTable = {}

--
-- Extra enumerations
--

-- Collectibles
-- (unused normal item IDs: 43, 59, 61, 235, 263)
CollectibleType.COLLECTIBLE_ANGRY_FLY      = 511
CollectibleType.COLLECTIBLE_BLACK_HOLE     = 512
CollectibleType.COLLECTIBLE_BOZO           = 513
CollectibleType.COLLECTIBLE_BROKEN_MODEM   = 514
CollectibleType.COLLECTIBLE_MYSTERY_GIFT   = 515
CollectibleType.COLLECTIBLE_SPRINKLER      = 516
CollectibleType.COLLECTIBLE_FAST_BOMBS     = 517
CollectibleType.COLLECTIBLE_BUDDY_IN_A_BOX = 518
CollectibleType.COLLECTIBLE_LIL_DELIRIUM   = 519
CollectibleType.NUM_COLLECTIBLES           = 520

CollectibleType.COLLECTIBLE_BOOK_OF_SIN_SEEDED  = Isaac.GetItemIdByName("The Book of Sin") -- 520, active (repl. 97)
CollectibleType.COLLECTIBLE_CRYSTAL_BALL_SEEDED = Isaac.GetItemIdByName("Crystal Ball")    -- 521, active (repl. 158)
CollectibleType.COLLECTIBLE_BETRAYAL_NOANIM     = Isaac.GetItemIdByName("Betrayal")        -- 522, passive (repl. 391)
CollectibleType.COLLECTIBLE_SMELTER_LOGGER      = Isaac.GetItemIdByName("Smelter")         -- 523, passive (repl. 479)
CollectibleType.COLLECTIBLE_DEBUG               = Isaac.GetItemIdByName("Debug")           -- 524, active
CollectibleType.COLLECTIBLE_SCHOOLBAG           = Isaac.GetItemIdByName("Schoolbag")       -- 525, passive
CollectibleType.COLLECTIBLE_SOUL_JAR            = Isaac.GetItemIdByName("Soul Jar")        -- 526, passive
CollectibleType.COLLECTIBLE_TROPHY              = Isaac.GetItemIdByName("Trophy")          -- 527, passive
CollectibleType.COLLECTIBLE_VICTORY_LAP         = Isaac.GetItemIdByName("Victory Lap")     -- 528, passive
CollectibleType.COLLECTIBLE_FINISHED            = Isaac.GetItemIdByName("Finished")        -- 529, passive
CollectibleType.COLLECTIBLE_OFF_LIMITS          = Isaac.GetItemIdByName("Off Limits")      -- 530, passive
CollectibleType.COLLECTIBLE_13_LUCK             = Isaac.GetItemIdByName("13 Luck")         -- 531, passive
CollectibleType.NUM_COLLECTIBLES                = Isaac.GetItemIdByName("13 Luck") + 1

-- Pills
PillEffect.PILLEFFECT_GULP_LOGGER = Isaac.GetPillEffectByName("Gulp!") -- 47
PillEffect.NUM_PILL_EFFECTS       = Isaac.GetPillEffectByName("Gulp!") + 1

-- Pickups
PickupVariant.PICKUP_MIMIC = 54

-- Sounds
SoundEffect.SOUND_LAUGH       = Isaac.GetSoundIdByName("Laugh")
SoundEffect.NUM_SOUND_EFFECTS = Isaac.GetSoundIdByName("Laugh") + 1

-- Spaded by ilise rose (@yatboim)
RPGlobals.RoomTransition = {
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
  TRANSITION_MISSING_POSTER    = 14
}

-- Spaded by me
RPGlobals.FadeoutTarget = {
  -- -1 and lower result in a black screen
  FADEOUT_FILE_SELECT     = 0,
  FADEOUT_MAIN_MENU       = 1,
  FADEOUT_TITLE_SCREEN    = 2,
  FADEOUT_RESTART_RUN     = 3,
  FADEOUT_RESTART_RUN_LAP = 4,
  -- 5 and higher result in a black screen
}

--
-- Misc. subroutines
--

function RPGlobals:InitRun()
  -- Tracking per run
  RPGlobals.run.roomsCleared     = 0
  RPGlobals.run.roomsEntered     = 0
  RPGlobals.run.touchedBookOfSin = false

  -- Tracking per floor
  RPGlobals.run.currentFloor        = 0
  -- (start at 0 so that we can trigger the PostNewRoom callback after the PostNewLevel callback)
  RPGlobals.run.levelDamaged        = false
  RPGlobals.run.replacedPedestals   = {}
  RPGlobals.run.replacedTrapdoors   = {}
  RPGlobals.run.replacedCrawlspaces = {}
  RPGlobals.run.replacedHeavenDoors = {}

  -- Tracking per room
  RPGlobals.run.roomEnterting         = false
  RPGlobals.run.currentRoomClearState = true
  RPGlobals.run.currentGlobins        = {}
  RPGlobals.run.currentKnights        = {}
  RPGlobals.run.currentLilHaunts      = {}

  -- Temporary tracking
  RPGlobals.run.restartFrame          = 0
  RPGlobals.run.itemReplacementDelay = 0
  RPGlobals.run.naturalTeleport      = false
  RPGlobals.run.usedTelepills        = false
  RPGlobals.run.giveExtraCharge      = false
  RPGlobals.run.blackRingTime        = 0
  RPGlobals.run.blackRingDropChance  = 0
  RPGlobals.run.consoleWindowOpen    = false
  RPGlobals.run.bossRushReturn       = -1 -- Used to fix a misc. bug with custom crawlspaces

  -- Boss hearts tracking
  RPGlobals.run.bossHearts = {
    spawn       = false,
    extra       = false,
    extraIsSoul = false,
    position    = {},
    velocity    = {},
  }

  -- Eden's Soul tracking
  RPGlobals.run.edensSoulSet     = false
  RPGlobals.run.edensSoulCharges = 0

  -- Trapdoor tracking
  RPGlobals.run.trapdoor = {
    state   = 0,
    upwards = false,
    floor   = 0,
    frame   = 0,
    scale   = Vector(0, 0),
  }

  -- Keeper + Greed's Gullet tracking
  RPGlobals.run.keeper = {
    baseHearts   = 4, -- Either 4 (for base), 2, 0, -2, -4, -6, etc.
    healthItems  = {},
    usedStrength = false,
    coins        = 50,
  }

  -- Schoolbag tracking
  RPGlobals.run.schoolbag = {
    item            = 0,
    charges         = 0,
    pressed         = false, -- Used for keeping track of whether the "Switch" button is held down or not
    lastCharge      = 0,     -- Used to keep track of the charges when we pick up a second active item
    lastRoomItem    = 0,     -- Used to prevent bugs with GLowing Hour Glass
    lastRoomCharges = 0,     -- Used to prevent bugs with GLowing Hour Glass
    nextRoomCharge  = false, -- Used to prevent bugs with GLowing Hour Glass
    bossRushActive  = false, -- Used for giving a charge when the Boss Rush starts
  }

  -- Soul Jar tracking
  RPGlobals.run.soulJarSouls = 0
end

function RPGlobals:IncrementRNG(seed)
  -- The game expects seeds in the range of 0 to 4294967295
  local rng = RNG()
  rng:SetSeed(seed, 35)
  -- This is the ShiftIdx that blcd recommended after having reviewing the game's internal functions
  rng:Next()
  local newSeed = rng:GetSeed()
  return newSeed
end

function RPGlobals:AddItemBanList(itemID)
  local inBanList = false
  for i = 1, #RPGlobals.raceVars.itemBanList do
    if RPGlobals.raceVars.itemBanList[i] == itemID then
      inBanList = true
      break
    end
  end
  if inBanList == false then
    RPGlobals.raceVars.itemBanList[#RPGlobals.raceVars.itemBanList + 1] = itemID
  end
end

function RPGlobals:AddTrinketBanList(trinketID)
  local inBanList = false
  for i = 1, #RPGlobals.raceVars.trinketBanList do
    if RPGlobals.raceVars.trinketBanList[i] == trinketID then
      inBanList = true
      break
    end
  end
  if inBanList == false then
    RPGlobals.raceVars.trinketBanList[#RPGlobals.raceVars.trinketBanList + 1] = trinketID
  end
end

function RPGlobals:GridToPos(x, y)
  local game = Game()
  local room = game:GetRoom()
  x = x + 1
  y = y + 1
  return room:GetGridPosition(y * room:GetGridWidth() + x)
end

-- Get a Config::Item from an collectible ID
-- from ilise rose (@yatboim)
-- (this will crash the game if fed an item ID of 0)
function RPGlobals:GetConfigItem(id)
    local player = Isaac.GetPlayer(0)
    player:GetEffects():AddCollectibleEffect(id, true)
    local effect = player:GetEffects():GetCollectibleEffect(id)
    player:GetEffects():RemoveCollectibleEffect(id)
    return effect.Item
end

-- From: http://lua-users.org/wiki/SimpleRound
function RPGlobals:Round(num, numDecimalPlaces)
  local mult = 10 ^ (numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Find out how many charges this item has
function RPGlobals:GetActiveCollectibleMaxCharges(itemID)
  local charges = 0

  if itemID == CollectibleType.COLLECTIBLE_KAMIKAZE or -- 40
     itemID == CollectibleType.COLLECTIBLE_RAZOR_BLADE or -- 126
     itemID == CollectibleType.COLLECTIBLE_GUPPYS_PAW or -- 133
     itemID == CollectibleType.COLLECTIBLE_IV_BAG or -- 135
     itemID == CollectibleType.COLLECTIBLE_REMOTE_DETONATOR or -- 137
     itemID == CollectibleType.COLLECTIBLE_PORTABLE_SLOT or -- 177
     itemID == CollectibleType.COLLECTIBLE_BLOOD_RIGHTS or -- 186
     itemID == CollectibleType.COLLECTIBLE_HOW_TO_JUMP or -- 282
     itemID == CollectibleType.COLLECTIBLE_THE_JAR or -- 290
     itemID == CollectibleType.COLLECTIBLE_MAGIC_FINGERS or -- 295
     itemID == CollectibleType.COLLECTIBLE_CONVERTER or -- 296
     itemID == CollectibleType.COLLECTIBLE_BLUE_BOX or -- 297
     itemID == CollectibleType.COLLECTIBLE_DIPLOPIA or -- 347
     itemID == CollectibleType.COLLECTIBLE_JAR_OF_FLIES or -- 434
     itemID == CollectibleType.COLLECTIBLE_MYSTERY_GIFT then -- 515

    charges = 0

  elseif itemID == CollectibleType.COLLECTIBLE_POOP or -- 36
       itemID == CollectibleType.COLLECTIBLE_TAMMYS_HEAD or -- 38
       itemID == CollectibleType.COLLECTIBLE_BEAN or -- 111
       itemID == CollectibleType.COLLECTIBLE_FORGET_ME_NOW or -- 127
       itemID == CollectibleType.COLLECTIBLE_GUPPYS_HEAD or -- 145
       itemID == CollectibleType.COLLECTIBLE_DEBUG or -- 235
       itemID == CollectibleType.COLLECTIBLE_D10 or -- 285
       itemID == CollectibleType.COLLECTIBLE_UNICORN_STUMP or -- 298
       itemID == CollectibleType.COLLECTIBLE_WOODEN_NICKEL or -- 349
       itemID == CollectibleType.COLLECTIBLE_TEAR_DETONATOR or -- 383
       itemID == CollectibleType.COLLECTIBLE_MINE_CRAFTER or -- 427
       itemID == CollectibleType.COLLECTIBLE_PLAN_C then -- 475

    charges = 1

  elseif itemID == CollectibleType.COLLECTIBLE_MR_BOOM or -- 37
         itemID == CollectibleType.COLLECTIBLE_TELEPORT or -- 44
         itemID == CollectibleType.COLLECTIBLE_DOCTORS_REMOTE or -- 47
         itemID == CollectibleType.COLLECTIBLE_SHOOP_DA_WHOOP or -- 49
         itemID == CollectibleType.COLLECTIBLE_LEMON_MISHAP or -- 56
         itemID == CollectibleType.COLLECTIBLE_HOURGLASS or -- 66
         itemID == CollectibleType.COLLECTIBLE_DEAD_SEA_SCROLLS or -- 124
         itemID == CollectibleType.COLLECTIBLE_SPIDER_BUTT or -- 171
         itemID == CollectibleType.COLLECTIBLE_DADS_KEY or -- 175
         itemID == CollectibleType.COLLECTIBLE_TELEPATHY_BOOK or -- 192
         itemID == CollectibleType.COLLECTIBLE_BOX_OF_SPIDERS or -- 288
         itemID == CollectibleType.COLLECTIBLE_SCISSORS or -- 325
         itemID == CollectibleType.COLLECTIBLE_KIDNEY_BEAN or -- 421
         itemID == CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS or -- 422
         itemID == CollectibleType.COLLECTIBLE_PAUSE or -- 478
         itemID == CollectibleType.COLLECTIBLE_COMPOST or -- 480
         itemID == CollectibleType.COLLECTIBLE_DULL_RAZOR or -- 486
         itemID == CollectibleType.COLLECTIBLE_METRONOME or -- 488
         itemID == CollectibleType.COLLECTIBLE_DINF then -- 489

    charges = 2

  elseif itemID == CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL or -- 34
         itemID == CollectibleType.COLLECTIBLE_MOMS_BRA or -- 39
         itemID == CollectibleType.COLLECTIBLE_MOMS_PAD or -- 41
         itemID == CollectibleType.COLLECTIBLE_BOBS_ROTTEN_HEAD or -- 42
         itemID == CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS or -- 58
         itemID == CollectibleType.COLLECTIBLE_ANARCHIST_COOKBOOK or -- 65
         itemID == CollectibleType.COLLECTIBLE_MONSTROS_TOOTH or -- 86
         itemID == CollectibleType.COLLECTIBLE_MONSTER_MANUAL or -- 123
         itemID == CollectibleType.COLLECTIBLE_BEST_FRIEND or -- 136
         itemID == CollectibleType.COLLECTIBLE_NOTCHED_AXE or -- 147
         itemID == CollectibleType.COLLECTIBLE_MEGA_BEAN or -- 351
         itemID == CollectibleType.COLLECTIBLE_FRIEND_BALL or -- 382
         itemID == CollectibleType.COLLECTIBLE_D12 or -- 386
         itemID == CollectibleType.COLLECTIBLE_D7 then -- 437

    charges = 3

  elseif itemID == CollectibleType.COLLECTIBLE_YUM_HEART or -- 45
         itemID == CollectibleType.COLLECTIBLE_BOOK_OF_SIN or -- 97
         itemID == CollectibleType.COLLECTIBLE_BOOK_OF_SIN_SEEDED or
         itemID == CollectibleType.COLLECTIBLE_PONY or -- 130
         itemID == CollectibleType.COLLECTIBLE_CRACK_THE_SKY or -- 160
         itemID == CollectibleType.COLLECTIBLE_BLANK_CARD or -- 286
         itemID == CollectibleType.COLLECTIBLE_PLACEBO or -- 348
         itemID == CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS or -- 357
         itemID == CollectibleType.COLLECTIBLE_D8 or -- 406
         itemID == CollectibleType.COLLECTIBLE_TELEPORT_2 or -- 419
         itemID == CollectibleType.COLLECTIBLE_MOMS_BOX or -- 439
         itemID == CollectibleType.COLLECTIBLE_D1 or -- 476
         itemID == CollectibleType.COLLECTIBLE_DATAMINER or -- 481
         itemID == CollectibleType.COLLECTIBLE_CROOKED_PENNY or -- 485
         itemID == CollectibleType.COLLECTIBLE_BLACK_HOLE or -- 512
         itemID == CollectibleType.COLLECTIBLE_SPRINKLER then -- 516

    charges = 4

  elseif itemID == CollectibleType.COLLECTIBLE_BIBLE or -- 33
         itemID == CollectibleType.COLLECTIBLE_NECRONOMICON or -- 35
         itemID == CollectibleType.COLLECTIBLE_MY_LITTLE_UNICORN or -- 77
         itemID == CollectibleType.COLLECTIBLE_BOOK_REVELATIONS or -- 78
         itemID == CollectibleType.COLLECTIBLE_THE_NAIL or -- 83
         itemID == CollectibleType.COLLECTIBLE_WE_NEED_GO_DEEPER or -- 84
         itemID == CollectibleType.COLLECTIBLE_DECK_OF_CARDS or -- 85
         itemID == CollectibleType.COLLECTIBLE_GAMEKID or -- 93
         itemID == CollectibleType.COLLECTIBLE_MOMS_BOTTLE_PILLS or -- 102
         itemID == CollectibleType.COLLECTIBLE_D6 or -- 105
         itemID == CollectibleType.COLLECTIBLE_PINKING_SHEARS or -- 107
         itemID == CollectibleType.COLLECTIBLE_PRAYER_CARD or -- 146
         itemID == CollectibleType.COLLECTIBLE_CRYSTAL_BALL or -- 158
         itemID == CollectibleType.COLLECTIBLE_CRYSTAL_BALL_SEEDED or
         itemID == CollectibleType.COLLECTIBLE_D20 or -- 166
         itemID == CollectibleType.COLLECTIBLE_WHITE_PONY or -- 181
         itemID == CollectibleType.COLLECTIBLE_D100 or -- 283
         itemID == CollectibleType.COLLECTIBLE_D4 or -- 284
         itemID == CollectibleType.COLLECTIBLE_BOOK_OF_SECRETS or -- 287
         itemID == CollectibleType.COLLECTIBLE_FLUSH or -- 291
         itemID == CollectibleType.COLLECTIBLE_SATANIC_BIBLE or -- 292
         itemID == CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS or -- 293
         itemID == CollectibleType.COLLECTIBLE_ISAACS_TEARS or -- 323
         itemID == CollectibleType.COLLECTIBLE_UNDEFINED or -- 324
         itemID == CollectibleType.COLLECTIBLE_BREATH_OF_LIFE or -- 326
         itemID == CollectibleType.COLLECTIBLE_VOID or -- 477
         itemID == CollectibleType.COLLECTIBLE_SMELTER or -- 479
         itemID == CollectibleType.COLLECTIBLE_SMELTER_LOGGER or
         itemID == CollectibleType.COLLECTIBLE_CLICKER then -- 482

    charges = 6

  elseif itemID == CollectibleType.COLLECTIBLE_MEGA_SATANS_BREATH or -- 441
     itemID == CollectibleType.COLLECTIBLE_EDENS_SOUL or -- 490
     itemID == CollectibleType.COLLECTIBLE_DELIRIOUS then -- 510

    charges = 12

  elseif itemID == CollectibleType.COLLECTIBLE_BOOMERANG then -- 338
    charges = 70

  elseif itemID == CollectibleType.COLLECTIBLE_BUTTER_BEAN then -- 294
    charges = 90

  elseif itemID == CollectibleType.COLLECTIBLE_CANDLE or -- 164
         itemID == CollectibleType.COLLECTIBLE_RED_CANDLE or -- 289
         itemID == CollectibleType.COLLECTIBLE_GLASS_CANNON then -- 352

    charges = 110

  elseif itemID == CollectibleType.COLLECTIBLE_BROWN_NUGGET then -- 504
    charges = 250

  elseif itemID == CollectibleType.COLLECTIBLE_WAIT_WHAT or -- 484
         itemID == CollectibleType.COLLECTIBLE_SHARP_STRAW then -- 507

    charges = 300
  end

  return charges
end

-- This is not named GetStageType to differentiate it from "level:GetStageType"
function RPGlobals:DetermineStageType(stage)
  -- Local variables
  local game = Game()
  local seeds = game:GetSeeds()
  local stageSeed = seeds:GetStageSeed(stage)

  -- Based on the game's internal code (from Spider)
  --[[
    u32 Seed = g_Game->GetSeeds().GetStageSeed(NextStage);
    if (!g_Game->IsGreedMode()) {
      StageType = ((Seed % 2) == 0 && (
        ((NextStage == STAGE1_1 || NextStage == STAGE1_2) && gd.Unlocked(ACHIEVEMENT_CELLAR)) ||
        ((NextStage == STAGE2_1 || NextStage == STAGE2_2) && gd.Unlocked(ACHIEVEMENT_CATACOMBS)) ||
        ((NextStage == STAGE3_1 || NextStage == STAGE3_2) && gd.Unlocked(ACHIEVEMENT_NECROPOLIS)) ||
        ((NextStage == STAGE4_1 || NextStage == STAGE4_2)))
      ) ? STAGETYPE_WOTL : STAGETYPE_ORIGINAL;
    if (Seed % 3 == 0 && NextStage < STAGE5)
      StageType = STAGETYPE_AFTERBIRTH;
  --]]
  local stageType = StageType.STAGETYPE_ORIGINAL -- 0
  if stageSeed & 1 == 0 then -- This is the same as "stageSeed % 2 == 0", but faster
    stageType = StageType.STAGETYPE_WOTL -- 1
  end
  if stageSeed % 3 == 0 then
    stageType = StageType.STAGETYPE_AFTERBIRTH -- 2
  end

  return stageType
end

-- Remove the long fade out / fade in when entering trapdoors (3/4)
function RPGlobals:GotoNextFloor(upwards)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stageType = level:GetStageType()
  local roomIndexUnsafe = level:GetCurrentRoomIndex()

  local stage = RPGlobals.run.currentFloor
  -- We use this instead of "level:GetStage()" so that we can divert the player from going to the Dark Room

  -- Build the command
  local stageCommand
  if roomIndexUnsafe == GridRooms.ROOM_BLUE_WOOM_IDX then -- -8
    stageCommand = "stage 9" -- Blue Womb
  elseif stage == 8 then -- Account for Womb 2
    if upwards then
      stageCommand = "stage 10a" -- Cathedral
    else
      stageCommand = "stage 10" -- Sheol
    end

  elseif stage == 10 and stageType == 0 then
    stageCommand = "stage 11" -- Dark Room

  elseif stage == 10 and stageType == 1 then
    stageCommand = "stage 11a" -- The Chest

  else
    local nextStage = stage + 1
    stageCommand = "stage " .. tostring(nextStage) -- By default, we go to the non-alternate version of the floor
    local newStageType = RPGlobals:DetermineStageType(nextStage)
    if newStageType == 1 then
      stageCommand = stageCommand .. "a"
    elseif newStageType == 2 then
      stageCommand = stageCommand .. "b"
    end
  end

  Isaac.ExecuteCommand(stageCommand)
end

-- This is used for the Victory Lap feature that spawns multiple bosses
RPGlobals.bossArray = {
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
}

return RPGlobals

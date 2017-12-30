local RPGlobals  = {}

--
-- Global variables
--

RPGlobals.version = "v0.14.27"
RPGlobals.corrupted = false -- Checked in the MC_POST_GAME_STARTED callback
RPGlobals.debug = false

-- These are variables that are reset at the beginning of every run
-- (defaults are set below in the "RPGlobals:InitRun()" function)
RPGlobals.run = {}

-- This is the table that gets updated from the "save.dat" file
RPGlobals.race = {
  status          = "none",      -- Can be "none", "open", "starting", "in progress"
  myStatus        = "not ready", -- Can be either "not ready", "ready", or "racing"
  ranked          = false,       -- Can be true or false
  solo            = false,       -- Can be true or false
  rFormat         = "unseeded",  -- Can be "unseeded", "seeded", "diversity", "unseeded-lite", or "custom"
  -- Unofficially this can also be "pageant"
  character       = 3,           -- 3 is Judas; can be 0 to 15 (the "PlayerType" Lua enumeration)
  goal            = "Blue Baby", -- Can be "Blue Baby", "The Lamb", "Mega Satan", or "Everything"
  seed            = "-",         -- Corresponds to the seed that is the race goal
  startingItems   = {},          -- The starting items for this race
  countdown       = -1,          -- This corresponds to the graphic to draw on the screen
  placeMid        = 0,           -- This is either the number of people ready, or the non-fnished place
  place           = 1,           -- This is the final place
  numEntrants     = 1,           -- The number of people in the race
  order7          = {0},         -- The order for a Racing+ 7 character speedrun
  order9          = {0},         -- The order for a Racing+ 9 character speedrun
  order14         = {0},         -- The order for a Racing+ 14 character speedrun
}
-- (unofficially, this can also have "timer = false")

-- These are things that pertain to the race but are not read from the "save.dat" file
RPGlobals.raceVars = {
  loadOnNextFrame    = false,
  challenge          = 0,
  resetEnabled       = true,
  started            = false,
  startedTime        = 0,
  finished           = false,
  finishedTime       = 0,
  showPlaceGraphic   = false,
  fireworks          = 0,
  victoryLaps        = 0,
}

RPGlobals.RNGCounter = {
  BookOfSin     = 0,
  Teleport      = 0, -- Broken Remote also uses this
  Undefined     = 0,
  Telepills     = 0,
}

--
-- Extra enumerations
--

-- Collectibles
-- (unused normal item IDs are: 43, 59, 61, 235, 263)
CollectibleType.COLLECTIBLE_BETRAYAL_NOANIM         = Isaac.GetItemIdByName("Betrayal") -- Replacing 391
CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM        = Isaac.GetItemIdByName("Schoolbag")
CollectibleType.COLLECTIBLE_SOUL_JAR                = Isaac.GetItemIdByName("Soul Jar")
CollectibleType.COLLECTIBLE_TROPHY                  = Isaac.GetItemIdByName("Trophy")
CollectibleType.COLLECTIBLE_VICTORY_LAP             = Isaac.GetItemIdByName("Victory Lap")
CollectibleType.COLLECTIBLE_FINISHED                = Isaac.GetItemIdByName("Finished")
CollectibleType.COLLECTIBLE_OFF_LIMITS              = Isaac.GetItemIdByName("Off Limits")
CollectibleType.COLLECTIBLE_13_LUCK                 = Isaac.GetItemIdByName("13 Luck")
CollectibleType.COLLECTIBLE_CHECKPOINT              = Isaac.GetItemIdByName("Checkpoint")
CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1 = Isaac.GetItemIdByName("Diversity Placeholder #1")
CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2 = Isaac.GetItemIdByName("Diversity Placeholder #2")
CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3 = Isaac.GetItemIdByName("Diversity Placeholder #3")
CollectibleType.COLLECTIBLE_DEBUG                   = Isaac.GetItemIdByName("Debug")
CollectibleType.NUM_COLLECTIBLES                    = Isaac.GetItemIdByName("Debug") + 1

-- Pills
PillEffect.PILLEFFECT_GULP_LOGGER = Isaac.GetPillEffectByName("Gulp!") -- 47
PillEffect.NUM_PILL_EFFECTS       = Isaac.GetPillEffectByName("Gulp!") + 1

-- Sounds
SoundEffect.SOUND_SPEEDRUN_FINISH = Isaac.GetSoundIdByName("Speedrun Finish")
SoundEffect.NUM_SOUND_EFFECTS     = Isaac.GetSoundIdByName("Speedrun Finish") + 1

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
  TRANSITION_MISSING_POSTER    = 14,
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
  RPGlobals.run.startedTime       = 0
  RPGlobals.run.roomsEntered      = 0
  RPGlobals.run.movingBoxOpen     = true
  RPGlobals.run.killedLamb        = false -- Used for the "Everything" race goal
  RPGlobals.run.removeMoreOptions = false -- Used to give only one double item Treasure Room

  -- Tracking per floor
  RPGlobals.run.currentFloor        = 0
  -- (start at 0 so that we can trigger the PostNewRoom callback after the PostNewLevel callback)
  RPGlobals.run.currentFloorType    = 0 -- We need to track this because we can go from Cathedral to Sheol, for example
  RPGlobals.run.levelDamaged        = false
  RPGlobals.run.replacedPedestals   = {}
  RPGlobals.run.replacedTrapdoors   = {}
  RPGlobals.run.replacedCrawlspaces = {}
  RPGlobals.run.replacedHeavenDoors = {}

  -- Tracking per room
  RPGlobals.run.currentRoomClearState = true
  RPGlobals.run.currentGlobins        = {} -- Used for softlock prevention
  RPGlobals.run.currentKnights        = {} -- Used to delete invulnerability frames
  RPGlobals.run.currentHaunts         = {} -- Used to speed up Lil' Haunts
  RPGlobals.run.currentLilHaunts      = {} -- Used to delete invulnerability frames
  RPGlobals.run.currentHoppers        = {} -- Used to prevent softlocks
  RPGlobals.run.handsDelay            = 0
  RPGlobals.run.naturalTeleport       = false
  RPGlobals.run.megaSatanDead         = false
  RPGlobals.run.dopleRoom             = false

  -- Temporary tracking
  RPGlobals.run.restartFrame         = 0 -- If set, tells the mod to restart the run on that frame
  RPGlobals.run.itemReplacementDelay = 0 -- Set when Void is used
  RPGlobals.run.usedTelepills        = false
  RPGlobals.run.giveExtraCharge      = false -- Used to fix The Battery + 9 Volt synergy
  RPGlobals.run.consoleWindowOpen    = false -- We don't want to do a fast-reset if the console window is open
  RPGlobals.run.droppedButterItem    = 0 -- Needed to fix a bug with the Schoolbag and the Butter! trinket
  RPGlobals.run.fastResetFrame       = 0 -- Set when the user presses the reset button on the keyboard
  RPGlobals.run.teleportSubverted    = false -- Used for repositioning the player on It Lives! / Gurdy (1/2)
  RPGlobals.run.teleportSubvertScale = Vector(1, 1) -- Used for repositioning the player on It Lives! / Gurdy (2/2)
  RPGlobals.run.dualityCheckFrame    = 0
  RPGlobals.run.changeFartColor      = false
  RPGlobals.run.replaceBuggedScolex  = 0
  -- Equal to the game frame number with which to replace Scolex, or 0 for disabled
  RPGlobals.run.theLambLockedPos     = nil -- Used to prevent unavoidable damage on The Lamb
  RPGlobals.run.spawnedPhotos        = false -- Used when replacing The Polaroid and The Negative (1/2)
  RPGlobals.run.spawningPhoto        = false -- Used when replacing The Polaroid and The Negative (2/2)
  RPGlobals.run.spawningKrampusItem  = false -- Used for spawning Krampus items early
  RPGlobals.run.spawningKeyPiece     = false -- Used for spawning Key Piece 1 or Key Piece 2 early
  RPGlobals.run.mysteryGiftFrame     = 0 -- Used so that we don't delete A Lump of Coal from a Mystery Gift
  RPGlobals.run.itLivesKillFrame     = 0 -- Used to delete the trapdoor and beam of light after It Lives! and Hush
  RPGlobals.run.speedLilHauntsFrame  = 0 -- Used to speed up The Haunt fight (1/2)
  RPGlobals.run.speedLilHauntsBlack  = false -- Used to speed up The Haunt fight (2/2)
  RPGlobals.run.rechargeItemFrame    = 0 -- Used to recharge the D6 / Void after a failed attempt
  RPGlobals.run.killAttackFly        = false -- Used to prevent a bug with trapdoors/crawlspaces and Corny Poop

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
    state     = 0,
    upwards   = false,
    floor     = 0,
    frame     = 0,
    scale     = Vector(0, 0),
  }

  -- Crawlspace tracking
  RPGlobals.run.crawlspace = {
    prevRoom    = 0,
    direction   = -1, -- Used to fix nested room softlocks
    blackMarket = false,
  }

  -- Keeper + Greed's Gullet tracking
  RPGlobals.run.keeper = {
    baseHearts       = 4, -- Either 4 (for base), 2, 0, -2, -4, -6, etc.
    healthUpItems    = {},
    coins            = 50,
    usedStrength     = false,
    usedHealthUpPill = false,
  }
  for i = 1, #RPGlobals.healthUpItems do
    local itemID = RPGlobals.healthUpItems[i]
    RPGlobals.run.keeper.healthUpItems[itemID] = 0
  end

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

  -- Special death handling for seeded races
  RPGlobals.run.seededDeath = {
    state = 0,
    -- 0 is not dead, 1 is during the death animation, 2 is during the AppearVanilla animation, 3 is during the debuff
    pos      = Vector(0, 0),
    time     = 0,
    items    = {},
    charge   = 0,
    dealTime = Isaac.GetTime(),
  }
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

function RPGlobals:GridToPos(x, y)
  local game = Game()
  local room = game:GetRoom()
  x = x + 1
  y = y + 1
  return room:GetGridPosition(y * room:GetGridWidth() + x)
end

-- From: http://lua-users.org/wiki/SimpleRound
function RPGlobals:Round(num, numDecimalPlaces)
  local mult = 10 ^ (numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function RPGlobals:TableEqual(table1, table2)
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
function RPGlobals:TableValToStr(v)
  if "string" == type(v) then
    v = string.gsub(v, "\n", "\\n")
    if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v, '"', '\\"') .. '"'
  else
    return "table" == type(v) and RPGlobals.TableToString(v) or tostring(v)
  end
end

function RPGlobals:TableKeyToStr(k)
  if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
    return k
  else
    return "[" .. RPGlobals:TableValToStr(k) .. "]"
  end
end

function RPGlobals:TableToString(tbl)
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert(result, RPGlobals:TableValToStr(v))
    done[k] = true
  end
  for k, v in pairs(tbl) do
    if not done[k] then
      table.insert(result, RPGlobals:TableKeyToStr(k) .. "=" .. RPGlobals:TableValToStr(v))
    end
  end
  return "{" .. table.concat(result, ",") .. "}"
end

-- From: http://lua-users.org/wiki/CopyTable
function RPGlobals:TableClone(tbl)
  return {table.unpack(tbl)}
end

-- Find out how many charges this item has
function RPGlobals:GetItemMaxCharges(itemID)
  -- Local variables
  local itemConfig = Isaac.GetItemConfig()

  if itemID == 0 then
    return 0
  else
    return itemConfig:GetCollectible(itemID).MaxCharges
  end
end

function RPGlobals:ExecuteCommand(command)
  Isaac.ExecuteCommand(command)
  Isaac.DebugString("Executed command: " .. command)
end

function RPGlobals:InsideSquare(pos1, pos2, squareSize)
  if pos1.X >= pos2.X - squareSize and
     pos1.X <= pos2.X + squareSize and
     pos1.Y >= pos2.Y - squareSize and
     pos1.Y <= pos2.Y + squareSize then

    return true
  else
    return false
  end
end

-- From the ProAPI
function RPGlobals:RevivePlayer(item)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)

  player:Revive()
  if item then
      if type(item) == "table" and item.ID ~= nil then
          item = item.ID
      end
      local d = player:GetData()
      d.api_HoldingItem = item
      d.api_HoldingFrame = 0
  end
  local enterDoor = level.EnterDoor
  local door = room:GetDoor(enterDoor)
  local direction = door and door.Direction or Direction.NO_DIRECTION
  game:StartRoomTransition(level:GetPreviousRoomIndex(),direction,0)
  level.LeaveDoor = enterDoor
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

-- Used to fix Greed's Gullet bugs
RPGlobals.healthUpItems = {
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

return RPGlobals

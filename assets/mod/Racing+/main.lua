--
-- The Racing+ Lua Mod
-- by Zamiel
--

--[[

TODO:
- put on Steam
- forget me now after killing boss, go back to B1
- recode greed's gullet
- fix shop rolling bug - https://clips.twitch.tv/dea1h/WonderfulHornetRaccAttack
- megasatan
- add more doors to more boss rooms where appropriate to make duality better
- remove void portal pngs
- Add trophy for finish, add fireworks for first place: https://www.reddit.com/r/bindingofisaac/comments/5r4vmb/spawn_1000104/
- fix master of Potato softlock with Poly + Epic Fetus (Globin)
- Fix unseeded Boss heart drops from Pin, etc. (and make it so that they drop during door opening)
- Integrate 1st place, 2nd place, etc.
- Fix Dead Eye on poop
- Change Troll Bombs and Mega Troll Bombs fuse timer to Rebirth-style
- Make Devil / Angel Rooms given in order and independent of floor

ROOMS TODO:
- Womb/Utero #825 - https://gyazo.com/86396e78c14372ef5470e33b619a0976
  - Remove entire bottom row of Nerve Endings
- Caves/Catacombs room #914 - 
  - 1 Row of pits at the bottom, + 3 squares of pits on 2nd row from bottom
- Fatty room with like 30 fatties????
- Depths/Necropolis #863 - 
  - Fix fires to always be non-red fires
  - Make space for Mr. Mega
- Sheol #255
  - Delete?
  - 251.10.0
- Sheol Greed Move #31, #32, #58
  - 251.10.0
- Move TNT barrels in Treasure Room still
- Move TNT barrels in Haunt Boss Room
- Fix door in room #208 Caves
- Slightly move Hive upward in room #519 Caves
- Test Ragman room on Basement in narrow room
- Catacombs #854 - 12 Pale Fatties (and close to entrance, explode unavoidable?)
- Catacombs #843 - 11 Pale Fatties
- rerun XML script finder to find all out of bounds entities
- run XML script finder to find all rooms with all doors disabled
- Copy over Afterbirth room changes after the next patch

TODO CAN'T FIX:
- Automatically enable BLCK CNDL seed (not possible with current bindings)
- Automatically enter in a seed for seeded races (not possible with current bindings)
- Make timer on the screen use real time
- Do item bans in a proper way via editing item pools (not possible to modify item pools via current bindings)
  - When spawning an item via the console (like "spawn 5.100.12"), it removes it from item pools.
  - When spawning a specific item with Lua (like "game:Spawn(5, 100, Vector(300, 300), Vector(0, 0), nil, 12, 0)"), it does not remove it from any pools.
  - When spawning a random item with Lua (like "game:Spawn(5, 100, Vector(300, 300), Vector(0, 0), nil, 0, 0)"), it removes it from item pools.
  - When giving the player an item with Lua (like "player:AddCollectible(race.startingItems[i], 12, true)"), it does not remove it from any pools.
- Make Teleport / Undefined / Cursed Eye / Telepills seeded (the ChangeRoom() function is broken and doesn't actually consistently send you to the room that you specify)
- Be able to skip specific champions from the fast-clear check (not possible to detect what type of champion it is with the current bindings)
- Skip the fade in and fade out animation when traveling to the next floor (need console access or the "StartStageTransition()" second argument to be working)
- Stop the player from being teleported upon entering a room with Gurdy, Mom's Heart, or It Lives (Isaac is placed in the location and you can't move him fast enough)

--]]

-- Register the mod (the second argument is the API version)
local RacingPlus = RegisterMod("Racing+", 1);

-- Global variables
local run = {
  initializing          = false,
  roomsCleared          = 0,
  roomsEntered          = 0,
  roomEntering          = false,
  currentFloor          = 1,
  currentRoomClearState = true,
  replacedItems         = {},
  replacedTrinkets      = {}
}
local race = { -- The table that gets updated from the "save.dat" file
  status          = "none",      -- Can be "none", "open", "starting", "in progress"
  rType           = "unranked",  -- Can be "unranked", "ranked" (this is not currently used)
  rFormat         = "unseeded",  -- Can be "unseeded", "seeded", "diveristy", "custom"
  character       = "Judas",     -- Can be the name of any character
  goal            = "Blue Baby", -- Can be "Blue Baby", "The Lamb", "Mega Satan"
  seed            = "-",         -- Corresponds to the seed that is the race goal
  startingItems   = {},          -- The starting items for this race
  currentSeed     = "-",         -- The seed of our current run (detected through the "log.txt" file)
  countdown       = -1           -- This corresponds to the graphic to draw on the screen
}
local raceVars = { -- Things that pertain to the race but are not read from the "save.dat" file
  blckCndlOn                    = false,
  difficulty                    = 0,
  character                     = "Isaac",
  itemBanList                   = {},
  trinketBanList                = {},
  hourglassUsed                 = false,
  skipInit                      = false,
  checkForNewRoomAfterHourglass = false,
  started                       = false,
  startedTime                   = 0
}
local RNGCounter = {
  InitialSeed,
  BookOfSin,
  Teleport,
  Undefined,
  SackOfPennies,
  BombBag,
  JuicySack,
  MysterySack,
  LilChest,
  RuneBag,
  AcidBaby,
  SackOfSacks
}
local spriteTable = {}

-- Welcome banner
Isaac.DebugString("+----------------------+")
Isaac.DebugString("| Racing+ initialized. |")
Isaac.DebugString("+----------------------+")

---
--- Table subroutines
--- From: http://lua-users.org/wiki/TableUtils
---

function tableval_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and tabletostring( v ) or
      tostring( v )
  end
end

function tablekey_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. tableval_to_str( k ) .. "]"
  end
end

function tabletostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, tableval_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        tablekey_to_str( k ) .. "=" .. tableval_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

--
-- Math subroutines
--

-- From: http://lua-users.org/wiki/SimpleRound
function round(num, numDecimalPlaces)
  local mult = 10 ^ (numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

--
-- Sprite subroutines
--

function spriteInit(spriteType, spriteName)
  -- If this is a new sprite type, initialize it in the sprite table
  if spriteTable[spriteType] == nil then
    spriteTable[spriteType] = {}
  end

  -- Do nothing if this sprite type is already set to this name
  if spriteTable[spriteType].spriteName == spriteName then
    return
  end

  -- Check to see if we are clearing this sprite
  if spriteName == 0 then
    spriteTable[spriteType].sprite = nil
    spriteTable[spriteType].spriteName = 0
    return
  end

  -- Otherwise, initialize the sprite
  spriteTable[spriteType].sprite = Sprite()
  spriteTable[spriteType].sprite:Load("gfx/race/" .. spriteName .. ".anm2", true) -- The second argument is "LoadGraphics"
  spriteTable[spriteType].spriteName = spriteName
end

-- Call this every frame in MC_POST_RENDER
function spriteDisplay()
  -- Local variables
  local game = Game();
  local room = game:GetRoom();

  -- Loop through all the sprites and render them
  for k, v in pairs(spriteTable) do
    local vec = Vector(0, 0)
    if k == "top" then
      -- Make it be a little bit higher than the center of the screen
      vec = Isaac.WorldToRenderPosition(room:GetCenterPos(), false) -- The second argument is "ToRound"
      vec.Y = vec.Y - 80 -- Move it upwards from the center
    elseif k == "clock" then
      vec.X = 7.5 -- Move it below the Angel chance
      vec.Y = 217.0
    end
    if v.sprite ~= nil then
      spriteTable[k].sprite:SetFrame("Default", 0)
      spriteTable[k].sprite:RenderLayer(0, vec)
    end
  end
end

function timerUpdate()
  if raceVars.startedTime == 0 then
    return
  end

  local elapsedFrames = Isaac:GetFrameCount() - raceVars.startedTime
  local elapsedTime = elapsedFrames * 0.017

  local minutes = math.floor(elapsedTime / 60)
  if minutes < 10 then
    minutes = "0" .. tostring(minutes)
  else
    minutes = tostring(minutes)
  end
  
  local seconds = elapsedTime % 60
  seconds = round(seconds, 1)
  if seconds < 10 then
    seconds = "0" .. tostring(seconds)
  else
    seconds = tostring(seconds)
  end

  local timerString = minutes .. ':' .. seconds
  Isaac.RenderText(timerString, 17, 211, 0.7, 1.8, 0.2, 1.0) -- X, Y, R, G, B, A
end

---
--- Misc. subroutines
---

function incrementRNG(seed)
  -- The initial RNG value recieved from the B1 floor RNG is a 10 digit integer
  -- So let's just continue to work with integers that are roughly in this range
  math.randomseed(seed)
  return math.random(1, 9999999999)
end

function readServer()
  -- The server will write data for us to the "save.dat" file in the mod subdirectory
  -- From: https://www.reddit.com/r/themoddingofisaac/comments/5q3ml0/tutorial_saving_different_moddata_for_each_run/

  oldRace = race
  race = load("return " .. Isaac.LoadModData(RacingPlus))() -- This loads the "save.dat" file
  -- If the loading failed (which it seems to do sometimes), try again until it succeeds
  while race == nil do
    race = load("return " .. Isaac.LoadModData(RacingPlus))()
  end

  -- If anything changed, write it to the log
  --[[
  if oldRace.status ~= race.status then
    Isaac.DebugString("ModData status changed: " .. race.status)
  end
  if oldRace.rType ~= race.rType then
    Isaac.DebugString("ModData rType changed: " .. race.rType)
  end
  if oldRace.rFormat ~= race.rFormat then
    Isaac.DebugString("ModData rFormat changed: " .. race.rFormat)
  end
  if oldRace.character ~= race.character then
    Isaac.DebugString("ModData character changed: " .. race.character)
  end
  if oldRace.goal ~= race.goal then
    Isaac.DebugString("ModData goal changed: " .. race.goal)
  end
  if oldRace.seed ~= race.seed then
    Isaac.DebugString("ModData seed changed: " .. race.seed)
  end
  if #oldRace.startingItems ~= #race.startingItems then
    Isaac.DebugString("ModData startingItems amount changed: " .. tostring(#race.startingItems))
  end
  if oldRace.currentSeed ~= race.currentSeed then
    Isaac.DebugString("ModData currentSeed changed: " .. race.currentSeed)
  end
  if oldRace.countdown ~= race.countdown then
    Isaac.DebugString("ModData countdown changed: " .. tostring(race.countdown))
  end
  --]]
end

-- This is done when a run is started and after the Glowing Hourglass is used
function characterInit()
  -- Local variables
  local game = Game()
  local player = Game():GetPlayer(0)
  local playerType = player:GetPlayerType()

  -- Do character-specific actions
  if playerType == PlayerType.PLAYER_JUDAS then -- 3
    -- Decrease his red hearts
    player:AddHearts(-1)

  elseif playerType == PlayerType.PLAYER_EVE then
    -- Remove the existing items (they need to be in "players.xml" so that they get removed from item pools)
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_D6) -- 105
    Isaac.DebugString("Removing collectible " .. tostring(CollectibleType.COLLECTIBLE_D6))
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON) -- 122
    Isaac.DebugString("Removing collectible " .. tostring(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON))
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_DEAD_BIRD) -- 117
    Isaac.DebugString("Removing collectible " .. tostring(CollectibleType.COLLECTIBLE_DEAD_BIRD))
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_RAZOR_BLADE) -- 126
    Isaac.DebugString("Removing collectible " .. tostring(CollectibleType.COLLECTIBLE_RAZOR_BLADE))

    -- Add the D6, Whore of Babylon, and Dead Bird
    player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, true) -- 105
    player:AddCollectible(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON, 0, true) -- 122
    player:AddCollectible(CollectibleType. COLLECTIBLE_DEAD_BIRD, 0, true) -- 117

  elseif playerType == PlayerType.PLAYER_AZAZEL then
    -- Decrease his red hearts
    player:AddHearts(-1)

  elseif playerType == PlayerType.PLAYER_EDEN then
    -- Swap the random active item with the D6
    local activeItem = player:GetActiveItem()
    player:RemoveCollectible(activeItem)
    Isaac.DebugString("Removing collectible " .. tostring(activeItem))
    player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, true) -- 105

    -- It would be nice to remove and re-add the passive item so that it appears in the correct order with the D6 first
    -- However, if the passive gives pickups (on the ground), then it would give double

  elseif playerType == PlayerType.PLAYER_KEEPER then
    -- Remove the existing items (they need to be in "players.xml" so that they get removed from item pools)
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_D6) -- 105
    Isaac.DebugString("Removing collectible " .. tostring(CollectibleType.COLLECTIBLE_D6))
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET) -- 501
    Isaac.DebugString("Removing collectible " .. tostring(CollectibleType.COLLECTIBLE_GREEDS_GULLET))
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_DUALITY) -- 498
    Isaac.DebugString("Removing collectible " .. tostring(CollectibleType.COLLECTIBLE_DUALITY))
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_WOODEN_NICKEL) -- 349
    Isaac.DebugString("Removing collectible " .. tostring(CollectibleType.COLLECTIBLE_WOODEN_NICKEL))

    -- Add the D6, Greed's Gullet, and Duality
    player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, true) -- 105
    player:AddCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET, 0, true) -- 501
    player:AddCollectible(CollectibleType.COLLECTIBLE_DUALITY, 0, true) -- 498

    -- Grant an extra coin/heart container
    player:AddCoins(24) -- Keeper starts with 1 coin so we only need to give 24
    player:AddCoins(1) -- This fills in the new heart container
  end
end

-- This is done either after using the glowing hourglass or if reset in the middle of the run
function giveStartingItems()
  -- Local varaibles
  local game = Game()
  local player = game:GetPlayer(0)
  local inBanList

  -- Give the player their starting items, if any
  for i = 1, #race.startingItems do
    -- Send a message to the item tracker to remove this item
    -- (otherwise, since we are using Glowing Hourglass, it will record two of them)
    Isaac.DebugString("Removing collectible " .. tostring(race.startingItems[i]))

    -- 12 is the maximum amount of charges that any item can have
    player:AddCollectible(race.startingItems[i], 12, true) -- The second argument is "AddConsumables"

    -- Giving the player the item does not actually remove it from any of the pools, so we have to expliticly add it to the ban list
    addItemBanList(race.startingItems[i])
  end

  -- Add item bans for seeded mode
  if race.rFormat == "seeded" then
    addItemBanList(CollectibleType.COLLECTIBLE_TELEPORT) -- 44
    addItemBanList(CollectibleType.COLLECTIBLE_UNDEFINED) -- 324
    addTrinketBanList(TrinketType.TRINKET_CAINS_EYE) -- 59
  end
end

function addItemBanList(itemID)
  local inBanList = false
  for i = 1, #raceVars.itemBanList do
    if raceVars.itemBanList[i] == itemID then
      inBanList = true
      break
    end
  end
  if inBanList == false then
    raceVars.itemBanList[#raceVars.itemBanList + 1] = itemID
  end
end

function addTrinketBanList(trinketID)
  local inBanList = false
  for i = 1, #raceVars.trinketBanList do
    if raceVars.trinketBanList[i] == trinketID then
      inBanList = true
      break
    end
  end
  if inBanList == false then
    raceVars.trinketBanList[#raceVars.trinketBanList + 1] = trinketID
  end
end

--
-- Main functions
--

-- Called when starting a new run
function RacingPlus:RunInit()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local player = game:GetPlayer(0)
  local seed = level:GetDungeonPlacementSeed()

  -- Reset some global variables that we keep track of per run
  run.roomsCleared = 0
  run.roomsEntered = 0
  run.roomEntering = false
  run.currentFloor = 0
  run.currentRoomClearState = true
  run.replacedItems = {}
  run.replacedTrinkets = {}

  -- Reset some race variables that we keep track of per run
  raceVars.itemBanList = {}
  raceVars.trinketBanList = {}
  raceVars.hourglassUsed = false
  raceVars.checkForNewRoomAfterHourglass = false

  -- Reset some RNG counters to the floor RNG of B1 for this seed
  -- (future drops will be based on the RNG from this initial random value)
  RNGCounter.InitialSeed = seed
  RNGCounter.BookOfSin = seed
  RNGCounter.SackOfPennies = seed
  RNGCounter.BombBag = seed
  RNGCounter.JuicySack = seed
  RNGCounter.MysterySack = seed
  RNGCounter.LilChest = seed
  RNGCounter.RuneBag = seed
  RNGCounter.AcidBaby = seed
  RNGCounter.SackOfSacks = seed

  -- Check to see if we are on the BLCK CNDL Easter Egg
  level:AddCurse(LevelCurse.CURSE_OF_THE_CURSED, false) -- The second argument is "ShowName"
  local curses = level:GetCurses()
  if curses == 0 then
    raceVars.blckCndlOn = true
  else
    raceVars.blckCndlOn = false

    -- The client assumes that it is on by default, so it only needs to be alerted for the negative case
    Isaac.DebugString("BLCK CNDL off.")
  end
  level:RemoveCurse(LevelCurse.CURSE_OF_THE_CURSED)

  -- Check to see if we are on normal mode or hard mode
  raceVars.difficulty = game.Difficulty
  Isaac.DebugString("Difficulty: " .. tostring(game.Difficulty))

  -- Check what character we are on
  local playerType = player:GetPlayerType()
  if playerType == 0 then
    raceVars.character = "Isaac"
  elseif playerType == 1 then
    raceVars.character = "Magdalene"
  elseif playerType == 2 then
    raceVars.character = "Cain"
  elseif playerType == 3 then
    raceVars.character = "Judas"
  elseif playerType == 4 then
    raceVars.character = "Blue Baby"
  elseif playerType == 5 then
    raceVars.character = "Eve"
  elseif playerType == 6 then
    raceVars.character = "Samson"
  elseif playerType == 7 then
    raceVars.character = "Azazel"
  elseif playerType == 8 then
    raceVars.character = "Lazarus"
  elseif playerType == 9 then
    raceVars.character = "Eden"
  elseif playerType == 10 then
    raceVars.character = "The Lost"
  elseif playerType == 13 then
    raceVars.character = "Lilith"
  elseif playerType == 14 then
    raceVars.character = "Keeper"
  elseif playerType == 15 then
    raceVars.character = "Apollyon"
  end

  -- Give us custom racing items, depending on the character (mostly just the D6)
  characterInit()

  -- Log the run beginning
  Isaac.DebugString("A new run has begun.")

  -- Update our race table
  readServer()

  -- If we are not in a race, don't do anything special
  if race.status == "none" then
    return
  end

  -- Validate BLCK CNDL for races
  if raceVars.blckCndlOn == false then
    Isaac.DebugString("Race error: BLCK CNDL not enabled.")
    return
  end

  -- Validate difficulty (hard mode) for races
  if raceVars.difficulty ~= 0 then
    Isaac.DebugString("Race error: On the wrong difficulty (hard mode or Greed mode).")
    return
  end

  -- Validate character for races
  if raceVars.character ~= race.character then
    Isaac.DebugString("Race error: On the wrong character.")
    return
  end
  
  -- Validate that we are on the right seed for the race
  -- (if this is an unseeded race, the seed with be "-")
  if race.seed ~= "-" and race.seed ~= race.currentSeed then
    Isaac.DebugString("Race error: On the wrong seed.")
    return
  end

  -- If this is a seeded race, give us extra starting items
  giveStartingItems()

  if race.status == "in progress" then
    -- The race has already started (we are late, or perhaps died in the middle of the race)
    RacingPlus:RaceStart()
  else
    -- Spawn two Gaping Maws (235.0)
    game:Spawn(EntityType.ENTITY_GAPING_MAW, 0, Vector(280, 360), Vector(0,0), nil, 0, 0)
    game:Spawn(EntityType.ENTITY_GAPING_MAW, 0, Vector(360, 360), Vector(0,0), nil, 0, 0)
  end
end

function RacingPlus:RaceStart()
  -- Only do these actions once per race
  if raceVars.started == true then
    return
  else
    raceVars.started = true
    race.status = "in progress"
  end

  Isaac.DebugString("Starting the race!")

  -- Load the clock sprite for the timer
  spriteInit("clock", "clock")
end

-- This emulates what happens when you normally clear a room
function RacingPlus:ManuallyClearCurrentRoom()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)

  -- Set the room clear to true (so that it gets marked off on the minimap)
  room:SetClear(true)

  -- Open the doors
  local door
  for i = 0, 7 do
    door = room:GetDoor(i)
    if door ~= nil then
      door:Open()
    end
  end

  -- Check to see if it is a boss room
  if room:GetType() == RoomType.ROOM_BOSS then
    -- Try and spawn a Devil Room or Angel Room
    -- (this takes into account their Devil/Angel percentage and so forth)
    room:TrySpawnDevilRoomDoor(true) -- The argument is "Animate"

    -- Try to spawn the Boss Rush door
    if stage == 6 then
      room:TrySpawnBossRushDoor(false) -- The argument is "IgnoreTime"
    end
  end

  -- Spawns the award for clearing the room (the pickup, chest, etc.)
  room:SpawnClearAward() -- This takes into account their luck and so forth

  -- After the reward is spawned, if it is a boss room, the trapdoor(s)
  -- to the next floor will show up and the item pedestals will spawn
  if room:GetType() == RoomType.ROOM_BOSS then
    -- Check all the grid entities in the room
    local num = room:GetGridSize()
    for i = 1, num do
      local gridEntity = room:GetGridEntity(i)
      if gridEntity ~= nil then
        -- If this entity is a trap door
        local test = gridEntity:ToTrapdoor()
        if test ~= nil then
          if gridEntity:GetSaveState().VarData == 1 then
            -- Delete Void Portals, which have a VarData of 1
            room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
          elseif stage == 8 then
            -- Delete the W2 normal trap door
            if race.goal == "Blue Baby" then
              room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
            end
          end
        end
      end
    end

    -- Check all the (non-grid) entities in the room
    local entities = Isaac.GetRoomEntities()
    for i = 1, #entities do
      -- Check for The Polaroid (5.100.327)
      if entities[i].Type == EntityType.ENTITY_PICKUP and
         entities[i].Variant == PickupVariant.PICKUP_COLLECTIBLE and
         entities[i].SubType == CollectibleType.COLLECTIBLE_POLAROID and
         race.goal == "The Lamb" then

        entities[i]:Remove()
        break
      end

      -- Check for The Negative (5.100.328)
      if entities[i].Type == EntityType.ENTITY_PICKUP and
         entities[i].Variant == PickupVariant.PICKUP_COLLECTIBLE and
         entities[i].SubType == CollectibleType.COLLECTIBLE_NEGATIVE and
         race.goal == "Blue Baby" then

        entities[i]:Remove()
        break
      end

      -- Check for Heaven door (1000.39)
      if entities[i].Type == EntityType.ENTITY_EFFECT and
         entities[i].Variant == EffectVariant.HEAVEN_LIGHT_DOOR and
         race.goal == "The Lamb" then

        entities[i]:Remove()
        break
      end
    end
  end

  -- Give a charge to the player's active item
  if player:NeedsCharge() == true then
    -- Find out if we are in a 2x2 or L room
    local chargesToAdd = 1
    local shape = room:GetRoomShape()
    if shape >= 8 then
      chargesToAdd = 2
    end

    -- Add the correct amount of charges
    local currentCharge = player:GetActiveCharge()
    local newCharge = currentCharge + chargesToAdd
    player:SetActiveCharge(newCharge)
  end

  -- Play the sound effect for the door opening
  -- (the only way to play sounds is to attach them to an NPC, so we have to create one and then destroy it)
  local entity = game:Spawn(EntityType.ENTITY_FLY, 0, Vector(0, 0), Vector(0,0), nil, 0, 0)
  local npc = entity:ToNPC()
  npc:PlaySound(SoundEffect.SOUND_DOOR_HEAVY_OPEN, 1, 0, false, 1)
  entity:Remove()

  -- Emulate various familiars dropping things
  local newRoomsCleared = run.roomsCleared + 1
  local pos
  local vel = Vector(0, 0)
  local constant1 = 1.1 -- For Little C.H.A.D., Bomb Bag, Acid Baby, Sack of Sacks
  local constant2 = 1.11 -- For The Relic, Mystery Sack, Rune Bag
  if player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then -- 247
    constant1 = 1.2
    constant2 = 1.2
  end

  -- Sack of Pennies (21)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SACK_OF_PENNIES) then -- 21
    -- This drops a penny/nickel/dime/etc. every 2 rooms cleared (or more with BFFs!)
    RNGCounter.SackOfPennies = incrementRNG(RNGCounter.SackOfPennies)
    math.randomseed(RNGCounter.SackOfPennies)
    local sackBFFChance = math.random(1, 4294967295)
    if newRoomsCleared & 1 == 0 or
       (player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and sackBFFChance % 3 == 0) then

      -- Get the position of the familiar
      local entities = Isaac.GetRoomEntities()
      for i = 1, #entities do
        -- Sack of Pennies - 3.21
        if entities[i].Type == EntityType.ENTITY_FAMILIAR and
           entities[i].Variant == FamiliarVariant.SACK_OF_PENNIES then

          pos = entities[i].Position
          break
        end
      end

      -- Random Coin - 5.20.0
      RNGCounter.SackOfPennies = incrementRNG(RNGCounter.SackOfPennies)
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, pos, vel, player, 0, RNGCounter.SackOfPennies)
    end
  end

  -- Little C.H.A.D (96)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_LITTLE_CHAD) then -- 96
    -- This drops a half a red heart based on the formula:
    -- floor(roomsCleared / 1.1) > 0 && floor(roomsCleared / 1.1) & 1 == 0
    if math.floor(newRoomsCleared / constant1) > 0 and math.floor(newRoomsCleared / constant1) & 1 == 0 then
      -- Get the position of the familiar
      local entities = Isaac.GetRoomEntities()
      for i = 1, #entities do
        -- Little C.H.A.D. - 3.22
        if entities[i].Type == EntityType.ENTITY_FAMILIAR and
           entities[i].Variant == FamiliarVariant.LITTLE_CHAD then

          pos = entities[i].Position
          break
        end
      end

      -- Heart (half) - 5.10.2
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, pos, vel, player, 2, 0)
    end
  end

  -- The Relic (98)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_RELIC) then -- 98
    -- This drops a soul heart based on the formula:
    -- floor(roomsCleared / 1.11) & 3 == 2
    if math.floor(newRoomsCleared / constant2) & 3 == 2 then
      -- Get the position of familiar
      local entities = Isaac.GetRoomEntities()
      for i = 1, #entities do
        -- The Relic - 3.23
        if entities[i].Type == EntityType.ENTITY_FAMILIAR and
           entities[i].Variant == FamiliarVariant.RELIC then

          pos = entities[i].Position
          break
        end
      end

      -- Heart (soul) - 5.10.3
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, pos, vel, player, 3, 0)
    end
  end

  -- Bomb Bag (131)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_BOMB_BAG) then -- 131
    -- This drops a bomb based on the formula:
    -- floor(roomsCleared / 1.1) > 0 && floor(roomsCleared / 1.1) & 1 == 0
    if math.floor(newRoomsCleared / constant1) > 0 and math.floor(newRoomsCleared / constant1) & 1 == 0 then
      -- Get the position of the familiar
      local entities = Isaac.GetRoomEntities()
      for i = 1, #entities do
        -- Bomb Bag - 3.20
        if entities[i].Type == EntityType.ENTITY_FAMILIAR and
           entities[i].Variant == FamiliarVariant.BOMB_BAG then

          pos = entities[i].Position
          break
        end
      end

      -- Random Bomb - 5.40.0
      RNGCounter.BombBag = incrementRNG(RNGCounter.BombBag)
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, pos, vel, player, 0, RNGCounter.BombBag)
    end
  end

  -- Juicy Sack (266)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_JUICY_SACK) then -- 266
    -- Get the position of the familiar
    local entities = Isaac.GetRoomEntities()
    for i = 1, #entities do
      -- Juicy Sack - 3.52
      if entities[i].Type == EntityType.ENTITY_FAMILIAR and
         entities[i].Variant == FamiliarVariant.JUICY_SACK then

        pos = entities[i].Position
        break
      end
    end

    -- Spawn either 1 or 2 blue spiders (50% chance of each)
    RNGCounter.JuicySack = incrementRNG(RNGCounter.JuicySack)
    math.randomseed(RNGCounter.JuicySack)
    local spiders = math.random(1, 2)
    player:AddBlueSpider(pos)
    if spiders == 2 then
      player:AddBlueSpider(pos)
    end

    -- The BFFs! synergy gives an additional spider
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
      player:AddBlueSpider(pos)
    end
  end

  -- Mystery Sack (271)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_MYSTERY_SACK) then -- 271
    -- This drops a heart, coin, bomb, or key based on the formula:
    -- floor(roomsCleared / 1.11) & 3 == 2
    if math.floor(newRoomsCleared / constant2) & 3 == 2 then
      -- Get the position of the familiar
      local entities = Isaac.GetRoomEntities()
      for i = 1, #entities do
        -- Mystery Sack - 3.57
        if entities[i].Type == EntityType.ENTITY_FAMILIAR and
           entities[i].Variant == FamiliarVariant.MYSTERY_SACK then

          pos = entities[i].Position
          break
        end
      end

      -- First, decide whether we get a heart, coin, bomb, or key
      RNGCounter.MysterySack = incrementRNG(RNGCounter.MysterySack)
      math.randomseed(RNGCounter.MysterySack)
      local sackPickupType = math.random(1, 4)
      RNGCounter.MysterySack = incrementRNG(RNGCounter.MysterySack)

      -- If heart
      if sackPickupType == 1 then
        -- Random Heart - 5.10.0
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, pos, vel, player, 0, RNGCounter.MysterySack)

      -- If coin
      elseif sackPickupType == 2 then
        -- Random Coin - 5.20.0
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, pos, vel, player, 0, RNGCounter.MysterySack)

      -- If bomb
      elseif sackPickupType == 3 then
        -- Random Bomb - 5.40.0
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, pos, vel, player, 0, RNGCounter.MysterySack)

      -- If key
      elseif sackPickupType == 4 then
        -- Random Key - 5.30.0
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, pos, vel, player, 0, RNGCounter.MysterySack)
      end
    end
  end

  -- Lil' Chest (362)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_LIL_CHEST) then -- 362
    -- This drops a heart, coin, bomb, or key based on the formula:
    -- 10% chance for a trinket, if no trinket, 25% chance for a random consumable (based on time)
    -- Or, with BFFS!, 12.5% chance for a trinket, if no trinket, 31.25% chance for a random consumable
    -- We don't want it based on time in the Racing+ mod

    -- Get the position of the familiar
    local entities = Isaac.GetRoomEntities()
    for i = 1, #entities do
      -- Lil Chest - 3.82
      if entities[i].Type == EntityType.ENTITY_FAMILIAR and
         entities[i].Variant == FamiliarVariant.LIL_CHEST then

        pos = entities[i].Position
        break
      end
    end

    -- First, decide whether we get a trinket
    RNGCounter.LilChest = incrementRNG(RNGCounter.LilChest)
    math.randomseed(RNGCounter.LilChest)
    local chestTrinket = math.random(1, 1000)
    if chestTrinket <= 100 or
       (player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 125) then

       -- Random Trinket - 5.350.0
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, pos, vel, player, 0, RNGCounter.LilChest)
    else
      -- Second, decide whether it spawns a consumable
      RNGCounter.LilChest = incrementRNG(RNGCounter.LilChest)
      math.randomseed(RNGCounter.LilChest)
      local chestConsumable = math.random(1, 10000)
      if chestConsumable <= 2500 or
         (player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 3125) then

        -- Third, decide whether we get a heart, coin, bomb, or key
        RNGCounter.LilChest = incrementRNG(RNGCounter.LilChest)
        math.randomseed(RNGCounter.LilChest)
        local chestPickupType = math.random(1, 4)
        RNGCounter.LilChest = incrementRNG(RNGCounter.LilChest)

        -- If heart
        if chestPickupType == 1 then
          -- Random Heart - 5.10.0
          game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, pos, vel, player, 0, RNGCounter.LilChest)

        -- If coin
        elseif chestPickupType == 2 then
          -- Random Coin - 5.20.0
          game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, pos, vel, player, 0, RNGCounter.LilChest)

        -- If bomb
        elseif chestPickupType == 3 then
          -- Random Bomb - 5.40.0
          game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, pos, vel, player, 0, RNGCounter.LilChest)

        -- If key
        elseif chestPickupType == 4 then
          -- Random Key - 5.30.0
          game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, pos, vel, player, 0, RNGCounter.LilChest)
        end
      end
    end
  end

  -- Rune Bag (389)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_RUNE_BAG) then -- 389
    -- This drops a random rune based on the formula:
    -- floor(roomsCleared / 1.11) & 3 == 2
    if math.floor(newRoomsCleared / constant2) & 3 == 2 then
      -- Get the position of the familiar
      local entities = Isaac.GetRoomEntities()
      for i = 1, #entities do
        -- Rune Bag - 3.91
        if entities[i].Type == EntityType.ENTITY_FAMILIAR and
           entities[i].Variant == FamiliarVariant.RUNE_BAG then

          pos = entities[i].Position
          break
        end
      end

      -- For some reason you cannot spawn the normal "Random Rune" entity (5.301.0)
      -- So, spawn a random card (5.300.0) over and over until we get a rune
      while true do
        RNGCounter.RuneBag = incrementRNG(RNGCounter.RuneBag)
        local entity = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, pos, vel, player, 0, RNGCounter.RuneBag)
        -- Hagalaz is 32 and Black Rune is 41
        if entity.SubType >= 32 and entity.SubType <= 41 then
          break
        end
        entity:Remove()
      end
    end
  end

  -- Acid Baby (491)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_ACID_BABY) then -- 491
    -- This drops a pill based on the formula:
    -- floor(roomsCleared / 1.1) > 0 && floor(roomsCleared / 1.1) & 1 == 0
    if math.floor(newRoomsCleared / constant1) > 0 and math.floor(newRoomsCleared / constant1) & 1 == 0 then
      -- Get the position of the familiar
      local entities = Isaac.GetRoomEntities()
      for i = 1, #entities do
        -- Acid Baby - 3.112
        if entities[i].Type == EntityType.ENTITY_FAMILIAR and
           entities[i].Variant == FamiliarVariant.ACID_BABY then

          pos = entities[i].Position
          break
        end
      end

      -- Random Pill - 5.70.0
      RNGCounter.AcidBaby = incrementRNG(RNGCounter.AcidBaby)
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, pos, vel, player, 0, RNGCounter.AcidBaby)
    end
  end

  -- Sack of Sacks (500)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SACK_OF_SACKS) then -- 500
    -- This drops a sack based on the formula:
    -- floor(roomsCleared / 1.1) > 0 && floor(roomsCleared / 1.1) & 1 == 0
    if math.floor(newRoomsCleared / constant1) > 0 and math.floor(newRoomsCleared / constant1) & 1 == 0 then
      -- Get the position of the familiar
      local entities = Isaac.GetRoomEntities()
      for i = 1, #entities do
        -- Sack of Sacks - 3.114
        if entities[i].Type == EntityType.ENTITY_FAMILIAR and
           entities[i].Variant == FamiliarVariant.SACK_OF_SACKS then

          pos = entities[i].Position
          break
        end
      end

      -- Grab Bag - 5.69.0
      RNGCounter.SackOfSacks = incrementRNG(RNGCounter.SackOfSacks)
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_GRAB_BAG, pos, vel, player, 0, RNGCounter.SackOfSacks)
    end
  end
end

--
-- Callbacks
--

-- We want to look for enemies that are dying so that we can open the doors prematurely
function RacingPlus:NPCUpdate(aNpc)
  -- Local variables
  local game = Game()
  local runFrameCount = game:GetFrameCount()
  local room = game:GetRoom()

  -- Only look for enemies that are dying
  if aNpc:IsDead() == false then
    return
  end

  -- Only look for enemies that can shut the doors
  if aNpc.CanShutDoors == false then
    return
  end

  -- Only look when the the room is not cleared yet
  if room:IsClear() then
    return
  end

  -- We don't want to look for certain splitting enemies, so make an exception for those
  if aNpc.Type == EntityType.ENTITY_FISTULA_BIG then -- 71 (Teratoma also counts as Fistula)
    return
  elseif aNpc.Type == EntityType.ENTITY_FISTULA_MEDIUM then -- 72 (Teratoma also counts as Fistula)
    return
  elseif aNpc.Type == EntityType.ENTITY_FISTULA_SMALL then -- 73 (Teratoma also counts as Fistula)
    return
  elseif aNpc.Type == EntityType.ENTITY_SQUIRT then -- 220
    return
  elseif aNpc.Type == EntityType.ENTITY_MEATBALL then -- 290
    return
  elseif aNpc:IsBoss() == false and aNpc:IsChampion() then
    -- The following champions split:
    -- 1) Dark red champion, collapses into a red flesh pile upon death and regenerates if not finished off (like a Globin)
    -- 2) Pulsing Green champion, spawns 2 versions of itself
    -- 3) Holy (white) champion, spawns 2 flies
    -- The Lua API doesn't allow us to check the specific champion type, so just make an exception for all champions
    return
  end

  -- We don't want to open the doors in a a puzzle room
  if room:HasTriggerPressurePlates() then
    return
  end

  -- Check all the (non-grid) entities in the room to see if anything is alive
  local allDead = true
  local entities = Isaac.GetRoomEntities()
  for i = 1, #entities do
    local npc = entities[i]:ToNPC()
    if npc ~= nil then
      if npc:IsDead() == false and npc.CanShutDoors == true then
        allDead = false
        break
      end
    end
  end
  if allDead then
    -- Manually clear the room, emulating all the steps that the game does
    RacingPlus:ManuallyClearCurrentRoom()
  end
end

-- Check various things once per frame (this will fire while the floor/room is loading)
function RacingPlus:PostRender()
  -- Local variables
  local isaacFrameCount = Isaac:GetFrameCount()
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local room = game:GetRoom()
  local roomFrameCount = room:GetFrameCount()
  local stage = level:GetStage()
  local player = game:GetPlayer(0)

  -- Check to see if we are starting a run
  -- (this does not work if we put it in a PostUpdate callback because that only starts on the first frame of movement)
  -- (this does not work if we put it in a PlayerInit callback because Eve/Keeper are given their active items after the callback has fired)

  if gameFrameCount == 0 and run.initializing == false then
    run.initializing = true
    if raceVars.skipInit == false then
      RacingPlus.RunInit()
    end
  elseif gameFrameCount > 0 and run.initializing == true then
    run.initializing = false
    raceVars.skipInit = false
  end

  -- Keep track of when we change floors
  if stage ~= run.currentFloor then
    run.currentFloor = stage

    -- Reset the RNG of some items that should be seeded per floor
    local floorSeed = level:GetDungeonPlacementSeed()
    RNGCounter.Teleport = floorSeed
    RNGCounter.Undefined = floorSeed
  end

  -- Keep track of when we change rooms
  if roomFrameCount == 0 and run.roomEntering == false then
     run.roomEntering = true
     if raceVars.checkForNewRoomAfterHourglass == true then
      -- We just reloaded the room from using the Glowing Hourglass
      raceVars.checkForNewRoomAfterHourglass = false

      -- Move them back to the starting position
      player.Position = Vector(320.0, 380.0)

      -- The hourglass removed all of the items that we got in the run initialization step, so redo this
      characterInit()
      giveStartingItems()
    else
      run.roomsEntered = run.roomsEntered + 1
    end
  elseif roomFrameCount > 0 then
    run.roomEntering = false
  end

  --
  -- Fix seed incrementation from touching active pedestal items
  -- (this also fixes Angel key pieces and Pandora's Box items being unseeded)
  --

  -- Get a reproducible seed based on the room
  local roomSeed = room:GetSpawnSeed() -- Will return something like "2496979501"

  -- Find "unseeded" pedestal items/trinkets and do item/trinket bans
  local entities = Isaac.GetRoomEntities()
  for i = 1, #entities do
    -- Item pedestals
    if entities[i].Type == EntityType.ENTITY_PICKUP and -- If this is a pedestal item (5.100)
       entities[i].Variant == PickupVariant.PICKUP_COLLECTIBLE and
       entities[i].InitSeed ~= roomSeed then

      -- Check to see if we already replaced it with a seeded pedestal
      local itemIdentifier = tostring(roomSeed) .. "-" .. tostring(entities[i].InitSeed)
      local alreadyReplaced = false
      for j = 1, #run.replacedItems do
        if itemIdentifier == run.replacedItems[j] then
          alreadyReplaced = true
          break
        end
      end

      if alreadyReplaced == false then
        -- Add it to the list of items that have been replaced
        run.replacedItems[#run.replacedItems + 1] = itemIdentifier

        -- Check to see if this is a B1 item room on a seeded race
        local offLimits = false
        --[[
        if race.rFormat == "seeded" and
           stage == 1 and
           room:GetType() == RoomType.ROOM_TREASURE and
           entities[i].SubType ~= 263 then
          offLimits = true
        end
        --]]

        -- Check to see if this item is banned
        local bannedItem = false
        for j = 1, #raceVars.itemBanList do
          if entities[i].SubType == raceVars.itemBanList[j] then
            bannedItem = true
            break
          end
        end

        local newPedestal
        if offLimits then
          -- Change the item to Off Limits (263)
          newPedestal = game:Spawn(5, 100, entities[i].Position, entities[i].Velocity, entities[i].Parent, 263, RNGCounter.InitialSeed)
          game:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0) -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
          --Isaac.DebugString("Made a new random pedestal (Off Limits).")
        elseif bannedItem then
          -- Make a new random item pedestal (using the B1 floor seed)
          -- (the new random item generated will automatically be decremented from item pools properly on sight)
          newPedestal = game:Spawn(5, 100, entities[i].Position, entities[i].Velocity, entities[i].Parent, 0, RNGCounter.InitialSeed)
          game:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0) -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
          --Isaac.DebugString("Made a new random pedestal using seed: " .. tostring(RNGCounter.InitialSeed))
        else
          -- Make a new copy of this item using the room seed
          newPedestal = game:Spawn(5, 100, entities[i].Position, entities[i].Velocity, entities[i].Parent, entities[i].SubType, roomSeed)
          -- We don't need to make a fart noise because the swap will be completely transparent to the user
          -- (the sprites of the two items will obviously be identical)
          -- We don't need to add this item to the ban list because since it already existed, it was properly decremented from the pools on sight
          --Isaac.DebugString("Made a copied " .. tostring(newPedestal.SubType) .. " pedestal using seed: " .. tostring(roomSeed))
        end

        -- If we don't do this, the item will be fully recharged every time the player swaps it out
        newPedestal:ToPickup().Charge = entities[i]:ToPickup().Charge

        -- If we don't do this, shop items will become automatically bought
        newPedestal:ToPickup().Price = entities[i]:ToPickup().Price

        -- If we don't do this, you can take both of the pedestals in a double Treasure Room
        newPedestal:ToPickup().TheresOptionsPickup = entities[i]:ToPickup().TheresOptionsPickup

        -- Now that we have created a new pedestal, we can delete the old one
        entities[i]:Remove()
      end
    end

    -- Trinkets
    if entities[i].Type == EntityType.ENTITY_PICKUP and -- If this is a trinket (5.350)
       entities[i].Variant == PickupVariant.PICKUP_TRINKET and
       entities[i].InitSeed ~= roomSeed then

      -- Check to see if we already replaced it with a seeded trinket
      local trinketIdentifier = tostring(roomSeed) .. "-" .. tostring(entities[i].InitSeed)
      local alreadyReplaced = false
      for j = 1, #run.replacedTrinkets do
        if trinketIdentifier == run.replacedTrinkets[j] then
          alreadyReplaced = true
          break
        end
      end

      if alreadyReplaced == false then
        -- Add it to the list of trinkets that have been replaced
        run.replacedTrinkets[#run.replacedTrinkets + 1] = trinketIdentifier

        -- Check to see if this trinket is banned
        local bannedTrinket = false
        for j = 1, #raceVars.trinketBanList do
          if entities[i].SubType == raceVars.trinketBanList[j] then
            bannedTrinket = true
            break
          end
        end

        local newTrinket
        if bannedItem then
          -- Spawn a new random trinket (using the B1 floor seed)
          newTrinket = game:Spawn(5, 350, entities[i].Position, entities[i].Velocity, entities[i].Parent, 0, roomSeed)
          --Isaac.DebugString("Made a new random trinket using seed: " .. tostring(roomSeed))
        else
          -- Make a new copy of this trinket using the room seed
          newTrinket = game:Spawn(5, 350, entities[i].Position, entities[i].Velocity, entities[i].Parent, entities[i].SubType, roomSeed)
          --Isaac.DebugString("Made a copied " .. tostring(newPedestal.SubType) .. " trinket using seed: " .. tostring(roomSeed))
        end

        -- Now that we have created a new trinket, we can delete the old one
        entities[i]:Remove()
      end
    end
  end

  ---
  --- Do race stuff / draw graphics
  ---

  -- Race will be nil if a run has not started yet
  -- Also, sometimes mod loading (reading the "save.dat" file) can fail, in which case the race table will become nil
  if race == nil then
    return
  end

  -- If we are not in a run, do nothing
  if race.status == "none" then
    raceVars.started = false -- This needs to be manually reset at the end of every race
    raceVars.startedTime = 0 -- Remove the timer after we finish or quit a race (1/2)
    spriteInit("clock", 0) -- Remove the timer after we finish or quit a race (2/2)
    return
  end

  -- If we are waiting for the race to start, check for updates every frame
  if race.status == "open" or race.status == "starting" then
    readServer()
  end

  -- Otherwise, check every half second (file reads are expensive)
  if race.status == "in progress" and isaacFrameCount % 30 == 0 then
    readServer()
  end

  -- Check to see if we are on the BLCK CNDL Easter Egg
  if raceVars.blckCndlOn == false and raceVars.startedTime == 0 then
    spriteInit("top", "errorBlckCndl")
    spriteDisplay()
    return
  end

  -- Check to see if we are on hard mode
  if raceVars.difficulty ~= 0 and raceVars.startedTime == 0 then
    spriteInit("top", "errorHardMode")
    spriteDisplay()
    return
  end

  -- Check to see if we are on the right character
  if race.character ~= raceVars.character and raceVars.startedTime == 0 then
    spriteInit("top", "errorCharacter")
    spriteDisplay()
    return
  end

  -- Check to see if we are on the right seed
  if race.seed ~= "-" and race.seed ~= race.currentSeed and raceVars.startedTime == 0 then
    spriteInit("top", "errorSeed")
    spriteDisplay()
    return
  end

  -- Hold the player in place if the race has not started yet (forcefield)
  if raceVars.started == false then
    -- The starting position is 320.0, 380.0
    player.Position = Vector(320.0, 380.0)
  end

  -- Show the "Wait for the race to begin!" graphic/text
  if race.status == "open" then
    spriteInit("top", "wait")
  end

  -- Show the appropriate countdown graphic/text
  if race.status == "starting" or race.status == "in progress" then
    if race.countdown == 10 then
      spriteInit("top", "10")
    elseif race.countdown == 5 then
      spriteInit("top", "5")
    elseif race.countdown == 4 then
      spriteInit("top", "4")
    elseif race.countdown == 3 then
      spriteInit("top", "3")
    elseif race.countdown == 2 then
      spriteInit("top", "2")

      if raceVars.hourglassUsed == false then
        raceVars.hourglassUsed = true
        raceVars.skipInit = true -- Set this so that the mod doesn't detect that a new run has started
        player:UseActiveItem(422, false, false, false, false) -- Glowing Hour Glass (422)
        raceVars.checkForNewRoomAfterHourglass = true
      end
    elseif race.countdown == 1 then
      spriteInit("top", "1")
    elseif run.roomsEntered > 1 then
      -- Remove the "Go!" graphic as soon as we enter another room
      -- (the starting room counts as room #1)
      spriteInit("top", 0)
    elseif race.countdown == 0 or -- The countdown has reached 0
           (race.countdown == -1 and raceVars.started == false) then -- We somehow missed the window where the countdown was 0, so start the race now

      spriteInit("top", "go")
      RacingPlus:RaceStart()

      -- Set the start time to the number of frames that have elapsed since the game is open
      -- (this won't account for lag, but we are unable to call things like "os.clock()" without forcing the using to enable the "--luadebug" flag on the game)
      -- (we have to do this here so that the clock doesn't get reset if the player dies or resets)
      raceVars.startedTime = Isaac:GetFrameCount()
    end

    timerUpdate()
  end

  -- Display all initialized sprites
  spriteDisplay()
end

-- Check various things once per frame (this will not fire while the floor/room is loading)
function RacingPlus:PostUpdate()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()

  --
  -- Keep track of the total amount of rooms cleared on this run thus far
  --

  -- Check the clear status of the room and compare it to what it was a frame ago
  local clear = room:IsClear()
  if clear ~= run.currentRoomClearState then
    run.currentRoomClearState = clear

    if clear == true then
      -- If the room just got changed to a cleared state, increment the total rooms cleared
      run.roomsCleared = run.roomsCleared + 1
      Isaac.DebugString("Rooms cleared: " .. tostring(run.roomsCleared))
    end
  end
end

function RacingPlus:BookOfSin()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- The Book of Sin has an equal chance to spawn a heart, coin, bomb, key, battery, pill, or card/rune.
  RNGCounter.BookOfSin = incrementRNG(RNGCounter.BookOfSin)
  math.randomseed(RNGCounter.BookOfSin)
  local bookPickupType = math.random(1, 7)
  RNGCounter.BookOfSin = incrementRNG(RNGCounter.BookOfSin)

  local pos = player.Position
  local vel = Vector(0, 0)

  -- If heart
  if bookPickupType == 1 then
    -- Random Heart - 5.10.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, pos, vel, player, 0, RNGCounter.BookOfSin)

  -- If coin
  elseif bookPickupType == 2 then
    -- Random Coin - 5.20.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, pos, vel, player, 0, RNGCounter.BookOfSin)

  -- If bomb
  elseif bookPickupType == 3 then
    -- Random Bomb - 5.40.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, pos, vel, player, 0, RNGCounter.BookOfSin)

  -- If key
  elseif bookPickupType == 4 then
    -- Random Key - 5.30.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, pos, vel, player, 0, RNGCounter.BookOfSin)

  -- If battery
  elseif bookPickupType == 5 then
    -- Lil' Battery - 5.90.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, pos, vel, player, 0, RNGCounter.BookOfSin)

  -- If pill
  elseif bookPickupType == 6 then
    -- Random Pill - 5.70.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, pos, vel, player, 0, RNGCounter.BookOfSin)

  -- If card/rune
  elseif bookPickupType == 7 then
    -- Random Card - 5.300.0
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, pos, vel, player, 0, RNGCounter.RuneBag)
  end

  -- By returning true, it will play the animation where Isaac holds the Book of Sin over his head
  return true
end

function RacingPlus:Teleport()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local index = level:GetCurrentRoomIndex()
  local index2 = level:GetStartingRoomIndex()

  game:ChangeRoom(index2)
end

function RacingPlus:TestCallback()
  local game = Game()
  local level = game:GetLevel()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)

  -- Recharge the item so we can use it forever
  player:SetActiveCharge(1)

  -- Print out various debug information to Isaac's log.txt
  Isaac.DebugString("-----------------------")
  Isaac.DebugString("Entering test callback.")
  Isaac.DebugString("-----------------------")

  Isaac.DebugString("run table:")
  for k, v in pairs(run) do
    Isaac.DebugString("    " .. k .. ': ' .. tostring(v))
  end

  Isaac.DebugString("race table:")
  for k, v in pairs(race) do
    Isaac.DebugString("    " .. k .. ': ' .. tostring(v))
  end

  Isaac.DebugString("raceVars table:")
  for k, v in pairs(raceVars) do
    Isaac.DebugString("    " .. k .. ': ' .. tostring(v))
  end

  Isaac.DebugString("sprite table:")
  for k, v in pairs(spriteTable) do
    for k2, v2 in pairs(v) do
      Isaac.DebugString("    " .. k .. '.' .. k2 .. ': ' .. tostring(v2))
    end
  end

  Isaac.DebugString("---------------------")
  Isaac.DebugString("Ending test callback.")
  Isaac.DebugString("---------------------")
end

RacingPlus:AddCallback(ModCallbacks.MC_NPC_UPDATE,  RacingPlus.NPCUpdate)
RacingPlus:AddCallback(ModCallbacks.MC_POST_RENDER, RacingPlus.PostRender)
RacingPlus:AddCallback(ModCallbacks.MC_POST_UPDATE, RacingPlus.PostUpdate)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM,    RacingPlus.BookOfSin, 43); -- Replacing Book of Sin (97)
--RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM,    RacingPlus.Teleport, 59); -- Replacing Teleport (44) (this is not possible with the current bindings)
--RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM,    RacingPlus.Undefined, 61); -- Replacing Undefined (324) (this is not possible with the current bindings)
RacingPlus:AddCallback(ModCallbacks.MC_USE_ITEM,    RacingPlus.TestCallback, 235); -- Debug (custom item)

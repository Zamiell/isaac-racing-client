--
-- The Jud6s Mod
-- by Zamiel
--

--[[

TODO:
- Copy over Afterbirth room changes after the next patch
- Fix unseeded Boss heart drops from Pin, etc. (and make it so that they drop during door opening)
- Fix Dead Eye on poop
- Change Troll Bombs and Mega Troll Bombs fuse timer to Rebirth-style
- Make Devil / Angel Rooms given in order and independent of floor

TODO CAN'T FIX:
- Automatically enable BLCK CNDL seed (not possible with current bindings)
- Automatically enter in a seed for seeded races (not possible with current bindings)
- Do item bans in a proper way via editing item pools (not possible to modify item pools via current bindings)
- Make Teleport / Undefined / Cursed Eye / Telepills seeded (the ChangeRoom() function is broken and doesn't actually consistently send you to the room that you specify)
- Be able to skip specific champions from the fast-clear check (not possible to detect what type of champion it is with the current bindings)
- Skip the fade in and fade out animation when traveling to the next floor (need console access or StartStageTransition() 2nd argument to be working)
- Stop the player from being teleported upon entering a room with Gurdy, Mom's Heart, or It Lives (Isaac is placed in the location and you can't move him fast enough)
- Make Book of Sin play the proper animation (no idea how to play vanilla item animations)

--]]

-- Register the mod (the second argument is the API version)
local Jud6s = RegisterMod("Jud6s", 1);

-- Global variables
local runInitializing = false
local roomsCleared = 0
local currentGameFrame = 0
local currentFloor = 1
local currentRoomClearState = true
local itemBanList = {}
local trinketBanList = {}
local inRacingPlusRace = false
local raceState = 0
local runGoal = "Blue Baby" -- Other possible values are "The Lamb" and "Mega Satan"
local runFormat = "Unseeded" -- Other possible values are "Seeded", "Diveristy", and "Custom"
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
local host, port = "127.0.0.1", 9999
local socket = require("socket")
local tcp = assert(socket.tcp())
tcp:settimeout(0)
tcp:connect(host, port)
tcp:send("i poopd\n")

---
--- Subroutines
---

local function IncrementRNG(seed)
  -- The initial RNG value recieved from the B1 floor RNG is a 10 digit integer
  -- So let's just continue to work with integers that are roughly in this range
  math.randomseed(seed)
  return math.random(1, 9999999999)
end

local function connectTCP()
  
  tcp:connect(host, port)
end

--
-- Main functions
-- 

-- Called when starting a new run
function Jud6s:RunInit()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local player = game:GetPlayer(0)
  local seed = level:GetDungeonPlacementSeed()

  -- Reset some global variables that we keep track of per run
  roomsCleared = 0
  currentGameFrame = 0
  currentFloor = 0
  currentRoomClearState = true
  itemBanList = {}
  trinketBanList = {}
  raceState = 0

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

  -- Add item bans
  if runFormat == "Seeded" then
    itemBanList[#itemBanList + 1] = CollectibleType.COLLECTIBLE_COMPASS -- 21
    itemBanList[#itemBanList + 1] = CollectibleType.COLLECTIBLE_TELEPORT -- 44
    itemBanList[#itemBanList + 1] = CollectibleType.COLLECTIBLE_UNDEFINED  -- 324
    trinketBanList[#trinketBanList + 1] = TrinketType.TRINKET_CAINS_EYE -- 59
  end

  -- Do character-specific actions
  if player:GetPlayerType() == PlayerType.PLAYER_JUDAS then -- 3
    -- Decrease his red hearts
    player:AddHearts(-1)

  elseif player:GetPlayerType() == PlayerType.PLAYER_EVE then
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
    player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105
    player:AddCollectible(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON, 0, false) -- 122
    player:AddCollectible(CollectibleType. COLLECTIBLE_DEAD_BIRD, 0, false) -- 117

  elseif player:GetPlayerType() == PlayerType.PLAYER_AZAZEL then
    -- Decrease his red hearts
    player:AddHearts(-1)

  elseif player:GetPlayerType() == PlayerType.PLAYER_EDEN then
    -- Swap the random active item with the D6
    local activeItem = player:GetActiveItem()
    player:RemoveCollectible(activeItem)
    Isaac.DebugString("Removing collectible " .. tostring(activeItem))
    player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105

    -- It would be nice to remove and re-add the passive item so that it appears in the correct order with the D6 first
    -- However, if the passive gives pickups, then it would give double

  elseif player:GetPlayerType() == PlayerType.PLAYER_KEEPER then
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
    player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105
    player:AddCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET, 0, false) -- 501
    player:AddCollectible(CollectibleType.COLLECTIBLE_DUALITY, 0, false) -- 498

    -- Grant an extra coin/heart container
    player:AddCoins(24) -- Keeper starts with 1 coin so we only need to give 24
    player:AddCoins(1) -- This fills in the new heart container
  end
  
  -- Trap the player in a forcefield
  if inRacingPlusRace then
    player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS, true) -- Second argument is AddCostume
  end

  --tcp:connect(host, port)
end

-- This emulates what happens when you normally clear a room
function Jud6s:ManuallyClearCurrentRoom()
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
      room:TrySpawnBossRushDoor(true) -- The argument is "IgnoreTime"
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
            if runGoal == "Blue Baby" then
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
         runGoal == "The Lamb" then

        entities[i]:Remove()
        break
      end

      -- Check for The Negative (5.100.328)
      if entities[i].Type == EntityType.ENTITY_PICKUP and
         entities[i].Variant == PickupVariant.PICKUP_COLLECTIBLE and
         entities[i].SubType == CollectibleType.COLLECTIBLE_NEGATIVE and
         runGoal == "Blue Baby" then

        entities[i]:Remove()
        break
      end

      -- Check for Heaven door (1000.39)
      if entities[i].Type == EntityType.ENTITY_EFFECT and
         entities[i].Variant == EffectVariant.HEAVEN_LIGHT_DOOR and
         runGoal == "The Lamb" then

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
  local newRoomsCleared = roomsCleared + 1
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
    RNGCounter.SackOfPennies = IncrementRNG(RNGCounter.SackOfPennies)
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
      RNGCounter.SackOfPennies = IncrementRNG(RNGCounter.SackOfPennies)
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
      RNGCounter.BombBag = IncrementRNG(RNGCounter.BombBag)
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
    RNGCounter.JuicySack = IncrementRNG(RNGCounter.JuicySack)
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
      RNGCounter.MysterySack = IncrementRNG(RNGCounter.MysterySack)
      math.randomseed(RNGCounter.MysterySack)
      local sackPickupType = math.random(1, 4)
      RNGCounter.MysterySack = IncrementRNG(RNGCounter.MysterySack)

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
    -- We don't want it based on time in the Jud6s mod

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
    RNGCounter.LilChest = IncrementRNG(RNGCounter.LilChest)
    math.randomseed(RNGCounter.LilChest)
    local chestTrinket = math.random(1, 1000)
    if chestTrinket <= 100 or
       (player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 125) then

       -- Random Trinket - 5.350.0
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, pos, vel, player, 0, RNGCounter.LilChest)
    else
      -- Second, decide whether it spawns a consumable
      RNGCounter.LilChest = IncrementRNG(RNGCounter.LilChest)
      math.randomseed(RNGCounter.LilChest)
      local chestConsumable = math.random(1, 10000)
      if chestConsumable <= 2500 or
         (player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 3125) then

        -- Third, decide whether we get a heart, coin, bomb, or key
        RNGCounter.LilChest = IncrementRNG(RNGCounter.LilChest)
        math.randomseed(RNGCounter.LilChest)
        local chestPickupType = math.random(1, 4)
        RNGCounter.LilChest = IncrementRNG(RNGCounter.LilChest)

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
        RNGCounter.RuneBag = IncrementRNG(RNGCounter.RuneBag)
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
      RNGCounter.AcidBaby = IncrementRNG(RNGCounter.AcidBaby)
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
      RNGCounter.SackOfSacks = IncrementRNG(RNGCounter.SackOfSacks)
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_GRAB_BAG, pos, vel, player, 0, RNGCounter.SackOfSacks)
    end
  end
end

--
-- Callbacks
--

-- We want to look for enemies that are dying so that we can open the doors prematurely
function Jud6s:NPCUpdate(aNpc)
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
    Jud6s:ManuallyClearCurrentRoom()
  end
end

-- Check various things once per frame (this will fire while the floor/room is loading)
function Jud6s:PostRender()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local stage = level:GetStage()

  -- Check to see if we are starting a run
  -- (this does not work if we put it in a PostUpdate callback because that only starts on the first frame of movement)
  -- (this does not work if we put it in a PlayerInit callback because Eve/Keeper are given their active items after the callback has fired)
  if gameFrameCount == 0 and runInitializing == false then
    runInitializing = true
    Isaac.DebugString("We are on frame 0, runInitializing is now true.")
    Jud6s.RunInit()
  elseif gameFrameCount > 0 and runInitializing == true then
    runInitializing = false
    Isaac.DebugString("We are on frame 1, runInitializing is now false.")
  end

  -- Keep track of when we change floors
  if stage ~= currentFloor then
    currentFloor = stage

    -- Reset the RNG of some items that should be seeded per floor
    local floorSeed = level:GetDungeonPlacementSeed()
    RNGCounter.Teleport = floorSeed
    RNGCounter.Undefined = floorSeed
  end

  ---
  --- Draw some graphics
  ---

  -- TODO
end

-- Check various things once per frame (this will not fire while the floor/room is loading)
function Jud6s:PostUpdate()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)

  --
  -- Keep track of the total amount of rooms cleared on this run thus far
  --

  -- Check the clear status of the room and compare it to what it was a frame ago
  local clear = room:IsClear()
  if clear ~= currentRoomClearState then
    currentRoomClearState = clear
    
    if clear == true then
      -- If the room just got changed to a cleared state, increment the total rooms cleared
      roomsCleared = roomsCleared + 1
      Isaac.DebugString("Rooms cleared: " .. tostring(roomsCleared))
    end
  end

  --
  -- Fix seed incrementation from touching active pedestal items
  -- (this also fixes Angel key pieces and Pandora's Box items being unseeded)
  --

  -- Get a reproducible seed based on the room
  local roomSeed = room:GetSpawnSeed() -- Will return something like "2496979501"

  -- Find "unseeded" pedestal items and do item bans
  local entities = Isaac.GetRoomEntities()
  for i = 1, #entities do
    if entities[i].Type == EntityType.ENTITY_PICKUP and -- If this is a pedestal item (5.100)
       entities[i].Variant == PickupVariant.PICKUP_COLLECTIBLE and
       entities[i].FrameCount == 1 and -- If this is freshly spawned
       entities[i].InitSeed ~= roomSeed then -- If it was spawned naturally instead of by us

      -- Check to see if this item is banned
      local bannedItem = false
      for j = 1, #itemBanList do
        if entities[i].SubType == itemBanList[j] then
          bannedItem = true
          break
        end
      end

      local newPedestal
      if bannedItem then
        -- Make a new random item pedestal (using the B1 floor seed)
        newPedestal = game:Spawn(5, 100, entities[i].Position, entities[i].Velocity, entities[i].Parent, 0, RNGCounter.InitialSeed)
        game:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0) -- Play a fart animation so that it doesn't look like some bug with the Jud6s mod
        --Isaac.DebugString("Made a new random pedestal using seed: " .. tostring(RNGCounter.InitialSeed))
      else
        -- Make a new copy of this item using the room seed
        newPedestal = game:Spawn(5, 100, entities[i].Position, entities[i].Velocity, entities[i].Parent, entities[i].SubType, roomSeed)
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

    if entities[i].Type == EntityType.ENTITY_PICKUP and -- If this is a trinket item (5.350)
       entities[i].Variant == PickupVariant.PICKUP_TRINKET and
       entities[i].FrameCount == 1 then -- If this is freshly spawned

      -- Check to see if this item is banned
      local bannedItem = false
      for j = 1, #trinketBanList do
        if entities[i].SubType == trinketBanList[j] then
          bannedItem = true
          break
        end
      end

      if bannedItem then
        -- Spawn a new random trinket in its place
        game:Spawn(5, 350, entities[i].Position, entities[i].Velocity, nil, 0, roomSeed)

        -- Now that we have created a new trinket, we can delete the old one
        entities[i]:Remove()
      end
    end
  end

  ---
  --- Do race stuff
  ---

  --[[
  if raceState == 0 then
    -- Keep the "forcefield" going forever
    player:GetEffects():RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS)
    player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS, true) -- Second argument is AddCostume

    -- The starting position is 320.0, 380.0
    --player.Position = Vector(320.0, 380.0)
  elseif raceState == 1 then
    raceState = 2
    player:GetEffects():RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS)
  end

  if gameFrameCount == 1 then
    -- Draw "Waiting for the race to start..."
    
  elseif gameFrameCount == 2 then
    -- Draw "Race starting in 10 seconds!"

  elseif gameFrameCount == 600 then
    -- Draw "5"

  elseif gameFrameCount == 660 then
    -- Draw "4"

  elseif gameFrameCount == 720 then
    -- Draw "3"

  elseif gameFrameCount == 780 then
    -- Draw "2"

  elseif gameFrameCount == 8400 then
    -- Draw "1"

  elseif gameFrameCount == 900 then
    -- Draw "Go!"
    -- TODO
    raceState = 1
  end
  --]]
end

function Jud6s:BookOfSin()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- The Book of Sin has an equal chance to spawn a heart, coin, bomb, key, battery, pill, or card/rune.
  RNGCounter.BookOfSin = IncrementRNG(RNGCounter.BookOfSin)
  math.randomseed(RNGCounter.BookOfSin)
  local bookPickupType = math.random(1, 7)
  RNGCounter.BookOfSin = IncrementRNG(RNGCounter.BookOfSin)

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

function Jud6s:Teleport()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local index = level:GetCurrentRoomIndex()
  local index2 = level:GetStartingRoomIndex()

  game:ChangeRoom(index2)
end

Jud6s:AddCallback(ModCallbacks.MC_NPC_UPDATE,  Jud6s.NPCUpdate)
Jud6s:AddCallback(ModCallbacks.MC_POST_RENDER, Jud6s.PostRender)
Jud6s:AddCallback(ModCallbacks.MC_POST_UPDATE, Jud6s.PostUpdate)
Jud6s:AddCallback(ModCallbacks.MC_USE_ITEM,    Jud6s.BookOfSin, 43); -- Replacing Book of Sin (97)
--Jud6s:AddCallback(ModCallbacks.MC_USE_ITEM,    Jud6s.Teleport, 59); -- Replacing Teleport (44) (this is not possible with the current bindings)
--Jud6s:AddCallback(ModCallbacks.MC_USE_ITEM,    Jud6s.Undefined, 61); -- Replacing Undefined (324) (this is not possible with the current bindings)

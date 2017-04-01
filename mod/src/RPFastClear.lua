local RPFastClear = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")
local RPSoulJar = require("src/rpsouljar")

--
-- Fast clear functions
--

-- Look for enemies that are dying so that we can open the doors prematurely
function RPFastClear:NPCUpdate(npc)
    -- Local variables
    local game = Game()
    local room = game:GetRoom()

    -- Only look for enemies that are dying
    if npc:IsDead() == false then
      return
    end

    -- Only look for enemies that can shut the doors
    if npc.CanShutDoors == false then
      return
    end

    -- Only look when the the room is not cleared yet
    -- (the room clear state is always true when fighting in Challenge Rooms and Boss Rushes,
    -- but we don't want fast-clear to apply to those due to limitations in the Afterbirth+ API)
    if room:IsClear() then
      return
    end

    -- If we are in a puzzle room, check to see if all of the plates have been pressed
    if room:HasTriggerPressurePlates() then
      -- Check all the grid entities in the room
      local num = room:GetGridSize()
      for i = 1, num do
        local gridEntity = room:GetGridEntity(i)
        if gridEntity ~= nil then
          -- If this entity is a trap door
          local test = gridEntity:ToPressurePlate()
          if test ~= nil then
            if gridEntity:GetSaveState().State ~= 3 then
              return
            end
          end
        end
      end
    end

    RPFastClear:CheckAlive()
end

-- Fast-clear for puzzle rooms
-- (when puzzle rooms are cleared, there is an annoying delay before the doors are opened)
function RPFastClear:CheckPuzzleRoom()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomClear = room:IsClear()

  -- If we are in a puzzle room, check to see if all of the plates have been pressed
  if roomClear == false and room:HasTriggerPressurePlates() then
    -- Check all the grid entities in the room
    local allPushed = true
    local num = room:GetGridSize()
    for i = 1, num do
      local gridEntity = room:GetGridEntity(i)
      if gridEntity ~= nil then
        -- If this entity is a button
        if gridEntity:GetSaveState().Type == GridEntityType.GRID_PRESSURE_PLATE then
          if gridEntity:GetSaveState().State ~= 3 then
            allPushed = false
            break
          end
        end
      end
    end
    if allPushed then
      RPFastClear:CheckAlive()
    end
  end
end

function RPFastClear:CheckAlive()
  -- Check all the (non-grid) entities in the room to see if anything is alive
  local allDead = true
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    local npc = entity:ToNPC()
    if npc ~= nil then
      -- We don't fast-clear to apply to splitting enemies, so make an exception for those
      if (npc:IsDead() == false and npc.CanShutDoors == true) or -- This is an alive enemy
         (npc:IsBoss() == false and npc:IsChampion()) or -- This is a champion
         npc.Type == EntityType.ENTITY_GAPER or -- 10 (all 3 variants split)
         (npc.Type == EntityType.ENTITY_MULLIGAN and npc.Variant == 0) or -- 16 (Mulligoon and Muliboon do not split)
         npc.Type == EntityType.ENTITY_HIVE or -- 22 (both variants split)
         npc.Type == EntityType.ENTITY_GLOBIN or -- 24 (all 3 variants split)
         (npc.Type == EntityType.ENTITY_BOOMFLY and npc.Variant == 2) or -- 25 (Drowned Boom Flies split)
         npc.Type == EntityType.ENTITY_ENVY or -- 51 (both variants split)
         npc.Type == EntityType.ENTITY_MEMBRAIN or -- 57 (both variants split; Mama Guts also counts as Membrain)
         npc.Type == EntityType.ENTITY_FISTULA_BIG or -- 71 (both variants split; Teratoma also counts as Fistula)
         npc.Type == EntityType.ENTITY_FISTULA_MEDIUM or -- 72 (both variants split; Teratoma also counts as Fistula)
         npc.Type == EntityType.ENTITY_FISTULA_SMALL or -- 73 (both variants split; Teratoma also counts as Fistula)
         npc.Type == EntityType.ENTITY_BLASTOCYST_BIG or -- 74
         npc.Type == EntityType.ENTITY_BLASTOCYST_MEDIUM or -- 75
         npc.Type == EntityType.ENTITY_BLASTOCYST_SMALL or -- 76
         npc.Type == EntityType.ENTITY_MOTER or -- 80
         (npc.Type == EntityType.ENTITY_FALLEN and npc.Variant ~= 1 and npc.Scale ~= 0.75) or -- 81
         -- (fast-clear should apply to Krampus and split Fallens)
         npc.Type == EntityType.ENTITY_GURGLE or -- 87
         npc.Type == EntityType.ENTITY_HANGER or -- 90
         npc.Type == EntityType.ENTITY_SWARMER or -- 91
         npc.Type == EntityType.ENTITY_BIGSPIDER or -- 94
         npc.Type == EntityType.ENTITY_NEST or -- 205 (looks like a Mulligan)
         (npc.Type == EntityType.ENTITY_FATTY and npc.Variant == 1) or -- 208 (Pale Fatties split)
         npc.Type == EntityType.ENTITY_FAT_SACK or -- 209
         npc.Type == EntityType.ENTITY_BLUBBER or -- 210
         npc.Type == EntityType.ENTITY_SWINGER or -- 216 (both variants split)
         npc.Type == EntityType.ENTITY_SQUIRT or -- 220 (both variants split)
         (npc.Type == EntityType.ENTITY_SKINNY and npc.Variant == 1) or -- 226 (Rotties split)
         npc.Type == EntityType.ENTITY_DINGA or -- 223
         npc.Type == EntityType.ENTITY_GRUB or -- 239
         (npc.Type == EntityType.ENTITY_CONJOINED_FATTY and npc.Variant == 0) or -- 257
         -- (Blue Conjoined Fatties do not split)
         npc.Type == EntityType.ENTITY_BLACK_GLOBIN or -- 278
         npc.Type == EntityType.ENTITY_MEGA_CLOTTY or -- 282
         npc.Type == EntityType.ENTITY_MOMS_DEAD_HAND or -- 287
         npc.Type == EntityType.ENTITY_MEATBALL or -- 290
         npc.Type == EntityType.ENTITY_BLISTER or -- 303
         npc.Type == EntityType.ENTITY_BROWNIE then -- 402

        -- The following champions split:
        -- 1) Pulsing Green champion, spawns 2 versions of itself
        -- 2) Holy (white) champion, spawns 2 flies
        -- The Lua API doesn't allow us to check the specific champion type, so just make an exception for all champions

        allDead = false
        break
      end
    end
  end
  if allDead then
    -- Manually clear the room, emulating all the steps that the game does
    RPFastClear:Main()
  end
end

-- This emulates what happens when you normally clear a room
function RPFastClear:Main()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local player = game:GetPlayer(0)
  local activeItem = player:GetActiveItem()
  local activeCharge = player:GetActiveCharge()
  local batteryCharge = player:GetBatteryCharge()
  local sfx = SFXManager()

  -- Set the room clear to true (so that it gets marked off on the minimap)
  room:SetClear(true)

  -- Open the doors
  for i = 0, 7 do
    local door = room:GetDoor(i)
    if door ~= nil then
      local openDoor = true
      if RPGlobals.race.rFormat == "seeded" and
         door:IsRoomType(RoomType.ROOM_TREASURE) and -- 4
         roomType ~= RoomType.ROOM_TREASURE then -- 4

        openDoor = false
      end
      if openDoor then
        door:Open()
      end
    end
  end

  -- Check to see if it is a boss room
  if room:GetType() == RoomType.ROOM_BOSS then
    -- Check for the Soul Jar Devil Deal mechanic
    RPSoulJar:CheckDamaged()

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

  -- Give a charge to the player's active item
  if player:NeedsCharge() == true then
    -- Find out if we are in a 2x2 or L room
    local chargesToAdd = 1
    local shape = room:GetRoomShape()
    if shape >= 8 then
      -- L rooms and 2x2 rooms should grant 2 charges
      chargesToAdd = 2
    elseif player:HasTrinket(TrinketType.TRINKET_AAA_BATTERY) and -- 3
           activeCharge == RPGlobals:GetActiveCollectibleMaxCharges(activeItem) - 2 then

      -- The AAA Battery grants an extra charge when the active item is one away from being fully charged
      chargesToAdd = 2
    elseif player:HasTrinket(TrinketType.TRINKET_AAA_BATTERY) and -- 3
           activeCharge == RPGlobals:GetActiveCollectibleMaxCharges(activeItem) and
           player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and -- 63
           batteryCharge == RPGlobals:GetActiveCollectibleMaxCharges(activeItem) - 2 then

      -- The AAA Battery should grant an extra charge when the active item is one away from being fully charged
      -- with The Battery (this is bugged in vanilla for The Battery)
      chargesToAdd = 2
    end

    -- Add the correct amount of charges
    local currentCharge = player:GetActiveCharge()
    player:SetActiveCharge(currentCharge + chargesToAdd)
  end

  -- Play the sound effect for the door opening
  -- (the only way to play sounds is to attach them to an NPC, so we have to create one and then destroy it)
  if room:GetType() ~= RoomType.ROOM_DUNGEON then -- 16
    sfx:Play(SoundEffect.SOUND_DOOR_HEAVY_OPEN, 1, 0, false, 1) -- ID, Volume, FrameDelay, Loop, Pitch
  end

  -- Emulate various familiars dropping things
  -- (all of these formula were reverse engineered by blcd)
  local newRoomsCleared = RPGlobals.run.roomsCleared + 1
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
    RPGlobals.RNGCounter.SackOfPennies = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.SackOfPennies)
    math.randomseed(RPGlobals.RNGCounter.SackOfPennies)
    local sackBFFChance = math.random(1, 4294967295)
    if newRoomsCleared & 1 == 0 or
       (player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and sackBFFChance % 3 == 0) then

      -- Get the position of the familiar
      for i, entity in pairs(Isaac.GetRoomEntities()) do
        -- Sack of Pennies - 3.21
        if entity.Type == EntityType.ENTITY_FAMILIAR and
           entity.Variant == FamiliarVariant.SACK_OF_PENNIES then

          pos = entity.Position
          break
        end
      end

      -- Random Coin - 5.20.0
      RPGlobals.RNGCounter.SackOfPennies = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.SackOfPennies)
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, pos, vel,
                 player, 0, RPGlobals.RNGCounter.SackOfPennies)
    end
  end

  -- Little C.H.A.D (96)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_LITTLE_CHAD) then -- 96
    -- This drops a half a red heart based on the formula:
    -- floor(roomsCleared / 1.1) > 0 && floor(roomsCleared / 1.1) & 1 == 0
    if math.floor(newRoomsCleared / constant1) > 0 and math.floor(newRoomsCleared / constant1) & 1 == 0 then
      -- Get the position of the familiar
      for i, entity in pairs(Isaac.GetRoomEntities()) do
        -- Little C.H.A.D. - 3.22
        if entity.Type == EntityType.ENTITY_FAMILIAR and
           entity.Variant == FamiliarVariant.LITTLE_CHAD then

          pos = entity.Position
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
      for i, entity in pairs(Isaac.GetRoomEntities()) do
        -- The Relic - 3.23
        if entity.Type == EntityType.ENTITY_FAMILIAR and
           entity.Variant == FamiliarVariant.RELIC then

          pos = entity.Position
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
      for i, entity in pairs(Isaac.GetRoomEntities()) do
        -- Bomb Bag - 3.20
        if entity.Type == EntityType.ENTITY_FAMILIAR and
           entity.Variant == FamiliarVariant.BOMB_BAG then

          pos = entity.Position
          break
        end
      end

      -- Random Bomb - 5.40.0
      RPGlobals.RNGCounter.BombBag = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.BombBag)
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, pos, vel, player, 0, RPGlobals.RNGCounter.BombBag)
    end
  end

  -- Juicy Sack (266)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_JUICY_SACK) then -- 266
    -- Get the position of the familiar
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      -- Juicy Sack - 3.52
      if entity.Type == EntityType.ENTITY_FAMILIAR and
         entity.Variant == FamiliarVariant.JUICY_SACK then

        pos = entity.Position
        break
      end
    end

    -- Spawn either 1 or 2 blue spiders (50% chance of each)
    RPGlobals.RNGCounter.JuicySack = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.JuicySack)
    math.randomseed(RPGlobals.RNGCounter.JuicySack)
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
      for i, entity in pairs(Isaac.GetRoomEntities()) do
        -- Mystery Sack - 3.57
        if entity.Type == EntityType.ENTITY_FAMILIAR and
           entity.Variant == FamiliarVariant.MYSTERY_SACK then

          pos = entity.Position
          break
        end
      end

      -- First, decide whether we get a heart, coin, bomb, or key
      RPGlobals.RNGCounter.MysterySack = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.MysterySack)
      math.randomseed(RPGlobals.RNGCounter.MysterySack)
      local sackPickupType = math.random(1, 4)
      RPGlobals.RNGCounter.MysterySack = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.MysterySack)

      -- If heart
      if sackPickupType == 1 then
        -- Random Heart - 5.10.0
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, pos, vel,
                   player, 0, RPGlobals.RNGCounter.MysterySack)

      -- If coin
      elseif sackPickupType == 2 then
        -- Random Coin - 5.20.0
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, pos, vel,
                   player, 0, RPGlobals.RNGCounter.MysterySack)

      -- If bomb
      elseif sackPickupType == 3 then
        -- Random Bomb - 5.40.0
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, pos, vel,
                   player, 0, RPGlobals.RNGCounter.MysterySack)

      -- If key
      elseif sackPickupType == 4 then
        -- Random Key - 5.30.0
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, pos, vel,
                   player, 0, RPGlobals.RNGCounter.MysterySack)
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
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      -- Lil Chest - 3.82
      if entity.Type == EntityType.ENTITY_FAMILIAR and
         entity.Variant == FamiliarVariant.LIL_CHEST then

        pos = entity.Position
        break
      end
    end

    -- First, decide whether we get a trinket
    RPGlobals.RNGCounter.LilChest = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.LilChest)
    math.randomseed(RPGlobals.RNGCounter.LilChest)
    local chestTrinket = math.random(1, 1000)
    if chestTrinket <= 100 or
       (player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 125) then

       -- Random Trinket - 5.350.0
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, pos, vel,
                 player, 0, RPGlobals.RNGCounter.LilChest)
    else
      -- Second, decide whether it spawns a consumable
      RPGlobals.RNGCounter.LilChest = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.LilChest)
      math.randomseed(RPGlobals.RNGCounter.LilChest)
      local chestConsumable = math.random(1, 10000)
      if chestConsumable <= 2500 or
         (player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 3125) then

        -- Third, decide whether we get a heart, coin, bomb, or key
        RPGlobals.RNGCounter.LilChest = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.LilChest)
        math.randomseed(RPGlobals.RNGCounter.LilChest)
        local chestPickupType = math.random(1, 4)
        RPGlobals.RNGCounter.LilChest = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.LilChest)

        -- If heart
        if chestPickupType == 1 then
          -- Random Heart - 5.10.0
          game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, pos, vel,
                     player, 0, RPGlobals.RNGCounter.LilChest)

        -- If coin
        elseif chestPickupType == 2 then
          -- Random Coin - 5.20.0
          game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, pos, vel,
                     player, 0, RPGlobals.RNGCounter.LilChest)

        -- If bomb
        elseif chestPickupType == 3 then
          -- Random Bomb - 5.40.0
          game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, pos, vel,
                     player, 0, RPGlobals.RNGCounter.LilChest)

        -- If key
        elseif chestPickupType == 4 then
          -- Random Key - 5.30.0
          game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, pos, vel,
                     player, 0, RPGlobals.RNGCounter.LilChest)
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
      for i, entity in pairs(Isaac.GetRoomEntities()) do
        -- Rune Bag - 3.91
        if entity.Type == EntityType.ENTITY_FAMILIAR and
           entity.Variant == FamiliarVariant.RUNE_BAG then

          pos = entity.Position
          break
        end
      end

      -- For some reason you cannot spawn the normal "Random Rune" entity (5.301.0)
      -- So, spawn a random card (5.300.0) over and over until we get a rune
      while true do
        RPGlobals.RNGCounter.RuneBag = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.RuneBag)
        local entity = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD,
                                  pos, vel, player, 0, RPGlobals.RNGCounter.RuneBag)
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
      for i, entity in pairs(Isaac.GetRoomEntities()) do
        -- Acid Baby - 3.112
        if entity.Type == EntityType.ENTITY_FAMILIAR and
           entity.Variant == FamiliarVariant.ACID_BABY then

          pos = entity.Position
          break
        end
      end

      -- Random Pill - 5.70.0
      RPGlobals.RNGCounter.AcidBaby = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.AcidBaby)
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, pos, vel,
                 player, 0, RPGlobals.RNGCounter.AcidBaby)
    end
  end

  -- Sack of Sacks (500)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SACK_OF_SACKS) then -- 500
    -- This drops a sack based on the formula:
    -- floor(roomsCleared / 1.1) > 0 && floor(roomsCleared / 1.1) & 1 == 0
    if math.floor(newRoomsCleared / constant1) > 0 and math.floor(newRoomsCleared / constant1) & 1 == 0 then
      -- Get the position of the familiar
      for i, entity in pairs(Isaac.GetRoomEntities()) do
        -- Sack of Sacks - 3.114
        if entity.Type == EntityType.ENTITY_FAMILIAR and
           entity.Variant == FamiliarVariant.SACK_OF_SACKS then

          pos = entity.Position
          break
        end
      end

      -- Grab Bag - 5.69.0
      RPGlobals.RNGCounter.SackOfSacks = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.SackOfSacks)
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_GRAB_BAG, pos, vel,
                 player, 0, RPGlobals.RNGCounter.SackOfSacks)
    end
  end
end

return RPFastClear

local RPFastClear = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")
local RPSoulJar = require("src/rpsouljar")

--
-- Variables
--

RPFastClear.familiars = {} -- Reset in the "RPFastClear:InitRun()" function
RPFastClear.aliveEnemies = {} -- Reset in the "RPCallbacks:PostNewRoom2()" function
RPFastClear.aliveEnemiesCount = 0 -- Reset in the "RPCallbacks:PostNewRoom2()" function
RPFastClear.buttonsAllPushed = false -- Reset in the "RPCallbacks:PostNewRoom2()" function
RPFastClear.delayFrame = 0

--
-- Fast clear functions
--

-- Called from the PostGameStarted callback
function RPFastClear:InitRun()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local levelSeed = level:GetDungeonPlacementSeed()

  local familiars = {
    "BombBag",
    "SackOfPennies",
    "LittleCHAD",
    "TheRelic",
    "JuicySack",
    "MysterySack",
    "Bumbo",
    "LilChest",
    "RuneBag",
    "SpiderMod",
    "AcidBaby",
    "SackOfSacks",
  }
  for i = 1, #familiars do
    RPFastClear.familiars[familiars[i]] = {
      seed         = levelSeed,
      roomsCleared = 0,
      incremented  = false,
    }
  end
end

-- Called from the NPCUpdate callback
function RPFastClear:NPCUpdate(npc)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local room = game:GetRoom()
  local roomClear = room:IsClear()

  -- We don't care if the room is cleared already or if this is a non-battle NPC
  -- (the room clear state is always true when fighting in Challenge Rooms and Boss Rushes,
  -- but we don't want fast-clear to apply to those due to limitations in the Afterbirth+ API)
  if roomClear or
     npc.CanShutDoors == false then

    return
  end

  -- Add new enemies to the list
  if npc:IsDead() == false then
    if RPFastClear.aliveEnemies[npc.Index] == nil then
      RPFastClear.aliveEnemies[npc.Index] = true
      RPFastClear.aliveEnemiesCount = RPFastClear.aliveEnemiesCount + 1
      --Isaac.DebugString("Added NPC " .. tostring(npc.Index) .. ", " ..
      --                  "total: " .. tostring(RPFastClear.aliveEnemiesCount))
    end
    return
  end

  -- The NPC is dead, so remove it from the table
  if RPFastClear.aliveEnemies[npc.Index] ~= nil then
    RPFastClear.aliveEnemies[npc.Index] = nil
    RPFastClear.aliveEnemiesCount = RPFastClear.aliveEnemiesCount - 1
    --Isaac.DebugString("Removed NPC " .. tostring(npc.Index) .. ", " ..
    --                  "total: " .. tostring(RPFastClear.aliveEnemiesCount))
  end

  -- Reset the exception list delay frame
  if RPFastClear.delayFrame ~= 0 and
     gameFrameCount > RPFastClear.delayFrame then

    RPFastClear.delayFrame = 0
  end

  -- Check to see if any other enemies are alive in the room
  if gameFrameCount <= 2 and -- If a Mushroom is replaced, the room can be clear of enemies on the first or second frame
     RPFastClear.delayFrame == 0 and
     RPFastClear.aliveEnemiesCount == 0 and
     RPFastClear:CheckAllPressurePlatesPushed() and
     RPFastClear:CheckFastClearException(npc) == false then

    RPFastClear:ClearRoom()
  end
end

function RPFastClear:CheckAllPressurePlatesPushed()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()

  -- If we are in a puzzle room, check to see if all of the plates have been pressed
  if room:HasTriggerPressurePlates() == false or
     RPFastClear.buttonsAllPushed then

    return true
  end

  -- Check all the grid entities in the room
  local num = room:GetGridSize()
  for i = 1, num do
    local gridEntity = room:GetGridEntity(i)
    if gridEntity ~= nil then
      -- If this entity is a trap door
      local test = gridEntity:ToPressurePlate()
      if test ~= nil then
        if gridEntity:GetSaveState().State ~= 3 then
          return false
        end
      end
    end
  end

  RPFastClear.buttonsAllPushed = true
  return true
end

function RPFastClear:CheckFastClearException(npc)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  if npc:GetChampionColorIdx() == 12 or -- Dark Red champion (collapses into a flesh pile upon death)
     npc:GetChampionColorIdx() == 15 or -- Pulsing Green champion (splits into two copies of itself upon death)
     npc:GetChampionColorIdx() == 17 or -- Light White champion (spawns one or more flies upon death)
     npc.Type == EntityType.ENTITY_GAPER or -- 10
     -- All 3 Gaper types have a chance to split into Gusher (11.0) or Pacer (11.1)
     (npc.Type == EntityType.ENTITY_MULLIGAN and npc.Variant == 0) or -- 16 (Mulligoon and Muliboon do not split)
     -- Mulligan splits into 4 flies; nothing will spawn if damage is high enough
     npc.Type == EntityType.ENTITY_HIVE or -- 22 (both variants split)
     -- Hive splits into 4 flies and Drowned Hive splits into 2 Drowned Chargers
     (npc.Type == EntityType.ENTITY_GLOBIN and npc.State == 4) or -- 24 (all 3 variants split)
     -- (they have been proven to cause the doors to open prematurely)
     (npc.Type == EntityType.ENTITY_BOOMFLY and npc.Variant == 2) or -- 25
     -- Drowned Boom Flies split into a Drowned Charger
     (npc.Type == EntityType.ENTITY_ENVY and npc.Variant == 0) or -- Envy (51.0)
     (npc.Type == EntityType.ENTITY_ENVY and npc.Variant == 1) or -- Super Envy (51.1)
     (npc.Type == EntityType.ENTITY_ENVY and npc.Variant == 10) or -- Envy (level 2) (51.10)
     (npc.Type == EntityType.ENTITY_ENVY and npc.Variant == 11) or -- Super Envy (level 2) (51.11)
     (npc.Type == EntityType.ENTITY_ENVY and npc.Variant == 20) or -- Envy (level 3) (51.20)
     (npc.Type == EntityType.ENTITY_ENVY and npc.Variant == 21) or -- Super Envy (level 3) (51.21)
     -- 30 and 31 are the final forms of Envy and Super Envy respectively
     npc.Type == EntityType.ENTITY_MEMBRAIN or -- 57
     -- Membrain splits into 2 Brains (32.0) and Mama Guts splits into 2 Guts (40.0)
     npc.Type == EntityType.ENTITY_FISTULA_BIG or -- 71 (both variants split; Teratoma also counts as Fistula)
     npc.Type == EntityType.ENTITY_FISTULA_MEDIUM or -- 72 (both variants split; Teratoma also counts as Fistula)
     npc.Type == EntityType.ENTITY_FISTULA_SMALL or -- 73 (both variants split; Teratoma also counts as Fistula)
     npc.Type == EntityType.ENTITY_BLASTOCYST_BIG or -- 74
     npc.Type == EntityType.ENTITY_BLASTOCYST_MEDIUM or -- 75
     npc.Type == EntityType.ENTITY_BLASTOCYST_SMALL or -- 76
     npc.Type == EntityType.ENTITY_MOTER or -- 80
     -- Moter splits into 2 Attack Flies (18.0)
     (npc.Type == EntityType.ENTITY_FALLEN and npc.Variant ~= 1 and npc.Scale ~= 0.75) or -- 81
     -- Fast-clear should apply to Krampus and split Fallens
     npc.Type == EntityType.ENTITY_GURGLE or -- 87
     -- Gurgles have a chance to split into a Splasher (238.0)
     npc.Type == EntityType.ENTITY_HANGER or -- 90
     -- Hangers split into an Attack Fly (18.0)
     npc.Type == EntityType.ENTITY_SWARMER or -- 91
     -- Swarmers split into a Boom Fly (25.0)
     npc.Type == EntityType.ENTITY_BIGSPIDER or -- 94
     -- Big Spiders split into 2 Spiders (85.0)
     npc.Type == EntityType.ENTITY_NEST or -- 205 (looks like a Mulligan)
     -- Nests have a chance to split into a Trite (29.1) or Big Spider (94.0)
     (npc.Type == EntityType.ENTITY_FATTY and npc.Variant == 1) or -- 208
     -- Pale Fatties have a chance to split into a Blubber (210.0)
     npc.Type == EntityType.ENTITY_FAT_SACK or -- 209
     -- Fat Sacks have a chance to split into a Blubber (210.0)
     npc.Type == EntityType.ENTITY_BLUBBER or -- 210
     -- Blubbers have a chance to split into a Half Sack (211.0)
     npc.Type == EntityType.ENTITY_SWINGER or -- 216 (both variants split)
     -- Swingers have a chance to split into a Maw (26.0) if you kill the body,
     -- or a Globin (24.0) if you kill the head
     npc.Type == EntityType.ENTITY_SQUIRT or -- 220 (both variants split)
     -- Squirts split into 2 Dips (217.0) and Dark Squirts split into 2 Clots (15.1)
     (npc.Type == EntityType.ENTITY_SKINNY and npc.Variant == 1) or -- 226 (Rotties split)
     -- Rotties split into a Bony (227.0)
     npc.Type == EntityType.ENTITY_DINGA or -- 223
     -- Dingas split into two Squirts (220.0)
     npc.Type == EntityType.ENTITY_GRUB or -- 239
     -- Grubs split into a random Maggot
     (npc.Type == EntityType.ENTITY_CONJOINED_FATTY and npc.Variant == 0) or -- 257
     -- Coinjoined Fatties split into a Fatty (208.0); Blue Conjoined Fatties do not split
     npc.Type == EntityType.ENTITY_BLACK_GLOBIN or -- 278
     -- Black Globin's split into Black Globin's Head (279.0) and Black Globin's Body (280.0)
     npc.Type == EntityType.ENTITY_MEGA_CLOTTY or -- 282
     -- Mega Clotties split into 2 Clotties (15.0)
     npc.Type == EntityType.ENTITY_MOMS_DEAD_HAND or -- 287
     -- Mom's Dead Hands split into 2 Spiders (85.0)
     npc.Type == EntityType.ENTITY_MEATBALL or -- 290
     -- Meatballs split into a Host (27.0)
     npc.Type == EntityType.ENTITY_BLISTER or -- 303
     -- Blisters split into a Sack (30.2)
     npc.Type == EntityType.ENTITY_PORTAL or -- 306
     -- Portals don't split, but they do spawn random enemies and
     -- have been proven to cause the doors to open prematurely
     npc.Type == EntityType.ENTITY_BROWNIE or -- 402
     -- Brownie splits into a Dangle (217.2)
     npc.Type == EntityType.ENTITY_MEGA_SATAN or -- 274
     -- We explicitly handle the win condition for the Mega Satan fight in the NPCUpdate callback
     npc.Type == EntityType.ENTITY_MEGA_SATAN_2 then -- 275

    -- An NPC died that is on the exception list, so we have to stall from fast-clearing the room for the next 4 frames
    -- (another enemy in the room could die before the adds from this splitting enemy has spawned)
    RPFastClear.delayFrame = gameFrameCount + 4
    return true
  else
    return false
  end
end

-- Fast-clear for puzzle rooms (1/2)
-- (when puzzle rooms are cleared, there is an annoying delay before the doors are opened)
-- (called from the PostUpdate callback)
function RPFastClear:CheckPuzzleRoom()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomClear = room:IsClear()

  -- If we are in a puzzle room, check to see if all of the plates have been pressed
  if roomClear or
     room:HasTriggerPressurePlates() == false or
     RPFastClear.buttonsAllPushed then

    return
  end

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
    RPFastClear.buttonsAllPushed = true
    RPFastClear:CheckAllAlive()
  end
end

-- Fast-clear for puzzle rooms (2/2)
-- (check to see if any other enemies are alive in the room)
function RPFastClear:CheckAllAlive()
  local allDead = true
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    local npc = entity:ToNPC()
    if npc ~= nil then
      if npc:IsDead() == false and npc.CanShutDoors then
        allDead = false
        break
      end
    end
  end
  if allDead then
    -- Manually clear the room, emulating all the steps that the game does
    RPFastClear:ClearRoom()
  end
end

-- This emulates what happens when you normally clear a room
function RPFastClear:ClearRoom()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local room = game:GetRoom()
  local roomType = room:GetType()
  local player = game:GetPlayer(0)
  local activeItem = player:GetActiveItem()
  local activeCharge = player:GetActiveCharge()
  local batteryCharge = player:GetBatteryCharge()
  local sfx = SFXManager()

  -- Set the room clear to true (so that it gets marked off on the minimap)
  room:SetClear(true)
  Isaac.DebugString("Initiated a fast-clear.")

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

  -- Manually kill Death's Heads and Flesh Death's Heads
  -- (by default, they will only die after the death animations are completed)
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_DEATHS_HEAD and entity.Variant == 0 then -- 212.0
      -- Activate its death state
      entity:ToNPC().State = 18
    elseif entity.Type == EntityType.ENTITY_FLESH_DEATHS_HEAD then -- 286.0
      -- Activating the death state won't make the tears explode out of it, so just kill it and spawn another one to die
      entity.Visible = false
      entity:Kill()
      local newHead = game:Spawn(entity.Type, entity.Variant, entity.Position, entity.Velocity,
                                 entity.Parent, entity.SubType, entity.InitSeed)
      newHead:ToNPC().State = 18
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

  -- Subvert the "Would you like to do a Victory Lap!?" popup that happens after defeating The Lamb
  if stage == 11 and stageType == 0 and -- 11.0 is the Dark Room
     roomType == RoomType.ROOM_BOSS and -- 5
     roomIndex ~= GridRooms.ROOM_MEGA_SATAN_IDX then -- -7

    game:Spawn(Isaac.GetEntityTypeByName("Room Clear Delay Effect"),
               Isaac.GetEntityVariantByName("Room Clear Delay Effect"),
               RPGlobals:GridToPos(0, 0), Vector(0, 0), nil, 0, 0)
    Isaac.DebugString("Spawned the \"Room Clear Delay Effect\" custom entity (for The Lamb).")

    -- Spawn a big chest (which will get replaced with a trophy on the next frame if we happen to be in a race)
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, -- 5.340
               room:GetCenterPos(), Vector(0, 0), nil, 0, 0)

  else
    -- Spawns the award for clearing the room (the pickup, chest, etc.)
    -- (this also makes the trapdoor appear if we are in a boss room)
    room:SpawnClearAward() -- This takes into account their luck and so forth
  end

  -- Give a charge to the player's active item
  if player:NeedsCharge() == true then
    -- Find out if we are in a 2x2 or L room
    local chargesToAdd = 1
    local shape = room:GetRoomShape()
    if shape >= 8 then
      -- L rooms and 2x2 rooms should grant 2 charges
      chargesToAdd = 2
    elseif player:HasTrinket(TrinketType.TRINKET_AAA_BATTERY) and -- 3
           activeCharge == RPGlobals:GetItemMaxCharges(activeItem) - 2 then

      -- The AAA Battery grants an extra charge when the active item is one away from being fully charged
      chargesToAdd = 2
    elseif player:HasTrinket(TrinketType.TRINKET_AAA_BATTERY) and -- 3
           activeCharge == RPGlobals:GetItemMaxCharges(activeItem) and
           player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and -- 63
           batteryCharge == RPGlobals:GetItemMaxCharges(activeItem) - 2 then

      -- The AAA Battery should grant an extra charge when the active item is one away from being fully charged
      -- with The Battery (this is bugged in vanilla for The Battery)
      chargesToAdd = 2
    end

    -- Add the correct amount of charges
    local currentCharge = player:GetActiveCharge()
    player:SetActiveCharge(currentCharge + chargesToAdd)
  end

  -- Play the sound effect for the door opening
  if room:GetType() ~= RoomType.ROOM_DUNGEON then -- 16
    sfx:Play(SoundEffect.SOUND_DOOR_HEAVY_OPEN, 1, 0, false, 1) -- ID, Volume, FrameDelay, Loop, Pitch
  end

  -- Check to see if any bag familiars will drop anything
  RPFastClear:CheckBagFamiliars()
end

-- Emulate various familiars dropping things
-- (all of these formula were reverse engineered by blcd:
-- https://bindingofisaacrebirth.gamepedia.com/User:Blcd/RandomTidbits#Pickup_Familiars)
function RPFastClear:CheckBagFamiliars()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local zeroVelocity = Vector(0, 0)
  local constant1 = 1.1 -- For Little C.H.A.D., Bomb Bag, Acid Baby, Sack of Sacks
  local constant2 = 1.11 -- For The Relic, Mystery Sack, Rune Bag
  if player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then -- 247
    constant1 = 1.2
    constant2 = 1.15
  end

  -- Look through all of the player's familiars
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_FAMILIAR then -- 3

      if entity.Variant == FamiliarVariant.BOMB_BAG then -- 20
        -- This drops a bomb based on the formula:
        -- floor(cleared / 1.1) > 0 && floor(cleared / 1.1) & 1 == 0
        -- or:
        -- floor(cleared / 1.2) > 0 && floor(cleared / 1.2) & 1 == 0
        local newRoomsCleared = RPFastClear.familiars.BombBag.roomsCleared + 1
        if math.floor(newRoomsCleared / constant1) > 0 and math.floor(newRoomsCleared / constant1) & 1 == 0 then
          -- Random Bomb - 5.40.0
          RPFastClear.familiars.BombBag.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.BombBag.seed)
          game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, entity.Position, zeroVelocity,
                     player, 0, RPFastClear.familiars.BombBag.seed)
        end

      elseif entity.Variant == FamiliarVariant.SACK_OF_PENNIES then -- 21
        -- This drops a penny/nickel/dime/etc. based on the formula:
        -- cleared > 0 && cleared & 1 == 0
        -- or:
        -- cleared > 0 && (cleared & 1 == 0 || rand() % 3 == 0)
        local newRoomsCleared = RPFastClear.familiars.SackOfPennies.roomsCleared + 1
        RPFastClear.familiars.SackOfPennies.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.SackOfPennies.seed)
        math.randomseed(RPFastClear.familiars.SackOfPennies.seed)
        local sackBFFChance = math.random(1, 4294967295)
        if newRoomsCleared > 0 and
           (newRoomsCleared & 1 == 0 or
            (player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and sackBFFChance % 3 == 0)) then

          -- Random Coin - 5.20.0
          RPFastClear.familiars.SackOfPennies.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.SackOfPennies.seed)
          game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, entity.Position, zeroVelocity,
                     player, 0, RPFastClear.familiars.SackOfPennies.seed)
        end

      elseif entity.Variant == FamiliarVariant.LITTLE_CHAD then -- 22
        -- This drops a half a red heart based on the formula:
        -- floor(cleared / 1.1) > 0 && floor(cleared / 1.1) & 1 == 0
        -- or:
        -- floor(cleared / 1.2) > 0 && floor(cleared / 1.2) & 1 == 0
        local newRoomsCleared = RPFastClear.familiars.LittleCHAD.roomsCleared + 1
        if math.floor(newRoomsCleared / constant1) > 0 and math.floor(newRoomsCleared / constant1) & 1 == 0 then
          -- Heart (half) - 5.10.2
          game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, entity.Position, zeroVelocity,
                     player, 2, 0)
        end

      elseif entity.Variant == FamiliarVariant.RELIC then -- 23
        -- This drops a soul heart based on the formula:
        -- floor(cleared / 1.11) & 3 == 2
        -- or:
        -- floor(cleared / 1.15) & 3 == 2
        local newRoomsCleared = RPFastClear.familiars.TheRelic.roomsCleared + 1
        if math.floor(newRoomsCleared / constant2) & 3 == 2 then
          -- Heart (soul) - 5.10.3
          game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, entity.Position, zeroVelocity,
                     player, 3, 0)
        end

      elseif entity.Variant == FamiliarVariant.JUICY_SACK then -- 52

        -- Spawn either 1 or 2 blue spiders (50% chance of each)
        RPFastClear.familiars.JuicySack.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.JuicySack.seed)
        math.randomseed(RPFastClear.familiars.JuicySack.seed)
        local spiders = math.random(1, 2)
        player:AddBlueSpider(entity.Position)
        if spiders == 2 then
          player:AddBlueSpider(entity.Position)
        end

        -- The BFFs! synergy gives an additional spider
        if player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
          player:AddBlueSpider(entity.Position)
        end

      elseif entity.Variant == FamiliarVariant.MYSTERY_SACK then -- 57
        -- This drops a heart, coin, bomb, or key based on the formula:
        -- floor(cleared / 1.11) & 3 == 2
        -- or:
        -- floor(cleared / 1.15) & 3 == 2
        -- (also, each pickup sub-type has an equal chance of occuring)
        local newRoomsCleared = RPFastClear.familiars.MysterySack.roomsCleared + 1
        if math.floor(newRoomsCleared / constant2) & 3 == 2 then
          -- First, decide whether we get a heart, coin, bomb, or key
          RPFastClear.familiars.MysterySack.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.MysterySack.seed)
          math.randomseed(RPFastClear.familiars.MysterySack.seed)
          local sackPickupType = math.random(1, 4)
          RPFastClear.familiars.MysterySack.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.MysterySack.seed)
          math.randomseed(RPFastClear.familiars.MysterySack.seed)

          if sackPickupType == 1 then
            local heartType = math.random(1, 10) -- From Heart (5.10.1) to Blended Heart (5.10.10)
            game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, entity.Position, zeroVelocity,
                       player, heartType, RPFastClear.familiars.MysterySack.seed)

          elseif sackPickupType == 2 then
            local coinType = math.random(1, 6) -- From Penny (5.20.1) to Sticky Nickel (5.20.6)
            game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, entity.Position, zeroVelocity,
                       player, coinType, RPFastClear.familiars.MysterySack.seed)

          elseif sackPickupType == 3 then
            local keyType = math.random(1, 4) -- From Key (5.30.1) to Charged Key (5.30.4)
            game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, entity.Position, zeroVelocity,
                       player, keyType, RPFastClear.familiars.MysterySack.seed)

          elseif sackPickupType == 4 then
            local bombType = math.random(1, 5) -- From Bomb (5.40.1) to Megatroll Bomb (5.40.5)
            game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, entity.Position, zeroVelocity,
                       player, bombType, RPFastClear.familiars.MysterySack.seed)
          end
        end

      elseif entity.Variant == FamiliarVariant.LIL_CHEST then -- 82
        -- This drops a heart, coin, bomb, or key based on the formula:
        -- 10% chance for a trinket, if no trinket, 25% chance for a random consumable (based on time)
        -- Or, with BFFS!, 12.5% chance for a trinket, if no trinket, 31.25% chance for a random consumable
        -- We don't want it based on time in the Racing+ mod

        -- First, decide whether we get a trinket
        RPFastClear.familiars.LilChest.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.LilChest.seed)
        math.randomseed(RPFastClear.familiars.LilChest.seed)
        local chestTrinket = math.random(1, 1000)
        if chestTrinket <= 100 or
           (player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 125) then

           -- Random Trinket - 5.350.0
          game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, entity.Position, zeroVelocity,
                     player, 0, RPFastClear.familiars.LilChest.seed)
        else
          -- Second, decide whether it spawns a consumable
          RPFastClear.familiars.LilChest.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.LilChest.seed)
          math.randomseed(RPFastClear.familiars.LilChest.seed)
          local chestConsumable = math.random(1, 10000)
          if chestConsumable <= 2500 or
             (player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 3125) then

            -- Third, decide whether we get a heart, coin, bomb, or key
            RPFastClear.familiars.LilChest.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.LilChest.seed)
            math.randomseed(RPFastClear.familiars.LilChest.seed)
            local chestPickupType = math.random(1, 4)
            RPFastClear.familiars.LilChest.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.LilChest.seed)

            -- If heart
            if chestPickupType == 1 then
              -- Random Heart - 5.10.0
              game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, entity.Position, zeroVelocity,
                         player, 0, RPFastClear.familiars.LilChest.seed)

            -- If coin
            elseif chestPickupType == 2 then
              -- Random Coin - 5.20.0
              game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, entity.Position, zeroVelocity,
                         player, 0, RPFastClear.familiars.LilChest.seed)

            -- If bomb
            elseif chestPickupType == 3 then
              -- Random Bomb - 5.40.0
              game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, entity.Position, zeroVelocity,
                         player, 0, RPFastClear.familiars.LilChest.seed)

            -- If key
            elseif chestPickupType == 4 then
              -- Random Key - 5.30.0
              game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, entity.Position, zeroVelocity,
                         player, 0, RPFastClear.familiars.LilChest.seed)
            end
          end
        end

      elseif entity.Variant == FamiliarVariant.BUMBO and -- 88
             entity:ToFamiliar().State + 1 == 2 then
             -- It will be state 0 at level 1, state 1 at level 2, state 2 at level 3, and state 3 at level 4

        -- Level 2 Bumbo has a 32% / 40% chance to drop a random pickup
        RPFastClear.familiars.Bumbo.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.Bumbo.seed)
        math.randomseed(RPFastClear.familiars.Bumbo.seed)
        local chestTrinket = math.random(1, 100)
        if chestTrinket <= 32 or
           (player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 40) then

          -- Spawn a random pickup
          game:Spawn(EntityType.ENTITY_PICKUP, 0, entity.Position, zeroVelocity,
                     player, 0, RPFastClear.familiars.Bumbo.seed)
        end

      elseif entity.Variant == FamiliarVariant.RUNE_BAG then -- 91
        -- This drops a random rune based on the formula:
        -- floor(roomsCleared / 1.11) & 3 == 2
        local newRoomsCleared = RPFastClear.familiars.RuneBag.roomsCleared + 1
        if math.floor(newRoomsCleared / constant2) & 3 == 2 then
          -- For some reason you cannot spawn the normal "Random Rune" entity (5.301.0)
          -- So, spawn a random card (5.300.0) over and over until we get a rune
          while true do
            RPFastClear.familiars.RuneBag.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.RuneBag.seed)
            local rune = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, entity.Position,
                                    zeroVelocity, player, 0, RPFastClear.familiars.RuneBag.seed)
            -- Hagalaz is 32 and Black Rune is 41
            if rune.SubType >= 32 and rune.SubType <= 41 then
              break
            end
            rune:Remove()
          end
        end

      elseif entity.Variant == FamiliarVariant.SPIDER_MOD then -- 94
        -- Spider Mod has a 10% or 12.5% chance to drop something
        RPFastClear.familiars.SpiderMod.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.SpiderMod.seed)
        math.randomseed(RPFastClear.familiars.SpiderMod.seed)
        local chestTrinket = math.random(1, 1000)
        if chestTrinket <= 100 or
           (player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 125) then

          -- There is a 1/3 chance to spawn a battery and a 2/3 chance to spawn a blue spider
          RPFastClear.familiars.SpiderMod.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.SpiderMod.seed)
          math.randomseed(RPFastClear.familiars.SpiderMod.seed)
          local spiderModDrop = math.random(1, 3)
          if spiderModDrop == 1 then
            -- Lil' Battery (5.90)
            game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, entity.Position, zeroVelocity,
                       player, 0, RPFastClear.familiars.SpiderMod.seed)
          else
            player:AddBlueSpider(entity.Position)
          end
        end

      elseif entity.Variant == FamiliarVariant.ACID_BABY then -- 112
        -- This drops a pill based on the formula:
        -- floor(roomsCleared / 1.1) > 0 && floor(roomsCleared / 1.1) & 1 == 0
        local newRoomsCleared = RPFastClear.familiars.AcidBaby.roomsCleared + 1
        if math.floor(newRoomsCleared / constant1) > 0 and math.floor(newRoomsCleared / constant1) & 1 == 0 then
          -- Random Pill - 5.70.0
          RPFastClear.familiars.AcidBaby.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.AcidBaby.seed)
          game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, entity.Position, zeroVelocity,
                     player, 0, RPFastClear.familiars.AcidBaby.seed)
        end

      elseif entity.Variant == FamiliarVariant.SACK_OF_SACKS then -- 114
        -- This drops a sack based on the formula:
        -- floor(roomsCleared / 1.1) > 0 && floor(roomsCleared / 1.1) & 1 == 0
        local newRoomsCleared = RPFastClear.familiars.SackOfSacks.roomsCleared + 1
        if math.floor(newRoomsCleared / constant1) > 0 and math.floor(newRoomsCleared / constant1) & 1 == 0 then
          -- Grab Bag - 5.69.0
          RPFastClear.familiars.SackOfSacks.seed = RPGlobals:IncrementRNG(RPFastClear.familiars.SackOfSacks.seed)
          game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_GRAB_BAG, entity.Position, zeroVelocity,
                     player, 0, RPFastClear.familiars.SackOfSacks.seed)
        end
      end
    end
  end
end

function RPFastClear:IncrementBagFamiliars()
  -- Look through all of the player's familiars
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_FAMILIAR then -- 3
      -- We only want to increment the rooms cleared variable once, even if they have multiple of the same familiar
      if entity.Variant == FamiliarVariant.BOMB_BAG and -- 20
         RPFastClear.familiars.BombBag.incremented == false then

        RPFastClear.familiars.BombBag.incremented = true
        RPFastClear.familiars.BombBag.roomsCleared = RPFastClear.familiars.BombBag.roomsCleared + 1

      elseif entity.Variant == FamiliarVariant.SACK_OF_PENNIES and -- 21
             RPFastClear.familiars.SackOfPennies.incremented == false then

        RPFastClear.familiars.SackOfPennies.incremented = true
        RPFastClear.familiars.SackOfPennies.roomsCleared = RPFastClear.familiars.SackOfPennies.roomsCleared + 1

      elseif entity.Variant == FamiliarVariant.LITTLE_CHAD and -- 22
             RPFastClear.familiars.LittleCHAD.incremented == false then

        RPFastClear.familiars.LittleCHAD.incremented = true
        RPFastClear.familiars.LittleCHAD.roomsCleared = RPFastClear.familiars.LittleCHAD.roomsCleared + 1

      elseif entity.Variant == FamiliarVariant.RELIC and -- 23
             RPFastClear.familiars.TheRelic.incremented == false then

        RPFastClear.familiars.TheRelic.incremented = true
        RPFastClear.familiars.TheRelic.roomsCleared = RPFastClear.familiars.TheRelic.roomsCleared + 1
        Isaac.DebugString("The Relic counter increased: " .. tostring(RPFastClear.familiars.TheRelic.roomsCleared))

      elseif entity.Variant == FamiliarVariant.MYSTERY_SACK and -- 57
             RPFastClear.familiars.MysterySack.incremented == false then

        RPFastClear.familiars.MysterySack.incremented = true
        RPFastClear.familiars.MysterySack.roomsCleared = RPFastClear.familiars.MysterySack.roomsCleared + 1

      elseif entity.Variant == FamiliarVariant.RUNE_BAG and -- 91
             RPFastClear.familiars.RuneBag.incremented == false then

        RPFastClear.familiars.RuneBag.incremented = true
        RPFastClear.familiars.RuneBag.roomsCleared = RPFastClear.familiars.RuneBag.roomsCleared + 1

      elseif entity.Variant == FamiliarVariant.ACID_BABY and -- 112
             RPFastClear.familiars.AcidBaby.incremented == false then

        RPFastClear.familiars.AcidBaby.incremented = true
        RPFastClear.familiars.AcidBaby.roomsCleared = RPFastClear.familiars.AcidBaby.roomsCleared + 1

      elseif entity.Variant == FamiliarVariant.SACK_OF_SACKS and -- 114
             RPFastClear.familiars.SackOfSacks.incremented == false then

        RPFastClear.familiars.SackOfSacks.incremented = true
        RPFastClear.familiars.SackOfSacks.roomsCleared = RPFastClear.familiars.SackOfSacks.roomsCleared + 1
      end
    end
  end

  -- Reset the incremented variable
  for k, v in pairs(RPFastClear.familiars) do
    RPFastClear.familiars[k].incremented = false
  end
end

return RPFastClear

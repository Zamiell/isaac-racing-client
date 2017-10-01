local RPFastClear = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")
local RPSoulJar = require("src/rpsouljar")

--
-- Variables
--

-- These are reset in the "RPFastClear:InitRun()" function
RPFastClear.familiars = {}

-- These are reset in the "RPFastClear:InitRun()" function and
-- the "RPFastClear:CheckNewNPC()" function (upon entering a new room)
RPFastClear.aliveEnemies = {}
RPFastClear.aliveEnemiesCount = 0
RPFastClear.roomInitializing = false -- Set to true in the MC_POST_NEW_ROOM callback
RPFastClear.delayFrame = 0

-- These are reset in the "RPPostNewRoom:NewRoom()" function
RPFastClear.buttonsAllPushed = false

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

  RPFastClear.aliveEnemies = {}
  RPFastClear.aliveEnemiesCount = 0
  RPFastClear.buttonsAllPushed = false
  RPFastClear.roomInitializing = false
  RPFastClear.delayFrame = 0
end

-- ModCallbacks.MC_NPC_UPDATE (0)
function RPFastClear:NPCUpdate(npc)
  -- Friendly enemies (from Delirious or Friendly Ball) will be added to the aliveEnemies table because
  -- there are no flags set yet in the MC_POST_NPC_INIT callback
  -- Thus, we have to wait until they are initialized and then remove them from the table
  if npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
    -- Remove it from the list if it is on it
    RPFastClear:CheckDeadNPC(npc)
    return
  end

  -- We can't rely on the MC_POST_NPC_INIT callback because it is not fired for certain NPCs
  -- (like when a Gusher emerges from killing a Gaper)
  RPFastClear:CheckNewNPC(npc)
end

-- ModCallbacks.MC_NPC_UPDATE (0)
-- EntityType.ENTITY_RAGLING (246)
function RPFastClear:NPC246(npc)
  -- Rag Man Raglings don't actually die (they turn into patches on the ground),
  -- so we need to manually keep track of when this happens
  if npc.Variant == 1 and -- 246.1
     npc.State == NpcState.STATE_UNIQUE_DEATH then -- 16
     -- They go to state 16 when they are patches on the ground

    RPFastClear:CheckDeadNPC(npc)
  end
end

-- ModCallbacks.MC_NPC_UPDATE (0)
-- EntityType.ENTITY_STONEY (302)
function RPFastClear:NPC302(npc)
  -- Stoneys have a chance to morph from EntityType.ENTITY_FATTY (208),
  -- so they will get added to the aliveEnemies table before the room is loaded
  -- To correct for this, we constantly check to see if Stoneys are on the aliveEnemies table
  local index = GetPtrHash(npc)
  if RPFastClear.aliveEnemies[index] ~= nil then
    RPFastClear.aliveEnemies[index] = nil
    RPFastClear.aliveEnemiesCount = RPFastClear.aliveEnemiesCount - 1
    Isaac.DebugString("Removed a Fatty that morphed into Stoney from the aliveEnemies table.")
  end
end

function RPFastClear:CheckNewNPC(npc)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local room = game:GetRoom()
  local roomFrameCount = room:GetFrameCount()

  -- Don't do anything if we are already tracking this NPC
  -- (we can't use npc.Index for this because it is always 0 in the MC_POST_NPC_INIT callback)
  local index = GetPtrHash(npc)
  if RPFastClear.aliveEnemies[index] ~= nil then
    return
  end

  -- We don't care if this is a non-battle NPC
  if npc.CanShutDoors == false then
    return
  end

  -- We don't care if the NPC is already dead
  -- (this is needed because we can enter this function from the MC_NPC_UPDATE callback)
  if npc:IsDead() then
    return
  end

  -- Rag Man Raglings don't actually die (they turn into patches on the ground),
  -- so they will get past the above check
  if npc.Type == EntityType.ENTITY_RAGLING and npc.Variant == 1 and -- 246.1
     npc.State == NpcState.STATE_UNIQUE_DEATH then -- 16
     -- They go to state 16 when they are patches on the ground

    return
  end

  -- We don't care if this is a specific child NPC attached to some other NPC
  if RPFastClear:AttachedNPC(npc) then
    return
  end

  -- If we are entering a new room, flush all of the stuff in the old room
  -- (we can't use the POST_NEW_ROOM callback to handle this since that callback fires after this one)
  -- (roomFrameCount will be at -1 during the initialization phase)
  if roomFrameCount == -1 and RPFastClear.roomInitializing == false then
    RPFastClear.aliveEnemies = {}
    RPFastClear.aliveEnemiesCount = 0
    RPFastClear.roomInitializing = true -- This will get set back to false in the MC_POST_NEW_ROOM callback
    RPFastClear.delayFrame = 0
    Isaac.DebugString("Reset fast-clear variables.")
  end

  -- Keep track of the enemies in the room that are alive
  RPFastClear.aliveEnemies[index] = true
  RPFastClear.aliveEnemiesCount = RPFastClear.aliveEnemiesCount + 1
  Isaac.DebugString("Added NPC " ..
                    tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "." ..
                    tostring(npc.SubType) .. "." .. tostring(npc.State) .. ", " ..
                    "index " .. tostring(index) .. ", " ..
                    "frame " .. tostring(gameFrameCount) .. ", " ..
                    "total " .. tostring(RPFastClear.aliveEnemiesCount))
end

function RPFastClear:AttachedNPC(npc)
  -- These are NPCs that have "CanShutDoors" equal to true naturally by the game,
  -- but shouldn't actually keep the doors closed
  -- (there's no need to add Peep / Bloat eyes here since they die on the same frame as Peep / Bloat)
  if (npc.Type == EntityType.ENTITY_CHARGER and npc.Variant == 0 and npc.Subtype == 1) or -- My Shadow (23.0.1)
     -- These are the black worms generated by My Shadow; they are similar to charmed enemies,
     -- but do not actually have the "charmed" flag set, so we don't want to add them to the "aliveEnemies" table
     (npc.Type == EntityType.ENTITY_DEATH and npc.Variant == 10) or -- Death Scythe (66.10)
     (npc.Type == EntityType.ENTITY_BEGOTTEN and npc.Variant == 10) or -- Begotten Chain (251.10)
     (npc.Type == EntityType.ENTITY_MAMA_GURDY and npc.Variant == 1) or -- Mama Gurdy Left Hand (266.1)
     (npc.Type == EntityType.ENTITY_MAMA_GURDY and npc.Variant == 2) or -- Mama Gurdy Right Hand (266.2)
     (npc.Type == EntityType.ENTITY_BIG_HORN and npc.Variant == 1) or -- Small Hole (411.1)
     (npc.Type == EntityType.ENTITY_BIG_HORN and npc.Variant == 2) then -- Big Hole (411.2)

    return true
  else
    return false
  end
end

-- ModCallbacks.MC_POST_ENTITY_REMOVE (67)
function RPFastClear:PostEntityRemove(entity)
  -- We only care about NPCs dying
  local npc = entity:ToNPC()
  if npc == nil then
    return
  end

  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local index = GetPtrHash(npc)

  Isaac.DebugString("MC_POST_ENTITY_REMOVE - " ..
                    tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "." ..
                    tostring(npc.SubType) .. "." .. tostring(npc.State) .. ", " ..
                    "index " .. tostring(index) .. ", " ..
                    "frame " .. tostring(gameFrameCount))

  -- We can't rely on the MC_POST_ENTITY_KILL callback because it is not fired for certain NPCs
  -- (like when Daddy Long Legs does a stomp attack or a Portal despawns)
  RPFastClear:CheckDeadNPC(npc)
end

-- ModCallbacks.MC_POST_ENTITY_KILL (68)
-- (we can't use the MC_POST_NPC_DEATH callback because that will only fire once the death animation is finished)
function RPFastClear:PostEntityKill(entity)
  -- We only care about NPCs dying
  local npc = entity:ToNPC()
  if npc == nil then
    return
  end

  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local index = GetPtrHash(npc)

  Isaac.DebugString("MC_POST_ENTITY_KILL - " ..
                    tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "." ..
                    tostring(npc.SubType) .. "." .. tostring(npc.State) .. ", " ..
                    "index " .. tostring(index) .. ", " ..
                    "frame " .. tostring(gameFrameCount))

  -- We can't rely on the MC_POST_ENTITY_REMOVE callback because it is only fired once the death animation is complete
  RPFastClear:CheckDeadNPC(npc)
end

function RPFastClear:CheckDeadNPC(npc)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  -- We only care about entities that are in the aliveEnemies table
  local index = GetPtrHash(npc)
  if RPFastClear.aliveEnemies[index] == nil then
    return
  end

  -- We don't care if this is a Dark Red champion flesh pile
  if npc:GetChampionColorIdx() == 12 and -- Dark Red champion (collapses into a flesh pile upon death)
     npc:GetSprite():GetFilename() ~= "gfx/024.000_Globin.anm2" then
     -- The filename will be set to this if it is in the flesh pile state

    -- This callback will be triggered when the champion changes into the flesh pile
    -- We don't want to open the doors yet until the flesh pile is actually killed
    return
  end

  -- Keep track of the enemies in the room that are alive
  RPFastClear.aliveEnemies[index] = nil
  RPFastClear.aliveEnemiesCount = RPFastClear.aliveEnemiesCount - 1
  Isaac.DebugString("Removed NPC " ..
                    tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "." ..
                    tostring(npc.SubType) .. "." .. tostring(npc.State) .. ", " ..
                    "index " .. tostring(index) .. ", " ..
                    "frame " .. tostring(gameFrameCount) .. ", " ..
                    "total " .. tostring(RPFastClear.aliveEnemiesCount))

  -- We want to delay a frame before opening the doors to give time for splitting enemies to spawn their children
  RPFastClear.delayFrame = gameFrameCount + 1

  -- We check every frame to see if the "aliveEnemiesCount" variable is set to 0 in MC_POST_UPDATE callback
end

-- ModCallbacks.MC_POST_UPDATE (1)
-- Check on every frame to see if we need to open the doors
function RPFastClear:PostUpdate()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local room = game:GetRoom()
  local roomClear = room:IsClear()

  -- Disable this on the "Unseeded (Lite)" ruleset
  if RPGlobals.race.rFormat == "unseeded-lite" then
    return
  end

  -- If a frame has passed since an enemy died, reset the delay counter
  if RPFastClear.delayFrame ~= 0 and
     gameFrameCount >= RPFastClear.delayFrame then

    RPFastClear.delayFrame = 0
  end

  -- Check on every frame to see if we need to open the doors
  if RPFastClear.aliveEnemiesCount == 0 and
     RPFastClear.delayFrame == 0 and
     roomClear == false and
     RPFastClear:CheckAllPressurePlatesPushed() and
     gameFrameCount > 1 then -- If a Mushroom is replaced, the room can be clear of enemies on the first frame

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
      local saveState = gridEntity:GetSaveState();
      if saveState.Type == GridEntityType.GRID_PRESSURE_PLATE and -- 20
         saveState.State ~= 3 then

        return false
      end
    end
  end

  RPFastClear.buttonsAllPushed = true
  return true
end

-- This emulates what happens when you normally clear a room
function RPFastClear:ClearRoom()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
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
  Isaac.DebugString("Initiated a fast-clear on frame: " .. tostring(gameFrameCount))

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
    -- This won't work to delay the room clearing if "debug 10" is on

    -- Track that we have defeated The Lamb (for the "Everything" race goal)
    RPGlobals.run.killedLamb = true

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
    sfx:Play(SoundEffect.SOUND_DOOR_HEAVY_OPEN, 1, 0, false, 1) -- 36
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

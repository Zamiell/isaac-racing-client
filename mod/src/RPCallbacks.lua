local RPCallbacks = {}

--
-- Includes
--

local RPGlobals    = require("src/rpglobals")
local RPFastClear  = require("src/rpfastclear")
local RPFastTravel = require("src/rpfasttravel")

--
-- Miscellaneous game callbacks
--

-- ModCallbacks.MC_NPC_UPDATE (0)
function RPCallbacks:NPCUpdate(npc)
  --
  -- Lock Knights that are in the "warmup" animation
  -- (still seems to be buggy)
  --

  if (npc.Type == EntityType.ENTITY_KNIGHT or -- 41
      npc.Type == EntityType.ENTITY_FLOATING_KNIGHT or -- 254
      npc.Type == EntityType.ENTITY_BONE_KNIGHT) and -- 283
     npc.FrameCount >= 5 and
     npc.FrameCount <= 30 and
     RPGlobals.run.currentKnights[npc.Index] ~= nil then

    -- Keep the 5th frame of the spawn animation going
    npc:GetSprite():SetFrame("Down", 0)

    -- Make sure that it stays in place
    npc.Position = RPGlobals.run.currentKnights[npc.Index].pos
    npc.Velocity = Vector(0, 0)
  end

  --
  -- Lock Lil' Haunts that are in the "warmup" animation
  --

  if (npc.Type == EntityType.ENTITY_THE_HAUNT and npc.Variant == 10) and -- 260
     npc.FrameCount >= 5 and
     npc.FrameCount <= 16 and
     RPGlobals.run.currentLilHaunts[npc.Index] ~= nil then

    -- Make sure that it stays in place
    npc.Position = RPGlobals.run.currentLilHaunts[npc.Index].pos
    npc.Velocity = Vector(0, 0)
  end

  -- Look for enemies that are dying so that we can open the doors prematurely
  RPFastClear:NPCUpdate(npc)
end

-- ModCallbacks.MC_EVALUATE_CACHE (8)
function RPCallbacks:EvaluateCache(player, cacheFlag)
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local character = player:GetPlayerType()
  local maxHearts = player:GetMaxHearts()
  local coins = player:GetNumCoins()
  local coinContainers = 0

  --
  -- Manage Keeper's heart containers
  --

  if character == PlayerType.PLAYER_KEEPER and -- 14
     cacheFlag == CacheFlag.CACHE_RANGE then -- 8

    -- Find out how many coin containers we should have
    -- (2 is equal to 1 actual heart container)
    if coins >= 99 then
      coinContainers = 8
    elseif coins >= 75 then
      coinContainers = 6
    elseif coins >= 50 then
      coinContainers = 4
    elseif coins >= 25 then
      coinContainers = 2
    end
    local baseHearts = maxHearts - coinContainers

    -- We have to add the range cache to all health up items
    --   12  - Magic Mushroom (already has range cache)
    --   15  - <3
    --   16  - Raw Liver (gives 2 containers)
    --   22  - Lunch
    --   23  - Dinner
    --   24  - Dessert
    --   25  - Breakfast
    --   26  - Rotten Meat
    --   81  - Dead Cat
    --   92  - Super Bandage
    --   101 - The Halo (already has range cache)
    --   119 - Blood Bag
    --   121 - Odd Mushroom (Thick) (already has range cache)
    --   129 - Bucket of Lard (gives 2 containers)
    --   138 - Stigmata
    --   176 - Stem Cells
    --   182 - Sacred Heart (already has range cache)
    --   184 - Holy Grail
    --   189 - SMB Super Fan (already has range cache)
    --   193 - Meat!
    --   218 - Placenta
    --   219 - Old Bandage
    --   226 - Black Lotus
    --   230 - Abaddon
    --   253 - Magic Scab
    --   307 - Capricorn (already has range cache)
    --   312 - Maggy's Bow
    --   314 - Thunder Theighs
    --   334 - The Body (gives 3 containers)
    --   342 - Blue Cap
    --   346 - A Snack
    --   354 - Crack Jacks
    --   456 - Moldy Bread
    local HPItemArray = {
      12,  15,  16,  22,  23,
      24,  25,  26,  81,  92,
      101, 119, 121, 129, 138,
      176, 182, 184, 189, 193,
      218, 219, 226, 230, 253,
      307, 312, 314, 334, 342,
      346, 354, 456,
    }
    for i = 1, #HPItemArray do
      if player:HasCollectible(HPItemArray[i]) then
        if RPGlobals.run.keeper.healthItems[HPItemArray[i]] == nil then
          RPGlobals.run.keeper.healthItems[HPItemArray[i]] = true

          if HPItemArray[i] == CollectibleType.COLLECTIBLE_ABADDON then -- 230
            player:AddMaxHearts(-24, true) -- Remove all hearts
            player:AddMaxHearts(coinContainers, true) -- Give whatever containers we should have from coins
            player:AddHearts(24) -- This is needed because all the new heart containers will be empty
            -- We have no way of knowing what the current health was before, because "player:GetHearts()"
            -- returns 0 at this point. So, just give them max health.
            Isaac.DebugString("Set 0 heart containers to Keeper (Abaddon).")

          elseif HPItemArray[i] == CollectibleType.COLLECTIBLE_DEAD_CAT then -- 81
            player:AddMaxHearts(-24, true) -- Remove all hearts
            player:AddMaxHearts(2 + coinContainers, true) -- Give 1 heart container +
                                                          -- whatever containers we should have from coins
            player:AddHearts(24) -- This is needed because all the new heart containers will be empty
            -- We have no way of knowing what the current health was before, because "player:GetHearts()"
            -- returns 0 at this point. So, just give them max health.
            Isaac.DebugString("Set 1 heart container to Keeper (Dead Cat).")

          elseif baseHearts < 0 and
             HPItemArray[i] == CollectibleType.COLLECTIBLE_BODY then -- 334

            player:AddMaxHearts(6, true) -- Give 3 heart containers
            Isaac.DebugString("Gave 3 heart containers to Keeper.")

            -- Fill in the new containers
            player:AddCoins(1)
            player:AddCoins(1)
            player:AddCoins(1)

          elseif baseHearts < 2 and
                 (HPItemArray[i] == CollectibleType.COLLECTIBLE_RAW_LIVER or -- 16
                  HPItemArray[i] == CollectibleType.COLLECTIBLE_BUCKET_LARD or -- 129
                  HPItemArray[i] == CollectibleType.COLLECTIBLE_BODY) then -- 334

            player:AddMaxHearts(4, true) -- Give 2 heart containers
            Isaac.DebugString("Gave 2 heart containers to Keeper.")

            -- Fill in the new containers
            player:AddCoins(1)
            player:AddCoins(1)

          elseif baseHearts < 4 then
            player:AddMaxHearts(2, true) -- Give 1 heart container
            Isaac.DebugString("Gave 1 heart container to Keeper.")

            if HPItemArray[i] ~= CollectibleType.COLLECTIBLE_ODD_MUSHROOM_DAMAGE and -- 121
               HPItemArray[i] ~= CollectibleType.COLLECTIBLE_OLD_BANDAGE then -- 219

              -- Fill in the new container
              -- (Odd Mushroom (Thick) and Old Bandage do not give filled heart containers)
              player:AddCoins(1)
            end

          else
            Isaac.DebugString("Health up detected, but baseHearts are full.")
          end
        end
      end
    end
  end

  --
  -- Race stuff
  --

  -- Look for the custom start item that gives 13 luck
  for i = 1, #RPGlobals.race.startingItems do
    if RPGlobals.race.startingItems[i] == 600 and -- 13 luck
       cacheFlag == CacheFlag.CACHE_LUCK then -- 1024

      player.Luck = player.Luck + 13
    end
  end

  -- The Pageant Boy ruleset starts with 7 luck
  if RPGlobals.race.rFormat == "pageant" and
     cacheFlag == CacheFlag.CACHE_LUCK then -- 1024

    player.Luck = player.Luck + 7
  end

  -- In diversity races, Crown of Light should heal for a half heart
  -- (don't explicitly check for race format in case loading failed)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT) and -- 415
     cacheFlag == CacheFlag.CACHE_SHOTSPEED and -- 4
     stage == 1 and
     roomType == RoomType.ROOM_TREASURE and -- 4
     -- (this will still work even if you exit the room with the item held overhead)
     (character == PlayerType.PLAYER_JUDAS or -- 3
      character == PlayerType.PLAYER_AZAZEL) then -- 7

    player:AddHearts(1)
  end
end

-- ModCallbacks.MC_POST_PLAYER_INIT (9)
-- (this will get called before the "PostGameStarted" callback)
function RPCallbacks:PostPlayerInit(player)
  -- Check for co-op babies
  if player.Variant ~= 1 then
    return
  end

  -- Local variables
  local game = Game()
  local mainPlayer = game:GetPlayer(0)

  mainPlayer:AnimateSad() -- Play a sound effect to communicate that the player made a mistake
  player:Kill() -- This kills the co-op baby, but the main character will still get their health back for some reason

  -- Since the player gets their health back, it is still possible to steal devil deals, so remove all unpurchased
  -- Devil Room items in the room (which will have prices of either -1 or -2)
  local entities = Isaac.GetRoomEntities()
  for i = 1, #entities do
    if entities[i].Type == EntityType.ENTITY_PICKUP and -- If this is a pedestal item (5.100)
       entities[i].Variant == PickupVariant.PICKUP_COLLECTIBLE and
       entities[i]:ToPickup().Price < 0 then

      entities[i]:Remove()
    end
  end
end

-- ModCallbacks.MC_ENTITY_TAKE_DMG (11)
function RPCallbacks:EntityTakeDamage(tookDamage, damageAmount, damageFlag, damageSource, damageCountdownFrames)
  -- local variables
  local player = tookDamage:ToPlayer()
  local sfx = SFXManager()

  -- Check to see if it was the player that took damage
  if player ~= nil then
    -- Make us invincibile while interacting with a trapdoor
    if RPGlobals.run.trapdoor.state > 0 then
      return false
    end

    local selfDamage = false
    for i = 0, 21 do -- There are 21 damage flags
      local bit = (damageFlag & (1 << i)) >> i

      -- Soul Jar damage tracking
      if (i == 5 or i == 18) and bit == 1 then -- 5 is DAMAGE_RED_HEARTS, 18 is DAMAGE_IV_BAG
        selfDamage = true
      end

      -- Mimic damage tracking
      if i == 20 and bit == 1 then
        sfx:Play(SoundEffect.SOUND_LAUGH, 1, 0, false, 1)
      end
    end
    if selfDamage == false then
      RPGlobals.run.levelDamaged = true
    end

    -- Betrayal (custom)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BETRAYAL_NOANIM) then
      local entities = Isaac.GetRoomEntities()
      for i = 1, #entities do
        local npc = entities[i]:ToNPC()
        if npc ~= nil and entities[i]:IsVulnerableEnemy() then
          entities[i]:AddCharmed(150) -- 5 seconds
        end
      end
    end
  end

  -- Globins softlock prevention
  local npc = tookDamage:ToNPC()
  if npc ~= nil then
    if (npc.Type == EntityType.ENTITY_GLOBIN or
        npc.Type == EntityType.ENTITY_BLACK_GLOBIN) and
       RPGlobals.run.currentGlobins[npc.Index] == nil then

      RPGlobals.run.currentGlobins[npc.Index] = {
        npc       = npc,
        lastState = npc.State,
        regens    = 0,
      }
    end
  end
end

-- ModCallbacks.MC_INPUT_ACTION (13)
function RPCallbacks:InputAction(entity, inputHook, buttonAction)
  -- Disable resetting if the countdown is at 1
  if buttonAction == ButtonAction.ACTION_RESTART and RPGlobals.raceVars.resetEnabled == false then
    return false
  end
end

-- ModCallbacks.MC_POST_NEW_LEVEL (18)
function RPCallbacks:PostNewLevel()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  Isaac.DebugString("MC_POST_NEW_LEVEL")

  -- Make sure the callbacks run in the right order
  -- (naturally, PostNewLevel gets called before the PostGameStarted callbacks)
  if gameFrameCount == 0 then
    return
  end

  RPCallbacks:PostNewLevel2()
end

function RPCallbacks:PostNewLevel2()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

  Isaac.DebugString("MC_POST_NEW_LEVEL2")

  -- Find out if we performed a Sacrifice Room teleport
  if stage == 11 and stageType == 0 and RPGlobals.run.currentFloor ~= 10 then -- 11.0 is Dark Room
    -- We arrivated at the Dark Room without going through Sheol
    Isaac.DebugString("Sacrifice Room teleport detected.")
    RPGlobals:GotoNextFloor(false) -- The argument is "upwards"
    return
  end

  -- Set the new floor
  RPGlobals.run.currentFloor = stage
  Isaac.DebugString("New floor: " .. tostring(RPGlobals.run.currentFloor))

  -- Reset some per level flags
  RPGlobals.run.levelDamaged = false
  RPGlobals.run.replacedPedestals = {}
  RPGlobals.run.replacedTrapdoors = {}
  RPGlobals.run.replacedCrawlspaces = {}
  RPGlobals.run.replacedHeavenDoors = {}

  -- Reset the RNG of some items that should be seeded per floor
  local floorSeed = level:GetDungeonPlacementSeed()
  RPGlobals.RNGCounter.Teleport = floorSeed
  RPGlobals.RNGCounter.Undefined = floorSeed
  RPGlobals.RNGCounter.Telepills = floorSeed
  for i = 1, 100 do
    -- Increment the RNG 100 times so that players cannot use knowledge of Teleport! teleports
    -- to determine where the Telepills destination will be
    RPGlobals.RNGCounter.Telepills = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.Telepills)
  end

  -- Start showing the place graphic if we get to Basement 2
  if stage >= 2 then
    RPGlobals.raceVars.showPlaceGraphic = true
  end

  -- Call PostNewRoom manually (they get naturally called out of order)
  RPCallbacks:PostNewRoom2()
end

-- ModCallbacks.MC_POST_NEW_ROOM (19)
function RPCallbacks:PostNewRoom()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local stage = level:GetStage()

  -- Make sure the callbacks run in the right order
  -- (naturally, PostNewRoom gets called before the PostNewLevel and PostGameStarted callbacks)
  Isaac.DebugString("MC_POST_NEW_ROOM")
  if gameFrameCount == 0 or RPGlobals.run.currentFloor ~= stage then
    return
  end

  RPCallbacks:PostNewRoom2()
end

function RPCallbacks:PostNewRoom2()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomClear = room:IsClear()
  local player = game:GetPlayer(0)
  local activeCharge = player:GetActiveCharge()
  local maxHearts = player:GetMaxHearts()
  local soulHearts = player:GetSoulHearts()
  local sfx = SFXManager()

  Isaac.DebugString("MC_POST_NEW_ROOM2")

  RPGlobals.run.roomsEntered = RPGlobals.run.roomsEntered + 1
  RPGlobals.run.currentRoomClearState = roomClear
  -- This is needed so that we don't get credit for clearing a room when
  -- bombing from a room with enemies into an empty room

  -- Reset the lists we use to keep track of certain enemies
  RPGlobals.run.currentGlobins = {} -- Used for softlock prevention
  RPGlobals.run.currentKnights = {} -- Used to delete invulnerability frames
  RPGlobals.run.currentLilHaunts = {} -- Used to delete invulnerability frames

  -- Clear some room-based flags
  RPGlobals.run.naturalTeleport = false
  RPGlobals.run.bossHearts = { -- Copied from RPGlobals
    spawn       = false,
    extra       = false,
    extraIsSoul = false,
    position    = {},
    velocity    = {},
  }
  RPGlobals.run.schoolbag.bossRushActive = false

  -- We might need to respawn trapdoors / crawlspaces / beams of light
  RPFastTravel:CheckRoomRespawn()

  -- Check for miscellaneous crawlspace bugs
  RPFastTravel:CheckCrawlspaceMiscBugs()

  -- Check to see if we need to remove the heart container from a Strength card on Keeper
  if RPGlobals.run.keeper.usedStrength and RPGlobals.run.keeper.baseHearts == 4 then
    RPGlobals.run.keeper.baseHearts = 2
    RPGlobals.run.keeper.usedStrength = false
    player:AddMaxHearts(-2, true) -- Take away a heart container
    Isaac.DebugString("Took away 1 heart container from Keeper (via a Strength card).")
  end

  -- Check to see if we need to remove More Options in a diversity race
  if roomType == RoomType.ROOM_TREASURE and -- 4
     player:HasCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) and -- 414
     RPGlobals.race.rFormat == "diversity" and
     RPGlobals.raceVars.removedMoreOptions == false then

    RPGlobals.raceVars.removedMoreOptions = true
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) -- 414
  end

  -- Check health (to fix the bug where we don't die at 0 hearts)
  -- (this happens if Keeper uses Guppy's Paw or when Magdalene takes a devil deal that grants soul/black hearts)
  if maxHearts == 0 and soulHearts == 0 then
    player:Kill()
  end

  -- Make the Schoolbag work properly with the Glowing Hour Glass
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) then
    -- Recharge our active item if we used the Glowing Hour Glass
    if RPGlobals.run.schoolbag.nextRoomCharge then
      RPGlobals.run.schoolbag.nextRoomCharge = false
      player:SetActiveCharge(RPGlobals.run.schoolbag.lastRoomSlot1Charges)
    end

    -- Keep track of our last Schoolbag item
    RPGlobals.run.schoolbag.lastRoomItem = RPGlobals.run.schoolbag.item
    RPGlobals.run.schoolbag.lastRoomSlot1Charges = activeCharge
    RPGlobals.run.schoolbag.lastRoomSlot2Charges = RPGlobals.run.schoolbag.charges
  end

  -- Extend the Maw of the Void / Athame ring into the next room
  if RPGlobals.run.blackRingTime > 1 then
    player:SpawnMawOfVoid(RPGlobals.run.blackRingTime) -- The argument is "Timeout"

    -- The "player:SpawnMawOfVoid()" will spawn a Maw of the Void ring, but we might be extending an Athame ring,
    -- so we have to reset the Black HP drop chance
    local entities = Isaac.GetRoomEntities()
    for i = 1, #entities do
      if entities[i].Type == EntityType.ENTITY_LASER and -- 7
         entities[i].Variant == 1 and -- A Brimstone laser
         entities[i].SubType == 3 then -- A Maw of the Void or Athame ring

        entities[i]:ToLaser():SetBlackHpDropChance(RPGlobals.run.blackRingDropChance)
      end
    end

    -- "player:SpawnMawOfVoid()" will cause a new Maw sound effect to play, so mute it
    sfx:Stop(SoundEffect.SOUND_MAW_OF_VOID) -- 426
  end

  -- Spawn a Get out of Jail Free Card if we have arrived on The Chest / Dark Room
  -- (this can't be in the "CheckChangeFloor()" function because the items won't show up)
  if (RPGlobals.race.goal == "Mega Satan" or
      RPGlobals.raceVars.finished) and
     stage == 11 and -- If this is The Chest or Dark Room
     level:GetCurrentRoomIndex() == level:GetStartingRoomIndex() then

    --[[
    RPGlobals.raceVars.placedJailCard = true

    -- Get out of Jail Free Card (5.300.47)
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, RPGlobals:GridToPos(6, 0), Vector(0, 0),
               nil, Card.CARD_GET_OUT_OF_JAIL, roomSeed)
    Isaac.DebugString("Placed the Get out of Jail Free Card.")
    --]]
    local door = room:GetDoor(1)
    door.State = 2
    Isaac.DebugString("Opened the Mega Satan door.")
  end

  -- Set up the "Race Room"
  if RPGlobals.run.enteringRaceRoom then
    RPGlobals.run.enteringRaceRoom = false

    -- Stop the boss room sound effect
    sfx:Stop(SoundEffect.SOUND_CASTLEPORTCULLIS) -- 190

    -- We want to trap the player in the room,
    -- but we can't make a room with no doors because then the "goto" command would crash the game,
    -- so we have one door at the bottom
    room:RemoveDoor(3) -- The bottom door is always 3

    -- Spawn two Gaping Maws (235.0)
    game:Spawn(EntityType.ENTITY_GAPING_MAW, 0, RPGlobals:GridToPos(5, 5), Vector(0, 0), nil, 0, 0)
    game:Spawn(EntityType.ENTITY_GAPING_MAW, 0, RPGlobals:GridToPos(7, 5), Vector(0, 0), nil, 0, 0)
  end
end

return RPCallbacks

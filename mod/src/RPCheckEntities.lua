local RPCheckEntities = {}

--
-- Includes
--

local RPGlobals    = require("src/rpglobals")
local RPSchoolbag  = require("src/rpschoolbag")
local RPFastTravel = require("src/rpfasttravel")
local RPSpeedrun   = require("src/rpspeedrun")

--
-- Check entities functions
--

-- Check all the grid entities in the room
function RPCheckEntities:Grid()
  local game = Game()
  local room = game:GetRoom()

  local num = room:GetGridSize()
  for i = 1, num do
    local gridEntity = room:GetGridEntity(i)
    if gridEntity ~= nil then
      if gridEntity:GetSaveState().Type == GridEntityType.GRID_TRAPDOOR and -- 17
         gridEntity:GetSaveState().VarData == 1 then -- Void Portals have a VarData of 1

        -- Delete all Void Portals
        room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work

      elseif gridEntity:GetSaveState().Type == GridEntityType.GRID_TRAPDOOR then -- 17
        RPFastTravel:ReplaceTrapdoor(gridEntity, i)

      elseif gridEntity:GetSaveState().Type == GridEntityType.GRID_STAIRS then -- 18
        RPFastTravel:ReplaceCrawlspace(gridEntity, i)

      elseif gridEntity:GetSaveState().Type == GridEntityType.GRID_PRESSURE_PLATE then -- 20
        RPSpeedrun:CheckButtonPressed(gridEntity)
      end
    end
  end
end

-- Check all the non-grid entities in the room
function RPCheckEntities:NonGrid()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomIndexUnsafe = level:GetCurrentRoomIndex()
  local roomData = level:GetCurrentRoomDesc().Data
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
  local player = game:GetPlayer(0)
  local sfx = SFXManager()

  -- Go through all the entities
  local fireworkActive = false
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_BOMBDROP and -- 4
       (entity.Variant == 3 or -- Troll Bomb
        entity.Variant == 4) and -- Mega Troll Bomb
        entity.FrameCount == 1 then

      -- Make Troll Bomb and Mega Troll Bomb fuses deterministic (exactly 2 seconds long)
      -- (in vanilla the fuse is: 45 + random(1, 2147483647) % 30)
      local bomb = entity:ToBomb()
      bomb:SetExplosionCountdown(59) -- 60 minus 1 because we start at frame 1
      -- Note that game physics occur at 30 frames per second instead of 60

    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_HEART and -- 10
           RPCheckEntities:IsBossType(entity.SpawnerType) and
           roomType == RoomType.ROOM_BOSS then -- 5

      -- Delete heart drops in boss rooms so that we can properly seed them
      RPGlobals.run.bossHearts.spawn = true
      RPGlobals.run.bossHearts.position[#RPGlobals.run.bossHearts.position + 1] = entity.Position
      RPGlobals.run.bossHearts.velocity[#RPGlobals.run.bossHearts.velocity + 1] = entity.Velocity
      entity:Remove()
      Isaac.DebugString("Removed boss room heart drop #" .. tostring(#RPGlobals.run.bossHearts.position) .. ": " ..
                        "(" .. tostring(entity.Position.X) .. "," .. tostring(entity.Position.Y) .. ") " ..
                        "(" .. tostring(entity.Velocity.X) .. "," .. tostring(entity.Velocity.Y) .. ")")

    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
           (entity.Variant == PickupVariant.PICKUP_SPIKEDCHEST or -- 52
            entity.Variant == PickupVariant.PICKUP_MIMIC) and -- 54
            entity:ToPickup().TheresOptionsPickup == false then -- This is used as a replacement counter
           -- We can't check for the "Appear" animation because this is not fast enough
           -- to intercept the unavoidable damage when a Mimic spawns on top of the player

      -- Change all Mimics and Spiked Chests to normal chests until the appearing animation is complete
      -- (this also fixes the unavoidable damage when a Mimic spawns where you happen to be standing)
      -- (Spiked Chests do not have this problem)
      entity.Variant = 50

      -- Check to see if we are in a specific room where a Spiked Chest or Mimic will cause unavoidable damage
      if (roomData.StageID == 4 and roomData.Variant == 12) or -- Caves
         (roomData.StageID == 4 and roomData.Variant == 19) or
         (roomData.StageID == 4 and roomData.Variant == 244) or
         (roomData.StageID == 4 and roomData.Variant == 518) or
         (roomData.StageID == 4 and roomData.Variant == 519) or
         (roomData.StageID == 5 and roomData.Variant == 19) or -- Catacombs
         (roomData.StageID == 5 and roomData.Variant == 518) or
         (roomData.StageID == 10 and roomData.Variant == 489) or -- Womb
         (roomData.StageID == 11 and roomData.Variant == 489) then -- Utero

        -- Leave it as a normal chest, but changing the variant doesn't actually change the sprite
        entity:GetSprite():Load("gfx/005.050_chest.anm2", true)

        -- We have to play an animation for the new sprite to actually appear
        entity:GetSprite():Play("Appear", false)
        Isaac.DebugString("Replaced a Spiked Chest / Mimic (for an unavoidable damage room).")

      else
        local squareSize = 100 -- This is fairly large, about 1/4 of a room width
        if player.Position.X >= entity.Position.X - squareSize and
           player.Position.X <= entity.Position.X + squareSize and
           player.Position.Y >= entity.Position.Y - squareSize and
           player.Position.Y <= entity.Position.Y + squareSize then

          -- The chest is spawning close to us, so our bodies might be blocking it,
          -- so use a custom mimic sprite to compensate
          entity:GetSprite():Load("gfx/005.054_mimic chest2.anm2", true)
          Isaac.DebugString("Replaced a Spiked Chest / Mimic (1/2) (with custom animation).")

        else
          -- Changing the variant doesn't actually change the sprite
          -- Furthermore, we make it look like a Mimic
          entity:GetSprite():Load("gfx/005.054_mimic chest.anm2", true)
          Isaac.DebugString("Replaced a Spiked Chest / Mimic (1/2).")
        end

        -- We have to play an animation for the new sprite to actually appear
        entity:GetSprite():Play("Appear", false)

        -- Use the normally unused "TheresOptionsPickup" varaible to store that this is not a normal chest
        entity:ToPickup().TheresOptionsPickup = true
      end

    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_CHEST and -- 50
           entity:ToPickup().TheresOptionsPickup and
           entity:GetSprite():IsPlaying("Appear") and
           entity:GetSprite():GetFrame() == 21 then -- This is the last frame of the "Appear" animation

      -- The "Appear" animation is finished, so now change this back to a Mimic
      -- (we can't just check for "IsPlaying("Appear") == false" because if the player is touching it,
      -- they will get the contents of a normal chest before the swap back occurs)
      entity.Variant = 54
      Isaac.DebugString("Replaced a Spiked Chest / Mimic (2/2).")

    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and -- 100
           entity.SubType == CollectibleType.COLLECTIBLE_POLAROID and -- 327
           RPGlobals.race.goal == "The Lamb" and
           RPGlobals.race.rFormat ~= "pageant" then

      entity:Remove()
      Isaac.DebugString("Removed The Polaroid.")

    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and -- 100
           entity.SubType == CollectibleType.COLLECTIBLE_POLAROID and -- 327
           entity.Position.X >= 270 and entity.Position.X <= 290 and
           RPGlobals.race.goal ~= "Mega Satan" and
           RPGlobals.race.rFormat ~= "pageant" then

      -- Reposition it to the center
      game:Spawn(entity.Type, entity.Variant, Vector(320, 360), Vector(0, 0),
                 entity.Parent, entity.SubType, entity.InitSeed)
      -- (respawn it with the initial seed so that it will be replaced normally on the frame)
      entity:Remove()
      Isaac.DebugString("Moved The Polaroid.")

    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
       entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and -- 100
       entity.SubType == CollectibleType.COLLECTIBLE_NEGATIVE and -- 328
       RPGlobals.race.goal == "Blue Baby" and
       RPGlobals.race.rFormat ~= "pageant" then

      entity:Remove()
      Isaac.DebugString("Removed The Negative.")

    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and -- 100
           entity.SubType == CollectibleType.COLLECTIBLE_NEGATIVE and -- 327
           entity.Position.X >= 350 and entity.Position.X <= 370 and
           RPGlobals.race.goal ~= "Mega Satan" and
           RPGlobals.race.rFormat ~= "pageant" then

      -- Reposition it to the center
      game:Spawn(entity.Type, entity.Variant, Vector(320, 360), Vector(0, 0),
                 entity.Parent, entity.SubType, entity.InitSeed)
      -- (respawn it with the initial seed so that it will be replaced normally on the frame)
      entity:Remove()
      Isaac.DebugString("Moved The Negative.")

    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and -- 100
           gameFrameCount >= RPGlobals.run.itemReplacementDelay then
           -- We need to delay after using a Void (in case the player has consumed a D6)

      RPCheckEntities:ReplacePedestal(entity)


    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_TRINKET and -- 350
           RPGlobals.run.roomsEntered <= 1 and
           RPGlobals.race.rFormat == "pageant" then

      -- Delete Pageant Boy starting trinkets
      entity:Remove()

    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_TRINKET then -- 350

      -- Ban trinkets (1/2)
      -- (picked up trinkets are banned in the PostUpdate callback)
      local bannedTrinket = false
      for j = 1, #RPGlobals.raceVars.trinketBanList do
        if entity.SubType == RPGlobals.raceVars.trinketBanList[j] then
          bannedTrinket = true
          break
        end
      end

      if bannedTrinket then
        -- Spawn a new random trinket (the seed should not matter since trinkets are given in order per run)
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, entity.Position,
                   entity.Velocity, entity.Parent, 0, entity.InitSeed) -- 5.350.0

        -- Now that we have created a new trinket, we can delete the old one
        entity:Remove()
        Isaac.DebugString("Banned trinket " .. tostring(entity.SubType) .. " and made a new random trinket.")
      end

    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_BIGCHEST and -- 340
           stage == 10 and stageType == 0 and -- Sheol
           player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328

      -- Delete the chest and replace it with a trapdoor so that we can fast-travel normally
      RPFastTravel:ReplaceTrapdoor(entity, -1)
      -- A -1 indicates that we are replacing an entity instead of a grid entity

    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_BIGCHEST and -- 340
           stage == 10 and stageType == 1 and -- Cathedral
           player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327

      -- Delete the chest and replace it with the custom beam of light so that we can fast-travel normally
      RPFastTravel:ReplaceHeavenDoor(entity)

    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_BIGCHEST and -- 340
           stage == 11 and
           RPGlobals.race.rFormat == "pageant" then

      -- Delete all big chests on the Pageant Boy ruleset so that
      -- you don't accidently end your run before you can show off your build to the judges
      entity:Remove()

    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_BIGCHEST and -- 340
           stage == 11 and
           RPGlobals.raceVars.finished == false and
           RPGlobals.race.status == "in progress" and
           ((RPGlobals.race.goal == "Blue Baby" and stageType == 1 and
             roomIndexUnsafe ~= GridRooms.ROOM_MEGA_SATAN_IDX) or -- -7
            (RPGlobals.race.goal == "The Lamb" and stageType == 0 and
             roomIndexUnsafe ~= GridRooms.ROOM_MEGA_SATAN_IDX) or -- -7
            (RPGlobals.race.goal == "Mega Satan" and
             roomIndexUnsafe == GridRooms.ROOM_MEGA_SATAN_IDX)) then -- -7

      -- Spawn the "Race Trophy" custom entity
      game:Spawn(Isaac.GetEntityTypeByName("Race Trophy"), Isaac.GetEntityVariantByName("Race Trophy"),
                 entity.Position, entity.Velocity, nil, 0, 0)
      Isaac.DebugString("Spawned the end of race trophy.")

      -- Get rid of the chest
      entity:Remove()

    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_BIGCHEST and -- 340
           stage == 11 and
           RPGlobals.raceVars.finished == false and
           RPGlobals.race.status == "in progress" and
           (RPGlobals.race.goal == "Mega Satan" and
            roomIndexUnsafe ~= GridRooms.ROOM_MEGA_SATAN_IDX) then -- -7

      -- Get rid of the chest as a reminder that the race goal is Mega Satan
      entity:Remove()
      Isaac.DebugString("Got rid of the big chest since the goal is Mega Satan.")

    elseif entity.Type == EntityType.ENTITY_PICKUP and -- 5
           entity.Variant == PickupVariant.PICKUP_BIGCHEST and -- 340
           stage == 11 and
           RPGlobals.raceVars.finished then

      -- Spawn a Victory Lap (a custom item that emulates Forget Me Now) in the center of the room
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, room:GetCenterPos(), Vector(0, 0),
                 nil, CollectibleType.COLLECTIBLE_VICTORY_LAP, roomSeed)
      Isaac.DebugString("Spawned a Victory Lap in the center of the room.")

      -- Get rid of the chest
      entity:Remove()

    elseif entity.Type == EntityType.ENTITY_LASER and -- 7
           entity.Variant == 1 and -- A Brimstone laser
           entity.SubType == 3 then -- A Maw of the Void or Athame ring

      -- Keep track of how much time is left on the ring
      -- (the lowest this can be is 1, since the entity won't exist when the timer ends)
      RPGlobals.run.blackRingTime = entity:ToLaser().Timeout

      -- Also keep track of whether this is a Maw of the Void or Athame ring
      RPGlobals.run.blackRingDropChance = entity:ToLaser().BlackHpDropChance

    elseif entity.Type == EntityType.ENTITY_EFFECT and -- 1000
           entity.Variant == EffectVariant.HEAVEN_LIGHT_DOOR then -- 39

      RPFastTravel:ReplaceHeavenDoor(entity)

    elseif entity.Type == EntityType.ENTITY_EFFECT and -- 1000
           entity.Variant == EffectVariant.FIREWORKS then -- 104

     -- Check for fireworks so that we can reduce the volume
     fireworkActive = true

    elseif entity.Type == Isaac.GetEntityTypeByName("Race Trophy") and
           entity.Variant == Isaac.GetEntityVariantByName("Race Trophy") and
           RPGlobals.raceVars.finished == false and
           player.Position.X >= entity.Position.X - 24 and -- 25 is a touch too big
           player.Position.X <= entity.Position.X + 24 and
           player.Position.Y >= entity.Position.Y - 24 and
           player.Position.Y <= entity.Position.Y + 24 then

      -- Check to see if we are touching the trophy
      RPGlobals.raceVars.finished = true
      RPGlobals.raceVars.finishedTime = Isaac.GetTime()
      entity:Remove()
      player:AnimateCollectible(CollectibleType.COLLECTIBLE_TROPHY, "Pickup", "PlayerPickupSparkle2")
      Isaac.DebugString("Finished run.") -- The client looks for this line to know when the goal was achieved

      -- Spawn a Victory Lap (a custom item that emulates Forget Me Now) in the corner of the room
      local victoryLapPosition = RPGlobals:GridToPos(11, 1)
      if roomIndexUnsafe == GridRooms.ROOM_MEGA_SATAN_IDX then
        victoryLapPosition = RPGlobals:GridToPos(11, 6) -- A Y of 1 is out of bounds inside of the Mega Satan room
      end
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, victoryLapPosition, Vector(0, 0),
                 nil, CollectibleType.COLLECTIBLE_VICTORY_LAP, roomSeed)

      -- Spawn a Finish (a custom item that takes you to the main menu) in the corner of the room
      local finishedPosition = RPGlobals:GridToPos(1, 1)
      if roomIndexUnsafe == GridRooms.ROOM_MEGA_SATAN_IDX then
        finishedPosition = RPGlobals:GridToPos(1, 6) -- A Y of 1 is out of bounds inside of the Mega Satan room
      end
      game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, finishedPosition, Vector(0, 0),
                 nil, CollectibleType.COLLECTIBLE_FINISHED, roomSeed)

      Isaac.DebugString("Spawned a Victory Lap / Finished in the corners of the room.")

    elseif (entity.Type == Isaac.GetEntityTypeByName("Trapdoor (Fast-Travel)") and
            entity.Variant == Isaac.GetEntityVariantByName("Trapdoor (Fast-Travel)")) or
           (entity.Type == Isaac.GetEntityTypeByName("Womb Trapdoor (Fast-Travel)") and
            entity.Variant == Isaac.GetEntityVariantByName("Womb Trapdoor (Fast-Travel)")) or
           (entity.Type == Isaac.GetEntityTypeByName("Blue Womb Trapdoor (Fast-Travel)") and
            entity.Variant == Isaac.GetEntityVariantByName("Blue Womb Trapdoor (Fast-Travel)")) then

      RPFastTravel:CheckTrapdoorCrawlspaceOpen(entity)
      RPFastTravel:CheckTrapdoorEnter(entity, false) -- The second argument is "upwards"

    elseif entity.Type == Isaac.GetEntityTypeByName("Crawlspace (Fast-Travel)") and
           entity.Variant == Isaac.GetEntityVariantByName("Crawlspace (Fast-Travel)") then

      RPFastTravel:CheckTrapdoorCrawlspaceOpen(entity)
      RPFastTravel:CheckCrawlspaceEnter(entity)

    elseif entity.Type == Isaac.GetEntityTypeByName("Heaven Door (Fast-Travel)") and
           entity.Variant == Isaac.GetEntityVariantByName("Heaven Door (Fast-Travel)") then

      RPFastTravel:CheckTrapdoorEnter(entity, true) -- The second argument is "upwards"

    else
      -- Also do various checks on NPCs
      RPCheckEntities:NPC(entity)
    end
  end

  -- Spawn seeded heart drops from bosses
  if RPGlobals.run.bossHearts.spawn then
    RPGlobals.run.bossHearts.spawn = false

    -- Random Heart - 5.10.0
    for i = 1, 2 do
      if i == 2 and RPGlobals.run.bossHearts.extra == false then
        break
      end

      -- Get the position of the heart
      local position = RPGlobals.run.bossHearts.position[i]
      if position == nil then
        position = room:GetCenterPos() -- This should never happen
        Isaac.DebugString("Error: Not enough entries for position in the bossHearts table. " ..
                          "(i is " .. tostring(i) .. ")")
      end

      -- Get the velocity of the heart
      local velocity = RPGlobals.run.bossHearts.velocity[i]
      if velocity == nil then
        velocity = Vector(0, 0)
        Isaac.DebugString("Error: Not enough entries for velocity in the bossHearts table. " ..
                          "(i is " .. tostring(i) .. ")")
      end

      -- Spawn the heart
      local heartSeed = roomSeed
      if i == 2 then
        heartSeed = RPGlobals:IncrementRNG(heartSeed)
      end
      if i == 2 and RPGlobals.run.bossHearts.extraIsSoul then
        -- Heart (soul) - 5.10.3
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, position, velocity, nil, 3, heartSeed)
        RPGlobals.run.bossHearts.extraIsSoul = false
        Isaac.DebugString("Spawned an extra boss heart drop (soul heart).")
      else
        -- Random Heart - 5.10.0
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, position, velocity, nil, 0, heartSeed)
        Isaac.DebugString("Spawned a boss heart drop.")
      end
    end

    -- The bossHearts variables are reset entering a new room
  end

  -- Make Fireworks quieter
  if fireworkActive then
    if sfx:IsPlaying(SoundEffect.SOUND_BOSS1_EXPLOSIONS) then -- 182
      sfx:AdjustVolume(SoundEffect.SOUND_BOSS1_EXPLOSIONS, 0.2)
    end
  end
end

-- Fix seed "incrementation" from touching active pedestal items and do other various pedestal fixes
-- (this also fixes Angel key pieces and Pandora's Box items being unseeded)
function RPCheckEntities:ReplacePedestal(entity)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"

  -- Check to see if this is a pedestal that was already replaced
  local squareSize = 15
  for i = 1, #RPGlobals.run.replacedPedestals do
    if RPGlobals.run.replacedPedestals[i].room == roomIndex and
       RPGlobals.run.replacedPedestals[i].seed == entity.InitSeed then

      -- We have already replaced it, so check to see if we need to delete the delay
      if entity:ToPickup().Wait > 15 then
        -- When we enter a new room, the "wait" variable on all pedestals is set to 18
        -- This is too long, so shorten it
        entity:ToPickup().Wait = 15
      end
      return
    end
  end

  -- We haven't replaced this pedestal yet,
  -- so start off by assuming that we should set the new pedestal seed to that of the room
  local newSeed = roomSeed

  if entity:ToPickup().Touched then
    -- If we touched this item, we need to set it back to the last seed that we have for this position
    for i = 1, #RPGlobals.run.replacedPedestals do
      if RPGlobals.run.replacedPedestals[i].room == roomIndex and
         RPGlobals.run.replacedPedestals[i].X >= entity.Position.X - squareSize and
         RPGlobals.run.replacedPedestals[i].X <= entity.Position.X + squareSize and
         RPGlobals.run.replacedPedestals[i].Y >= entity.Position.Y - squareSize and
         RPGlobals.run.replacedPedestals[i].Y <= entity.Position.Y + squareSize then

        -- Don't break after this because we want it to be equal to the seed of the last item
        newSeed = RPGlobals.run.replacedPedestals[i].seed

        -- Also reset the X and Y coordinates of the pedestal before we replace it
        -- (this is necessary because the player will push the pedestal slightly when they drop the item,
        -- so the replaced pedestal will be slightly off)
        entity.Position.X = RPGlobals.run.replacedPedestals[i].X
        entity.Position.Y = RPGlobals.run.replacedPedestals[i].Y
      end
    end
  else
    -- This is a new pedestal, so find the new seed that we should set for it,
    -- which will correspond with how many times it has been rolled
    -- (we can't just seed all items with the room seed because
    -- it causes items that are not fully decremented on sight to roll into themselves)
    for i = 1, #RPGlobals.run.replacedPedestals do
      if RPGlobals.run.replacedPedestals[i].room == roomIndex then
        newSeed = RPGlobals:IncrementRNG(newSeed)
      end
    end
  end

  -- Check to see if this is a B1 item room on a seeded race
  local offLimits = false
  if RPGlobals.race.rFormat == "seeded" and
     stage == 1 and
     room:GetType() == RoomType.ROOM_TREASURE and -- 4
     entity.SubType ~= CollectibleType.COLLECTIBLE_OFF_LIMITS then -- 235
    offLimits = true
  end

  -- Check to see if this item is banned
  local bannedItem = false
  for i = 1, #RPGlobals.raceVars.itemBanList do
    if entity.SubType == RPGlobals.raceVars.itemBanList[i] then
      -- If we put down our starting item, it will automaticlly be fart-rolled
      -- So, make an exception for this
      if entity:ToPickup().Touched == false then
        bannedItem = true
      end
      break
    end
  end

  -- Check to see if this is a special Basement 1 diversity reroll
  local specialReroll = 0
  if bannedItem and
     stage == 1 and
     roomType == RoomType.ROOM_TREASURE and -- 4
     RPGlobals.race.rFormat == "diversity" then

    if entity.SubType == CollectibleType.COLLECTIBLE_MOMS_KNIFE then -- 114
      specialReroll = CollectibleType.COLLECTIBLE_INCUBUS -- 360
    elseif entity.SubType == CollectibleType.COLLECTIBLE_EPIC_FETUS then -- 168
      specialReroll = CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT -- 415
    elseif entity.SubType == CollectibleType.COLLECTIBLE_TECH_X then -- 395
      specialReroll = CollectibleType.COLLECTIBLE_SACRED_HEART -- 182
    end
  end

  -- Check to see if this is a "moved" Krampus pedestal
  -- (this can occur when you have Gimpy and Krampus drops a heart,
  -- which causes the spawned pedestal to be moved one tile over,
  -- and this movement can cause the item to be different)
  if roomType == RoomType.ROOM_DEVIL and -- 14
     entity:ToPickup().Touched == false and -- This is necessary because we only want to target fresh Krampus Heads
     (entity.SubType == CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS or -- 293
      entity.SubType == CollectibleType.COLLECTIBLE_LUMP_OF_COAL) then -- 132

    -- Seed the pedestal ourselves manually
    math.randomseed(newSeed)
    local krampusItem = math.random(1, 2)
    if krampusItem == 1 then
      entity.SubType = 293
    else
      entity.SubType = 132
    end
  end

  -- Check to see if this item should go into a Schoolbag
  local putInSchoolbag = RPSchoolbag:CheckSecondItem(entity)
  if putInSchoolbag == false then
    -- Replace the pedestal
    local randomItem = false
    local newPedestal
    if offLimits then
      -- Change the item to Off Limits (5.100.235)
      newPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, entity.Position,
                               entity.Velocity, entity.Parent, CollectibleType.COLLECTIBLE_OFF_LIMITS, newSeed)
      game:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0)
      -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
      Isaac.DebugString("Made an Off Limits pedestal using seed: " .. tostring(newSeed))

    elseif specialReroll ~= 0 then
      -- Change the item to the special reroll
      newPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, entity.Position,
                               entity.Velocity, entity.Parent, specialReroll, newSeed)
      game:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0)
      -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
      Isaac.DebugString("Made a new special " .. tostring(specialReroll) ..
                        " pedestal using seed: " .. tostring(newSeed))

    elseif bannedItem then
      -- Make a new random item pedestal
      -- (the new random item generated will automatically be decremented from item pools properly on sight)
      newPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, entity.Position,
                               entity.Velocity, entity.Parent, 0, entity.InitSeed)
      game:Fart(newPedestal.Position, 0, newPedestal, 0.5, 0)
      -- Play a fart animation so that it doesn't look like some bug with the Racing+ mod
      Isaac.DebugString("Made a new random pedestal using vanilla seed: " .. tostring(entity.InitSeed))
      randomItem = true -- Set that this is a random item so that we don't add it to the tracking index

    else
      -- Make a new copy of this item
      newPedestal = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, entity.Position,
                               entity.Velocity, entity.Parent, entity.SubType, newSeed)

      -- We don't need to make a fart noise because the swap will be completely transparent to the user
      -- (the sprites of the two items will obviously be identical)
      -- We don't need to add this item to the ban list because since it already existed, it was properly
      -- decremented from the pools on sight
      Isaac.DebugString("Made a copied " .. tostring(newPedestal.SubType) ..
                        " pedestal using seed: " .. tostring(newSeed))
    end

    -- We don't want to replicate the charge if this is a brand new item
    if specialReroll == false or bannedItem == false then
      -- If we don't do this, the item will be fully recharged every time the player swaps it out
      newPedestal:ToPickup().Charge = entity:ToPickup().Charge
    end

    -- If we don't do this, shop and Devil Room items will become automatically bought
    newPedestal:ToPickup().Price = entity:ToPickup().Price

    -- We need to keep track of touched items for banned item exception purposes
    newPedestal:ToPickup().Touched = entity:ToPickup().Touched

    -- If we don't do this, shop items will reroll into consumables and
    -- shop items that are on sale will no longer be on sale
    newPedestal:ToPickup().ShopItemId = entity:ToPickup().ShopItemId

    -- If we don't do this, you can take both of the pedestals in a double Treasure Room
    newPedestal:ToPickup().TheresOptionsPickup = entity:ToPickup().TheresOptionsPickup

    -- Also remove the vanilla delay that is imposed upon newly spawned collectible items
    newPedestal:ToPickup().Wait = 15 -- On vanilla, all pedestals get a 20 frame delay

    -- Add it to the tracking table so that we don't replace it again
    -- (don't add random items to the index in case a banned item rolls into another banned item)
    if randomItem == false then
      RPGlobals.run.replacedPedestals[#RPGlobals.run.replacedPedestals + 1] = {
        room = roomIndex,
        X    = entity.Position.X,
        Y    = entity.Position.Y,
        seed = newSeed,
      }
      --[[
      Isaac.DebugString("Added to replacedPedestals (" .. tostring(#RPGlobals.run.replacedPedestals) .. "): (" ..
                        tostring(RPGlobals.run.replacedPedestals[#RPGlobals.run.replacedPedestals].room) .. "," ..
                        tostring(RPGlobals.run.replacedPedestals[#RPGlobals.run.replacedPedestals].X) .. "," ..
                        tostring(RPGlobals.run.replacedPedestals[#RPGlobals.run.replacedPedestals].Y) .. "," ..
                        tostring(RPGlobals.run.replacedPedestals[#RPGlobals.run.replacedPedestals].seed) .. ")")
      --]]
    end

    -- Now that we have created a new pedestal, we can delete the old one
    entity:Remove()
  end
end

-- Check all the NPCs in the room
function RPCheckEntities:NPC(entity)
  local npc = entity:ToNPC()
  if npc == nil then
    return
  end

  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"

  -- Check for specific kinds of NPCs
  if npc.Type == EntityType.ENTITY_HOST or -- 27
     npc.Type == EntityType.ENTITY_MOBILE_HOST then -- 204

    -- Hosts and Mobile Hosts
    -- Find out if they are feared
    local entityFlags = npc:GetEntityFlags()
    local feared = false
    local i = 11
    local bit = (entityFlags & (1 << i)) >> i
    if bit == 1 then -- 11 is FLAG_FEAR
      feared = true
    end
    if feared then
      -- Make them immune to fear
      npc:RemoveStatusEffects()
      Isaac.DebugString("Unfeared a Host / Mobile Host.")
      RPGlobals.run.levelDamaged = true
    end

  elseif npc.Type == EntityType.ENTITY_KNIGHT or -- 41
         npc.Type == EntityType.ENTITY_FLOATING_KNIGHT or -- 254
         npc.Type == EntityType.ENTITY_BONE_KNIGHT then -- 283

    -- Knights, Selfless Knights, Floating Knights, and Bone Knights
    -- Add their position to the table so that we can keep track of it on future frames
    if RPGlobals.run.currentKnights[npc.Index] == nil then
      RPGlobals.run.currentKnights[npc.Index] = {
        pos = npc.Position,
      }
    end

    if npc.FrameCount == 4 then
      -- Changing the NPC's state triggers the invulnerability removal in the next frame
      npc.State = 4

      -- Manually setting visible to true allows us to disable the invulnerability 1 frame earlier
      -- (this is to compensate for having only post update hooks)
      npc.Visible = true
    end

  elseif npc.Type == EntityType.ENTITY_STONEHEAD or -- 42 (Stone Grimace and Vomit Grimace)
         npc.Type == EntityType.ENTITY_CONSTANT_STONE_SHOOTER or -- 202 (left, up, right, and down)
         npc.Type == EntityType.ENTITY_BRIMSTONE_HEAD or -- 203 (left, up, right, and down)
         npc.Type == EntityType.ENTITY_GAPING_MAW or -- 235
         npc.Type == EntityType.ENTITY_BROKEN_GAPING_MAW then -- 236

    -- Fix the bug with fast-clear where the "room:SpawnClearAward()" function will
    -- spawn a pickup inside a Stone Grimace and the like
    -- Check to see if there are any pickups/trinkets overlapping with it
    for i, entity2 in pairs(Isaac.GetRoomEntities()) do
      local squareSize = 15
      if (entity2.Type == EntityType.ENTITY_BOMBDROP or -- 4
          entity2.Type == EntityType.ENTITY_PICKUP) and -- 5
         entity2.Position.X >= entity.Position.X - squareSize and
         entity2.Position.X <= entity.Position.X + squareSize and
         entity2.Position.Y >= entity.Position.Y - squareSize and
         entity2.Position.Y <= entity.Position.Y + squareSize then

        -- Respawn it in a accessible location
        local newPosition = room:FindFreePickupSpawnPosition(entity.Position, 0, true)
        -- The arguments are Pos, InitialStep, and AvoidActiveEntities
        game:Spawn(entity2.Type, entity2.Variant, newPosition, entity2.Velocity,
                   entity2.Parent, entity2.SubType, entity2.InitSeed)
        entity2:Remove()
      end
    end

  elseif npc.Type == EntityType.ENTITY_EYE then -- 60
    -- Eyes and Blootshot Eyes
    if npc.FrameCount == 4 then
      npc:GetSprite():SetFrame("Eye Opened", 0)
      npc.State = 3
      npc.Visible = true
    end

    -- Prevent the Eye from shooting for 30 frames
    if (npc.State == 4 or npc.State == 8) and npc.FrameCount < 31 then
      npc.StateFrame = 0
    end

  elseif npc.Type == EntityType.ENTITY_PIN and npc.Variant == 1 and -- 62.1 (Scolex)
         roomType == RoomType.ROOM_BOSS and -- 5
         npc.InitSeed ~= roomSeed and
         RPGlobals.race.rFormat == "seeded" then

     -- Since Scolex attack patterns ruin seeded races, delete it and replace it with two Frails
     -- There are 10 Scolex entities, so we know we are on the last one if there is no child
     npc:Remove() -- This takes a game frame to actually get removed
     if npc.Child == nil then
       -- Spawn two Frails (62.2)
       for i = 1, 2 do
         local frail = game:Spawn(EntityType.ENTITY_PIN, 2, room:GetCenterPos(), Vector(0,0), nil, 0, roomSeed)
         frail.Visible = false -- It will show the head on the first frame after spawning unless we do this
         -- The game will automatically make the entity visible later on
       end
       Isaac.DebugString("Spawned 2 replacement Frails for Scolex with seed: " .. tostring(roomSeed))
     end

  elseif RPGlobals.raceVars.finished and
         npc:GetSprite():IsPlaying("Appear") and
         -- This is needed or else it will swap out the boss during the death animation
         ((npc.Type == EntityType.ENTITY_ISAAC and npc.Variant == 1) or -- Blue Baby (102.1)
          (npc.Type == EntityType.ENTITY_THE_LAMB)) then -- 273

    -- Replace Blue Baby / The Lamb with some random bosses (based on the number of Victory Laps)
    npc:Remove()
    local randomBossSeed = roomSeed
    for i = 1, RPGlobals.raceVars.victoryLaps + 1 do
      randomBossSeed = RPGlobals:IncrementRNG(randomBossSeed)
      math.randomseed(randomBossSeed)
      local randomBoss = RPGlobals.bossArray[math.random(1, #RPGlobals.bossArray)]
      if randomBoss[1] == 19 then
        -- Larry Jr. and The Hollow require multiple segments
        for j = 1, 6 do
          game:Spawn(randomBoss[1], randomBoss[2], room:GetCenterPos(), Vector(0,0), nil, randomBoss[3], roomSeed)
        end
      else
        game:Spawn(randomBoss[1], randomBoss[2], room:GetCenterPos(), Vector(0,0), nil, randomBoss[3], roomSeed)
      end
    end

  elseif npc.Type == EntityType.ENTITY_MOMS_HAND or-- 213
         npc.Type == EntityType.ENTITY_MOMS_DEAD_HAND then -- 287

    if npc.State == 4 and npc.StateFrame < 25 then
      -- Mom's Hands and Mom's Dead Hands
      -- Speed up their attack patterns
      -- (StateFrame starts between 0 and a random negative value and ticks upwards)
      -- (we have to do a small adjustment because if multiple hands fall at the exact same time,
      -- they can stack on top of each other and cause buggy behavior)
      local frameAdjustment = math.random(0, 10)
      -- If we don't seed this with "math.randomseed()", it will just use a random seed
      npc.StateFrame = 25 + frameAdjustment
    end

  elseif npc.Type == EntityType.ENTITY_WIZOOB or -- 219
         npc.Type == EntityType.ENTITY_RED_GHOST then -- 285

    -- Wizoobs and Red Ghosts
    -- Make it so that tears don't pass through them
    if npc.FrameCount == 1 then -- (most NPCs are only visable on the 4th frame, but these are visible immediately)
      -- The ghost is set to ENTCOLL_NONE until the first reappearance
      npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL -- 4
    end

    -- Speed up their attack pattern
    if npc.State == 3 and npc.StateFrame ~= 0 then -- State 3 is when they are disappeared and doing nothing
      npc.StateFrame = 0 -- StateFrame decrements down from 60 to 0, so just jump ahead
    end

  elseif npc.Type == EntityType.ENTITY_THE_HAUNT and npc.Variant == 10 and -- 260.10
         npc.Parent == nil then

    -- Lil' Haunts
    -- Find out if The Haunt is in the room
    if RPGlobals.run.currentLilHaunts[npc.Index] == nil then
      -- Add their position to the table so that we can keep track of it on future frames
      RPGlobals.run.currentLilHaunts[npc.Index] = {
        pos = npc.Position,
      }
    end

    -- Get rid of the Lil' Haunt invulnerability frames
    if npc.FrameCount == 4 then
      npc.State = 4 -- Changing the NPC's state triggers the invulnerability removal in the next frame
      npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL -- 4
      -- Tears will pass through Lil' Haunts when they first spawn, so fix that
      npc.Visible = true -- If we don't do this, they will be invisible after being spawned by a Haunt
    end

  elseif npc.Type == EntityType.ENTITY_THE_LAMB and
         npc.Variant == 10 and -- Lamb Body (267.10)
         npc:IsInvincible() then -- It only turns invincible once it is dead

    -- Remove the body once it dies so that it does not interfere with taking the trophy
    npc:Kill() -- This plays the blood and guts animation, but does not actually remove the entity
    npc:Remove()

  elseif npc.Type == EntityType.ENTITY_PORTAL then -- 306
    if npc.I2 ~= 5 then -- Portals can spawn 1-5 enemies, and this is stored in I2
      npc.I2 = 5 -- Make all portals spawn 5 enemies since this is unseeded
    end
  end

  -- Do extra monitoring for blue variant bosses that drop extra soul hearts
  -- (should only be Larry Jr., Mom, Famine, and Gemini)
  if npc:IsBoss() and npc.SubType ~= 0 then -- From blcd
    RPGlobals.run.bossHearts.extra = true
  end

  if npc:IsBoss() and
     (npc:GetBossColorIdx() == 3 or npc:GetBossColorIdx() == 6) then -- From blcd

    RPGlobals.run.bossHearts.extraIsSoul = true
  end
end

function RPCheckEntities:IsBossType(entityType)
  if entityType == EntityType.ENTITY_LARRYJR or -- 19
     entityType == EntityType.ENTITY_MONSTRO or -- 20
     entityType == EntityType.ENTITY_CHUB or -- 28
     entityType == EntityType.ENTITY_GURDY or -- 36
     entityType == EntityType.ENTITY_MONSTRO2 or -- 43
     entityType == EntityType.ENTITY_MOM or -- 45
     entityType == EntityType.ENTITY_FRED or -- 59
     entityType == EntityType.ENTITY_PIN or -- 62
     entityType == EntityType.ENTITY_FAMINE or -- 63
     entityType == EntityType.ENTITY_PESTILENCE or -- 64
     entityType == EntityType.ENTITY_WAR or -- 65
     entityType == EntityType.ENTITY_DEATH or -- 66
     entityType == EntityType.ENTITY_DUKE or -- 67
     entityType == EntityType.ENTITY_PEEP or -- 68
     entityType == EntityType.ENTITY_LOKI or -- 69
     entityType == EntityType.ENTITY_FISTULA_BIG or -- 71
     entityType == EntityType.ENTITY_FISTULA_MEDIUM or -- 72
     entityType == EntityType.ENTITY_FISTULA_SMALL or -- 73
     entityType == EntityType.ENTITY_BLASTOCYST_BIG or -- 74
     entityType == EntityType.ENTITY_BLASTOCYST_MEDIUM or -- 75
     entityType == EntityType.ENTITY_BLASTOCYST_SMALL or -- 76
     entityType == EntityType.ENTITY_MOMS_HEART or -- 78
     entityType == EntityType.ENTITY_GEMINI or -- 79
     entityType == EntityType.ENTITY_FALLEN or -- 81
     entityType == EntityType.ENTITY_HEADLESS_HORSEMAN or -- 82
     entityType == EntityType.ENTITY_SATAN or -- 84
     entityType == EntityType.ENTITY_MASK_OF_INFAMY or -- 97
     entityType == EntityType.ENTITY_GURDY_JR or -- 99
     entityType == EntityType.ENTITY_WIDOW or -- 100
     entityType == EntityType.ENTITY_DADDYLONGLEGS or -- 101
     entityType == EntityType.ENTITY_ISAAC or -- 102
     entityType == EntityType.ENTITY_GURGLING or -- 237
     entityType == EntityType.ENTITY_THE_HAUNT or -- 260
     entityType == EntityType.ENTITY_DINGLE or -- 261
     entityType == EntityType.ENTITY_MEGA_MAW or -- 262
     entityType == EntityType.ENTITY_GATE or -- 263
     entityType == EntityType.ENTITY_MEGA_FATTY or -- 264
     entityType == EntityType.ENTITY_CAGE or -- 265
     entityType == EntityType.ENTITY_MAMA_GURDY or -- 266
     entityType == EntityType.ENTITY_DARK_ONE or -- 267
     entityType == EntityType.ENTITY_ADVERSARY or -- 268
     entityType == EntityType.ENTITY_POLYCEPHALUS or -- 269
     entityType == EntityType.ENTITY_URIEL or -- 271
     entityType == EntityType.ENTITY_GABRIEL or -- 272
     entityType == EntityType.ENTITY_THE_LAMB or -- 273
     entityType == EntityType.ENTITY_MEGA_SATAN or -- 274
     entityType == EntityType.ENTITY_MEGA_SATAN_2 or -- 275
     entityType == EntityType.ENTITY_STAIN or -- 401
     entityType == EntityType.ENTITY_BROWNIE or -- 402
     entityType == EntityType.ENTITY_FORSAKEN or -- 403
     entityType == EntityType.ENTITY_LITTLE_HORN or -- 404
     entityType == EntityType.ENTITY_RAG_MAN or -- 405
     entityType == EntityType.ENTITY_ULTRA_GREED or -- 406
     entityType == EntityType.ENTITY_HUSH or -- 407
     entityType == EntityType.ENTITY_RAG_MEGA or -- 409
     entityType == EntityType.ENTITY_SISTERS_VIS or -- 410
     entityType == EntityType.ENTITY_BIG_HORN or -- 411
     entityType == EntityType.ENTITY_DELIRIUM then -- 412

    return true
  else
    return false
  end
end

return RPCheckEntities

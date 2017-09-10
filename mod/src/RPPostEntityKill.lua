local RPPostEntityKill = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")

--
-- ModCallbacks.MC_POST_ENTITY_KILL (68)
--

-- EntityType.ENTITY_MOM (45)
function RPPostEntityKill:NPC45(npc)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local room = game:GetRoom()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
  local player = game:GetPlayer(0)
  local challenge = Isaac.GetChallenge()

  -- There can be up to 5 Mom entities in the room, so don't do anything if we have already spawned the photos
  if RPGlobals.run.spawnedPhotos then
    return
  end
  RPGlobals.run.spawnedPhotos = true

  -- Define pedestal positions
  local posCenter = Vector(320, 360)
  local posCenterLeft = Vector(280, 360)
  local posCenterRight = Vector(360, 360)

  -- Figure out if we need to spawn either The Polaroid, The Negative, or both
  local photoSituation -- 1 for The Polaroid, 2 for The Negative, 3 for both, and 4 for a random boss item
  if player:HasTrinket(TrinketType.TRINKET_MYSTERIOUS_PAPER) then -- 21
    -- On every frame, the Mysterious Paper trinket will randomly give The Polaroid or The Negative,
    -- so since it is impossible to determine their actual photo status,
    -- just give the player a choice between the photos
    photoSituation = 3

  elseif player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) and -- 327
     player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328

    -- The player has both photos already (this can only occur in a diversity race)
    -- So, spawn a random boss item instead of a photo
    photoSituation = 4

  elseif player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327
    -- The player has The Polaroid already (this can only occur in a diversity race)
    -- So, spawn The Negative instead
    photoSituation = 2

  elseif player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328
    -- The player has The Negative already (this can only occur in a diversity race)
    -- So, spawn The Polaroid instead
    photoSituation = 1

  elseif challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") or
         challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S3)") then

    -- Give the player a choice between the photos on the season 2 speedrun challenge
    photoSituation = 3

  elseif RPGlobals.race.rFormat == "pageant" then
    -- Give the player a choice between the photos on the Pageant Boy ruleset
    photoSituation = 3

  elseif RPGlobals.race.goal == "The Lamb" then
    -- Races to The Lamb need The Negative
    photoSituation = 2

  elseif RPGlobals.race.goal == "Mega Satan" or
         RPGlobals.race.goal == "Everything" then

    -- Give the player a choice between the photos for races to Mega Satan
    photoSituation = 3

  else
    -- By default, spawn just The Polaroid
    -- (this applies to races with a goal of "Blue Baby" and all normal runs)
    photoSituation = 1
  end

  -- Do the appropriate action depending on the situation
  if photoSituation == 1 then
    -- A situation of 1 means to spawn The Polaroid
    RPGlobals.run.spawningPhoto = true
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, posCenter, Vector(0, 0),
               nil, CollectibleType.COLLECTIBLE_POLAROID, roomSeed)
    Isaac.DebugString("Spawned The Polaroid (on frame " .. tostring(gameFrameCount) .. ").")

  elseif photoSituation == 2 then
    -- A situation of 2 means to spawn The Negative
    RPGlobals.run.spawningPhoto = true
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, posCenter, Vector(0, 0),
               nil, CollectibleType.COLLECTIBLE_NEGATIVE, roomSeed)
    Isaac.DebugString("Spawned The Negative (on frame " .. tostring(gameFrameCount) .. ").")

  elseif photoSituation == 3 then
    -- A situation of 3 means to spawn both The Polaroid and The Negative
    RPGlobals.run.spawningPhoto = true
    local polaroid = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE,
                                posCenterLeft, Vector(0, 0), nil, CollectibleType.COLLECTIBLE_POLAROID, roomSeed)
    polaroid:ToPickup().TheresOptionsPickup = true

    RPGlobals.run.spawningPhoto = true
    local negative = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE,
                                posCenterRight, Vector(0, 0), nil, CollectibleType.COLLECTIBLE_NEGATIVE, roomSeed)
    negative:ToPickup().TheresOptionsPickup = true

    Isaac.DebugString("Spawned both The Polaroid and The Negative (on frame " .. tostring(gameFrameCount) .. ").")

  elseif photoSituation == 4 then
    -- A situation of 4 means to spawn a random boss item
    RPGlobals.run.spawningPhoto = true
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, posCenter, Vector(0, 0), nil, 0, roomSeed)
    -- (a SubType of 0 will make a random item of the pool according to the room type)
    -- (if we use an InitSeed of 0, the item will always be Magic Mushroom, so use the room seed instead)
    Isaac.DebugString("Spawned a random boss item instead of a photo (on frame " .. tostring(gameFrameCount) .. ").")
  end
end

-- EntityType.ENTITY_FALLEN (81)
-- We want to manually spawn the Krampus item instead of letting the game do it
-- This slightly speeds up the spawn so that it can not be accidently deleted by leaving the room
-- Furthermore, it fixes the seeding issue where if you have Gimpy and Krampus drops a heart,
-- the spawned pedestal to be moved one tile over, and this movement can cause the item to be different
function RPPostEntityKill:NPC81(npc)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"

  -- We only care about Krampus (81.1)
  if npc.Variant ~= 1 then
    return
  end

  -- Figure out whether we should spawn the Lump of Coal of Krampus' Head
  local coalBanned = false
  local headBanned = false
  for i = 1, #RPGlobals.race.startingItems do
    if RPGlobals.race.startingItems[i] == CollectibleType.COLLECTIBLE_LUMP_OF_COAL then -- 132
      coalBanned = true
    elseif RPGlobals.race.startingItems[i] == CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS then -- 293
      headBanned = true
    end
  end
  local krampusItem
  if coalBanned and headBanned then
    -- Both A Lump of Coal and Krampus' Head are on the ban list, so make a random item instead
    krampusItem = 0
    Isaac.DebugString("Spawned a random item since both A Lump of Coal and Krampus' Head are banned.")
  elseif coalBanned then
    -- Switch A Lump of Coal to Krampus' Head
    krampusItem = CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS -- 293
    Isaac.DebugString("Spawned Krampus' Head since A Lump of Coal is banned.")
  elseif headBanned then
    -- Switch Krampus' Head to A Lump of Coal
    krampusItem = CollectibleType.COLLECTIBLE_LUMP_OF_COAL -- 132
    Isaac.DebugString("Spawned A Lump of Coal since Krampus' Head is banned.")
  else
    math.randomseed(roomSeed)
    krampusItem = math.random(1, 2)
    if krampusItem == 1 then
      krampusItem = CollectibleType.COLLECTIBLE_LUMP_OF_COAL -- 132
      Isaac.DebugString("Spawned A Lump of Coal (randomly based on the room seed).")
    else
      krampusItem = CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS -- 293
      Isaac.DebugString("Spawned Krampus' Head (randomly based on the room seed).")
    end
  end

  -- Spawn it with a seed of 0 so that it gets replaced on the next frame
  if krampusItem ~= 0 then
    -- We have to let the "ReplacePedestal" function know that this is not a natural Krampus pedestal
    RPGlobals.run.spawningKrampusItem = true
  end
  game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, npc.Position, Vector(0, 0),
             nil, krampusItem, 0)
end

return RPPostEntityKill
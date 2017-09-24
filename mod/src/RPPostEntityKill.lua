local RPPostEntityKill = {}

--
-- Includes
--

local RPGlobals  = require("src/rpglobals")
local RPSpeedrun = require("src/rpspeedrun")

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
  local situation -- 1 for The Polaroid, 2 for The Negative, 3 for both, and 4 for a random boss item
  if challenge == Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") or
     challenge == Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") then

    -- Season 1 speedrun challenges always go to The Chest
    situation = 1

  elseif challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") or
         challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S3)") then

    -- Give the player a choice between the photos on the season 2 and season 3 speedrun challenges
    situation = 3

  elseif player:HasTrinket(TrinketType.TRINKET_MYSTERIOUS_PAPER) then -- 21
    -- On every frame, the Mysterious Paper trinket will randomly give The Polaroid or The Negative,
    -- so since it is impossible to determine their actual photo status,
    -- just give the player a choice between the photos
    situation = 3

  elseif player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) and -- 327
         player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328

    -- The player has both photos already (this can only occur in a diversity race)
    -- So, spawn a random boss item instead of a photo
    situation = 4

  elseif player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327
    -- The player has The Polaroid already (this can only occur in a diversity race)
    -- So, spawn The Negative instead
    situation = 2

  elseif player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328
    -- The player has The Negative already (this can only occur in a diversity race)
    -- So, spawn The Polaroid instead
    situation = 1

  elseif RPGlobals.race.rFormat == "pageant" then
    -- Give the player a choice between the photos on the Pageant Boy ruleset
    situation = 3

  elseif RPGlobals.race.goal == "The Lamb" then
    -- Races to The Lamb need The Negative
    situation = 2

  elseif RPGlobals.race.goal == "Mega Satan" or
         RPGlobals.race.goal == "Everything" then

    -- Give the player a choice between the photos for races to Mega Satan
    situation = 3

  else
    -- By default, spawn just The Polaroid
    -- (this applies to races with a goal of "Blue Baby" and all normal runs)
    situation = 1
  end

  -- Do the appropriate action depending on the situation
  if situation == 1 then
    -- A situation of 1 means to spawn The Polaroid
    RPGlobals.run.spawningPhoto = true
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, posCenter, Vector(0, 0),
               nil, CollectibleType.COLLECTIBLE_POLAROID, roomSeed)
    Isaac.DebugString("Spawned The Polaroid (on frame " .. tostring(gameFrameCount) .. ").")

  elseif situation == 2 then
    -- A situation of 2 means to spawn The Negative
    RPGlobals.run.spawningPhoto = true
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, posCenter, Vector(0, 0),
               nil, CollectibleType.COLLECTIBLE_NEGATIVE, roomSeed)
    Isaac.DebugString("Spawned The Negative (on frame " .. tostring(gameFrameCount) .. ").")

  elseif situation == 3 then
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

  elseif situation == 4 then
    -- A situation of 4 means to spawn a random boss item
    RPGlobals.run.spawningPhoto = true
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, posCenter, Vector(0, 0), nil, 0, roomSeed)
    -- (a SubType of 0 will make a random item of the pool according to the room type)
    -- (if we use an InitSeed of 0, the item will always be Magic Mushroom, so use the room seed instead)
    Isaac.DebugString("Spawned a random boss item instead of a photo (on frame " .. tostring(gameFrameCount) .. ").")
  end

  -- Fix the (vanilla) Globin / Sack bug
  RPPostEntityKill:KillExtraEnemies()
end

-- EntityType.ENTITY_MOMS_HEART (78)
-- EntityType.ENTITY_HUSH (407)
function RPPostEntityKill:NPC78(npc)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local player = game:GetPlayer(0)
  local challenge = Isaac.GetChallenge()

  -- Record when we killed It Lives! or Hush;
  -- a trapdoor and/or beam of light will spawn 1 frame from now, and we will delete it in the
  -- "RPFastTravel:ReplaceTrapdoor()" and the "RPFastTravel:ReplaceHeavenDoor()" functions
  RPGlobals.run.itLivesKillFrame = gameFrameCount

  -- Define positions for the trapdoor and beam of light (recorded from vanilla)
  local posCenter = Vector(320, 280)
  local posCenterLeft = Vector(280, 280)
  local posCenterRight = Vector(360, 280)
  if stage == LevelStage.STAGE4_3 then -- 9
    -- The positions are different for the Blue Womb; they are more near the top wall
    posCenter = Vector(600, 280)
    posCenterLeft = Vector(560, 280)
    posCenterRight = Vector(640, 280)
  end

  -- Figure out if we need to spawn either a trapdoor, a beam of light, or both
  local situation -- 1 for the beam of light, 2 for the trapdoor, 3 for both
  if challenge == Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") or
     challenge == Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") then

    -- Season 1 speedrun challenges always go to The Chest
    situation = 1

  elseif challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S2)") then
    -- Season 1 speedrun challenges always go to the Dark Room
    situation = 2

  elseif challenge == Isaac.GetChallengeIdByName("R+7 Speedrun (S3)") then
    -- Season 3 speedrun challenges alternate between The Chest and the Dark Room
    situation = RPSpeedrun.s3direction

  elseif RPGlobals.race.goal == "The Lamb" then
    -- Races to The Lamb go to the Dark Room
    situation = 2

  elseif RPGlobals.race.rFormat == "pageant" or
         RPGlobals.race.goal == "Mega Satan" or
         RPGlobals.race.goal == "Everything" then

    -- On races to Mega Satan (and the Pageant Boy ruleset), we can potentially go in either direction
    -- So, determine the direction by looking at the photo(s) that we collected
    if player:HasTrinket(TrinketType.TRINKET_MYSTERIOUS_PAPER) then -- 21
      -- On every frame, the Mysterious Paper trinket will randomly give The Polaroid or The Negative,
      -- so since it is impossible to determine their actual photo status,
      -- just give the player a choice between the directions
      situation = 3

    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) and -- 327
           player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328

      -- The player has both photos (this can only occur in a diversity race)
      -- So, give the player a choice between the directions
      situation = 3

    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327
      -- The player has The Polaroid, so send them to The Chest
      situation = 1

    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328
      -- The player has The Negative, so send them to the Dark Room
      situation = 2

    else
      -- The player does not have either The Polaroid or The Negative, so give them a choice between the directions
      situation = 3
    end

  else
    -- By default, go to The Chest
    -- (this applies to races with a goal of "Blue Baby" and all normal runs)
    situation = 1
  end

  -- Do the appropriate action depending on the situation
  if situation == 1 then
    -- Spawn a beam of light, a.k.a. Heaven Door (1000.39)
    -- (it will get replaced with the fast-travel version on this frame)
    game:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, posCenter, Vector(0, 0), nil, 0, 0)
    Isaac.DebugString("It Lives! or Hush killed; situation 1.")

  elseif situation == 2 then
    -- Spawn a trapdoor (it will get replaced with the fast-travel version on this frame)
    Isaac.GridSpawn(GridEntityType.GRID_TRAPDOOR, 0, posCenter, true) -- 17
    Isaac.DebugString("It Lives! or Hush killed; situation 2.")

  elseif situation == 3 then
    -- Spawn both a trapdoor and a beam of light (they will get replaced with the fast-travel versions on this frame)
    Isaac.GridSpawn(GridEntityType.GRID_TRAPDOOR, 0, posCenterLeft, true) -- 17
    game:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, posCenterRight, Vector(0, 0), nil, 0, 0)
    Isaac.DebugString("It Lives! or Hush killed; situation 3.")
  end

  -- Fix the (vanilla) Globin / Sack bug
  RPPostEntityKill:KillExtraEnemies()
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
  local subType
  if coalBanned and headBanned then
    -- Both A Lump of Coal and Krampus' Head are on the ban list, so make a random item instead
    subType = 0
    Isaac.DebugString("Spawned a random item since both A Lump of Coal and Krampus' Head are banned.")
  elseif coalBanned then
    -- Switch A Lump of Coal to Krampus' Head
    subType = CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS -- 293
    Isaac.DebugString("Spawned Krampus' Head since A Lump of Coal is banned.")
  elseif headBanned then
    -- Switch Krampus' Head to A Lump of Coal
    subType = CollectibleType.COLLECTIBLE_LUMP_OF_COAL -- 132
    Isaac.DebugString("Spawned A Lump of Coal since Krampus' Head is banned.")
  else
    math.randomseed(roomSeed)
    local seededChoice = math.random(1, 2)
    if seededChoice == 1 then
      subType = CollectibleType.COLLECTIBLE_LUMP_OF_COAL -- 132
      Isaac.DebugString("Spawned A Lump of Coal (randomly based on the room seed).")
    else
      subType = CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS -- 293
      Isaac.DebugString("Spawned Krampus' Head (randomly based on the room seed).")
    end
  end

  -- We have to let the "ReplacePedestal()" function know that this is not a natural Krampus pedestal
  if subType ~= 0 then
    RPGlobals.run.spawningKrampusItem = true
  end

  -- Spawn it with a seed of 0 so that it gets replaced on the next frame
  game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, npc.Position, Vector(0, 0), nil, subType, 0)
end

-- EntityType.ENTITY_URIEL (271)
-- EntityType.ENTITY_GABRIEL (272)
-- We want to manually spawn the key pieces instead of letting the game do it
-- This slightly speeds up the spawn so that they can not be accidently deleted by leaving the room
function RPPostEntityKill.NPC271(npc)
  -- Local variables
  local game = Game()

  -- Figure out whether we should spawn the Key Piece 1 or Key Piece 2
  local subType
  if npc.Type == EntityType.ENTITY_URIEL then -- 271
    subType = CollectibleType.COLLECTIBLE_KEY_PIECE_1 -- 238
  elseif npc.Type == EntityType.ENTITY_GABRIEL then -- 272
    subType = CollectibleType.COLLECTIBLE_KEY_PIECE_2 -- 239
  end

  -- We have to let the "ReplacePedestal()" function know that this is not a natural Krampus pedestal
  RPGlobals.run.spawningKeyPiece = true

  -- Spawn it with a seed of 0 so that it gets replaced on the next frame
  game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, npc.Position, Vector(0, 0), nil, subType, 0)
end

-- EntityType.ENTITY_HUSH (407)
function RPPostEntityKill.NPC407(npc)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  Isaac.DebugString("Killed Hush on frame: " .. tostring(gameFrameCount))
  RPGlobals.run.itLivesKillFrame = gameFrameCount
end

-- After killing Mom, Mom's Heart, or It Lives!, all entities in the room are killed
-- However, Nicalis didn't consider that Globins need to be killed twice (to kill their flesh pile forms)
-- Blisters also need to be killed twice (to kill the spawned Sacks)
-- Racing+ manually fixes this bug by expliticly killing them
-- This code is also necessary to fix the issue where a Globin will prevent the
-- removal of the natural trapdoor and beam of light after It Lives!
--- (in the "RPFastTravel:ReplaceTrapdoor()" and the "RPFastTravel:ReplaceHeavenDoor()" functions)
function RPPostEntityKill:KillGlobins()
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_GLOBIN or -- 24
       entity.Type == EntityType.ENTITY_BOIL then -- 30

      entity:Kill()
      Isaac.DebugString("Manually killed a Globin / Sack after Mom / It Lives!")
    end
  end
end

return RPPostEntityKill

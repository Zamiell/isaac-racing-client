local RPPostEntityKill = {}

-- Includes
local RPGlobals  = require("src/rpglobals")
local RPSpeedrun = require("src/rpspeedrun")

-- ModCallbacks.MC_POST_ENTITY_KILL (68)
-- When beginning a death animation, make bosses faded so that it makes it easier to see
function RPPostEntityKill:Main(entity)
  -- We only want to fade bosses
  local npc = entity:ToNPC()
  if npc == nil then
    return
  end
  if npc:IsBoss() == false then
    return
  end

  -- In a season 6 speedrun,
  -- allow the player to reset for a new item if they kill the Basement 2 boss
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local challenge = Isaac.GetChallenge()
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 6 Beta)") and
     stage == 2 then

    RPSpeedrun.timeItemAssigned = 0
  end

  -- We don't want to fade multi-segment bosses since killing one segment will fade the rest of the segments
  if entity.Type == EntityType.ENTITY_LARRYJR or -- 19 (and The Hollow)
     entity.Type == EntityType.ENTITY_PIN or -- 62 (and Scolex / Frail)
     entity.Type == EntityType.ENTITY_GEMINI or -- 79 (and Steven / Blighted Ovum)
     entity.Type == EntityType.ENTITY_HEART_OF_INFAMY then -- 98

    return
  end

  -- Set the color to have an alpha of 0.4
  local faded = Color(1, 1, 1, 0.4, 0, 0, 0)
  entity:SetColor(faded, 1000, 0, true, true) -- KColor, Duration, Priority, Fadeout, Share
  -- Priority doesn't matter, but a low duration won't work;
  -- the longer the duration, the more fade, and a fade of 1000 looks nice
end

-- EntityType.ENTITY_MOM (45)
function RPPostEntityKill:Entity45(entity)
  -- There can be up to 5 Mom entities in the room, so don't do anything if we have already spawned the photos
  if RPGlobals.run.momDied then
    return
  end
  RPGlobals.run.momDied = true

  -- Fix the (vanilla) bug with Globins, Sacks, etc.
  RPPostEntityKill:KillExtraEnemies()
end

-- EntityType.ENTITY_MOMS_HEART (78)
-- EntityType.ENTITY_HUSH (407)
function RPPostEntityKill:Entity78(entity)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)
  local challenge = Isaac.GetChallenge()

  -- For some reason, Mom's Heart / It Lives! will die twice in a row on two subsequent frames
  -- (this does not happen on Hush)
  -- We don't want to do anything if this is the first time it died
  if stage ~= LevelStage.STAGE4_3 and -- 9
     gameFrameCount - RPGlobals.run.itLivesKillFrame > 1 then

    RPGlobals.run.itLivesKillFrame = gameFrameCount
    Isaac.DebugString("Killed Mom's Heart / It Lives! / Hush (fake first death) on frame: " ..
                      tostring(gameFrameCount))
    return
  end

  -- Record when we killed It Lives! or Hush;
  -- a trapdoor and/or beam of light will spawn 1 frame from now, and we will delete it in the
  -- "RPFastTravel:ReplaceTrapdoor()" and the "RPFastTravel:ReplaceHeavenDoor()" functions
  RPGlobals.run.itLivesKillFrame = gameFrameCount
  Isaac.DebugString("Killed Mom's Heart / It Lives! / Hush on frame: " .. tostring(gameFrameCount))

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
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") or
     challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") or
     RPSpeedrun.inSeededSpeedrun then

    -- Season 1, 4, and 5 always goes to Cathedral / The Chest
    situation = 1

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") then
    -- Season 2 always goes to Sheol / the Dark Room
    situation = 2

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") or
         challenge == Isaac.GetChallengeIdByName("R+7 (Season 6 Beta)") then

    -- Season 3 and 6 alternate between Cathedral / The Chest and Sheol / the Dark Room,
    -- starting with Cathedral / The Chest
    situation = RPSpeedrun.charNum % 2
    if situation == 0 then
      situation = 2
    end

  elseif RPGlobals.race.status == "in progress" and RPGlobals.race.goal == "Blue Baby" then
    -- Races to Blue Baby go to Cathedral / The Chest
    situation = 1

  elseif RPGlobals.race.status == "in progress" and RPGlobals.race.goal == "The Lamb" then
    -- Races to The Lamb go to Sheol / the Dark Room
    situation = 2

  elseif RPGlobals.race.status == "in progress" and RPGlobals.race.goal == "Everything" then
    -- "Everything" races always go to Cathedral first (and then Sheol after that)
    situation = 1

  else
    -- We can potentially go in either direction
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
      -- The player has The Polaroid, so send them to Cathdral
      situation = 1

    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328
      -- The player has The Negative, so send them to Sheol
      situation = 2

    else
      -- The player does not have either The Polaroid or The Negative, so give them a choice between the directions
      situation = 3
    end
  end

  -- Do the appropriate action depending on the situation
  if situation == 1 then
    -- Spawn a beam of light, a.k.a. Heaven Door (1000.39)
    -- (it will get replaced with the fast-travel version on this frame)
    game:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, posCenter, Vector(0, 0), nil, 0, 0)
    Isaac.DebugString("It Lives! or Hush killed; situation 1 - only up.")

  elseif situation == 2 then
    -- Spawn a trapdoor (it will get replaced with the fast-travel version on this frame)
    Isaac.GridSpawn(GridEntityType.GRID_TRAPDOOR, 0, posCenter, true) -- 17
    Isaac.DebugString("It Lives! or Hush killed; situation 2 - only down.")

  elseif situation == 3 then
    -- Spawn both a trapdoor and a beam of light (they will get replaced with the fast-travel versions on this frame)
    Isaac.GridSpawn(GridEntityType.GRID_TRAPDOOR, 0, posCenterLeft, true) -- 17
    game:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, posCenterRight, Vector(0, 0), nil, 0, 0)
    Isaac.DebugString("It Lives! or Hush killed; situation 3 - up and down.")
  end

  -- Fix the (vanilla) bug with Globins, Sacks, etc.
  RPPostEntityKill:KillExtraEnemies()

  -- Manually open the Void door if we just killed Hush
  if entity.Type == EntityType.ENTITY_HUSH then -- 407
    room:TrySpawnTheVoidDoor()
  end
end

-- EntityType.ENTITY_FALLEN (81)
-- We want to manually spawn the Krampus item instead of letting the game do it
-- This slightly speeds up the spawn so that it can not be accidently deleted by leaving the room
-- Furthermore, it fixes the seeding issue where if you have Gimpy and Krampus drops a heart,
-- the spawned pedestal to be moved one tile over, and this movement can cause the item to be different
function RPPostEntityKill:Entity81(entity)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local seeds = game:GetSeeds()
  local startSeed = seeds:GetStartSeed() -- Gets the starting seed of the run, something like "2496979501"
  local player = game:GetPlayer(0)

  -- We only care about Krampus (81.1)
  if entity.Variant ~= 1 then
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
  if player:HasCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) then -- 132
    coalBanned = true
  end
  if player:HasCollectible(CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS) or -- 293
     RPGlobals.run.schoolbag.item == CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS then -- 293

    headBanned = true
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
    math.randomseed(startSeed)
    local seededChoice = math.random(1, 2)
    if seededChoice == 1 then
      subType = CollectibleType.COLLECTIBLE_LUMP_OF_COAL -- 132
      Isaac.DebugString("Spawned A Lump of Coal (randomly based on the room seed).")
    else
      subType = CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS -- 293
      Isaac.DebugString("Spawned Krampus' Head (randomly based on the room seed).")
    end
  end

  -- We have to prevent the bug where the pedestal item can overlap with a grid entity
  local pos = entity.Position
  local gridIndex = room:GetGridIndex(pos)
  local gridEntity = room:GetGridEntity(gridIndex)
  if gridEntity ~= nil then
    pos = room:FindFreePickupSpawnPosition(pos, 1, false)
  end

  -- We have to let the "ReplacePedestal()" function know that this is not a natural Krampus pedestal
  if subType ~= 0 then
    RPGlobals.run.spawningKrampusItem = true
  end

  -- Spawn it with a seed of 0 (it will get replaced on the next frame in the "RPPedestals:Replace()" function)
  game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 5.100
             pos, Vector(0, 0), nil, subType, 0)
end

-- EntityType.ENTITY_URIEL (271)
-- EntityType.ENTITY_GABRIEL (272)
-- We want to manually spawn the key pieces instead of letting the game do it
-- This slightly speeds up the spawn so that they can not be accidently deleted by leaving the room
function RPPostEntityKill:Entity271(entity)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local player = game:GetPlayer(0)

  -- We only want to spawn key pieces from the non-Fallen versions
  if entity.Variant == 1 then
    return
  end

  -- We don't want to drop key pieces from angels in Victory Lap bosses or the Boss Rush
  if roomType ~= RoomType.ROOM_ANGEL and -- 15
     roomType ~= RoomType.ROOM_SUPERSECRET then -- 8
     -- Key pieces dropping from angels in non-Angel Rooms was introduced in Booster Pack #4

    return
  end

  -- We don't want to drop key pieces from angels if the player has the Filigree Feather
  -- (we could spawn a SubType 0 collectible, but then we wouldn't know how to remove the naturally dropped random item)
  if player:HasTrinket(TrinketType.TRINKET_FILIGREE_FEATHERS) then -- 123
    return
  end

  -- We don't want to drop a key piece if there is another alive angel in the room
  for i, entity2 in pairs(Isaac.GetRoomEntities()) do
    local isDead = entity2:IsDead()
    if (entity2.Type == EntityType.ENTITY_URIEL or -- 271
        entity2.Type == EntityType.ENTITY_GABRIEL) and -- 272
        isDead == false then

      return
    end
  end

  -- Figure out whether we should spawn the Key Piece 1 or Key Piece 2
  local subType
  if entity.Type == EntityType.ENTITY_URIEL then -- 271
    subType = CollectibleType.COLLECTIBLE_KEY_PIECE_1 -- 238
  elseif entity.Type == EntityType.ENTITY_GABRIEL then -- 272
    subType = CollectibleType.COLLECTIBLE_KEY_PIECE_2 -- 239
  end

  -- We have to prevent the bug where the pedestal item can overlap with a grid entity
  local pos = entity.Position
  local gridIndex = room:GetGridIndex(pos)
  local gridEntity = room:GetGridEntity(gridIndex)
  if gridEntity ~= nil then
    pos = room:FindFreePickupSpawnPosition(pos, 1, false)
  end

  -- We have to let the "ReplacePedestal()" function know that this is not a natural Krampus pedestal
  RPGlobals.run.spawningKeyPiece = true

  -- Spawn it with a seed of 0 (it will get replaced on the next frame in the "RPPedestals:Replace()" function)
  game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 5.100
             pos, Vector(0, 0), nil, subType, 0)
end

-- After killing Mom, Mom's Heart, or It Lives!, all entities in the room are killed
-- However, Nicalis didn't consider that Globins need to be killed twice (to kill their flesh pile forms)
-- Blisters also need to be killed twice (to kill the spawned Sacks)
-- Racing+ manually fixes this bug by expliticly killing them (and removing Fistula and Teratoma)
-- This code is also necessary to fix the issue where a Globin will prevent the
-- removal of the natural trapdoor and beam of light after It Lives!
--- (in the "RPFastTravel:ReplaceTrapdoor()" and the "RPFastTravel:ReplaceHeavenDoor()" functions)
function RPPostEntityKill:KillExtraEnemies()
  Isaac.DebugString("Checking for extra enemies to kill after a Mom / It Lives! fight.")
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    if entity.Type == EntityType.ENTITY_GLOBIN or -- 24
       entity.Type == EntityType.ENTITY_BOIL or -- 30
       entity.Type == EntityType.ENTITY_FISTULA_BIG or -- 71 (also includes Teratoma)
       entity.Type == EntityType.ENTITY_FISTULA_MEDIUM or -- 72 (also includes Teratoma)
       entity.Type == EntityType.ENTITY_FISTULA_SMALL or -- 73 (also includes Teratoma)
       entity.Type == EntityType.ENTITY_BLISTER then -- 303

      -- Removing it just causes it to disappear, which looks buggy, so show a small blood explosion as well
      entity:BloodExplode()
      entity:Remove()
      Isaac.DebugString("Manually removed an enemy after Mom / It Lives!")
    end
  end
end

return RPPostEntityKill

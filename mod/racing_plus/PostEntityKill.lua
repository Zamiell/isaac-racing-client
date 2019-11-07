local PostEntityKill = {}

-- Includes
local g         = require("racing_plus/globals")
local FastClear = require("racing_plus/fastclear")
local Speedrun  = require("racing_plus/speedrun")

-- ModCallbacks.MC_POST_ENTITY_KILL (68)
function PostEntityKill:Main(entity)
  FastClear:PostEntityKill(entity) -- Track which enemies are cleared for the purposes of the "fast-clear" feature
  PostEntityKill:FadeBosses(entity) -- Fade bosses that are killed
end

-- When beginning a death animation, make bosses faded so that it makes it easier to see
function PostEntityKill:FadeBosses(entity)
  -- We only want to fade bosses
  local npc = entity:ToNPC()
  if npc == nil then
    return
  end
  if not npc:IsBoss() then
    return
  end

  -- In a season 6 speedrun,
  -- reset the starting item timer if they have killed the Basement 2 boss
  local stage = g.l:GetStage()
  local challenge = Isaac.GetChallenge()
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") and
     stage == 2 then

    Speedrun.timeItemAssigned = 0
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
function PostEntityKill:Entity45(entity)
  -- There can be up to 5 Mom entities in the room, so don't do anything if we have already spawned the photos
  if g.run.momDied then
    return
  end
  g.run.momDied = true

  -- Fix the (vanilla) bug with Globins, Sacks, etc.
  PostEntityKill:KillExtraEnemies()
end

-- EntityType.ENTITY_MOMS_HEART (78)
-- EntityType.ENTITY_HUSH (407)
function PostEntityKill:Entity78(entity)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local stage = g.l:GetStage()
  local challenge = Isaac.GetChallenge()

  -- Don't do anything if we are fighting Mom's Heart / It Lives on The Void
  if stage == 12 then
    return
  end

  -- For some reason, Mom's Heart / It Lives! will die twice in a row on two subsequent frames
  -- (this does not happen on Hush)
  -- We don't want to do anything if this is the first time it died
  if stage ~= 9 and
     gameFrameCount - g.run.itLivesKillFrame > 1 then

    g.run.itLivesKillFrame = gameFrameCount
    Isaac.DebugString("Killed Mom's Heart / It Lives! / Hush (fake first death) on frame: " ..
                      tostring(gameFrameCount))
    return
  end

  -- Record when we killed It Lives! or Hush;
  -- a trapdoor and/or beam of light will spawn 1 frame from now, and we will delete it in the
  -- "FastTravel:ReplaceTrapdoor()" and the "FastTravel:ReplaceHeavenDoor()" functions
  g.run.itLivesKillFrame = gameFrameCount
  Isaac.DebugString("Killed Mom's Heart / It Lives! / Hush on frame: " .. tostring(gameFrameCount))

  -- Define positions for the trapdoor and beam of light (recorded from vanilla)
  local posCenter = Vector(320, 280)
  local posCenterLeft = Vector(280, 280)
  local posCenterRight = Vector(360, 280)
  if stage == 9 then
    -- The positions are different for the Blue Womb; they are more near the top wall
    posCenter = Vector(600, 280)
    posCenterLeft = Vector(560, 280)
    posCenterRight = Vector(640, 280)
  end

  -- Figure out if we need to spawn either a trapdoor, a beam of light, or both
  local situations = {
    NEITHER = 0,
    BEAM_OF_LIGHT = 1,
    TRAPDOOR = 2,
    BOTH = 3,
  }
  local situation
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") or
     challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") or
     challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") or
     challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") or
     Speedrun.inSeededSpeedrun or
     (g.race.status == "in progress" and g.race.goal == "Blue Baby") or
     (g.race.status == "in progress" and g.race.goal == "Everything") then

    -- Season 1, 4, 5, and Seeded speedruns always go to Cathedral / The Chest
    -- Races to Blue Baby go to Cathedral / The Chest
    -- "Everything" races always go to Cathedral first (and then Sheol after that)
    situation = situations.BEAM_OF_LIGHT

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") or
         (g.race.status == "in progress" and g.race.goal == "The Lamb") then

    -- Season 2 speedruns always goes to Sheol / the Dark Room
    -- Races to The Lamb go to Sheol / the Dark Room
    situation = situations.TRAPDOOR

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") or
         challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") then

    -- Some speedruns alternate between Cathedral / The Chest and Sheol / the Dark Room,
    -- starting with Cathedral / The Chest
    situation = Speedrun.charNum % 2
    if situation == 0 then
      situation = situations.TRAPDOOR
    end

  elseif ((g.race.status == "in progress" and g.race.goal == "Hush") or
          challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)")) and
         entity.Type == EntityType.ENTITY_HUSH then -- 78

    -- Hush is the goal
    -- Don't spawn any paths in case the player would accidently walk into them
    situation = situations.NEITHER

  else
    -- We can potentially go in either direction
    -- So, determine the direction by looking at the photo(s) that we collected
    if g.p:HasTrinket(TrinketType.TRINKET_MYSTERIOUS_PAPER) then -- 21
      -- On every frame, the Mysterious Paper trinket will randomly give The Polaroid or The Negative,
      -- so since it is impossible to determine their actual photo status,
      -- just give the player a choice between the directions
      situation = situations.BOTH

    elseif g.p:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) and -- 327
           g.p:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328

      -- The player has both photos (this can only occur in a diversity race)
      -- So, give the player a choice between the directions
      situation = situations.BOTH

    elseif g.p:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) then -- 327
      -- The player has The Polaroid, so send them to Cathdral
      situation = situations.BEAM_OF_LIGHT

    elseif g.p:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE) then -- 328
      -- The player has The Negative, so send them to Sheol
      situation = situations.TRAPDOOR

    else
      -- The player does not have either The Polaroid or The Negative, so give them a choice between the directions
      situation = situations.BOTH
    end
  end

  -- Handle special things for Season 7
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") and
     entity.Type == EntityType.ENTITY_MOMS_HEART then -- 78

    -- Spawn a big chest (which will get replaced with either a checkpoint or a trophy on the next frame)
    if g:TableContains(Speedrun.remainingGoals, "It Lives!") then
      Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, 0, -- 5.340
                  g.zeroVector, g.zeroVector, nil) -- It does not matter where we spawn it since it will be replaced
    end

    -- Perform some path validation for Season 7
    if situation ~= situations.NEITHER and
       not g:TableContains(Speedrun.remainingGoals, "Blue Baby") and
       not g:TableContains(Speedrun.remainingGoals, "The Lamb") and
       not g:TableContains(Speedrun.remainingGoals, "Mega Satan") and
       not g:TableContains(Speedrun.remainingGoals, "Ultra Greed") then

       situation = situations.NEITHER
    end
  end

  -- Do the appropriate action depending on the situation
  if situation == situations.NEITHER then
    Isaac.DebugString("It Lives! or Hush killed; situation 0 - neither up nor down.")

  elseif situation == situations.BEAM_OF_LIGHT then
    -- Spawn a beam of light, a.k.a. Heaven Door (1000.39)
    -- It will get replaced with the fast-travel version on this frame
    -- Make the spawner entity the player so that we can distinguish it from the vanilla heaven door
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, 0, -- 1000.39
                posCenter, g.zeroVector, g.p)
    Isaac.DebugString("It Lives! or Hush killed; situation 1 - only up.")

  elseif situation == situations.TRAPDOOR then
    -- Spawn a trapdoor (it will get replaced with the fast-travel version on this frame)
    Isaac.GridSpawn(GridEntityType.GRID_TRAPDOOR, 0, posCenter, true) -- 17
    Isaac.DebugString("It Lives! or Hush killed; situation 2 - only down.")

  elseif situation == situations.BOTH then
    -- Spawn both a trapdoor and a beam of light
    -- They will get replaced with the fast-travel versions on this frame
    -- Make the spawner entity the player so that we can distinguish it from the vanilla heaven door
    Isaac.GridSpawn(GridEntityType.GRID_TRAPDOOR, 0, posCenterLeft, true) -- 17
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, 0, -- 1000.39
                posCenterRight, g.zeroVector, g.p)
    Isaac.DebugString("It Lives! or Hush killed; situation 3 - up and down.")
  end

  -- Fix the (vanilla) bug with Globins, Sacks, etc.
  PostEntityKill:KillExtraEnemies()

  -- Finally, perform extra activities if we killed Hush
  if entity.Type ~= EntityType.ENTITY_HUSH then -- 407
    return
  end

  -- Season 7 speedruns end at Hush
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    -- Spawn a big chest (which will get replaced with either a checkpoint or a trophy on the next frame)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, 0, -- 5.340
                g.zeroVector, g.zeroVector, nil) -- It does not matter where we spawn it since it will be replaced
    return
  end

  -- Manually open the Void door
  g.r:TrySpawnTheVoidDoor()

  if g.race.status == "in progress" and
      g.race.goal == "Hush" then

    -- Spawn a big chest (which will get replaced with a trophy on the next frame)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, 0, -- 5.340
                g.zeroVector, g.zeroVector, nil) -- It does not matter where we spawn it since it will be replaced
  end
end

-- EntityType.ENTITY_FALLEN (81)
-- We want to manually spawn the Krampus item instead of letting the game do it
-- This slightly speeds up the spawn so that it can not be accidently deleted by leaving the room
-- Furthermore, it fixes the seeding issue where if you have Gimpy and Krampus drops a heart,
-- the spawned pedestal to be moved one tile over, and this movement can cause the item to be different
function PostEntityKill:Entity81(entity)
  -- We only care about Krampus (81.1)
  if entity.Variant ~= 1 then
    return
  end

  -- Local variables
  local startSeed = g.seeds:GetStartSeed() -- Gets the starting seed of the run, something like "2496979501"

  -- Figure out whether we should spawn the Lump of Coal of Krampus' Head
  local coalBanned = false
  local headBanned = false
  if g.race.status == "in progress" then
    for _, itemID in ipairs(g.race.startingItems) do
      if itemID == CollectibleType.COLLECTIBLE_LUMP_OF_COAL then -- 132
        coalBanned = true
      elseif itemID == CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS then -- 293
        headBanned = true
      end
    end
  end
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) then -- 132
    coalBanned = true
  end
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS) or -- 293
     g.run.schoolbag.item == CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS then -- 293

    headBanned = true
  end
  local subType
  if coalBanned and headBanned then
    -- Both A Lump of Coal and Krampus' Head are on the ban list, so make a random item instead
    subType = g.itemPool:GetCollectible(ItemPoolType.POOL_DEVIL, true, startSeed) -- 3
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
      Isaac.DebugString("Spawned A Lump of Coal (randomly based on the starting seed).")
    else
      subType = CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS -- 293
      Isaac.DebugString("Spawned Krampus' Head (randomly based on the starting seed).")
    end
  end

  -- We have to prevent the bug where the pedestal item can overlap with a grid entity
  local pos = entity.Position
  local gridIndex = g.r:GetGridIndex(pos)
  local gridEntity = g.r:GetGridEntity(gridIndex)
  if gridEntity ~= nil then
    pos = g.r:FindFreePickupSpawnPosition(pos, 1, false)
  end

  -- We have to let the "ReplacePedestal()" function know that this is not a natural Krampus pedestal
  if subType ~= 0 then
    g.run.spawningKrampusItem = true
  end

  -- Spawn the item (it will get replaced on the next frame in the "RPPedestals:Replace()" function)
  Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, subType, -- 5.100
              pos, g.zeroVector, nil)
end

-- EntityType.ENTITY_URIEL (271)
-- EntityType.ENTITY_GABRIEL (272)
-- We want to manually spawn the key pieces instead of letting the game do it
-- This slightly speeds up the spawn so that they can not be accidently deleted by leaving the room
function PostEntityKill:Entity271(entity)
  -- Local variables
  local roomType = g.r:GetType()

  -- We only want to spawn key pieces from the non-Fallen versions
  if entity.Variant == 1 then
    return
  end

  -- We don't want to drop key pieces from angels in Victory Lap bosses or the Boss Rush
  if roomType ~= RoomType.ROOM_SUPERSECRET and -- 8
     roomType ~= RoomType.ROOM_SACRIFICE and -- 13
     roomType ~= RoomType.ROOM_ANGEL then -- 15

    -- Key pieces dropping from angels in non-Angel Rooms was introduced in Booster Pack #4
    return
  end

  -- We don't want to drop key pieces from angels if the player has the Filigree Feather
  -- (we could spawn a SubType 0 collectible, but then we wouldn't know how to remove the naturally dropped random item)
  if g.p:HasTrinket(TrinketType.TRINKET_FILIGREE_FEATHERS) then -- 123
    return
  end

  -- We don't want to drop a key piece if there is another alive angel in the room
  for _, entity2 in ipairs(Isaac.GetRoomEntities()) do
    local isDead = entity2:IsDead()
    if (entity2.Type == EntityType.ENTITY_URIEL or -- 271
        entity2.Type == EntityType.ENTITY_GABRIEL) and -- 272
        not isDead then

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
  local gridIndex = g.r:GetGridIndex(pos)
  local gridEntity = g.r:GetGridEntity(gridIndex)
  if gridEntity ~= nil then
    pos = g.r:FindFreePickupSpawnPosition(pos, 1, false)
  end

  -- We have to let the "ReplacePedestal()" function know that this is not a natural key piece pedestal
  g.run.spawningKeyPiece = true

  -- Spawn the item (it will get replaced on the next frame in the "RPPedestals:Replace()" function)
  Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, subType, -- 5.100
              pos, g.zeroVector, nil)
end

-- EntityType.ENTITY_ULTRA_GREED (406)
function PostEntityKill:Entity406(entity)
  entity:Remove()
end

function PostEntityKill:RoomClearDelayNPC(entity)
  -- The room clear delay NPC may accidentally die if Lua code kills all NPCs in a room
  -- If this occurs, just spawn a new one
  Isaac.DebugString("Room Clear Delay NPC death detected - spawning a new one.")
  Isaac.Spawn(EntityType.ENTITY_ROOM_CLEAR_DELAY_NPC, 0, 0, g:GridToPos(0, 0), g.zeroVector, nil)
end

-- After killing Mom, Mom's Heart, or It Lives!, all entities in the room are killed
-- However, Nicalis didn't consider that Globins need to be killed twice (to kill their flesh pile forms)
-- Blisters also need to be killed twice (to kill the spawned Sacks)
-- Racing+ manually fixes this bug by expliticly killing them (and removing Fistula and Teratoma)
-- This code is also necessary to fix the issue where a Globin will prevent the
-- removal of the natural trapdoor and beam of light after It Lives!
--- (in the "FastTravel:ReplaceTrapdoor()" and the "FastTravel:ReplaceHeavenDoor()" functions)
function PostEntityKill:KillExtraEnemies()
  Isaac.DebugString("Checking for extra enemies to kill after a Mom / It Lives! fight.")
  for _, entity in ipairs(Isaac.GetRoomEntities()) do
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

return PostEntityKill

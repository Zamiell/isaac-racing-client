local RPNPCUpdate = {}

--
-- Includes
--

local RPGlobals   = require("src/rpglobals")
local RPFastClear = require("src/rpfastclear")

--
-- Functions
--

-- ModCallbacks.MC_NPC_UPDATE (0)
function RPNPCUpdate:Main(npc)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
  local player = game:GetPlayer(0)

  --Isaac.DebugString("MC_NPC_UPDATE - " ..
  --                  tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "." .. tostring(npc.SubType))

  -- Check for specific kinds of NPCs
  if npc.Type == EntityType.ENTITY_GLOBIN then -- 24
    -- Keep track of Globins for softlock prevention
    if RPGlobals.run.currentGlobins[npc.Index] == nil then
      RPGlobals.run.currentGlobins[npc.Index] = {
        npc       = npc,
        lastState = npc.State,
        regens    = 0,
      }
    end

    -- Fix Globin softlocks
    if npc.State == 3 and
       npc.State ~= RPGlobals.run.currentGlobins[npc.Index].lastState then

      -- A globin went down
      RPGlobals.run.currentGlobins[npc.Index].lastState = npc.State
      RPGlobals.run.currentGlobins[npc.Index].regens = RPGlobals.run.currentGlobins[npc.Index].regens + 1
      if RPGlobals.run.currentGlobins[npc.Index].regens >= 5 then
        npc:Kill()
        RPGlobals.run.currentGlobins[npc.Index] = nil
        Isaac.DebugString("Killed Globin #" .. tostring(npc.Index) .. " to prevent a soft-lock.")
      end
    else
      RPGlobals.run.currentGlobins[npc.Index].lastState = npc.State
    end

  elseif npc.Type == EntityType.ENTITY_HOST or -- 27
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

  elseif npc.Type == EntityType.ENTITY_STONEHEAD or -- 42 (Stone Grimace and Vomit Grimace)
         npc.Type == EntityType.ENTITY_CONSTANT_STONE_SHOOTER or -- 202 (left, up, right, and down)
         npc.Type == EntityType.ENTITY_BRIMSTONE_HEAD or -- 203 (left, up, right, and down)
         npc.Type == EntityType.ENTITY_GAPING_MAW or -- 235
         npc.Type == EntityType.ENTITY_BROKEN_GAPING_MAW then -- 236

    -- Fix the bug with fast-clear where the "room:SpawnClearAward()" function will
    -- spawn a pickup inside a Stone Grimace and the like
    -- Check to see if there are any pickups/trinkets overlapping with it
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      if (entity.Type == EntityType.ENTITY_BOMBDROP or -- 4
          entity.Type == EntityType.ENTITY_PICKUP) and -- 5
         RPGlobals:InsideSquare(entity.Position, npc.Position, 15) then

        -- Respawn it in a accessible location
        local newPosition = room:FindFreePickupSpawnPosition(entity.Position, 0, true)
        -- The arguments are Pos, InitialStep, and AvoidActiveEntities
        game:Spawn(entity.Type, entity.Variant, newPosition, entity.Velocity,
                   entity.Parent, entity.SubType, entity.InitSeed)
        entity:Remove()
      end
    end

  elseif npc.Type == EntityType.ENTITY_PIN and npc.Variant == 1 and -- 62.1 (Scolex)
         npc:IsDead() == false and -- This is necessary because the callback will be hit again during the removal
         roomType == RoomType.ROOM_BOSS and -- 5
         RPGlobals.race.rFormat == "seeded" and
         RPGlobals.race.status == "in progress" then

     -- Since Scolex attack patterns ruin seeded races, delete it and replace it with two Frails
     -- There are 10 Scolex entities, so we know we are on the last one if there is no child
     npc:Remove() -- This takes a game frame to actually get removed
     if npc.Child == nil then
       -- Spawn two Frails (62.2)
       for i = 1, 2 do
         -- We don't want to spawn both of them on top of each other since that would make them behave a little glitchy
         local pos = room:GetCenterPos()
         if i == 1 then
           pos.X = pos.X - 200
         elseif i == 2 then
           pos.X = pos.X + 200
         end
         local frail = game:Spawn(EntityType.ENTITY_PIN, 2, pos, Vector(0,0), nil, 0, roomSeed)
         frail.Visible = false -- It will show the head on the first frame after spawning unless we do this
         -- The game will automatically make the entity visible later on
       end
       Isaac.DebugString("Spawned 2 replacement Frails for Scolex with seed: " .. tostring(roomSeed))
     end

   elseif npc.Type == EntityType.ENTITY_PIN and npc.Variant == 1 and -- 62.1 (Scolex)
          npc:GetBossColorIdx() == 15 and -- The bugged black champion type
          npc.GroupIdx == 0 and -- We use the "GroupIdx" variable to keep track of whether we have morphed it yet or not
          npc:IsDead() == false then -- We need to check for this in case Scolex is being replaced in a seeded race

      -- Replace the bugged Scolex champion with the non-champion version
      npc.GroupIdx = 1
      npc:Morph(EntityType.ENTITY_PIN, 1, 0, -1) -- 62.1 (Scolex)
      Isaac.DebugString("Morphed a black champion Scolex on frame: " .. tostring(gameFrameCount))

  elseif ((npc.Type == EntityType.ENTITY_ISAAC and npc.Variant == 1) or -- Blue Baby (102.1)
          (npc.Type == EntityType.ENTITY_THE_LAMB)) and -- 273
         npc:IsDead() == false and -- This is necessary because the callback will be hit again during the removal
         RPGlobals.raceVars.finished and
         npc.FrameCount == 0 then -- This is needed or else it will swap out the boss during the death animation

    -- Replace Blue Baby / The Lamb with some random bosses (based on the number of Victory Laps)
    npc:Remove()
    local randomBossSeed = roomSeed
    local numBosses = RPGlobals.raceVars.victoryLaps + 1
    for i = 1, numBosses do
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
    Isaac.DebugString("Replaced Blue Baby with " .. tostring(numBosses) .. " random bosses.")

  elseif npc.Type == EntityType.ENTITY_MOMS_HAND or-- 213
         npc.Type == EntityType.ENTITY_MOMS_DEAD_HAND then -- 287

    if npc.State == 4 and npc.StateFrame < 25 then
      -- Mom's Hands and Mom's Dead Hands
      -- Speed up their attack patterns
      -- (StateFrame starts between 0 and a random negative value and ticks upwards)
      -- (we have to do a small adjustment because if multiple hands fall at the exact same time,
      -- they can stack on top of each other and cause buggy behavior)
      npc.StateFrame = 25 + RPGlobals.run.handsDelay
      RPGlobals.run.handsDelay = RPGlobals.run.handsDelay + 1
      if RPGlobals.run.handsDelay == 10 then
        RPGlobals.run.handsDelay = 0
      end
    end

  elseif npc.Type == EntityType.ENTITY_WIZOOB or -- 219
         npc.Type == EntityType.ENTITY_RED_GHOST then -- 285

    -- Wizoobs and Red Ghosts
    -- Make it so that tears don't pass through them
    if npc.FrameCount == 0 then -- (most NPCs are only visable on the 4th frame, but these are visible immediately)
      -- The ghost is set to ENTCOLL_NONE until the first reappearance
      npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL -- 4
    end

    -- Speed up their attack pattern
    if npc.State == 3 and npc.StateFrame ~= 0 then -- State 3 is when they are disappeared and doing nothing
      npc.StateFrame = 0 -- StateFrame decrements down from 60 to 0, so just jump ahead
    end

  elseif npc.Type == EntityType.ENTITY_THE_LAMB and
         npc.Variant == 10 and -- Lamb Body (267.10)
         npc:IsInvincible() and -- It only turns invincible once it is defeated
         npc:IsDead() == false then -- This is necessary because the callback will be hit again during the removal

    -- Remove the body once it is defeated so that it does not interfere with taking the trophy
    npc:Kill() -- This plays the blood and guts animation, but does not actually remove the entity
    npc:Remove()

  elseif npc.Type == EntityType.ENTITY_MEGA_SATAN_2 and -- 275
         npc:GetSprite():IsPlaying("Death") and
         RPGlobals.run.megaSatanDead == false then

    -- Stop the room from being cleared, which has a chance to take us back to the menu
    RPGlobals.run.megaSatanDead = true
    game:Spawn(Isaac.GetEntityTypeByName("Room Clear Delay NPC"),
               Isaac.GetEntityVariantByName("Room Clear Delay NPC"),
               RPGlobals:GridToPos(0, 0), Vector(0, 0), nil, 0, 0)
    Isaac.DebugString("Spawned the \"Room Clear Delay NPC\" custom entity (for Mega Satan).")

    -- Give a charge to the player's active item
    if player:NeedsCharge() == true then
      local currentCharge = player:GetActiveCharge()
      player:SetActiveCharge(currentCharge + 1)
    end

    -- Spawn a big chest (which will get replaced with a trophy on the next frame if we happen to be in a race)
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, -- 5.340
               room:GetCenterPos(), Vector(0, 0), nil, 0, 0)

  elseif npc.Type == EntityType.ENTITY_MUSHROOM and -- 300
         npc:IsDead() == false and -- This is necessary because the callback will be hit again during the removal
         stage ~= LevelStage.STAGE2_1 and -- 3 (Caves)
         stage ~= LevelStage.STAGE2_2 then -- 4

    -- Replace Mushrooms with Hosts on non-Caves floors
    -- (Mushrooms are incorrectly coded to be champions of Hosts, so they can appear on all floors)
    -- (to fix the unavoidable damage with Leo / Thunder Thighs when walking over skulls,
    -- more code is needed in the EntityTakeDamage callback)
    game:Spawn(EntityType.ENTITY_HOST, 0, npc.Position, npc.Velocity, npc.Parent, 0, 1) -- 27.0
    -- (presumably the existing InitSeed results in a Mushroom, and an InitSeed of 0 results in a Mushroom,
    -- so we use an InitSeed of 1)
    npc:Remove()
    Isaac.DebugString("Replaced a Mushroom with a Host.")
  end

  -- Do extra monitoring for blue variant bosses that drop extra soul hearts
  -- (should only be Larry Jr., Mom, Famine, and Gemini)
  -- (this algorithm is from blcd, reverse engineered from the game binary)
  -- (Big Horn's hands are not SubType 0, so we have to explicitly filter those out)
  if npc:IsBoss() and npc.SubType ~= 0 and npc.Type ~= EntityType.ENTITY_BIG_HORN then -- 411
    RPGlobals.run.bossHearts.extra = true
  end

  if npc:IsBoss() and
     (npc:GetBossColorIdx() == 3 or npc:GetBossColorIdx() == 6) then -- From blcd

    RPGlobals.run.bossHearts.extraIsSoul = true
  end

  -- Look for enemies that are dying so that we can open the doors prematurely
  RPFastClear:NPCUpdate(npc)
end

return RPNPCUpdate

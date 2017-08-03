local RPNPCUpdate = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")

--
-- Functions
--

-- ModCallbacks.MC_NPC_UPDATE (0)
function RPNPCUpdate:Main(npc)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()

  --[[
  Isaac.DebugString("MC_NPC_UPDATE - " ..
                    tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "." .. tostring(npc.SubType))
  --]]

  -- Do extra monitoring for blue variant bosses that drop extra soul hearts
  -- (should only be Larry Jr., Mom, Famine, and Gemini)
  -- (this algorithm is from blcd, reverse engineered from the game binary)
  -- (Big Horn's hands are not SubType 0, so we have to explicitly filter those out)
  if roomType == RoomType.ROOM_BOSS and -- 5
     npc:IsBoss() then

    if npc.SubType ~= 0 and npc.Type ~= EntityType.ENTITY_BIG_HORN then -- 411
      RPGlobals.run.bossHearts.extra = true
    end

    if npc:GetBossColorIdx() == 3 or npc:GetBossColorIdx() == 6 then -- From blcd
      RPGlobals.run.bossHearts.extraIsSoul = true
    end
  end
end

-- EntityType.ENTITY_GLOBIN (24)
function RPNPCUpdate:NPC24(npc)
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
end

-- EntityType.ENTITY_HOST (27)
-- EntityType.ENTITY_MOBILE_HOST (204)
function RPNPCUpdate:NPC27(npc)
  -- Hosts and Mobile Hosts
  -- Find out if they are feared
  local entityFlags = npc:GetEntityFlags()
  local feared = false
  local i = 11 -- EntityFlag.FLAG_FEAR
  local bit = (entityFlags & (1 << i)) >> i
  if bit == 1 then
    feared = true
  end
  if feared then
    -- Make them immune to fear
    npc:RemoveStatusEffects()
    Isaac.DebugString("Unfeared a Host / Mobile Host.")
    RPGlobals.run.levelDamaged = true
  end
end

-- EntityType.ENTITY_STONEHEAD (42; Stone Grimace and Vomit Grimace)
-- EntityType.ENTITY_CONSTANT_STONE_SHOOTER (202; left, up, right, and down)
-- EntityType.ENTITY_BRIMSTONE_HEAD (203; left, up, right, and down)
-- EntityType.ENTITY_GAPING_MAW (235)
-- EntityType.ENTITY_BROKEN_GAPING_MAW (236)
function RPNPCUpdate:NPC42(npc)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()

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
end

-- EntityType.ENTITY_MOMS_HAND (213)
-- EntityType.ENTITY_MOMS_DEAD_HAND (287)
function RPNPCUpdate:NPC213(npc)
  -- Disable the speed-up on the "Unseeded (Lite)" ruleset
  if RPGlobals.race.rFormat == "unseeded-lite" then
    return
  end

  -- Mom's Hands and Mom's Dead Hands
  if npc.State == 4 and npc.StateFrame < 25 then
    -- Speed up their attack patterns
    -- (StateFrame starts between 0 and a random negative value and ticks upwards)
    -- (we have to do a small adjustment because if multiple hands fall at the exact same time,
    -- they can stack on top of each other and cause buggy behavior)
    npc.StateFrame = 25 + RPGlobals.run.handsDelay
    RPGlobals.run.handsDelay = RPGlobals.run.handsDelay + 3
    if RPGlobals.run.handsDelay == 10 then
      RPGlobals.run.handsDelay = 0
    end
  end
end

-- EntityType.ENTITY_WIZOOB (219)
-- EntityType.ENTITY_RED_GHOST (285)
function RPNPCUpdate:NPC219(npc)
  -- Wizoobs and Red Ghosts
  -- Make it so that tears don't pass through them
  if npc.FrameCount == 0 then -- (most NPCs are only visable on the 4th frame, but these are visible immediately)
    -- The ghost is set to ENTCOLL_NONE until the first reappearance
    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL -- 4
  end

  -- Disable the speed-up on the "Unseeded (Lite)" ruleset
  if RPGlobals.race.rFormat == "unseeded-lite" then
    return
  end

  -- Speed up their attack pattern
  if npc.State == 3 and npc.StateFrame ~= 0 then -- State 3 is when they are disappeared and doing nothing
    npc.StateFrame = 0 -- StateFrame decrements down from 60 to 0, so just jump ahead
  end
end

-- EntityType.ENTITY_THE_LAMB (273)
function RPNPCUpdate:NPC273(npc)
  if npc.Variant == 0 then -- The Lamb (273.0)
    -- The spinning brimstone attack can persist during the period where The Lamb starts moving,
    -- which can be unavoidable damage, so delete the brimstones
    local brimstoneFiring = false
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      if entity.Type == EntityType.ENTITY_LASER and -- 7
         entity.Parent.Type == EntityType.ENTITY_THE_LAMB then -- 273

        brimstoneFiring = true
        break
      end
    end

    if brimstoneFiring then
      if RPGlobals.run.theLambLockedPos == nil and
         npc.State == 4 then -- The state where he is slowly moving around and not doing any attack

        RPGlobals.run.theLambLockedPos = npc.Position
        Isaac.DebugString("Locked The Lamb to prevent unavoidable damage.")
      end

    else
      if RPGlobals.run.theLambLockedPos ~= nil then
        RPGlobals.run.theLambLockedPos = nil
        Isaac.DebugString("Unlocked The Lamb now that all of the brimstones are gone.")
      end
    end

    -- Lock him in place on every frame until the brimstones go away
    if RPGlobals.run.theLambLockedPos ~= nil then
      npc.Position = RPGlobals.run.theLambLockedPos
    end

  elseif npc.Variant == 10 and -- Lamb Body (273.10)
         npc:IsInvincible() and -- It only turns invincible once it is defeated
         npc:IsDead() == false then -- This is necessary because the callback will be hit again during the removal

    -- Remove the body once it is defeated so that it does not interfere with taking the trophy
    npc:Kill() -- This plays the blood and guts animation, but does not actually remove the entity
    npc:Remove()
  end
end

-- EntityType.ENTITY_MEGA_SATAN_2 (275)
function RPNPCUpdate:NPC275(npc)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)

  if RPGlobals.run.megaSatanDead == false and
     npc:GetSprite():IsPlaying("Death") then

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
  end
end

-- EntityType.ENTITY_MUSHROOM (300)
function RPNPCUpdate:NPC300(npc)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()

  if npc:IsDead() == false and -- This is necessary because the callback will be hit again during the removal
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
end

return RPNPCUpdate

local RPNPCUpdate = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")

--
-- Functions
--

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
    if RPNPCUpdate:IsValidPickupForMove(entity, npc) then
      -- Respawn it in a accessible location
      local newPosition = room:FindFreePickupSpawnPosition(entity.Position, 0, true)
      -- The arguments are Pos, InitialStep, and AvoidActiveEntities
      game:Spawn(entity.Type, entity.Variant, newPosition, entity.Velocity,
                 entity.Parent, entity.SubType, entity.InitSeed)
      entity:Remove()
      Isaac.DebugString("Repositioned a pickup that was overlapping with a stationary stone entity.")
    end
  end
end

function RPNPCUpdate:IsValidPickupForMove(entity, npc)
  local pickup = entity:ToPickup()
  if pickup == nil then
    return false
  end

  if not RPGlobals:InsideSquare(pickup.Position, npc.Position, 15) then
    return false
  end

  -- Don't move pickups that are already touched and are in the process of disappearing
  -- (the "Touched" property is set in the "RPCheckEntities:Entity5()" function)
  if pickup.Touched then
    return false
  end

  -- Don't move chests that are already opened
  if entity.Variant <= PickupVariant.PICKUP_CHEST and -- 50
     entity.Variant >= PickupVariant.PICKUP_LOCKEDCHEST and -- 60
     entity.SubType == 0 then

    -- A Subtype of 0 indicates that it is already opened
    return false
  end

  return true
end

-- EntityType.ENTITY_FLAMINGHOPPER (54)
function RPNPCUpdate:NPC54(npc)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  -- Prevent Flaming Hopper softlocks
  if RPGlobals.run.currentHoppers[npc.Index] == nil then
    RPGlobals.run.currentHoppers[npc.Index] = {
      npc           = npc,
      posX          = npc.Position.X,
      posY          = npc.Position.Y,
      lastMoveFrame = gameFrameCount,
    }
  end

  -- Find out if it moved
  if RPGlobals.run.currentHoppers[npc.Index].posX ~= npc.Position.X or
     RPGlobals.run.currentHoppers[npc.Index].posY ~= npc.Position.Y then

    -- Update the position
    RPGlobals.run.currentHoppers[npc.Index].posX = npc.Position.X
    RPGlobals.run.currentHoppers[npc.Index].posY = npc.Position.Y
    RPGlobals.run.currentHoppers[npc.Index].lastMoveFrame = gameFrameCount
    return
  end

  -- It hasn't moved since the last time we checked
  if gameFrameCount - RPGlobals.run.currentHoppers[npc.Index].lastMoveFrame >= 150 then -- 5 seconds
    npc:Kill()
    Isaac.DebugString("Hopper " .. tostring(npc.Index) .. " softlock detected; killing it.")
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

-- EntityType.ENTITY_DINGLE (261)
function RPNPCUpdate:NPC261(npc)
  -- We only care about Dangles that are freshly spawned
  if npc.Variant == 1 and npc.State == NpcState.STATE_INIT then -- 0
    -- Fix the bug where a Dangle spawned from a Brownie will be faded
    local faded = Color(1, 1, 1, 1, 0, 0, 0)
    npc:SetColor(faded, 1000, 0, true, true) -- KColor, Duration, Priority, Fadeout, Share
  end
end

-- EntityType.ENTITY_THE_LAMB (273)
function RPNPCUpdate:NPC273(npc)
 if npc.Variant == 10 and -- Lamb Body (273.10)
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

    -- Set the room status to clear so that the player cannot fight Mega Satan a second time
    -- if they happen to use a Fool card after defeating it
    room:SetClear(true)
  end
end

-- EntityType.ENTITY_BIG_HORN (411)
function RPNPCUpdate:NPC411(npc)
  -- Speed up coming out of the ground
  if npc.State == NpcState.STATE_MOVE and -- 4
     npc.StateFrame >= 67 and
     npc.StateFrame < 100 then

    npc.StateFrame = 100
  end
end

return RPNPCUpdate

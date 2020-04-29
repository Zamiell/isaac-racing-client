local NPCUpdate = {}

-- Note: This callback only fires on frame 1 and onwards

-- Includes
local g         = require("racing_plus/globals")
local FastClear = require("racing_plus/fastclear")

-- ModCallbacks.MC_NPC_UPDATE (0)
function NPCUpdate:Main(npc)
  -- Check for dying enemies so that we can fix the bug where multi-segment enemies drop multiple black hearts
  -- We need to track enemy positions as a workaround because black hearts will not have a Parent or SpawnerEntity
  if npc:IsDead() then
    if g.run.blackHeartNPCs[npc.Index] == nil then
      -- An enemy has died for the first time (and begun its death animation on this frame)
      -- Make an entry in the blackHeartNPCs table
      g.run.blackHeartNPCs[npc.Index] = {
        initSeed = npc.InitSeed,
        position = Vector(npc.Position.X, npc.Position.Y),
      }
    end
  end

  -- Track all NPCs for the purposes of opening the doors early
  FastClear:NPCUpdate(npc)
end

-- EntityType.ENTITY_GLOBIN (24)
function NPCUpdate:NPC24(npc)
  -- Keep track of Globins for softlock prevention
  if g.run.currentGlobins[npc.Index] == nil then
    g.run.currentGlobins[npc.Index] = {
      npc       = npc,
      lastState = npc.State,
      regens    = 0,
    }
  end

  -- Fix Globin softlocks
  if npc.State == 3 and
     npc.State ~= g.run.currentGlobins[npc.Index].lastState then

    -- A globin went down
    g.run.currentGlobins[npc.Index].lastState = npc.State
    g.run.currentGlobins[npc.Index].regens = g.run.currentGlobins[npc.Index].regens + 1
    if g.run.currentGlobins[npc.Index].regens >= 5 then
      npc:Kill()
      g.run.currentGlobins[npc.Index] = nil
      Isaac.DebugString("Killed Globin #" .. tostring(npc.Index) .. " to prevent a soft-lock.")
    end
  else
    g.run.currentGlobins[npc.Index].lastState = npc.State
  end
end

-- EntityType.ENTITY_CHUB (28)
function NPCUpdate:NPC28(npc)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()

  -- We only care about Chubs spawned from The Matriarch
  if not g.run.matriarch.spawned then
    return
  end

  -- When Matriarch is killed, it will morph into a Chub (and the MC_POST_ENTITY_KILL will never fire)
  -- When this happens, the other segments of Chub will spawn (it is a multi-segment entity)
  -- The new segments will start at frame 0, but the main segment will retain the FrameCount of the Matriarch entity
  -- We want to find the index of the main Chub so that we can stun it
  if g.run.matriarch.chubIndex == -1 and
     npc.FrameCount > 30 then
     -- This can be any value higher than 1, since the new segments will first appear here on frame 1,
     -- but use 30 frames to be safe

    g.run.matriarch.chubIndex = npc.Index
    g.run.matriarch.stunFrame = gameFrameCount + 1

    -- The Matriarch has died, so also nerf the fight slightly by killing everything in the room
    -- to clear things up a little bit
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
      if entity:ToNPC() ~= nil and
         entity.Type ~= EntityType.ENTITY_CHUB and -- 28
         entity.Type ~= EntityType.ENTITY_ROOM_CLEAR_DELAY_NPC and
         entity.Type ~= EntityType.ENTITY_SAMAEL_SCYTHE then

        entity:Kill()
      end
    end
  end

  -- Stun (slow down) the Chub that spawns from The Matriarch
  if npc.Index == g.run.matriarch.chubIndex and
     gameFrameCount <= g.run.matriarch.stunFrame then

    npc.State = NpcState.STATE_UNIQUE_DEATH -- 16
    -- (the state after he eats a bomb)
    g.sfx:Stop(SoundEffect.SOUND_MONSTER_ROAR_2) -- 117
    Isaac.DebugString("Manually slowed a Chub coming from a Matriarch.")
  end
end

-- EntityType.ENTITY_FLAMINGHOPPER (54)
function NPCUpdate:NPC54(npc)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()

  -- Prevent Flaming Hopper softlocks
  if g.run.currentHoppers[npc.Index] == nil then
    g.run.currentHoppers[npc.Index] = {
      npc           = npc,
      posX          = npc.Position.X,
      posY          = npc.Position.Y,
      lastMoveFrame = gameFrameCount,
    }
  end

  -- Find out if it moved
  if g.run.currentHoppers[npc.Index].posX ~= npc.Position.X or
     g.run.currentHoppers[npc.Index].posY ~= npc.Position.Y then

    -- Update the position
    g.run.currentHoppers[npc.Index].posX = npc.Position.X
    g.run.currentHoppers[npc.Index].posY = npc.Position.Y
    g.run.currentHoppers[npc.Index].lastMoveFrame = gameFrameCount
    return
  end

  -- It hasn't moved since the last time we checked
  if gameFrameCount - g.run.currentHoppers[npc.Index].lastMoveFrame >= 150 then -- 5 seconds
    npc:Kill()
    Isaac.DebugString("Hopper " .. tostring(npc.Index) .. " softlock detected; killing it.")
  end
end

-- EntityType.ENTITY_PIN (62)
function NPCUpdate:NPC62(npc)
  -- We only care about the head
  if npc.Parent ~= nil then
    return
  end

  -- Don't do anything if there is more than one Pin in the room
  local pins = Isaac.FindByType(EntityType.ENTITY_PIN, -1, -1, false, false) -- 62
  local numPins = 0
  for _, pin in ipairs(pins) do
    if pin.Parent == nil then
      numPins = numPins + 1
    end
  end
  if numPins > 1 then
    return
  end

  -- Local variables
  local roomShape = g.r:GetRoomShape()

  -- Normally, Pin/Frail/Scolex first attacks on frame 73, so speed this up
  if npc.FrameCount == 30 then
    -- Changing the state to 3 will cause it to leap at the player on the next frame
    npc.State = 3
  elseif npc.FrameCount == 31 then
    -- We also need to adjust the "charge" velocity, or else the first attack will be really wimpy
    if g.l.EnterDoor == DoorSlot.UP0 or -- 1
       g.l.EnterDoor == DoorSlot.DOWN0 then -- 3

      -- From the bottom/top door, the vanilla V1 velocity (on frame 74) is 6.08
      -- From the bottom/top door, the frame 31 V1 velocity is 3.69
      npc.V1 = npc.V1 * 1.65

    else
      -- From the left/right door, the vanilla V1 velocity (on frame 74) is 6.92
      -- From the left/right door, the frame 16 V1 velocity is 2.13
      npc.V1 = npc.V1 * 3.25
    end
    while math.abs(npc.V1.X) > 7 or
          math.abs(npc.V1.Y) > 7 do

      npc.V1 = npc.V1 * 0.9
    end
    if roomShape > 3 then -- 1-3 are 1x1 room types
      npc.Velocity = npc.Velocity * -1
    end
  end
end

-- EntityType.ENTITY_DEATH (66)
function NPCUpdate:NPC66(npc)
  -- We only care about the main Death
  if npc.Variant ~= 0 then
    return
  end

  -- Stop Death from performing his slow attack
  if npc.State == NpcState.STATE_ATTACK then -- 8
    npc.State = NpcState.STATE_MOVE -- 4
  end
end

-- EntityType.ENTITY_DINGLE (261)
function NPCUpdate:NPC261(npc)
  -- We only care about Dangles that are freshly spawned
  if npc.Variant == 1 and
     npc.State == NpcState.STATE_INIT then -- 0

    -- Fix the bug where a Dangle spawned from a Brownie will be faded
    npc:SetColor(g.color, 1000, 0, true, true) -- KColor, Duration, Priority, Fadeout, Share
  end
end

-- EntityType.ENTITY_THE_LAMB (273)
function NPCUpdate:NPC273(npc)
 if npc.Variant == 10 and -- Lamb Body (273.10)
    npc:IsInvincible() and -- It only turns invincible once it is defeated
    not npc:IsDead() then -- This is necessary because the callback will be hit again during the removal

    -- Remove the body once it is defeated so that it does not interfere with taking the trophy
    npc:Kill() -- This plays the blood and guts animation, but does not actually remove the entity
    npc:Remove()
  end
end

-- EntityType.ENTITY_MEGA_SATAN_2 (275)
function NPCUpdate:NPC275(npc)
  if not g.run.megaSatanDead and
     npc:GetSprite():IsPlaying("Death") then

    -- Stop the room from being cleared, which has a chance to take us back to the menu
    g.run.megaSatanDead = true
    local roomClearDelayNPC = Isaac.Spawn(EntityType.ENTITY_ROOM_CLEAR_DELAY_NPC, 0, 0,
                                          g:GridToPos(0, 0), g.zeroVector, nil)
    roomClearDelayNPC:ClearEntityFlags(EntityFlag.FLAG_APPEAR) -- 1 << 2
    Isaac.DebugString("Spawned the \"Room Clear Delay NPC\" custom entity (for Mega Satan).")

    -- Give a charge to the player's active item
    if g.p:NeedsCharge() == true then
      local currentCharge = g.p:GetActiveCharge()
      g.p:SetActiveCharge(currentCharge + 1)
    end

    -- Spawn a big chest (which will get replaced with a trophy if we happen to be in a race)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, 0, -- 5.340
                g.r:GetCenterPos(), g.zeroVector, nil)

    -- Set the room status to clear so that the player cannot fight Mega Satan a second time
    -- if they happen to use a Fool card after defeating it
    g.r:SetClear(true)
  end
end

-- EntityType.ENTITY_ULTRA_GREED (406)
function NPCUpdate:NPC406(npc)
  if npc.State == NpcState.STATE_APPEAR_CUSTOM then -- 2
    npc.State = 3
    Isaac.DebugString("Sped up the appear animation of Ultra Greed.")
  end
end

-- EntityType.ENTITY_BIG_HORN (411)
function NPCUpdate:NPC411(npc)
  -- Speed up coming out of the ground
  if npc.State == NpcState.STATE_MOVE and -- 4
     npc.StateFrame >= 67 and
     npc.StateFrame < 100 then

    npc.StateFrame = 100
  end
end

-- EntityType.ENTITY_MATRIARCH (413)
function NPCUpdate:NPC413(npc)
  -- Mark that we are fighting a Matriarch so that we can slow down the Chub later
  g.run.matriarch.spawned = true
end

-- EntityType.ENTITY_HOST (27)
-- EntityType.ENTITY_MOBILE_HOST (204)
-- EntityType.ENTITY_FORSAKEN (403)
function NPCUpdate:FearImmunity(npc)
  if npc:HasEntityFlags(EntityFlag.FLAG_FEAR) then -- 1 << 11
    -- We can't use "npc:ClearEntityFlags(EntityFlag.FLAG_FEAR)" because it will not remove the color change
    npc:RemoveStatusEffects()
    Isaac.DebugString("Unfeared a Host / Mobile Host / Forsaken.")
  end
end

-- EntityType.ENTITY_BLASTOCYST_BIG (74)
-- EntityType.ENTITY_BLASTOCYST_MEDIUM (75)
-- EntityType.ENTITY_BLASTOCYST_SMALL (76)
function NPCUpdate:FreezeImmunity(npc)
  if npc:HasEntityFlags(EntityFlag.FLAG_FREEZE) then -- 1 << 5
    -- We can't use "npc:ClearEntityFlags(EntityFlag.FLAG_FREEZE)" because it will not remove the color change
    npc:RemoveStatusEffects()
    Isaac.DebugString("Unfreezed a Blastocyst.")
  end
end

-- EntityType.ENTITY_MOMS_HAND (213)
-- EntityType.ENTITY_MOMS_DEAD_HAND (287)
function NPCUpdate:SpeedupHand(npc)
  if npc.FrameCount == 1 then
    -- Play a custom "Appear" animation
    local sprite = npc:GetSprite()
    if not sprite:IsPlaying("Appear") then
      npc.Position = g.run.handPositions[npc.Index]
      sprite:Play("Appear", true)
    end
  end

  if npc.State == 4 and npc.StateFrame < 25 then
    -- Speed up their attack patterns
    -- (StateFrame starts between 0 and a random negative value and ticks upwards)
    -- (we have to do a small adjustment because if multiple hands fall at the exact same time,
    -- they can stack on top of each other and cause buggy behavior)
    npc.StateFrame = 25 + g.run.handsDelay
    g.run.handsDelay = g.run.handsDelay + 3
    if g.run.handsDelay == 10 then
      g.run.handsDelay = 0
    end
  end
end

-- EntityType.ENTITY_WIZOOB (219)
-- EntityType.ENTITY_RED_GHOST (285)
function NPCUpdate:SpeedupGhost(npc)
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
end

return NPCUpdate

local RPPostNPCInit = {}

--
-- Includes
--

local RPFastClear = require("src/rpfastclear")

-- ModCallbacks.MC_POST_NPC_INIT (27)
function RPPostNPCInit:Main(npc)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local index = GetPtrHash(npc)

  Isaac.DebugString("MC_POST_NPC_INIT - " ..
                    tostring(npc.Type) .. "." .. tostring(npc.Variant) .. "." ..
                    tostring(npc.SubType) .. "." .. tostring(npc.State) .. ", " ..
                    "index " .. tostring(index) .. ", " ..
                    "frame " .. tostring(gameFrameCount))

  -- Remove invulnerability frames from Lil' Haunts (1/2) and
  -- speed up the first Lil' Haunt attached to a Haunt (2/3)
  if npc.Type == EntityType.ENTITY_THE_HAUNT and npc.Variant == 10 then -- Lil' Haunt (260.10)
    -- Change it from NpcState.STATE_INIT (0) to NpcState.STATE_IDLE (3)
    -- For Lil' Haunts not attached to a Haunt, this will cause them to naturally transition to NpcState.STATE_MOVE (4)
    -- on the next frame, which is the normal "chasing" attack state
    -- (eith this method, we don't have to manually mess with the NPC's EntityCollisionClass or visibility)
    -- For Lil' Haunts attached to a Haunt, we still have to manually set them to NpcState.STATE_MOVE (4), but
    -- it produces cleaner results when you go from 3 to 4 rather than from 0 to 4
    npc.State = NpcState.STATE_IDLE -- 3
    Isaac.DebugString("Manually set a Lil' Haunt to an idle state (3) on frame: " .. tostring(gameFrameCount))

    -- Keeping Lil' Haunts in place is next handled in the "RPCheckEntities:Entity260()" function
    -- Speeding up the first Lil' Haunt is next handled in the ???
  end

  RPFastClear:CheckNewNPC(npc)
end

return RPPostNPCInit

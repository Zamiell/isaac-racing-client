local PreNPCUpdate = {}

-- Includes
local g = require("racing_plus/globals")

-- EntityType.ENTITY_MOMS_HAND (213)
-- EntityType.ENTITY_MOMS_DEAD_HAND (287)
function PreNPCUpdate:NPC213(npc)
  if g.run.handPositions[npc.Index] == nil then
    g.run.handPositions[npc.Index] = Vector(npc.Position.X, npc.Position.Y)
  end
  if npc:GetSprite():IsPlaying("Appear") then
    return true
  end
end

return PreNPCUpdate

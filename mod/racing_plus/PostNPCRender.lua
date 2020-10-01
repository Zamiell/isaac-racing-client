local PostNPCRender = {}

-- Includes
local g = require("racing_plus/globals")

-- EntityType.ENTITY_PITFALL (291)
function PostNPCRender:Pitfall(npc, offset)
  -- Disable this feature in Boss Rooms (since Big Horn can spawn Pitfalls)
  local roomType = g.r:GetType()
  if roomType == RoomType.ROOM_BOSS then -- 5
    return
  end

  local sprite = npc:GetSprite()
  if (
    sprite:IsPlaying("Disappear")
    and sprite.PlaybackSpeed == 1
  ) then
    sprite.PlaybackSpeed = 3
  end
end

return PostNPCRender

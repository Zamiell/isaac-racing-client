local PostNPCRender = {}

-- EntityType.ENTITY_PITFALL (291)
function PostNPCRender:NPC291(npc, offset)
  local sprite = npc:GetSprite()
  if sprite:IsPlaying("Disappear") and
     sprite.PlaybackSpeed == 1 then

    sprite.PlaybackSpeed = 3
  end

end

return PostNPCRender

local RPPreEntitySpawn = {}

-- ModCallbacks.MC_PRE_ENTITY_SPAWN (24)
-- Heart drops from fires in Devil Deals should never spawn
function RPPreEntitySpawn:Main(type, variant, subType, position, velocity, spawner, seed)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()

  -- We only care about hearts
  if type ~= EntityType.ENTITY_PICKUP or -- 5
     variant ~= PickupVariant.PICKUP_HEART then -- 10

    return
  end

  -- We only care about Devil Rooms
  if roomType ~= RoomType.ROOM_DEVIL then -- 14
    return
  end

  -- We only care about hearts from fires
  if spawner.Type ~= EntityType.ENTITY_FIREPLACE then -- 33
    return
  end

  Isaac.DebugString("Deleting a heart from a fire in a Devil Room.")
  -- If we return an entity type of 0, the game will crash
  -- Instead, return SpiderMod text with a variant of 0, which will just be a non-interacting invisible thing
  return {EntityType.ENTITY_TEXT, 0, 0, 0} -- 9001
end

return RPPreEntitySpawn

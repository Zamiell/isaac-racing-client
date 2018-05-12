local RPPreEntitySpawn = {}

-- ModCallbacks.MC_PRE_ENTITY_SPAWN (24)
-- Heart drops from fires in Devil Deals should never spawn
function RPPreEntitySpawn:Main(type, variant, subType, position, velocity, spawner, seed)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()

  -- We only care about hearts in Devil Rooms that spawned from fires
  if type ~= EntityType.ENTITY_PICKUP or -- 5
     variant ~= PickupVariant.PICKUP_HEART or -- 10
     roomType ~= RoomType.ROOM_DEVIL or -- 14
     spawner == nil or
     spawner.Type ~= EntityType.ENTITY_FIREPLACE then -- 33

    return
  end

  Isaac.DebugString("Deleting a heart from a fire in a Devil Room.")
  -- If we return an entity type of 0, the game will crash
  -- Instead, return an effect with a variant of 0, which will just be a non-interacting invisible thing
  return {EntityType.ENTITY_EFFECT, 0, 0, 0} -- 1000
end

return RPPreEntitySpawn

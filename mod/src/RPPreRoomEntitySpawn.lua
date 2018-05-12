local RPPreRoomEntitySpawn = {}

-- ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN (71)
-- We want the player to always be able to take an item in the Basement 1 Treasure Room without spending a bomb
-- or being forced to walk on spikes
function RPPreRoomEntitySpawn:Main(type, variant, subType, gridIndex, seed)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local roomDesc = level:GetCurrentRoomDesc()
  local roomVariant = roomDesc.Data.Variant
  local room = game:GetRoom()
  local roomType = room:GetType()

  if stage ~= 1 then
    return
  end

  if roomType ~= RoomType.ROOM_TREASURE then -- 4
    return
  end

  if roomVariant == 12 then
    -- Item surrounded by 3 rocks and 1 spike
    local rocks = {66, 68, 82}
    for i, rockIndex in ipairs(rocks) do
      if rockIndex == gridIndex then
        return {1930, 0} -- Spikes
      end
    end

  elseif roomVariant == 19 then
    -- Left item surrounded by rocks
    local rocksReplaced = {49, 63, 65, 79}
    for i, rockIndex in ipairs(rocksReplaced) do
      if rockIndex == gridIndex then
        return {1930, 0} -- Spikes
      end
    end
    local rocksDeleted = {20, 47, 48, 62, 77, 78, 82, 95, 109}
    for i, rockIndex in ipairs(rocksDeleted) do
      if rockIndex == gridIndex then
        return {999, 0} -- Equal to 1000.0, which is a blank effect, which is essentially nothing
      end
    end

  elseif roomVariant == 21 then
    -- Left item surrounded by spikes
    local spikes = {48, 50, 78, 80}
    for i, spikeIndex in ipairs(spikes) do
      if spikeIndex == gridIndex then
        return {999, 0} -- Equal to 1000.0, which is a blank effect, which is essentially nothing
      end
    end

  elseif roomVariant == 22 then
    -- Left item surrounded by pots/mushrooms/skulls
    local pots = {49, 63, 65, 79}
    for i, potIndex in ipairs(pots) do
      if potIndex == gridIndex then
        return {1930, 0} -- Spikes
      end
    end
  end
end

return RPPreRoomEntitySpawn

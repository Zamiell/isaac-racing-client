local PreRoomEntitySpawn = {}

-- Includes
local g           = require("racing_plus/globals")
local SeededRooms = require("racing_plus/seededrooms")

-- ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN (71)
-- We want the player to always be able to take an item in the Basement 1 Treasure Room without spending a bomb
-- or being forced to walk on spikes
function PreRoomEntitySpawn:Main(type, variant, subType, gridIndex, seed)
  local newTable
  newTable = PreRoomEntitySpawn:Basement1EasyItems(gridIndex)
  if newTable ~= nil then
    return newTable
  end
  newTable = SeededRooms:PreEntitySpawn(type, variant, subType, seed)
  if newTable ~= nil then
    return newTable
  end
end

function PreRoomEntitySpawn:Basement1EasyItems(gridIndex)
  -- Local variables
  local stage = g.l:GetStage()
  local roomDesc = g.l:GetCurrentRoomDesc()
  local roomVariant = roomDesc.Data.Variant
  local roomType = g.r:GetType()
  local roomFrameCount = g.r:GetFrameCount()

  -- We only care about replacing things when the room is first loading
  if roomFrameCount ~= -1 then
    return
  end

  if stage ~= 1 then
    return
  end

  if roomType ~= RoomType.ROOM_TREASURE then -- 4
    return
  end

  if roomVariant == 12 then
    -- Item surrounded by 3 rocks and 1 spike
    local rocks = {66, 68, 82}
    for _, rockIndex in ipairs(rocks) do
      if rockIndex == gridIndex then
        return {1930, 0, 0} -- Spikes
      end
    end

  elseif roomVariant == 19 then
    -- Left item surrounded by rocks
    local rocksReplaced = {49, 63, 65, 79}
    for _, rockIndex in ipairs(rocksReplaced) do
      if rockIndex == gridIndex then
        return {1930, 0, 0} -- Spikes
      end
    end
    local rocksDeleted = {20, 47, 48, 62, 77, 78, 82, 95, 109}
    for _, rockIndex in ipairs(rocksDeleted) do
      if rockIndex == gridIndex then
        return {999, 0, 0} -- Equal to 1000.0, which is a blank effect, which is essentially nothing
      end
    end

  elseif roomVariant == 21 then
    -- Left item surrounded by spikes
    local spikes = {48, 50, 78, 80}
    for _, spikeIndex in ipairs(spikes) do
      if spikeIndex == gridIndex then
        return {999, 0, 0} -- Equal to 1000.0, which is a blank effect, which is essentially nothing
      end
    end

  elseif roomVariant == 22 then
    -- Left item surrounded by pots/mushrooms/skulls
    local pots = {49, 63, 65, 79}
    for _, potIndex in ipairs(pots) do
      if potIndex == gridIndex then
        return {1930, 0, 0} -- Spikes
      end
    end
  end
end

return PreRoomEntitySpawn

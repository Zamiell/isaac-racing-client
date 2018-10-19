local RPCheckLoop = {}

-- Includes
local RPShapes = require("src/rpshapes")

-- Reseed the floor if there is a loop
function RPCheckLoop:Main()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local startingRoomIndex = level:GetStartingRoomIndex()
  local rooms = level:GetRooms()

  if stage == LevelStage.STAGE1_1 or -- 1 (Basement 1)
     stage == LevelStage.STAGE4_3 or -- 9 (Blue Womb)
     stage == LevelStage.STAGE7 then -- 12 (The Void)

    -- It is probably not possible to have a loop in Basement 1,
    -- so don't bother checking to make resetting faster on potato computers
    -- There are no loops in the Blue Womb
    -- Don't bother checking for loops in The Void, as the mixing of the floors makes it more complex to detect a loop
    return
  end

  -- Make an empty 13x13 grid and initialize all elements to the value that represents an obstacle
  -- The game uses a 0-indexed grid, but we will use a 1-indexed grid
  local grid = {}
  for i = 1, 13 do
    grid[i] = {}
    for j = 1, 13 do
      grid[i][j] = -1
    end
  end

  -- Get the floor string, i.e. "F1_1"
  -- (this is the index for the RPShapes table)
  local floorNum
  if stage == 1 or stage == 2 then
    floorNum = 1
  elseif stage == 3 or stage == 4 then
    floorNum = 2
  elseif stage == 5 or stage == 6 then
    floorNum = 3
  elseif stage == 7 or stage == 8 then
    floorNum = 4
  elseif stage == 10 then
    floorNum = 5
  elseif stage == 11 then
    floorNum = 6
  end
  local floorString = "F" .. tostring(floorNum) .. "_" .. tostring(stageType)

  -- Also, keep track of basic information about each room
  local roomsData = {}

  -- Make an entry for each room on the floor
  -- (to both the grid and the roomData)
  local startingRoomNum
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local roomDesc = rooms:Get(i)
    local roomIndex = roomDesc.SafeGridIndex -- This is always the top-left index
    local roomData = roomDesc.Data
    local roomType = roomData.Type

    -- There will never be a special room in a loop, so we can ignore them to save CPU cycles
    -- Furthermore, we don't want to account for the Secret Room / moon strats
    if roomType == RoomType.ROOM_DEFAULT then -- 5
      local roomDataVariant = roomData.Variant
      while roomDataVariant >= 10000 do
        -- The 3 flipped versions of room #1 would be #10001, #20001, and #30001
        roomDataVariant = roomDataVariant - 10000
      end

      -- Get the room shape from the STB XMLs
      local roomShape
      if roomIndex == startingRoomIndex then
        -- Keep track of the starting room for later
        startingRoomNum = i

        -- The starting room is in "00.special rooms.stb", so it may not be in the RPShapes table
        -- So, manually assign it the correct shape
        roomShape = RoomShape.ROOMSHAPE_1x1 -- 1
      else
        roomShape = RPShapes[floorString][roomDataVariant]
      end

      -- If Racing+ flipped an L room, the shape of the room will also change, so account for this
      if roomData.Variant >= 30000 then
        -- Flipped X + Y
        if roomShape == RoomShape.ROOMSHAPE_LTL then -- 9 (L room, top-left is missing)
          roomShape = RoomShape.ROOMSHAPE_LBR -- 12 (L room, bottom-right is missing)
        elseif roomShape == RoomShape.ROOMSHAPE_LTR then -- 10 (L room, top-right is missing)
          roomShape = RoomShape.ROOMSHAPE_LBL -- 11 (L room, bottom-left is missing)
        elseif roomShape == RoomShape.ROOMSHAPE_LBL then -- 11 (L room, bottom-left is missing)
          roomShape = RoomShape.ROOMSHAPE_LTR -- 10 (L room, top-right is missing)
        elseif roomShape == RoomShape.ROOMSHAPE_LBR then -- 12 (L room, bottom-right is missing)
          roomShape = RoomShape.ROOMSHAPE_LTL -- 9 (L room, top-left is missing)
        end

      elseif roomData.Variant >= 20000 then
        -- Flipped Y
        if roomShape == RoomShape.ROOMSHAPE_LTL then -- 9 (L room, top-left is missing)
          roomShape = RoomShape.ROOMSHAPE_LBL -- 11 (L room, bottom-left is missing)
        elseif roomShape == RoomShape.ROOMSHAPE_LTR then -- 10 (L room, top-right is missing)
          roomShape = RoomShape.ROOMSHAPE_LBR -- 12 (L room, bottom-right is missing)
        elseif roomShape == RoomShape.ROOMSHAPE_LBL then -- 11 (L room, bottom-left is missing)
          roomShape = RoomShape.ROOMSHAPE_LTL -- 9 (L room, top-left is missing)
        elseif roomShape == RoomShape.ROOMSHAPE_LBR then -- 12 (L room, bottom-right is missing)
          roomShape = RoomShape.ROOMSHAPE_LTR -- 10 (L room, top-right is missing)
        end

      elseif roomData.Variant >= 10000 then
        -- Flipped X
        if roomShape == RoomShape.ROOMSHAPE_LTL then -- 9 (L room, top-left is missing)
          roomShape = RoomShape.ROOMSHAPE_LTR -- 10 (L room, top-right is missing)
        elseif roomShape == RoomShape.ROOMSHAPE_LTR then -- 10 (L room, top-right is missing)
          roomShape = RoomShape.ROOMSHAPE_LTL -- 9 (L room, top-left is missing)
        elseif roomShape == RoomShape.ROOMSHAPE_LBL then -- 11 (L room, bottom-left is missing)
          roomShape = RoomShape.ROOMSHAPE_LBR -- 12 (L room, bottom-right is missing)
        elseif roomShape == RoomShape.ROOMSHAPE_LBR then -- 12 (L room, bottom-right is missing)
          roomShape = RoomShape.ROOMSHAPE_LBL -- 11 (L room, bottom-left is missing)
        end
      end

      -- If it is a new room, it might not be in the XML
      if roomShape == nil then
        Isaac.DebugString("Error: Failed to get the shape of room " .. tostring(roomDataVariant) ..
                          " (with a floor string of " .. floorString .. ").")
        return false
      end

      -- Fill in the grid with values corresponding to this room index
      local x, y = RPCheckLoop:GetXYFromGridIndex(roomIndex)
      grid[y][x] = i
      if roomShape == RoomShape.ROOMSHAPE_1x2 or -- 4 (1 wide x 2 tall)
         roomShape == RoomShape.ROOMSHAPE_IIV then -- 5 (1 wide x 2 tall, narrow)

        grid[y + 1][x] = i -- The square below

      elseif roomShape == RoomShape.ROOMSHAPE_2x1 or -- 6 (2 wide x 1 tall)
             roomShape == RoomShape.ROOMSHAPE_IIH then -- 7 (2 wide x 1 tall, narrow)

        grid[y][x + 1] = i -- The square to the right

      elseif roomShape == RoomShape.ROOMSHAPE_2x2 then -- 8 (2 wide x 2 tall)
        grid[y][x + 1] = i -- The square to the right
        grid[y + 1][x] = i -- The square below
        grid[y + 1][x + 1] = i -- The square to the bottom-right

      elseif roomShape == RoomShape.ROOMSHAPE_LTL then -- 9 (L room, top-left is missing)
        grid[y + 1][x] = i -- The square below
        grid[y + 1][x - 1] = i -- The square to the bottom-left

      elseif roomShape == RoomShape.ROOMSHAPE_LTR then -- 10 (L room, top-right is missing)
        grid[y + 1][x] = i -- The square below
        grid[y + 1][x + 1] = i -- The square to the bottom-right

      elseif roomShape == RoomShape.ROOMSHAPE_LBL then -- 11 (L room, bottom-left is missing)
        grid[y][x + 1] = i -- The square to the right
        grid[y + 1][x + 1] = i -- The square to the bottom-right

      elseif roomShape == RoomShape.ROOMSHAPE_LBR then -- 12 (L room, bottom-right is missing)
        grid[y][x + 1] = i -- The square to the right
        grid[y + 1][x] = i -- The square below
      end

      -- Also, fill in the roomsData with values corresponding to this room index
      roomsData[i] = {
        x = x,
        y = y,
        roomShape = roomShape,
      }

      --[[
      Isaac.DebugString("Plotted room " .. tostring(i) .. ":")
      Isaac.DebugString("  ID: " .. tostring(roomData.Variant))
      Isaac.DebugString("  Index: " .. tostring(roomIndex))
      Isaac.DebugString("  Coordinates: (" .. tostring(x) .. ", " .. tostring(y) .. ")")
      Isaac.DebugString("  Shape: " .. tostring(roomShape))
      --]]
    end
  end

  -- Print out a graphic representing the grid
  --[[
  Isaac.DebugString("Grid:")
  Isaac.DebugString("     1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16")
  for i = 1, #grid do
    local rowString = "  " .. tostring(i) .. " "
    if i < 10 then
      rowString = rowString .. " "
    end
    for j = 1, #grid[i] do
      if grid[i][j] == -1 then
        -- No room is here
        rowString = rowString .. "  "
      else
        -- A room is here
        rowString = rowString .. grid[i][j]
        if i == roomsData[startingRoomNum].y and
           j == roomsData[startingRoomNum].x then

          rowString = rowString .. "!"

        elseif grid[i][j] < 10 then
          rowString = rowString .. " "
        end
      end
      rowString = rowString .. " "
    end
    Isaac.DebugString(rowString)
  end
  --]]

  -- We have created a grid, so now we need to create a node connection table to feed to the cycle checker algorithm
  Isaac.DebugString("Creating connection table...")
  RPCheckLoop.nodes = {}
  for i, roomData in pairs(roomsData) do
    local connectedRooms = {}
    local adjacentSquares = RPCheckLoop:GetAdjacentSquares(roomData.roomShape)
    for j = 1, #adjacentSquares do
      local mod = adjacentSquares[j]
      local adjacentX = roomData.x + mod.x
      local adjacentY = roomData.y + mod.y
      local adjacentRoomID

      -- Get the adjacent room, if any
      if adjacentX < 1 or
         adjacentX > 13 or
         adjacentY < 1 or
         adjacentY > 13 then

        -- This adjacent square is out of bounds, so just treat it as an empty room
        adjacentRoomID = -1
      else
        -- This adjacent square is in bounds
        -- This will be -1 if there is no room on this square
        adjacentRoomID = grid[adjacentY][adjacentX]
      end
      local alreadyConnected = false
      for k = 1, #connectedRooms do
        if connectedRooms[k] == adjacentRoomID then
          alreadyConnected = true
          break
        end
      end
      if alreadyConnected == false and
         adjacentRoomID ~= -1 then -- We initialized every square to -1 when we created the grid

        connectedRooms[#connectedRooms + 1] = adjacentRoomID
      end
    end

    -- Keep track of the connected rooms for every room
    RPCheckLoop.nodes[i] = connectedRooms
  end

  --[[
  -- Print out the connection list
  Isaac.DebugString("Room connection list:")
  for i, node in pairs(RPCheckLoop.nodes) do
    local debugString = "  " .. tostring(i) .. " - (" .. table.concat(node) .. ")"
    Isaac.DebugString(debugString)
  end
  --]]

  -- Do a Depth First Search (DFS) to find a loop
  RPCheckLoop.visited = {}
  return RPCheckLoop:HasCycle(startingRoomNum, RPCheckLoop.nodes)
end

-- Get the grid coordinates on a 13x13 grid
function RPCheckLoop:GetXYFromGridIndex(idx)
  -- 0 --> (0, 0)
  -- 1 --> (1, 0)
  -- 13 --> (0, 1)
  -- 14 --> (1, 1)
  -- etc.
  local y = math.floor(idx / 13)
  local x = idx - (y * 13)

  -- Now, we add 1 to each x and y because the game uses a 0-indexed grid and Lua's tables are 1-indexed
  return x + 1, y + 1
end

function RPCheckLoop:GetAdjacentSquares(roomShape)
  -- Adjacent tiles for each room shape are listed clockwise, starting at the top
  -- The starting square is always the top-left square
  if roomShape == RoomShape.ROOMSHAPE_1x1 then -- 1
    return {
      {x = 0, y = -1}, -- Up
      {x = 1, y = 0}, -- Right
      {x = 0, y = 1}, -- Down
      {x = -1, y = 0}, -- Left
    }

  elseif roomShape == RoomShape.ROOMSHAPE_IH then -- 2
    return {
      {x = 1, y = 0}, -- Right
      {x = -1, y = 0}, -- Left
    }

  elseif roomShape == RoomShape.ROOMSHAPE_IV then -- 3
    return {
      {x = 0, y = -1}, -- Up
      {x = 0, y = 1}, -- Down
    }

  elseif roomShape == RoomShape.ROOMSHAPE_1x2 then -- 4 (1 wide x 2 tall)
    return {
      {x = 0, y = -1}, -- Up
      {x = 1, y = 0}, -- Right-top
      {x = 1, y = 1}, -- Right-bottom
      {x = 0, y = 2}, -- Down
      {x = -1, y = 1}, -- Left-bottom
      {x = -1, y = 0}, -- Left-top
    }

  elseif roomShape == RoomShape.ROOMSHAPE_IIV then -- 5 (1 wide x 2 tall, narrow)
    return {
      {x = 0, y = -1}, -- Up
      {x = 0, y = 2}, -- Down
    }

  elseif roomShape == RoomShape.ROOMSHAPE_2x1 then -- 6 (2 wide x 1 tall)
    return {
      {x = 0, y = -1}, -- Up-left
      {x = 1, y = -1}, -- Up-right
      {x = 2, y = 0}, -- Right
      {x = 1, y = 1}, -- Down-right
      {x = 0, y = 1}, -- Down-left
      {x = -1, y = 0}, -- Left
    }

  elseif roomShape == RoomShape.ROOMSHAPE_IIH then -- 7 (2 wide x 1 tall, narrow)
    return {
      {x = 2, y = 0}, -- Right
      {x = -1, y = 0}, -- Left
    }

  elseif roomShape == RoomShape.ROOMSHAPE_2x2 then -- 8 (2 wide x 2 tall)
    return {
      {x = 0, y = -1}, -- Up-left
      {x = 1, y = -1}, -- Up-right
      {x = 2, y = 0}, -- Right-top
      {x = 2, y = 1}, -- Right-bottom
      {x = 1, y = 2}, -- Down-right
      {x = 0, y = 2}, -- Down-left
      {x = -1, y = 1}, -- Left-bottom
      {x = -1, y = 0}, -- Left-top
    }

  elseif roomShape == RoomShape.ROOMSHAPE_LTL then -- 9 (L room, top-left is missing)
    return {
      {x = 0, y = -1}, -- Up
      {x = 1, y = 0}, -- Right-top
      {x = 1, y = 1}, -- Right-bottom
      {x = 0, y = 2}, -- Down-right
      {x = -1, y = 2}, -- Down-left
      {x = -2, y = 1}, -- Left-bottom
      {x = -1, y = 0}, -- Left-top
    }

  elseif roomShape == RoomShape.ROOMSHAPE_LTR then -- 10 (L room, top-right is missing)
    return {
      {x = 0, y = -1}, -- Up
      {x = 1, y = 0}, -- Right-top
      {x = 2, y = 1}, -- Right-bottom
      {x = 1, y = 2}, -- Down-right
      {x = 0, y = 2}, -- Down-left
      {x = -1, y = 1}, -- Left-bottom
      {x = -1, y = 0}, -- Left-top
    }

  elseif roomShape == RoomShape.ROOMSHAPE_LBL then -- 11 (L room, bottom-left is missing)
    return {
      {x = 0, y = -1}, -- Up-left
      {x = 1, y = -1}, -- Up-right
      {x = 2, y = 0}, -- Right-top
      {x = 2, y = 1}, -- Right-bottom
      {x = 1, y = 2}, -- Down
      {x = 0, y = 1}, -- Left-bottom
      {x = -1, y = 0}, -- Left-top
    }

  elseif roomShape == RoomShape.ROOMSHAPE_LBR then -- 12 (L room, bottom-right is missing)
    return {
      {x = 0, y = -1}, -- Up-left
      {x = 1, y = -1}, -- Up-right
      {x = 2, y = 0}, -- Right-top
      {x = 1, y = 1}, -- Right-bottom
      {x = 0, y = 2}, -- Down
      {x = -1, y = 1}, -- Left-bottom
      {x = -1, y = 0}, -- Left-top
    }
  end
end

-- A recursive function that does a Depth First Search (DFS)
-- to see if there is a cycle (loop) in the node connection list
function RPCheckLoop:HasCycle(node, cameFrom)
  -- If we found this node already, there is a cycle
  for i = 1, #RPCheckLoop.visited do
    if RPCheckLoop.visited[i] == node then
      Isaac.DebugString("Looping floor found (on node " .. tostring(node) .. ") - reseeding.")
      return true
    end
  end

  -- Mark that we have visited this node
  RPCheckLoop.visited[#RPCheckLoop.visited + 1] = node

  -- Go through all the nodes that are connected to this node
  for _, n in ipairs(RPCheckLoop.nodes[node]) do
    if n ~= cameFrom then
      if RPCheckLoop:HasCycle(n, node) then
        return true
      end
    end
  end

  return false
end

return RPCheckLoop

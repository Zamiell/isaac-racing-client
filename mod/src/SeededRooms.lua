local SeededRooms = {}

-- Includes
local g = require("src/globals")

-- ModCallbacks.MC_POST_NEW_ROOM (19)
function SeededRooms:PostNewRoom()
  -- We only want to manually create certain rooms in seeded races
  if g.race.rFormat ~= "seeded" or
     g.race.status ~= "in progress" then

    return
  end

  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()

  -- We only want to replace things on the first visit, or else everything will get duplicated
  if room:IsFirstVisit() == false then
    return
  end

  if roomType == RoomType.ROOM_DEVIL then -- 14
    SeededRooms:DevilRoom()
  elseif roomType == RoomType.ROOM_ANGEL then -- 15
    SeededRooms:AngelRoom()
  end
end

function SeededRooms:DevilRoom()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()

  -- Increment the seed 10 times,
  -- which will ensure that we are not using any seeds used on items in a previous Devil Room
  for i = 1, 10 do
    g.RNGCounter.DevilRoomItem = g:IncrementRNG(g.RNGCounter.DevilRoomItem)
  end

  -- First, find out if we should encounter Krampus instead of getting a normal Devil Room
  if g.run.metKrampus == false then
    local krampusChance
    if game:GetDevilRoomDeals() > 0 then
      krampusChance = 40
    else
      krampusChance = 10
    end

    g.RNGCounter.DevilRoomItem = g:IncrementRNG(g.RNGCounter.DevilRoomItem)
    math.randomseed(g.RNGCounter.DevilRoomItem)
    local krampusRoll = math.random(1, 100)
    if krampusRoll <= krampusChance then
      -- Spawn Krampus
      g.run.metKrampus = true
      game:Spawn(EntityType.ENTITY_FALLEN, 1,
                 room:GetCenterPos(), Vector(0, 0), nil, 0, g.RNGCounter.DevilRoomItem)
      room:SetClear(false) -- If we don't do this, we won't get a charge after Krampus is killed
      return
    end
  end

  -- Second, find out how many item pedestals we should spawn
  g.RNGCounter.DevilRoomItem = g:IncrementRNG(g.RNGCounter.DevilRoomItem)
  math.randomseed(g.RNGCounter.DevilRoomItem)
  local roomRoll = math.random(1, 1705) -- The total weight of all of the rooms is 17.05
  if roomRoll <= 10 then
    -- 1x 10 red chests (0.1 weight)
    for x = 4, 8 do
      for y = 3, 4 do
        g.RNGCounter.DevilRoomItem = g:IncrementRNG(g.RNGCounter.DevilRoomItem)
        local pos = g:GridToPos(x, y)
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_REDCHEST, -- 5.360
                   pos, Vector(0, 0), nil, 0, g.RNGCounter.DevilRoomItem)
      end
    end

  elseif roomRoll <= 110 then
    -- 1x 1 pedestal + 4 bombs (1 weight)
    SeededRooms:SpawnPedestalDevilRoom(6, 4)

    g.RNGCounter.DevilRoomItem = g:IncrementRNG(g.RNGCounter.DevilRoomItem)
    local pos2 = g:GridToPos(4, 4)
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, -- 5.40.2
               pos2, Vector(0, 0), nil, BombSubType.BOMB_DOUBLEPACK, g.RNGCounter.DevilRoomItem)

    g.RNGCounter.DevilRoomItem = g:IncrementRNG(g.RNGCounter.DevilRoomItem)
    local pos3 = g:GridToPos(8, 4)
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, -- 5.40.2
               pos3, Vector(0, 0), nil, BombSubType.BOMB_DOUBLEPACK, g.RNGCounter.DevilRoomItem)

  elseif roomRoll <= 210 then
    -- 1x 1 pedestal + ? card (1 weight)
    SeededRooms:SpawnPedestalDevilRoom(5, 4)

    g.RNGCounter.DevilRoomItem = g:IncrementRNG(g.RNGCounter.DevilRoomItem)
    local pos = g:GridToPos(7, 4)
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, -- 5.300.48
               pos, Vector(0, 0), nil, Card.CARD_QUESTIONMARK, g.RNGCounter.DevilRoomItem)

  elseif roomRoll <= 310 then
    -- 1x 1 pedestal + black rune (1 weight)
    g.RNGCounter.DevilRoomItem = g:IncrementRNG(g.RNGCounter.DevilRoomItem)
    local pos = g:GridToPos(5, 4)
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, -- 5.300.41
               pos, Vector(0, 0), nil, Card.RUNE_BLACK, g.RNGCounter.DevilRoomItem)

    SeededRooms:SpawnPedestalDevilRoom(7, 4)

  elseif roomRoll <= 410 then
    -- 1x 1 pedestal + Devil Beggar (1 weight)
    SeededRooms:SpawnPedestalDevilRoom(5, 4)

    g.RNGCounter.DevilRoomItem = g:IncrementRNG(g.RNGCounter.DevilRoomItem)
    local pos2 = g:GridToPos(7, 4)
    game:Spawn(EntityType.ENTITY_SLOT, 5, -- 6.5
               pos2, Vector(0, 0), nil, 0, g.RNGCounter.DevilRoomItem)

  elseif roomRoll <= 1610 then
    -- 12x 2 pedestals (12 weight)
    SeededRooms:SpawnPedestalDevilRoom(5, 4)
    SeededRooms:SpawnPedestalDevilRoom(7, 4)

  elseif roomRoll <= 1695 then
    -- 1x 3 pedestals (0.85 weight)
    for x = 4, 8 do
      if x % 2 == 0 then
        SeededRooms:SpawnPedestalDevilRoom(x, 4)
      end
    end

    -- Also spawn 8 pitfalls to match the normal Racing+ room
    for x = 3, 9 do
      for y = 4, 5 do
        if x % 2 ~= 0 then
          local pos = g:GridToPos(x, y)
          game:Spawn(EntityType.ENTITY_PITFALL, 0, pos, Vector(0, 0), nil, 0, 0) -- 291.0
        end
      end
    end

  elseif roomRoll <= 1705 then
    -- 1x 4 pedestals (0.1 weight)
    for x = 3, 9 do
      for y = 3, 4 do
        if (y == 3 and (x == 3 or x == 9)) or
           (y == 4 and (x == 5 or x == 7)) then

          SeededRooms:SpawnPedestalDevilRoom(x, y)
        end
      end
    end
  end

  -- Spawn the Devil Statue
  room:SpawnGridEntity(52, GridEntityType.GRID_STATUE, 0, 0, 0) -- 21

  -- Spawn the two fires
  local pos1 = g:GridToPos(3, 1)
  game:Spawn(EntityType.ENTITY_FIREPLACE, 0, pos1, Vector(0, 0), nil, 0, 0) -- 33
  local pos2 = g:GridToPos(9, 1)
  game:Spawn(EntityType.ENTITY_FIREPLACE, 0, pos2, Vector(0, 0), nil, 0, 0) -- 33

  -- Increment the seed a final time before the items are replaced
  g.RNGCounter.DevilRoomItem = g:IncrementRNG(g.RNGCounter.DevilRoomItem)
end

function SeededRooms:SpawnPedestalDevilRoom(x, y)
  -- Local variables
  local game = Game()

  -- Spawn it with a seed of 0 so that it gets replaced on the next frame
  local pos = g:GridToPos(x, y)
  g.RNGCounter.DevilRoomItem = g:IncrementRNG(g.RNGCounter.DevilRoomItem)
  game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_SHOPITEM, -- 5.150.0
             pos, Vector(0, 0), nil, 0, g.RNGCounter.DevilRoomItem)
end

function SeededRooms:AngelRoom()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()

  -- Increment the seed 10 times,
  -- which will ensure that we are not using any seeds used on items in a previous Angel Room
  for i = 1, 10 do
    g.RNGCounter.AngelRoomItem = g:IncrementRNG(g.RNGCounter.AngelRoomItem)
  end

  -- First, find out how many item pedestals we should spawn
  g.RNGCounter.AngelRoomItem = g:IncrementRNG(g.RNGCounter.AngelRoomItem)
  math.randomseed(g.RNGCounter.AngelRoomItem)
  local roomRoll = math.random(1, 16) -- The total weight of all of the rooms is 16
  if roomRoll <= 12 then
    -- 12x 2 pedestals (12 weight)
    SeededRooms:SpawnPedestalAngelRoom(4, 4)
    SeededRooms:SpawnPedestalAngelRoom(8, 4)

    -- Spawn the Angel Statue
    room:SpawnGridEntity(52, GridEntityType.GRID_STATUE, 1, 0, 0) -- 21

  elseif roomRoll <= 13 then
    -- 1x 3 pedestals (1 weight)
    SeededRooms:SpawnPedestalAngelRoom(0, 0)
    SeededRooms:SpawnPedestalAngelRoom(12, 0)
    SeededRooms:SpawnPedestalAngelRoom(0, 6)

    -- Spawn 3x blocks
    room:SpawnGridEntity(31, GridEntityType.GRID_ROCKB, 0, 0, 0) -- 3
    room:SpawnGridEntity(43, GridEntityType.GRID_ROCKB, 0, 0, 0) -- 3
    room:SpawnGridEntity(91, GridEntityType.GRID_ROCKB, 0, 0, 0) -- 3

    -- Spawn 3x lock blocks
    room:SpawnGridEntity(17, GridEntityType.GRID_LOCK, 0, 0, 0) -- 11
    room:SpawnGridEntity(27, GridEntityType.GRID_LOCK, 0, 0, 0) -- 11
    room:SpawnGridEntity(107, GridEntityType.GRID_LOCK, 0, 0, 0) -- 11

    -- Spawn the Angel Statue
    room:SpawnGridEntity(52, GridEntityType.GRID_STATUE, 1, 0, 0) -- 21

  elseif roomRoll <= 14 then
    -- 1x 1 pedestal + 2 Eternal Chests (1 weight)
    SeededRooms:SpawnPedestalAngelRoom(6, 4)

    -- Spawn 2 Angel Statues
    room:SpawnGridEntity(50, GridEntityType.GRID_STATUE, 1, 0, 0) -- 21
    room:SpawnGridEntity(54, GridEntityType.GRID_STATUE, 1, 0, 0) -- 21

    -- 2x Eternal Chests
    g.RNGCounter.AngelRoomItem = g:IncrementRNG(g.RNGCounter.AngelRoomItem)
    local pos1 = g:GridToPos(4, 4)
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_ETERNALCHEST, -- 5.53
               pos1, Vector(0, 0), nil, 0, g.RNGCounter.AngelRoomItem)

    g.RNGCounter.AngelRoomItem = g:IncrementRNG(g.RNGCounter.AngelRoomItem)
    local pos2 = g:GridToPos(8, 4)
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_ETERNALCHEST, -- 5.53
               pos2, Vector(0, 0), nil, 0, g.RNGCounter.AngelRoomItem)

  elseif roomRoll <= 15 then
    -- 1x 1 pedestal + 1 random bomb (1 weight)
    SeededRooms:SpawnPedestalAngelRoom(6, 4)

    -- 1x Random Bomb
    local pos = g:GridToPos(6, 1)
    game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, -- 5.40
               pos, Vector(0, 0), nil, 0, g.RNGCounter.AngelRoomItem)

    -- Spawn 2 Angel Statues
    room:SpawnGridEntity(50, GridEntityType.GRID_STATUE, 1, 0, 0) -- 21
    room:SpawnGridEntity(54, GridEntityType.GRID_STATUE, 1, 0, 0) -- 21

  elseif roomRoll <= 16 then
    -- 1x 1 pedestal (1 weight)
    SeededRooms:SpawnPedestalAngelRoom(6, 4)

    -- Spawn 2 Angel Statues
    room:SpawnGridEntity(50, GridEntityType.GRID_STATUE, 1, 0, 0) -- 21
    room:SpawnGridEntity(54, GridEntityType.GRID_STATUE, 1, 0, 0) -- 21
  end

  -- Increment the seed a final time before the items are replaced
  g.RNGCounter.AngelRoomItem = g:IncrementRNG(g.RNGCounter.AngelRoomItem)
end

function SeededRooms:SpawnPedestalAngelRoom(x, y)
  -- Local variables
  local game = Game()

  -- Spawn it with a seed of 0 so that it gets replaced on the next frame
  local pos = g:GridToPos(x, y)
  g.RNGCounter.AngelRoomItem = g:IncrementRNG(g.RNGCounter.AngelRoomItem)
  local entity = game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 100
                            pos, Vector(0, 0), nil, 0, g.RNGCounter.AngelRoomItem)
  entity:ToPickup().TheresOptionsPickup = true
end

-- ModCallbacks.MC_PRE_ENTITY_SPAWN (24)
function SeededRooms:PreEntitySpawn(type, variant, subType, seed)
  -- We only want to delete things in seeded races
  if g.race.rFormat ~= "seeded" or
     g.race.status ~= "in progress" then

    return
  end

  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()
  local roomFrameCount = room:GetFrameCount()

  -- We only care about replacing things when the room is first loading
  if roomFrameCount ~= -1 then
    return
  end

  if roomType == RoomType.ROOM_DEVIL or -- 14
     roomType == RoomType.ROOM_ANGEL then -- 15

    return {999, 0, 0} -- Equal to 1000.0, which is a blank effect, which is essentially nothing
  end
end

return SeededRooms

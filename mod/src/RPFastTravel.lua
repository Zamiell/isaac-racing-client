local RPFastTravel = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")

--
-- FastTravel functions
--

-- Remove the long fade out / fade in when entering trapdoors / beams of light (1/2)
-- (called from the "RPCheckEntities:Grid()" function)
function RPFastTravel:CheckTrapdoorEnter(gridOrEffectEntity, upwards)
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- Check to see if the player is in a square around the trapdoor that will trigger the animation
  -- ("room:GetGridIndex(player.Position) == gridEntity:GetGridIndex()" is too small of a square
  -- to trigger reliably)
  local squareSize = 25.5 -- 25 is too small
  if RPGlobals.run.trapdoor.state == 0 and
     ((upwards == false and gridOrEffectEntity.State == 1) or -- The trapdoor is open
      (upwards and gridOrEffectEntity.FrameCount >= 60)) and -- The beam of light is not freshly spawned
     player.Position.X >= gridOrEffectEntity.Position.X - squareSize and
     player.Position.X <= gridOrEffectEntity.Position.X + squareSize and
     player.Position.Y >= gridOrEffectEntity.Position.Y - squareSize and
     player.Position.Y <= gridOrEffectEntity.Position.Y + squareSize and
     player:IsHoldingItem() == false then

    -- State 1 is activated the moment we touch the trapdoor
    RPGlobals.run.trapdoor.state = 1
    RPGlobals.run.trapdoor.upwards = upwards
    RPGlobals.run.trapdoor.frame = Isaac.GetFrameCount() + 40
    -- The "Trapdoor" animation is 16 frames long and the "LightTravel" animation is 28 frames long,
    -- but we need to delay for longer than that to make it look smooth
    -- (we keep the "Trapdoor" animation at 2 for quick chest animations and
    -- make a custom "Trapdoor2" animation that is 40 frames long)
    -- (we have increased the "FrameNum" for the "LightTravel" animations to 40)

    player.ControlsEnabled = false
    player.Position = gridOrEffectEntity.Position -- Teleport the player on top of the trapdoor
    player.Velocity = Vector(0, 0) -- Remove all of the player's momentum
    if upwards then
      player:PlayExtraAnimation("LightTravel")
    else
      player:PlayExtraAnimation("Trapdoor2") -- This is a custom elongated animation
    end
  end
end

-- Remove the long fade out / fade in when entering trapdoors (2/2)
-- (called from the PostRender callback)
function RPFastTravel:CheckTrapdoor()
  -- Local varaibles
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)
  local frameCount = Isaac.GetFrameCount()

  if RPGlobals.run.trapdoor.state == 1 and
     frameCount >= RPGlobals.run.trapdoor.frame then

    -- State 2 is activated when the "Trapdoor" animation is completed
    -- Make Isaac invisible
    RPGlobals.run.crawlspace.scale = player.SpriteScale
    player.SpriteScale = Vector(0, 0)
    game:StartRoomTransition(level:GetStartingRoomIndex(), Direction.NO_DIRECTION, -- -1
                             RPGlobals.RoomTransition.TRANSITION_NONE) -- 0

    -- Mark to change floors after the screen is black
    RPGlobals.run.trapdoor.state = 2
    RPGlobals.run.trapdoor.frame = frameCount + 8
    -- 9 is too many (you can start to see the same room again)

  elseif RPGlobals.run.trapdoor.state == 2 and
         frameCount >= RPGlobals.run.trapdoor.frame then

    -- Stage 3 is actiated when the screen is black
    RPGlobals.run.trapdoor.state = 3
    RPGlobals.run.trapdoor.floor = stage
    RPGlobals:GotoNextFloor(RPGlobals.run.trapdoor.upwards) -- The argument is "upwards"

  elseif RPGlobals.run.trapdoor.state == 3 and
         RPGlobals.run.trapdoor.floor ~= stage then

    -- State 4 is activated when we get to the new floor
    RPGlobals.run.trapdoor.state = 4

    -- Spawn a Pitfall (291.0)
    local pitfall = game:Spawn(EntityType.ENTITY_PITFALL, 0, room:GetCenterPos(), Vector(0,0), nil, 0, 0)

    -- Make it so that it doesn't actually suck in the player
    pitfall:ToNPC().State = 4 -- (I found this through trial and error)

    -- Move Isaac to the center of the room
    player.Position = room:GetCenterPos()

  elseif RPGlobals.run.trapdoor.state == 4 and
         player.ControlsEnabled then

     -- State 5 is activated when the player controls are enabled
     -- (this happens automatically by the game)
     RPGlobals.run.trapdoor.state = 5
     RPGlobals.run.trapdoor.frame = frameCount + 10 -- Wait a while
     player.ControlsEnabled = false

  elseif RPGlobals.run.trapdoor.state == 5 and
         frameCount >= RPGlobals.run.trapdoor.frame then

     -- State 6 is activated when the the hole is spawned and ready
     RPGlobals.run.trapdoor.state = 6
     RPGlobals.run.trapdoor.frame = frameCount + 25
     -- The "JumpOut" animation is 15 frames long, so give a bit of leeway

     -- Make Isaac visable again
     player.SpriteScale = RPGlobals.run.trapdoor.scale

     -- Play the jumping out of the hole animation
     player:PlayExtraAnimation("Jump")

     -- Make the hole do the dissapear animation
     local entities = Isaac.GetRoomEntities()
     for i = 1, #entities do
       if entities[i].Type == EntityType.ENTITY_PITFALL then -- 291
         entities[i]:ToNPC().State = 5 -- State 5 causes it to disappear
         break
       end
     end

  elseif RPGlobals.run.trapdoor.state == 6 and
         frameCount >= RPGlobals.run.trapdoor.frame then

    -- We are finished when the the player has emerged from the hole
    RPGlobals.run.trapdoor.state = 0
    player.ControlsEnabled = true

    -- Kill the hole
    local entities = Isaac.GetRoomEntities()
    for i = 1, #entities do
      if entities[i].Type == EntityType.ENTITY_PITFALL then -- 291
        entities[i]:Remove()
        break
      end
    end
  end
end

-- Remove the animation when entering crawlspaces
-- (called from the "RPCheckEntities:Grid()" function)
function RPFastTravel:CheckCrawlspaceEnter(gridEntity)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomIndex()
  local player = game:GetPlayer(0)

  -- Check to see if the player is in a square around the stairs that will trigger the animation
  -- ("room:GetGridIndex(player.Position) == gridEntity:GetGridIndex()" is too small of a square
  -- to trigger reliably)
  local squareSize = 25.5 -- 25 is too small
  if gridEntity.State == 1 and -- The trapdoor is open
     RPGlobals.run.crawlspace.entering == false and
     player.Position.X >= gridEntity.Position.X - squareSize and
     player.Position.X <= gridEntity.Position.X + squareSize and
     player.Position.Y >= gridEntity.Position.Y - squareSize and
     player.Position.Y <= gridEntity.Position.Y + squareSize then

    RPGlobals.run.crawlspace.entering = true
    RPGlobals.run.crawlspace.room = roomIndex
    RPGlobals.run.crawlspace.position = gridEntity.Position
    game:StartRoomTransition(GridRooms.ROOM_DUNGEON_IDX, Direction.DOWN, -- -4, 3
                             RPGlobals.RoomTransition.TRANSITION_NONE) -- 0
  end
end

-- Remove the animation when leaving crawlspaces
-- (called from the PostUpdate callback)
function RPFastTravel:CheckCrawlspaceExit()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)
  local playerGridIndex = room:GetGridIndex(player.Position)

  if room:GetType() == RoomType.ROOM_DUNGEON and -- 16
     playerGridIndex == 2 and -- If the player is standing on top of the ladder
     RPGlobals.run.crawlspace.exiting == false then

    -- Make the player invisible to avoid a bug where they pop out of the wrong spot
    RPGlobals.run.crawlspace.scale = player.SpriteScale
    player.SpriteScale = Vector(0, 0)

    -- Do a manual room transition
    RPGlobals.run.crawlspace.exiting = true
    level.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
    game:StartRoomTransition(RPGlobals.run.crawlspace.room, Direction.UP, -- 1
                             RPGlobals.RoomTransition.TRANSITION_NONE) -- 0
  end
end

-- Fix the softlock with Boss Rushes and crawlspaces
-- (called from the PostUpdate callback)
function RPFastTravel:CheckCrawlspaceSoftlock()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local level = game:GetLevel()
  local player = game:GetPlayer(0)
  local playerGridIndex = room:GetGridIndex(player.Position)

  if room:GetType() == RoomType.ROOM_BOSSRUSH and -- 17
     level:GetPreviousRoomIndex() == GridRooms.ROOM_DUNGEON_IDX then -- -4

    if playerGridIndex == 7 then -- Top left door
      game:StartRoomTransition(RPFastTravel:GetBossRoomIndex(), Direction.UP, -- 1
                               RPGlobals.RoomTransition.TRANSITION_NONE) -- 0
    elseif playerGridIndex == 139 then -- Right top door
      game:StartRoomTransition(RPFastTravel:GetBossRoomIndex(), Direction.RIGHT, -- 2
                               RPGlobals.RoomTransition.TRANSITION_NONE) -- 0
    elseif playerGridIndex == 427 then -- Bottom left door
      game:StartRoomTransition(RPFastTravel:GetBossRoomIndex(), Direction.DOWN, -- 3
                               RPGlobals.RoomTransition.TRANSITION_NONE) -- 0
    elseif playerGridIndex == 112 then -- Left top door
      game:StartRoomTransition(RPFastTravel:GetBossRoomIndex(), Direction.LEFT, -- 0
                               RPGlobals.RoomTransition.TRANSITION_NONE) -- 0
    end
  end
end

function RPFastTravel:GetBossRoomIndex()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local rooms = level:GetRooms()

  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local roomType = rooms:Get(i).Data.Type
    if roomType == RoomType.ROOM_BOSS then -- 5
      return rooms:Get(i).SafeGridIndex
    end
  end

  -- We should never get here
  Isaac.DebugString("Error: Was not able to find the boss room index.")
  return level:GetStartingRoomIndex()
end

return RPFastTravel

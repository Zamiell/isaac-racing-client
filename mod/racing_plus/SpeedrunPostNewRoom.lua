local SpeedrunPostNewRoom = {}

-- Includes
local g        = require("racing_plus/globals")
local Speedrun = require("racing_plus/speedrun")

function SpeedrunPostNewRoom:Main()
  if not Speedrun:InSpeedrun() then
    return
  end

  SpeedrunPostNewRoom:Womb2Error()
  SpeedrunPostNewRoom:ReplaceBosses()
  SpeedrunPostNewRoom:CheckCurseRoom()
  SpeedrunPostNewRoom:CheckSacrificeRoom()
  SpeedrunPostNewRoom:RemoveVetoButton()
  SpeedrunPostNewRoom:Season7Stage11()
  SpeedrunPostNewRoom:Season7Stage12()
  SpeedrunPostNewRoom:Season7SpawnMahalath()
end

-- Fix the bug where the "correct" exit always appears in the I AM ERROR room in custom challenges (1/2)
function SpeedrunPostNewRoom:Womb2Error()
  -- Local variables
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"
  local gridSize = g.r:GetGridSize()

  if stage ~= 8 then
    return
  end

  if roomType ~= RoomType.ROOM_ERROR then -- 3
    return
  end

  -- Find out whether we should spawn a passage up or down, depending on the room seed
  math.randomseed(roomSeed)
  local direction = math.random(1, 2)
  if direction == 1 then
    Isaac.DebugString("Randomly decided that the I AM ERROR room direction should be up.")
  elseif direction == 2 then
    Isaac.DebugString("Randomly decided that the I AM ERROR room direction should be down.")
  end

  -- Find any existing trapdoors
  local pos
  for i = 1, gridSize do
    local gridEntity = g.r:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState()
      if saveState.Type == GridEntityType.GRID_TRAPDOOR then -- 17
        if direction == 1 then
          -- We need to remove it since we are going up
          pos = gridEntity.Position
          g.r:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work

          -- Spawn a Heaven Door (1000.39) (it will get replaced with the fast-travel version on this frame)
          g.g:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, pos, g.zeroVector, g.p, 0, 0)
          Isaac.DebugString("Replaced a trapdoor with a beam of light.")
          return
        elseif direction == 2 then
          -- If we are going down and there is already a trapdoor, we don't need to do anything
          return
        end
      end
    end
  end

  -- Find any existing beams of light
  local lightDoors = Isaac.FindByType(EntityType.ENTITY_EFFECT, -- 1000
                                      EffectVariant.HEAVEN_LIGHT_DOOR, -1, false, false) -- 39
  for _, lightDoor in ipairs(lightDoors) do
    if direction == 1 then
      -- If we are going up and there is already a beam of light, we don't need to do anything
      return
    elseif direction == 2 then
      -- We need to remove it since we are going down
      pos = lightDoor.Position
      lightDoor:Remove()

      -- Spawn a trapdoor (it will get replaced with the fast-travel version on this frame)
      Isaac.GridSpawn(GridEntityType.GRID_TRAPDOOR, 0, pos, true) -- 17
      Isaac.DebugString("Replaced a beam of light with a trapdoor.")
      return
    end
  end
end

-- In R+7 Season 3, replace the two final bosses
function SpeedrunPostNewRoom:ReplaceBosses()
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end
  local roomType = g.r:GetType()
  local roomClear = g.r:IsClear()
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 3)") then
    return
  end

  if stage ~= 10 and
     stage ~= 11 then

    return
  end

  if roomType ~= RoomType.ROOM_BOSS then -- 5
    return
  end

  if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
    return
  end

  if roomClear then
    return
  end

  -- Don't do anything if we have somehow gone the wrong direction
  -- (via We Need to Go Deeper!, Undefined, etc.)
  local direction = Speedrun.charNum % 2 -- 1 is up, 2 is down
  if direction == 0 then
    direction = 2
  end
  if stageType == 1 and -- Cathedral or The Chest
     direction == 2 then

    return
  end
  if stageType == 0 and -- Sheol or Dark Room
     direction == 1 then

    return
  end

  for _, entity in ipairs(Isaac.GetRoomEntities()) do
    if stageType == 1 and -- Cathedral
       entity.Type == EntityType.ENTITY_ISAAC then -- 273

      entity:Remove()

    elseif stageType == 0 and -- Sheol
           entity.Type == EntityType.ENTITY_SATAN then -- 84

        entity:Remove()

    elseif stageType == 1 and -- The Chest
           entity.Type == EntityType.ENTITY_ISAAC then -- 102

        entity:Remove()

      elseif stageType == 0 and -- Dark Room
             entity.Type == EntityType.ENTITY_THE_LAMB  then -- 273

        entity:Remove()
      end
    end

    -- Spawn the replacement boss
    if stage == 10 then
      Isaac.Spawn(838, 0, 0, g.r:GetCenterPos(), g.zeroVector, nil)
      Isaac.DebugString("Spawned Jr. Fetus (for season 3).")
    elseif stage == 11 then
      Isaac.Spawn(777, 0, 0, g.r:GetCenterPos(), g.zeroVector, nil)
      Isaac.DebugString("Spawned Mahalath (for season 3).")
    end
end

-- In instant-start seasons, prevent people from resetting for a Curse Room
function SpeedrunPostNewRoom:CheckCurseRoom()
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()
  local challenge = Isaac.GetChallenge()

  if (challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 4)") and
      challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)")) or
     Speedrun.charNum ~= 1 or
     stage ~= 1 or
     roomType ~= RoomType.ROOM_CURSE or -- 10
     not g.r:IsFirstVisit() then

    return
  end

  -- Check to see if there are any pickups in the room
  local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP, -1, -1, false, false) -- 5
  for _, pickup in ipairs(pickups) do
    pickup:Remove()
  end
  local slots = Isaac.FindByType(EntityType.ENTITY_SLOT, -1, -1, false, false) -- 6
  for _, slot in ipairs(slots) do
    slot:Remove()
  end
  if #pickups > 0 or #slots > 0 then
    g.p:AnimateSad()
    Isaac.DebugString("Deleted all of the pickups in a Curse Room (during a no-reset run).")
  end
end

-- In instant-start seasons, prevent people from resetting for a Sacrifice Room
function SpeedrunPostNewRoom:CheckSacrificeRoom()
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()
  local gridSize = g.r:GetGridSize()
  local challenge = Isaac.GetChallenge()

  if (challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 4)") and
      challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)")) or
     Speedrun.charNum ~= 1 or
     stage ~= 1 or
     roomType ~= RoomType.ROOM_SACRIFICE then -- 13

    return
  end

  if g.r:IsFirstVisit() then
    -- On the first visit to a Sacrifice Room, give a sign to the player that the spikes were intentionally deleted
    -- Note that the spikes need to be deleted every time we enter the room, as they will respawn once the player leaves
    g.p:AnimateSad()
  end
  for i = 1, gridSize do
    local gridEntity = g.r:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState()
      if saveState.Type == GridEntityType.GRID_SPIKES then -- 8
        g.r:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
      end
    end
  end
  Isaac.DebugString("Deleted the spikes in a Sacrifice Room (during a no-reset run).")
end

-- In seasons with the veto button, delete it if we are re-entering the starting room
function SpeedrunPostNewRoom:RemoveVetoButton()
  local stage = g.l:GetStage()
  local startingRoomIndex = g.l:GetStartingRoomIndex()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)") or
     stage ~= 1 or
     roomIndex ~= startingRoomIndex or
     g.run.roomsEntered == 1 then

    return
  end

  g.r:RemoveGridEntity(117, 0, false)
end

function SpeedrunPostNewRoom:Season7Stage11()
  -- Local variables
  local stage = g.l:GetStage()
  local roomIndexUnsafe = g.l:GetCurrentRoomIndex()
  local startingRoomIndex = g.l:GetStartingRoomIndex()
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)") or
     stage ~= 11 or
     roomIndexUnsafe ~= startingRoomIndex then

    return
  end

  -- Spawn a Void Portal if we still need to go to Mahalath
  if g:TableContains(Speedrun.remainingGoals, "Mahalath") then
    local trapdoor = g.g:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.VOID_PORTAL_FAST_TRAVEL, -- 1000
                              g:GridToPos(1, 1), g.zeroVector, nil, 0, 0)
    trapdoor.DepthOffset = -100 -- This is needed so that the entity will not appear on top of the player
  end

  -- Spawn the Mega Satan trapdoor if we still need to go to Mega Satan
  -- and we are on the second character or beyond
  -- (the normal Mega Satan door does not appear on custom challenges that have a goal set to Blue Baby)
  if g:TableContains(Speedrun.remainingGoals, "Mega Satan") then
     --Speedrun.charNum >= 2 then

    local trapdoor = g.g:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.MEGA_SATAN_TRAPDOOR, -- 1000
                               g:GridToPos(11, 1), g.zeroVector, nil, 0, 0)
    trapdoor.DepthOffset = -100 -- This is needed so that the entity will not appear on top of the player
  end
end

function SpeedrunPostNewRoom:Season7Stage12()
  -- Local variables
  local stage = g.l:GetStage()
  local rooms = g.l:GetRooms()
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)") then
    return
  end

  if stage ~= 12 then
    return
  end

  -- Show the boss icon for the Mahalath room and remove of the other ones
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local roomDesc = rooms:Get(i)
    local roomIndex = roomDesc.SafeGridIndex -- This is always the top-left index
    local roomData = roomDesc.Data
    local roomType = roomData.Type

    if roomType == RoomType.ROOM_BOSS then -- 5
      local room = g.l:GetRoomByIdx(roomIndex) -- We have use this function in order to modify the DisplayFlags
      if roomIndex == g.run.mahalathRoomIndex then
        room.DisplayFlags = 1 << 2 -- Show the icon
      else
        room.DisplayFlags = 1 << -1 -- Remove the icon (in case we have the Compass or The Mind)
      end
    end
  end
  g.l:UpdateVisibility() -- Setting the display flag will not actually update the map
end

function SpeedrunPostNewRoom:Season7SpawnMahalath()
  -- Local variables
  local stage = g.l:GetStage()
  local roomIndexUnsafe = g.l:GetCurrentRoomIndex()
  local centerPos = g.r:GetCenterPos()
  local isClear = g.r:IsClear()
  local challenge = Isaac.GetChallenge()

  -- In season 7 speedruns, we replace one of the bosses in The Void with Mahalath
  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)") or
     stage ~= 12 or
     roomIndexUnsafe ~= g.run.mahalathRoomIndex or
     isClear then

    return
  end

  -- Remove all enemies
  for _, entity in ipairs(Isaac.GetRoomEntities()) do
    local npc = entity:ToNPC()
    if npc ~= nil then
      entity:Remove()
    end
  end

  -- Spawn Mahalath (the second, harder version)
  g.g:Spawn(Isaac.GetEntityTypeByName("Mahalath"), 1, centerPos, g.zeroVector, nil, 0, 0)
end

return SpeedrunPostNewRoom

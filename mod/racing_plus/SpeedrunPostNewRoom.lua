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
  SpeedrunPostNewRoom:CheckMiniBossRoom()
  SpeedrunPostNewRoom:RemoveVetoButton()
end

-- Fix the bug where the "correct" exit always appears in the I AM ERROR room in custom challenges (1/2)
function SpeedrunPostNewRoom:Womb2Error()
  -- Local variables
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"
  local gridSize = g.r:GetGridSize()

  if stage ~= LevelStage.STAGE4_2 then -- 8
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
          g.g:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, pos, g.zeroVector, nil, 0, 0)
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
      challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)") and
      challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)")) or
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
      challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)") and
      challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)")) or
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

-- In instant-start seasons, prevent people from resetting for a Mini-Boss Room
function SpeedrunPostNewRoom:CheckMiniBossRoom()
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()
  local challenge = Isaac.GetChallenge()

  if (challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 4)") and
      challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)") and
      challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)")) or
     Speedrun.charNum ~= 1 or
     stage ~= 1 or
     roomType ~= RoomType.ROOM_MINIBOSS then -- 6

    return
  end

  if g.r:IsFirstVisit() then
    -- On the first visit to a Sacrifice Room, give a sign to the player that the spikes were intentionally deleted
    -- Note that the spikes need to be deleted every time we enter the room, as they will respawn once the player leaves
    g.p:AnimateSad()
  end
  for _, entity in ipairs(Isaac.GetRoomEntities()) do
    if entity:ToNPC() ~= nil then
      entity:Remove()
    end
  end
  g.r:SetClear(true)
  Isaac.DebugString("Deleted the mini-boss room (during a no-reset run).")
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
  if (challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)") and
      challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)")) or
     stage ~= 1 or
     roomIndex ~= startingRoomIndex or
     g.run.roomsEntered == 1 then

    return
  end

  g.r:RemoveGridEntity(117, 0, false)
end

return SpeedrunPostNewRoom

local SpeedrunPostNewRoom = {}

-- Includes
local g= require("racing_plus/globals")
local Speedrun = require("racing_plus/speedrun")
local Season3 = require("racing_plus/season3")
local Season6 = require("racing_plus/season6")
local Season7 = require("racing_plus/season7")

function SpeedrunPostNewRoom:Main()
  if not Speedrun:InSpeedrun() then
    return
  end

  if RacingPlusData == nil then
    return
  end

  SpeedrunPostNewRoom:Stage8IAMERROR()
  Season3:PostNewRoom()
  SpeedrunPostNewRoom:CheckCurseRoom() -- Season 4 and 6
  SpeedrunPostNewRoom:CheckSacrificeRoom() -- Season 4 and 6
  Season6:PostNewRoom()
  Season7:PostNewRoom()
end

-- Fix the bug where the "correct" exit always appears in the I AM ERROR room in custom challenges
-- (1/2)
function SpeedrunPostNewRoom:Stage8IAMERROR()
  -- Local variables
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()
  local roomSeed = g.r:GetSpawnSeed()
  local gridSize = g.r:GetGridSize()

  if stage ~= 8 or roomType ~= RoomType.ROOM_ERROR then -- 3
    return
  end

  -- Find out whether we should spawn a passage up or down, depending on the room seed
  math.randomseed(roomSeed)
  local direction = math.random(1, 2)
  if direction == 1 then -- Up
    Isaac.DebugString("Randomly decided that the I AM ERROR room direction should be up.")
  elseif direction == 2 then -- Down
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

          -- Spawn a Heaven Door (it will get replaced with the fast-travel version on this frame)
          -- Make the spawner entity the player so that we can distinguish it from the vanilla
          -- heaven door
          Isaac.Spawn(
            EntityType.ENTITY_EFFECT, -- 1000
            EffectVariant.HEAVEN_LIGHT_DOOR, -- 39
            0,
            pos,
            g.zeroVector,
            g.p
          )
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
  local lightDoors = Isaac.FindByType(
    EntityType.ENTITY_EFFECT, -- 1000
    EffectVariant.HEAVEN_LIGHT_DOOR, -- 39
    -1,
    false,
    false
  )
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

-- In instant-start seasons, prevent people from resetting for a Curse Room
function SpeedrunPostNewRoom:CheckCurseRoom()
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()
  local challenge = Isaac.GetChallenge()

  if (
    (
      challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 4)")
      and challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)")
    )
    or Speedrun.charNum ~= 1
    or stage ~= 1
    or roomType ~= RoomType.ROOM_CURSE -- 10
    or not g.r:IsFirstVisit()
  ) then
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

  if (
    (
      challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 4)")
      and challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)")
    )
    or Speedrun.charNum ~= 1
    or stage ~= 1
    or roomType ~= RoomType.ROOM_SACRIFICE -- 13
  ) then
    return
  end

  if g.r:IsFirstVisit() then
    -- On the first visit to a Sacrifice Room,
    -- give a sign to the player that the spikes were intentionally deleted
    -- Note that the spikes need to be deleted every time we enter the room,
    -- as they will respawn once the player leaves
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

return SpeedrunPostNewRoom

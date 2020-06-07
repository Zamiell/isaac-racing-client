local Race = {}

-- Includes
local g          = require("racing_plus/globals")
local Sprites    = require("racing_plus/sprites")
local FastTravel = require("racing_plus/fasttravel")

-- Called from the PostUpdate callback (the "CheckEntities:EntityRaceTrophy()" function)
function Race:Finish()
  -- Local variables
  local stage = g.l:GetStage()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end

  -- Finish the race
  g.raceVars.finished = true
  g.raceVars.finishedTime = Isaac.GetTime() - g.raceVars.startedTime
  g.raceVars.finishedFrames = Isaac.GetFrameCount() - g.raceVars.startedFrame
  g.run.endOfRunText = true -- Show the run summary

  -- Tell the client that the goal was achieved (and the race length)
  Isaac.DebugString("Finished race " .. tostring(g.race.raceID) ..
                    " with time: " .. tostring(g.raceVars.finishedTime))

  if stage == 11 then
    -- Spawn a button for the DPS feature
    local pos1 = g:GridToPos(1, 1)
    if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then
      pos1 = g:GridToPos(1, 6) -- A Y of 1 is out of bounds inside of the Mega Satan room
    end
    g.run.buttons[#g.run.buttons + 1] = {
      type      = "dps",
      pos       = pos1,
      roomIndex = roomIndex,
    }
    Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, g.run.buttons[#g.run.buttons].pos, true) -- 20
    Sprites:Init("dps-button", "dps-button")

    -- Spawn a button for the Victory Lap feature
    local pos2 = g:GridToPos(11, 1)
    if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then
      pos2 = g:GridToPos(11, 6) -- A Y of 1 is out of bounds inside of the Mega Satan room
    end
    g.run.buttons[#g.run.buttons + 1] = {
      type      = "victory-lap",
      pos       = pos2,
      roomIndex = roomIndex,
    }
    Isaac.GridSpawn(GridEntityType.GRID_PRESSURE_PLATE, 0, g.run.buttons[#g.run.buttons].pos, true) -- 20
    Sprites:Init("victory-lap-button", "victory-lap-button")
  end

  Isaac.DebugString("Spawned a Victory Lap / Finished in the corners of the room.")
end

function Race:VictoryLap()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()

  -- Remove the final place graphic if it is showing
  Sprites:Init("place2", 0)

  -- Make them float upwards
  -- (the code is loosely copied from the "FastTravel:CheckTrapdoorEnter()" function)
  g.run.trapdoor.state = FastTravel.state.PLAYER_ANIMATION
  g.run.trapdoor.upwards = true
  g.run.trapdoor.frame = gameFrameCount + 16
  g.p.ControlsEnabled = false
  g.p.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE -- 0
  -- (this is necessary so that enemy attacks don't move the player while they are doing the jumping animation)
  g.p.Velocity = g.zeroVector -- Remove all of the player's momentum
  g.p:PlayExtraAnimation("LightTravel")
  g.run.currentFloor = g.run.currentFloor - 1
  -- This is needed or else state 5 will not correctly trigger
  -- (because the PostNewRoom callback will occur 3 times instead of 2)
  g.raceVars.victoryLaps = g.raceVars.victoryLaps + 1
end

return Race
local RPSaveDat = {}

--
-- Includes
--

local json      = require("json")
local RPGlobals = require("src/rpglobals")
local RPSprites = require("src/rpsprites")

--
-- Variables
--

RPSaveDat.failedCounter = 0

--
-- Functions
--

-- Read the "save.dat" file for updates from the Racing+ client
function RPSaveDat:Load()
  -- Local variables
  local isaacFrameCount = Isaac.GetFrameCount()

  if RPGlobals.raceVars.loadOnNextFrame or -- We need to check on the first frame of the run
     (RPGlobals.race.status == "starting" and isaacFrameCount & 1 == 0) or
     -- (this is the same as "isaacFrameCount % 2 == 0", but runs 20% faster)
     -- We want to check for updates on every other frame if the race is starting so that the countdown is smooth
     isaacFrameCount % 30 == 0 then
     -- Otherwise, only check for updates every half second, since file reads are expensive

    -- Check to see if there a "save.dat" file for this save slot
    if Isaac.HasModData(RPGlobals.RacingPlus) == false then
      Isaac.DebugString("The \"save.dat\" file does not exist for this save slot. Writing defaults.")
      RPSaveDat:Save()
      return
    end

    -- Mark that we have loaded on this frame
    RPGlobals.raceVars.loadOnNextFrame = false

    -- Make a backup in case loading fails
    local oldRace = RPGlobals.race

    -- The server will write JSON data for us to the "save#.dat" file in the mod subdirectory
    local function loadJSON()
      RPGlobals.race = json.decode(Isaac.LoadModData(RPGlobals.RacingPlus))
    end
    if pcall(loadJSON) == false then
      -- Sometimes loading can fail if the file is currently being being written to,
      -- so give up for now and try again on the next frame
      RPGlobals.raceVars.loadOnNextFrame = true
      RPGlobals.race = oldRace -- Restore the backup
      RPSaveDat.failedCounter = RPSaveDat.failedCounter + 1
      if RPSaveDat.failedCounter >= 100 then
        Isaac.DebugString("Loading the \"save.dat\" file failed 100 times in a row. Writing defaults.")
        RPSaveDat:Save()
      else
        Isaac.DebugString("Loading the \"save.dat\" file failed. Trying again on the next frame...")
      end
      return
    end

    -- Loading succeeded
    RPSaveDat.failedCounter = 0

    -- If anything changed, write it to the log
    if oldRace.status ~= RPGlobals.race.status then
      Isaac.DebugString("ModData status changed: " .. RPGlobals.race.status)
      RPSaveDat:ChangedStatus()
    end
    if oldRace.myStatus ~= RPGlobals.race.myStatus then
      Isaac.DebugString("ModData myStatus changed: " .. RPGlobals.race.myStatus)
      RPSaveDat:ChangedMyStatus()
    end
    if oldRace.rType ~= RPGlobals.race.rType then
      Isaac.DebugString("ModData rType changed: " .. RPGlobals.race.rType)
    end
    if oldRace.rFormat ~= RPGlobals.race.rFormat then
      Isaac.DebugString("ModData rFormat changed: " .. RPGlobals.race.rFormat)
      RPSaveDat:ChangedFormat()
    end
    if oldRace.character ~= RPGlobals.race.character then
      Isaac.DebugString("ModData character changed: " .. RPGlobals.race.character)
    end
    if oldRace.goal ~= RPGlobals.race.goal then
      Isaac.DebugString("ModData goal changed: " .. RPGlobals.race.goal)
    end
    if oldRace.seed ~= RPGlobals.race.seed then
      Isaac.DebugString("ModData seed changed: " .. RPGlobals.race.seed)
    end
    if RPGlobals:TableEqual(oldRace.startingItems, RPGlobals.race.startingItems) == false then
      Isaac.DebugString("ModData startingItems amount changed: " .. tostring(#RPGlobals.race.startingItems))
    end
    if oldRace.countdown ~= RPGlobals.race.countdown then
      Isaac.DebugString("ModData countdown changed: " .. tostring(RPGlobals.race.countdown))
    end
    if oldRace.placeMid ~= RPGlobals.race.placeMid then
      Isaac.DebugString("ModData placeMid changed: " .. tostring(RPGlobals.race.placeMid))
    end
    if oldRace.place ~= RPGlobals.race.place then
      Isaac.DebugString("ModData place changed: " .. tostring(RPGlobals.race.place))
      RPSaveDat:ChangedPlace()
    end
    if RPGlobals:TableEqual(oldRace.order9, RPGlobals.race.order9) == false then
      Isaac.DebugString("ModData order9 changed.")
      RPSaveDat:ChangedOrder9()
    end
    if RPGlobals:TableEqual(oldRace.order14, RPGlobals.race.order14) == false then
      Isaac.DebugString("ModData order14 changed.")
      RPSaveDat:ChangedOrder9()
    end
  end
end

function RPSaveDat:Save()
  Isaac.SaveModData(RPGlobals.RacingPlus, json.encode(RPGlobals.race))
  Isaac.DebugString("Wrote to the \"save.dat\" file. (SaveModData)")
end

function RPSaveDat:ChangedStatus()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local isaacFrameCount = Isaac.GetFrameCount()

  if RPGlobals.race.status == "open" then
    if stage == 1 and roomIndex == level:GetStartingRoomIndex() then
      -- Doing a "restart" won't work if we are just starting a run, so mark to reset on the next frame
      RPGlobals.run.restartFrame = isaacFrameCount + 1
    else
      -- We are in the middle of a run, so don't go to the Race Room until a reset occurs
      RPGlobals.raceVars.started = false
      RPGlobals.raceVars.startedTime = 0
      if RPGlobals.race.myStatus == "not ready" then
        RPSprites:Init("place", "pre1")
      elseif RPGlobals.race.myStatus == "ready" then
        RPSprites:Init("place", "pre2")
      end
      RPGlobals.showPlaceGraphic = true
    end

  elseif RPGlobals.race.status == "starting" then
    -- Remove the final place graphic, if present
    RPSprites:Init("place2", 0)

  elseif RPGlobals.race.status == "in progress" or
         (RPGlobals.race.status == "none" and
          roomIndex == GridRooms.ROOM_DEBUG_IDX) then -- -3

    -- Doing a "restart" won't work if we are just starting a run, so mark to reset on the next frame
    RPGlobals.run.restartFrame = isaacFrameCount + 1
  end
end

function RPSaveDat:ChangedMyStatus()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end

  if (RPGlobals.race.status == "open" or
      RPGlobals.race.status == "starting") and
     RPGlobals.race.myStatus == "not ready" and
     roomIndex ~= GridRooms.ROOM_DEBUG_IDX then -- -3

    RPSprites:Init("place", "pre1")

  elseif (RPGlobals.race.status == "open" or
          RPGlobals.race.status == "starting") and
         RPGlobals.race.myStatus == "ready" and
         roomIndex ~= GridRooms.ROOM_DEBUG_IDX then -- -3

    RPSprites:Init("place", "pre2")
  end
end

function RPSaveDat:ChangedFormat()
  -- Local variables
  local isaacFrameCount = Isaac.GetFrameCount()

  if RPGlobals.race.rFormat == "pageant" then
    -- For Pageant Boy, fix the bug where it is not loaded on the first run
    -- Doing a "restart" won't work since we are just starting a run, so mark to reset on the next frame
    RPGlobals.run.restartFrame = isaacFrameCount + 1
  end
end

function RPSaveDat:ChangedPlace()
  if RPGlobals.raceVars.finished then
    -- Show a big graphic at the top of the screen with our final place
    -- (the client won't send a new place for solo races)
    RPSprites:Init("place2", tostring(RPGlobals.race.place))

    -- Also, update the place graphic on the left by the R+ icon with our final place
    RPSprites:Init("place", tostring(RPGlobals.race.place))
  end
end

function RPSaveDat:ChangedOrder9()
  -- Local variables
  local isaacFrameCount = Isaac.GetFrameCount()
  local challenge = Isaac.GetChallenge()

  if challenge ~= Challenge.CHALLENGE_NULL then -- 0
    -- Doing a "restart" won't work if we are just starting a run, so mark to reset on the next frame
    RPGlobals.run.restartFrame = isaacFrameCount + 1
  end
end

function RPSaveDat:ChangedOrder14()
  -- Local variables
  local isaacFrameCount = Isaac.GetFrameCount()
  local challenge = Isaac.GetChallenge()

  if challenge ~= Challenge.CHALLENGE_NULL then -- 0
    -- Doing a "restart" won't work if we are just starting a run, so mark to reset on the next frame
    RPGlobals.run.restartFrame = isaacFrameCount + 1
  end
end

return RPSaveDat

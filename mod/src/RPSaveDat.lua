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
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local isaacFrameCount = Isaac.GetFrameCount()
  local challenge = Isaac.GetChallenge()

  if RPGlobals.raceVars.loadOnNextFrame or -- We need to check on the first frame of the run
     (RPGlobals.race.status == "starting" and isaacFrameCount & 1 == 0) or
     -- (this is the same as "isaacFrameCount % 2 == 0", but runs 20% faster)
     -- We want to check for updates on every other frame if the race is starting so that the countdown is smooth
     isaacFrameCount % 30 == 0 then
     -- Otherwise, only check for updates every half second, since file reads are expensive

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

      if RPGlobals.race.status == "open" then
        if stage == 1 and roomIndex == level:GetStartingRoomIndex() then
          -- Doing a "restart" won't work if we are just starting a run, so mark to reset on the next frame
          RPGlobals.run.restartFrame = Isaac.GetFrameCount() + 1
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
      elseif RPGlobals.race.status == "in progress" or
             (RPGlobals.race.status == "none" and
              roomIndex == GridRooms.ROOM_DEBUG_IDX) then -- -3

        -- Doing a "restart" won't work if we are just starting a run, so mark to reset on the next frame
        RPGlobals.run.restartFrame = Isaac.GetFrameCount() + 1
      end
    end
    if oldRace.myStatus ~= RPGlobals.race.myStatus then
      Isaac.DebugString("ModData myStatus changed: " .. RPGlobals.race.myStatus)
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
    if oldRace.rType ~= RPGlobals.race.rType then
      Isaac.DebugString("ModData rType changed: " .. RPGlobals.race.rType)
    end
    if oldRace.rFormat ~= RPGlobals.race.rFormat then
      Isaac.DebugString("ModData rFormat changed: " .. RPGlobals.race.rFormat)
      if RPGlobals.race.rFormat == "pageant" then
        -- For Pageant Boy, fix the bug where it is not loaded on the first run
        -- Doing a "restart" won't work since we are just starting a run, so mark to reset on the next frame
        RPGlobals.run.restartFrame = Isaac.GetFrameCount() + 1
      end
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
    if #oldRace.startingItems ~= #RPGlobals.race.startingItems then
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
    end
    if oldRace.order9 ~= nil and RPGlobals.race.order9 ~= nil and
       #oldRace.order9 >= 1 and #RPGlobals.race.order9 >= 1 then

      for i = 1, #oldRace.order9 do
        if oldRace.order9[i] ~= RPGlobals.race.order9[i] then
          Isaac.DebugString("ModData order9 changed.")

          if challenge ~= Challenge.CHALLENGE_NULL then -- 0
            -- Doing a "restart" won't work if we are just starting a run, so mark to reset on the next frame
            RPGlobals.run.restartFrame = Isaac.GetFrameCount() + 1
          end

          break
        end
      end
    end
    if oldRace.order14 ~= nil and #oldRace.order14 >= 1 and
       #oldRace.order14 >= 1 and #RPGlobals.race.order14 >= 1 then

      for i = 1, #oldRace.order14 do
        if oldRace.order14[i] ~= RPGlobals.race.order14[i] then
          Isaac.DebugString("ModData order14 changed.")

          if challenge ~= Challenge.CHALLENGE_NULL then -- 0
            -- Doing a "restart" won't work if we are just starting a run, so mark to reset on the next frame
            RPGlobals.run.restartFrame = Isaac.GetFrameCount() + 1
          end

          break
        end
      end
    end
  end
end

function RPSaveDat:Save()
  Isaac.SaveModData(RPGlobals.RacingPlus, json.encode(RPGlobals.race))
  Isaac.DebugString("Wrote to the \"save.dat\" file. (SaveModData)")
end

return RPSaveDat

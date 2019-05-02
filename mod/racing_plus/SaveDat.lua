local SaveDat = {}

-- Includes
local json    = require("json")
local g       = require("racing_plus/globals")
local Sprites = require("racing_plus/sprites")

-- Variables
SaveDat.failedCounter = 0

-- Read the "save.dat" file for updates from the Racing+ client
function SaveDat:Load()
  -- Local variables
  local isaacFrameCount = Isaac.GetFrameCount()

  if g.raceVars.loadOnNextFrame or -- We need to check on the first frame of the run
     (g.race.status == "starting" and isaacFrameCount & 1 == 0) or
     -- (this is the same as "isaacFrameCount % 2 == 0", but runs 20% faster)
     -- We want to check for updates on every other frame if the race is starting so that the countdown is smooth
     isaacFrameCount % 30 == 0 then
     -- Otherwise, only check for updates every half second, since file reads are expensive

    -- Check to see if there a "save.dat" file for this save slot
    if not Isaac.HasModData(g.RacingPlus) then
      Isaac.DebugString("The \"save.dat\" file does not exist for this save slot. Writing defaults.")
      SaveDat:Save()
      return
    end

    -- Mark that we have loaded on this frame
    g.raceVars.loadOnNextFrame = false

    -- Make a backup in case loading fails (see below)
    local oldRace = g.race

    -- The server will write JSON data for us to the "save#.dat" file in the mod subdirectory
    local function loadJSON()
      g.race = json.decode(Isaac.LoadModData(g.RacingPlus))
    end
    if not pcall(loadJSON) then
      -- Sometimes loading can fail if the file is currently being being written to,
      -- so give up for now and try again on the next frame
      g.raceVars.loadOnNextFrame = true
      g.race = oldRace -- Restore the backup
      SaveDat.failedCounter = SaveDat.failedCounter + 1
      if SaveDat.failedCounter >= 100 then
        Isaac.DebugString("Loading the \"save.dat\" file failed 100 times in a row. Writing defaults.")
        SaveDat:Save()
      else
        Isaac.DebugString("Loading the \"save.dat\" file failed. Trying again on the next frame...")
      end
      return
    end

    -- Loading succeeded
    SaveDat.failedCounter = 0

    -- If anything changed, write it to the log
    if oldRace.status ~= g.race.status then
      Isaac.DebugString("ModData status changed: " .. g.race.status)
      SaveDat:ChangedStatus()
    end
    if oldRace.myStatus ~= g.race.myStatus then
      Isaac.DebugString("ModData myStatus changed: " .. g.race.myStatus)
      SaveDat:ChangedMyStatus()
    end
    if oldRace.ranked ~= g.race.ranked then
      Isaac.DebugString("ModData ranked changed: " .. tostring(g.race.ranked))
    end
    if oldRace.rFormat ~= g.race.rFormat then
      Isaac.DebugString("ModData rFormat changed: " .. g.race.rFormat)
      SaveDat:ChangedFormat()
    end
    if oldRace.character ~= g.race.character then
      Isaac.DebugString("ModData character changed: " .. g.race.character)
    end
    if oldRace.goal ~= g.race.goal then
      Isaac.DebugString("ModData goal changed: " .. g.race.goal)
    end
    if oldRace.seed ~= g.race.seed then
      Isaac.DebugString("ModData seed changed: " .. g.race.seed)
    end
    if not g:TableEqual(oldRace.startingItems, g.race.startingItems) then
      Isaac.DebugString("ModData startingItems changed: " .. g:TableToString(g.race.startingItems))
    end
    if oldRace.countdown ~= g.race.countdown then
      Isaac.DebugString("ModData countdown changed: " .. tostring(g.race.countdown))
    end
    if oldRace.placeMid ~= g.race.placeMid then
      Isaac.DebugString("ModData placeMid changed: " .. tostring(g.race.placeMid))
    end
    if oldRace.place ~= g.race.place then
      Isaac.DebugString("ModData place changed: " .. tostring(g.race.place))
      SaveDat:ChangedPlace()
    end
    if not g:TableEqual(oldRace.charOrder, g.race.charOrder) then
      Isaac.DebugString("ModData charOrder changed.")
      SaveDat:ChangedOrder()
    end
    if oldRace.hotkeyDrop ~= g.race.hotkeyDrop then
      Isaac.DebugString("ModData hotkeyDrop changed: " .. tostring(g.race.hotkeyDrop))
    end
    if oldRace.hotkeyDropTrinket ~= g.race.hotkeyDropTrinket then
      Isaac.DebugString("ModData hotkeyDropTrinket changed: " .. tostring(g.race.hotkeyDropTrinket))
    end
    if oldRace.hotkeyDropPocket ~= g.race.hotkeyDropPocket then
      Isaac.DebugString("ModData hotkeyDropPocket changed: " .. tostring(g.race.hotkeyDropPocket))
    end
    if oldRace.hotkeySwitch ~= g.race.hotkeySwitch then
      Isaac.DebugString("ModData hotkeyDrop changed: " .. tostring(g.race.hotkeySwitch))
    end
  end
end

function SaveDat:Save()
  Isaac.SaveModData(g.RacingPlus, json.encode(g.race))
  Isaac.DebugString("Wrote to the \"save.dat\" file. (SaveModData)")
end

function SaveDat:ChangedStatus()
  -- Local variables
  local stage = g.l:GetStage()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end

  if g.race.status == "open" then
    if stage == 1 and roomIndex == g.l:GetStartingRoomIndex() then
      -- Doing a "restart" won't work if we are just starting a run, so mark to reset on the next frame
      g.run.restart = true
    else
      -- We are in the middle of a run, so don't go to the Race Room until a reset occurs
      g.raceVars.started = false
      g.raceVars.startedTime = 0
      if g.race.myStatus == "not ready" then
        Sprites:Init("place", "pre1")
      elseif g.race.myStatus == "ready" then
        Sprites:Init("place", "pre2")
      end
      g.showPlaceGraphic = true
    end

  elseif g.race.status == "starting" then
    -- Remove the final place graphic, if present
    Sprites:Init("place2", 0)

  elseif g.race.status == "in progress" or
         (g.race.status == "none" and
          roomIndex == GridRooms.ROOM_DEBUG_IDX) then -- -3

    -- Doing a "restart" won't work if we are just starting a run, so mark to reset on the next frame
    g.run.restart = true
  end
end

function SaveDat:ChangedMyStatus()
  -- Local variables
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end

  if (g.race.status == "open" or
      g.race.status == "starting") and
     g.race.myStatus == "not ready" and
     roomIndex ~= GridRooms.ROOM_DEBUG_IDX then -- -3

    Sprites:Init("place", "pre1")

  elseif (g.race.status == "open" or
          g.race.status == "starting") and
         g.race.myStatus == "ready" and
         roomIndex ~= GridRooms.ROOM_DEBUG_IDX then -- -3

    Sprites:Init("place", "pre2")
  end
end

function SaveDat:ChangedFormat()
  if g.race.rFormat == "pageant" then
    -- For special rulesets, fix the bug where it is not loaded on the first run
    -- Doing a "restart" won't work since we are just starting a run, so mark to reset on the next frame
    g.run.restart = true
  end
end

function SaveDat:ChangedPlace()
  if g.raceVars.finished then
    -- Show a big graphic at the top of the screen with our final place
    -- (the client won't send a new place for solo races)
    Sprites:Init("place2", tostring(g.race.place))

    -- Also, update the place graphic on the left by the R+ icon with our final place
    Sprites:Init("place", tostring(g.race.place))
  end
end

function SaveDat:ChangedOrder()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Challenge.CHALLENGE_NULL and -- 0
     challenge ~= Isaac.GetChallengeIdByName("Change Char Order") then

    -- Doing a "restart" won't work if we are just starting a run, so mark to reset on the next frame
    g.run.restart = true
  end
end

return SaveDat

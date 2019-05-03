local UsePill = {}

-- Includes
local g       = require("racing_plus/globals")
local Pills   = require("racing_plus/pills")

-- ModCallbacks.MC_USE_PILL (10)
-- Will get called for all pills
function UsePill:Main(pillEffect)
  -- Display the streak text (because Racing+ removes the vanilla streak text)
  g.run.streakText = Pills.effects[pillEffect]
  g.run.streakFrame = Isaac.GetFrameCount()

  -- Don't add any more pills after 7, since it won't display cleanly
  if #g.run.pills >= 7 then
    return
  end

  -- See if we have already used this particular pill color on this run
  local pillColor = g.p:GetPill(0)
  if pillColor == PillColor.PILL_NULL then -- 0
    -- A separate mod may have manually used a pill with a null color
    return
  end
  for _, pill in ipairs(g.run.pills) do
    if pill.color == pillColor then
      return
    end
  end

  -- This is the first time we have used this pill, so keep track of the pill color and effect
  local pillEntry = {
    color  = pillColor,
    effect = pillEffect,
    sprite = Sprite()
  }

  -- Preload the graphics for this pill color so that we can display it if the player presses tab
  pillEntry.sprite:Load("gfx/pills/pill" .. pillColor .. ".anm2", true)
  pillEntry.sprite:SetFrame("Default", 0)
  g.run.pills[#g.run.pills + 1] = pillEntry
end

function UsePill:HealthUp()
  g.run.keeper.usedHealthUpPill = true
  g.p:AddCacheFlags(CacheFlag.CACHE_RANGE) -- 8
  g.p:EvaluateItems()
  -- We check to see if we are Keeper, have Greed's Gullet, and are at maximum hearts inside this function
end

function UsePill:Telepills()
  -- Local variables
  local stage = g.l:GetStage()
  local rooms = g.l:GetRooms()

  -- It is not possible to teleport to I AM ERROR rooms and Black Markets on The Chest / Dark Room
  local insertErrorRoom = false
  local insertBlackMarket = false
  if stage ~= 11 then
    insertErrorRoom = true

    -- There is a 2% chance have a Black Market inserted into the list of possibilities (according to blcd)
    g.RNGCounter.Telepills = g:IncrementRNG(g.RNGCounter.Telepills)
    math.randomseed(g.RNGCounter.Telepills)
    local blackMarketRoll = math.random(1, 100) -- Item room, secret room, super secret room, I AM ERROR room
    if blackMarketRoll <= 2 then
      insertBlackMarket = true
    end
  end

  -- Find the indexes for all of the room possibilities
  local roomIndexes = {}
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local gridIndex = rooms:Get(i).SafeGridIndex
    -- We need to use SafeGridIndex instead of GridIndex because we will crash when teleporting to L rooms otherwise
    roomIndexes[#roomIndexes + 1] = gridIndex
  end
  if insertErrorRoom then
    roomIndexes[#roomIndexes + 1] = GridRooms.ROOM_ERROR_IDX -- -2
  end
  if insertBlackMarket then
    roomIndexes[#roomIndexes + 1] = GridRooms.ROOM_BLACK_MARKET_IDX -- -6
  end

  -- Get a random room index
  g.RNGCounter.Telepills = g:IncrementRNG(g.RNGCounter.Telepills)
  math.randomseed(g.RNGCounter.Telepills)
  local gridIndex = roomIndexes[math.random(1, #roomIndexes)]

  -- Teleport
  g.run.naturalTeleport = true -- Mark that this is not a Cursed Eye teleport
  g.l.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
  g.g:StartRoomTransition(gridIndex, Direction.NO_DIRECTION, g.RoomTransition.TRANSITION_TELEPORT)

  -- We don't want to display the "use" animation, we just want to instantly teleport
  -- Pills are hard coded to queue the "use" animation, so stop it on the next frame
  g.run.usedTelepills = true
end

return UsePill

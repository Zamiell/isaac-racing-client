local RPSprites = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")

--
-- Sprite functions
--

-- Call this once to load the PNG from the anm2 file
function RPSprites:Init(spriteType, spriteName)
  -- If this is a new sprite type, initialize it in the sprite table
  if RPGlobals.spriteTable[spriteType] == nil then
    RPGlobals.spriteTable[spriteType] = {}
  end

  -- Do nothing if this sprite type is already set to this name
  if RPGlobals.spriteTable[spriteType].spriteName == spriteName then
    return
  end

  -- Check to see if we are clearing this sprite
  if spriteName == 0 then
    RPGlobals.spriteTable[spriteType].sprite = nil
    RPGlobals.spriteTable[spriteType].spriteName = 0
    return
  end

  -- Otherwise, initialize the sprite
  RPGlobals.spriteTable[spriteType].spriteName = spriteName
  RPGlobals.spriteTable[spriteType].sprite = Sprite()

  if spriteType == "stage" then
    RPGlobals.spriteTable[spriteType].sprite:Load("gfx/stage/" .. spriteName .. ".anm2", true)

  elseif spriteType == "speedrun-char1" or
         spriteType == "speedrun-slash" or
         spriteType == "speedrun-char2" then

    RPGlobals.spriteTable[spriteType].sprite:Load("gfx/timer/" .. spriteName .. ".anm2", true)

  elseif spriteType == "seeded-item1" or
         spriteType == "seeded-item2" or
         spriteType == "seeded-item3" or
         spriteType == "seeded-item4" or
         spriteType == "seeded-item5" or
         spriteType == "diversity-item1" or
         spriteType == "diversity-item2" or
         spriteType == "diversity-item3" or
         spriteType == "diversity-item4" then

    RPGlobals.spriteTable[spriteType].sprite:Load("gfx/items3/collectibles/" .. spriteName .. ".anm2", true)

  elseif spriteType == "diversity-item5" then
    RPGlobals.spriteTable[spriteType].sprite:Load("gfx/items3/trinkets/" .. spriteName .. ".anm2", true)

  elseif spriteType == "ready" or spriteType == "readyTotal" then
    if tonumber(spriteName) > 50 then
      RPGlobals.spriteTable[spriteType].sprite:Load("gfx/race/ready/unknown.anm2", true)
    else
      RPGlobals.spriteTable[spriteType].sprite:Load("gfx/race/ready/" .. spriteName .. ".anm2", true)
    end

  elseif spriteType == "place" then
    if spriteName == "pre" or tonumber(spriteName) <= 16 then
      RPGlobals.spriteTable[spriteType].sprite:Load("gfx/race/place/" .. spriteName .. ".anm2", true)
    else
      Isaac.DebugString("Places beyond 16 are not supported.")
    end

  elseif spriteType == "timerClock" or
         spriteType == "timer1" or
         spriteType == "timer2" or
         spriteType == "timerColon" or
         spriteType == "timer3" or
         spriteType == "timer4" or
         spriteType == "timer6" or
         spriteType == "timerColon2" then

    RPGlobals.spriteTable[spriteType].sprite:Load("gfx/timer/" .. spriteName .. ".anm2", true)

  elseif spriteType == "timer5" then
    RPGlobals.spriteTable[spriteType].sprite:Load("gfx/timer/mini/" .. spriteName .. ".anm2", true)

  else
    RPGlobals.spriteTable[spriteType].sprite:Load("gfx/race/" .. spriteName .. ".anm2", true)
  end

  -- For some sprites, we want to queue an animation
  if spriteType == "stage" then
    RPGlobals.spriteTable[spriteType].sprite:Play("TextIn", true)
  else
    -- For non-animations, we just want to set frame 0
    RPGlobals.spriteTable[spriteType].sprite:SetFrame("Default", 0)
  end
end

-- Call this every frame in MC_POST_RENDER
function RPSprites:Display()
  -- Loop through all the sprites and render them
  for k, v in pairs(RPGlobals.spriteTable) do
    -- Position it
    local vec = RPSprites:GetScreenCenterPosition() -- Start the vector off in the center of the screen by default

    -- Type stuff
    local typeFormatX = 110
    local typeFormatY = 10

    -- Timer stuff
    local timerSpace = 7.25
    local timerHourAdjust = 2
    local timerHourAdjust2 = 0
    local timerX = 19
    if RPGlobals.spriteTable.timer6 ~= nil and RPGlobals.spriteTable.timer6.spriteName ~= 0 then
      timerHourAdjust2 = 2
      timerX = timerX + timerSpace + timerHourAdjust
    end
    local timerY = 217

    -- Speedrun stuff
    local speedrunX = 23
    local speedrunY = 79
    local speedrunAdjust = 0
    if RPGlobals.speedrun.charNum > 9 then
      speedrunAdjust = timerSpace
    end

    -- Position all the sprites
    if k == "stage" then -- The name of the floor when we get to a new floor
      vec.Y = vec.Y - 85
    elseif k == "speedrun9-1" then -- "1 / 9"
      vec.X = speedrunX
      vec.Y = speedrunX
    elseif k == "speedrun9-slash" then -- "1 / 9"
      vec.X = 23
      vec.Y = 79
    elseif k == "speedrun-char2" then -- "1 / 9"
      vec.X = 23
      vec.Y = 79
    elseif k == "top" then -- Pre-race messages and the countdown
      vec.Y = vec.Y - 80
    elseif k == "myStatus" then
      vec.Y = vec.Y - 40
    elseif k == "raceType" then
      vec.X = vec.X - typeFormatX
      vec.Y = vec.Y + typeFormatY
    elseif k == "raceTypeIcon" then
      vec.X = vec.X - typeFormatX
      vec.Y = vec.Y + typeFormatY + 23
    elseif k == "raceFormat" then
      vec.X = vec.X + typeFormatX
      vec.Y = vec.Y + typeFormatY
    elseif k == "raceFormatIcon" then
      vec.X = vec.X + typeFormatX
      vec.Y = vec.Y + typeFormatY + 23
    elseif k == "ready" then
      vec.X = vec.X - 20
      vec.Y = vec.Y - 15
    elseif k == "slash" then
      vec.Y = vec.Y - 15
    elseif k == "readyTotal" then
      vec.X = vec.X + 20
      vec.Y = vec.Y - 15
    elseif k == "goal" then
      vec.X = vec.X - 25
      vec.Y = vec.Y + 95
    elseif k == "raceGoal" then
      vec.X = vec.X + 25
      vec.Y = vec.Y + 95
    elseif k == "seeded-starting-item" then
      vec.Y = vec.Y - 40
    elseif k == "seeded-starting-build" then
      vec.Y = vec.Y - 40
    elseif k == "seeded-item1" then
      vec.Y = vec.Y - 10
    elseif k == "seeded-item2" then
      vec.X = vec.X - 15
      vec.Y = vec.Y - 10
    elseif k == "seeded-item3" then
      vec.X = vec.X + 15
      vec.Y = vec.Y - 10
    elseif k == "seeded-item4" then
      vec.X = vec.X - 45
      vec.Y = vec.Y - 10
    elseif k == "seeded-item5" then
      vec.X = vec.X + 45
      vec.Y = vec.Y - 10
    elseif k == "diversity-active" then
      vec.X = vec.X - 80
      vec.Y = vec.Y - 40
    elseif k == "diversity-passives" then
      vec.Y = vec.Y - 40
    elseif k == "diversity-trinket" then
      vec.X = vec.X + 80
      vec.Y = vec.Y - 40
    elseif k == "diversity-item1" then -- The active item
      vec.X = vec.X - 80
      vec.Y = vec.Y - 10
    elseif k == "diversity-item2" then -- The 1st passive item
      vec.X = vec.X - 30
      vec.Y = vec.Y - 10
    elseif k == "diversity-item3" then -- The 2nd passive item
      vec.Y = vec.Y - 10
    elseif k == "diversity-item4" then -- The 3rd passive item
      vec.X = vec.X + 30
      vec.Y = vec.Y - 10
    elseif k == "diversity-item5" then -- The trinket
      vec.X = vec.X + 80
      vec.Y = vec.Y - 10
    elseif k == "clock" then
      -- Move it below the Angel chance
      vec.X = 7.5
      vec.Y = 217
    elseif k == "timerClock" then
      -- Move it below the Angel chance
      vec.X = 53 -- 8
      vec.Y = 262
    elseif k == "timer1" then
      vec.X = timerX
      vec.Y = timerY
    elseif k == "timer2" then
      vec.X = timerX + timerSpace
      vec.Y = timerY
    elseif k == "timerColon" then -- This is on a different scale (100%)
      vec.X = timerX + timerSpace + 10 -- (11 is 6 pixels)
      vec.Y = timerY + 19
    elseif k == "timer3" then
      vec.X = timerX + timerSpace + 11
      vec.Y = timerY
    elseif k == "timer4" then
      vec.X = timerX + timerSpace + 11 + timerSpace + 1 - timerHourAdjust2
      vec.Y = timerY
    elseif k == "timer5" then
      vec.X = timerX + timerSpace + 11 + timerSpace + timerSpace + 1 - timerHourAdjust2
      vec.Y = timerY + 1
    elseif k == "timer6" then
      vec.X = timerX - timerSpace - timerHourAdjust
      vec.Y = timerY
    elseif k == "timerColon2" then
      vec.X = timerX - timerSpace + 7
      vec.Y = timerY + 19
    elseif k == "place" then
      -- Move it next to the "R+" icon
      vec.X = 24
      vec.Y = 79
    end

    -- Draw it
    if v.sprite ~= nil then
      if k == "stage" then
        -- For animations, we have to both "Render()" and "Update()"
        RPGlobals.spriteTable[k].sprite:Render(vec, Vector(0, 0), Vector(0, 0))
        RPGlobals.spriteTable[k].sprite:Update()
      else
        -- For non-animations, we want to just render frame 0
        RPGlobals.spriteTable[k].sprite:RenderLayer(0, vec)
      end
    end
  end
end

function RPSprites:TimerUpdate()
  -- Don't show the timer if the race has not started yet,
  -- or they quit in the middle of the race,
  -- or if they closed the game in the middle of the run and came back
  if RPGlobals.raceVars.startedTime == 0 or
     (RPGlobals.race.status == "none" and RPGlobals.raceVars.finished == false) then

    --RPSprites:Init("clock", 0)
    RPSprites:Init("timerClock", 0)
    RPSprites:Init("timer1", 0)
    RPSprites:Init("timer2", 0)
    RPSprites:Init("timerColon", 0)
    RPSprites:Init("timer3", 0)
    RPSprites:Init("timer4", 0)
    RPSprites:Init("timer5", 0)
    RPSprites:Init("timer6", 0)
    RPSprites:Init("timerColon2", 0)
    return

  else
    --RPSprites:Init("clock", "clock") -- The old clock sprite
    RPSprites:Init("timerClock", "clock")
  end

  -- Find out how much time has passed since the race started
  -- (or what the race finish time was)
  local elapsedTime
  if RPGlobals.raceVars.finished then
    elapsedTime = RPGlobals.raceVars.finishedTime - RPGlobals.raceVars.startedTime
  else
    elapsedTime = Isaac.GetTime() - RPGlobals.raceVars.startedTime
    -- "Isaac.GetTime()" is analogous to Lua's "os.clock()"
  end
  elapsedTime = elapsedTime / 1000 -- This will be in milliseconds, so we divide by 1000

  -- Show the hours
  local minutes = math.floor(elapsedTime / 60)
  if minutes >= 60 then
    local hours = math.floor(elapsedTime / 3600)
    RPSprites:Init("timer6", tostring(hours))
    RPSprites:Init("timerColon2", "colon")
    minutes = minutes - hours * 60
  end

  -- Show the minutes
  if minutes < 10 then
    minutes = "0" .. tostring(minutes)
  else
    minutes = tostring(minutes)
  end
  local minute1 = string.sub(minutes, 1, 1) -- The first character
  local minute2 = string.sub(minutes, 2, 2) -- The second character
  RPSprites:Init("timer1", tostring(minute1))
  RPSprites:Init("timer2", tostring(minute2))

  -- Show the colon
  RPSprites:Init("timerColon", "colon")

  -- Show the seconds
  local rawSeconds = elapsedTime % 60
  local seconds = math.floor(rawSeconds)
  if seconds < 10 then
    seconds = "0" .. tostring(seconds)
  else
    seconds = tostring(seconds)
  end
  local second1 = string.sub(seconds, 1, 1) -- The first character
  local second2 = string.sub(seconds, 2, 2) -- The second character
  RPSprites:Init("timer3", tostring(second1))
  RPSprites:Init("timer4", tostring(second2))

  -- Show the tenths
  local tenths = RPGlobals:Round(rawSeconds, 1) - math.floor(rawSeconds) -- This will be betwen 0.0 and 0.9
  tenths = string.sub(tostring(tenths), 3, 3)
  RPSprites:Init("timer5", tostring(tenths))

  -- The old timer (using RenderText)
  --local timerString = minute1 .. minute2 .. ":" .. second1 .. second2 .. "." .. tenths
  --Isaac.RenderText(timerString, 17, 211, 0.7, 1, 0.2, 1.0) -- X, Y, R, G, B, A
end

-- Taken from Alphabirth: https://steamcommunity.com/sharedfiles/filedetails/?id=848056541
function RPSprites:GetScreenCenterPosition()
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local centerOffset = (room:GetCenterPos()) - room:GetTopLeftPos()
  local pos = room:GetCenterPos()

  if centerOffset.X > 260 then
    pos.X = pos.X - 260
  end
  if centerOffset.Y > 140 then
    pos.Y = pos.Y - 140
  end

  return Isaac.WorldToRenderPosition(pos, false)
end

-- This clears the graphics that should only appear in the starting room
function RPSprites:ClearStartingRoomGraphicsTop()
  RPSprites:Init("myStatus", 0)
  RPSprites:Init("ready", 0)
  RPSprites:Init("slash", 0)
  RPSprites:Init("readyTotal", 0)
end

function RPSprites:ClearStartingRoomGraphicsBottom()
  RPSprites:Init("raceType", 0)
  RPSprites:Init("raceTypeIcon", 0)
  RPSprites:Init("raceFormat", 0)
  RPSprites:Init("raceFormatIcon", 0)
  RPSprites:Init("goal", 0)
  RPSprites:Init("raceGoal", 0)
end

-- This clears the graphics that appear in the starting room after the race has started
function RPSprites:ClearPostRaceStartGraphics()
  RPSprites:Init("seeded-starting-item", 0)
  RPSprites:Init("seeded-starting-build", 0)
  RPSprites:Init("seeded-item1", 0)
  RPSprites:Init("seeded-item2", 0)
  RPSprites:Init("seeded-item3", 0)
  RPSprites:Init("seeded-item4", 0)
  RPSprites:Init("seeded-item5", 0)
  RPSprites:Init("diversity-active", 0)
  RPSprites:Init("diversity-passives", 0)
  RPSprites:Init("diversity-trinket", 0)
  RPSprites:Init("diversity-item1", 0)
  RPSprites:Init("diversity-item2", 0)
  RPSprites:Init("diversity-item3", 0)
  RPSprites:Init("diversity-item4", 0)
  RPSprites:Init("diversity-item5", 0)
end

return RPSprites

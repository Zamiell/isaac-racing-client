local RPTimer = {}

--
-- Includes
--

local RPGlobals  = require("src/rpglobals")
local RPSpeedrun = require("src/rpspeedrun")

--
-- Variables
--

RPTimer.sprites = {}

--
-- Timer functions
--

function RPTimer:Display()
  -- Don't show the timer if the race has not started yet or they quit in the middle of the race
  -- (and always show the timer in a custom speedrun challenge)
  local challenge = Isaac.GetChallenge()
  if RPGlobals.raceVars.started == false and
     RPGlobals.raceVars.finished == false and
     challenge ~= Isaac.GetChallengeIdByName("R+9 Speedrun (S1)") and
     challenge ~= Isaac.GetChallengeIdByName("R+9/14 Speedrun (S1)") then

    return
  end

  -- Load the sprites
  if RPTimer.sprites.clock == nil then
    RPTimer.sprites.clock = Sprite()
    RPTimer.sprites.clock:Load("gfx/timer/clock.anm2", true)
    RPTimer.sprites.clock:SetFrame("Default", 0)

    RPTimer.sprites.colon = {}
    for i = 1, 2 do
      RPTimer.sprites.colon[i] = Sprite()
      RPTimer.sprites.colon[i]:Load("gfx/timer/colon.anm2", true)
      RPTimer.sprites.colon[i]:SetFrame("Default", 0)
    end

    RPTimer.sprites.digit = {}
    for i = 1, 5 do
      RPTimer.sprites.digit[i] = Sprite()
      RPTimer.sprites.digit[i]:Load("gfx/timer/timer.anm2", true)
      RPTimer.sprites.digit[i]:SetFrame("Default", 0)
    end

    RPTimer.sprites.digitMini = Sprite()
    RPTimer.sprites.digitMini:Load("gfx/timer/timerMini.anm2", true)
    RPTimer.sprites.digitMini:SetFrame("Default", 0)
  end

  -- Find out how much time has passed since the race started
  -- (or what the race finish time was)
  local elapsedTime
  if challenge ~= 0 then
    if RPSpeedrun.finished then
      elapsedTime = RPSpeedrun.finishedTime
    elseif RPSpeedrun.startedTime == 0 then
      elapsedTime = 0
    else
      elapsedTime = Isaac.GetTime() - RPSpeedrun.startedTime
      -- "Isaac.GetTime()" is analogous to Lua's "os.clock()"
    end
  else
    if RPGlobals.raceVars.finished then
      elapsedTime = RPGlobals.raceVars.finishedTime
    else
      elapsedTime = Isaac.GetTime() - RPGlobals.raceVars.startedTime
      -- "Isaac.GetTime()" is analogous to Lua's "os.clock()"
    end
  end
  elapsedTime = elapsedTime / 1000 -- This will be in milliseconds, so we divide by 1000

  -- Calcuate the hours digit
  local hours = math.floor(elapsedTime / 3600)

  -- Calcuate the minutes digits
  local minutes = math.floor(elapsedTime / 60)
  if hours > 0 then
    minutes = minutes - hours * 60
  end
  if minutes < 10 then
    minutes = "0" .. tostring(minutes)
  else
    minutes = tostring(minutes)
  end
  local minute1 = string.sub(minutes, 1, 1) -- The first character
  local minute2 = string.sub(minutes, 2, 2) -- The second character

  -- Calcuate the seconds digits
  local seconds = math.floor(elapsedTime % 60)
  if seconds < 10 then
    seconds = "0" .. tostring(seconds)
  else
    seconds = tostring(seconds)
  end
  local second1 = string.sub(seconds, 1, 1) -- The first character
  local second2 = string.sub(seconds, 2, 2) -- The second character

  -- Calculate the tenths digit
  local rawSeconds = elapsedTime % 60
  local tenths = RPGlobals:Round(rawSeconds, 1) - math.floor(rawSeconds) -- This will be betwen 0.0 and 0.9
  tenths = string.sub(tostring(tenths), 3, 3)

  -- Local variables
  local digitLength = 7.25
  local hourAdjustment = 2
  local hourAdjustment2 = 0
  local startingX = 19
  if hours > 0 then
    hourAdjustment2 = 2
    startingX = startingX + digitLength + hourAdjustment
  end
  local startingY = 217

  --
  -- Display the sprites
  --

  local posClock = Vector(53, 262)
  RPTimer.sprites.clock:RenderLayer(0, posClock)

  if hours > 0 then
    -- The format is "#:##:##" instead of "##:##"
    local posHours = Vector(startingX - digitLength - hourAdjustment, startingY)
    RPTimer.sprites.digit[5]:SetFrame("Default", tostring(hours))
    RPTimer.sprites.digit[5]:RenderLayer(0, posHours)

    local posColon2 = Vector(startingX - digitLength + 7, startingY + 19)
    RPTimer.sprites.colon[2]:RenderLayer(0, posColon2)
  end

  local posMinute1 = Vector(startingX, startingY)
  RPTimer.sprites.digit[1]:SetFrame("Default", minute1)
  RPTimer.sprites.digit[1]:RenderLayer(0, posMinute1)

  local posMinute2 = Vector(startingX + digitLength, startingY)
  RPTimer.sprites.digit[2]:SetFrame("Default", minute2)
  RPTimer.sprites.digit[2]:RenderLayer(0, posMinute2)

  local posColon1 = Vector(startingX + digitLength + 10, startingY + 19)
  RPTimer.sprites.colon[1]:RenderLayer(0, posColon1)

  local posSecond1 = Vector(startingX + digitLength + 11, startingY)
  RPTimer.sprites.digit[3]:SetFrame("Default", second1)
  RPTimer.sprites.digit[3]:RenderLayer(0, posSecond1)

  local posSecond2 = Vector(startingX + digitLength + 11 + digitLength + 1 - hourAdjustment2, startingY)
  RPTimer.sprites.digit[4]:SetFrame("Default", second2)
  RPTimer.sprites.digit[4]:RenderLayer(0, posSecond2)

  local posTenths = Vector(startingX + digitLength + 11 + digitLength + 1 - hourAdjustment2 + digitLength,
                           startingY + 1)
  RPTimer.sprites.digitMini:SetFrame("Default", tenths)
  RPTimer.sprites.digitMini:RenderLayer(0, posTenths)
end

return RPTimer

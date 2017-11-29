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
  -- Don't show the timer if the user wants it explicitly disabled
  -- (through an additional setting in the "save#.dat" file)
  if RPGlobals.race.timer ~= nil and
     RPGlobals.race.timer == false then

    return
  end

  -- Don't show the timer if the race has not started yet or they quit in the middle of the race
  -- (and always show the timer in a custom speedrun challenge)
  local challenge = Isaac.GetChallenge()
  if RPGlobals.raceVars.started == false and
     RPGlobals.raceVars.finished == false and
     challenge ~= Isaac.GetChallengeIdByName("R+9 (Season 1)") and
     challenge ~= Isaac.GetChallengeIdByName("R+14 (Season 1)") and
     challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 2)") and
     challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 3)") then

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
  local rawSeconds = elapsedTime % 60 -- 0.000 to 59.999
  local decimals = rawSeconds - math.floor(rawSeconds)
  local tenths = math.floor(decimals * 10)

  -- Local variables
  local digitLength = 7.25
  local hourAdjustment = 2
  local hourAdjustment2 = 0
  local startingX = 19
  local startingY = 217

  --
  -- Display the sprites
  --

  local posClock = Vector(startingX + 34, startingY + 45)
  RPTimer.sprites.clock:RenderLayer(0, posClock)

  if hours > 0 then
    -- The format is "#:##:##" instead of "##:##"
    hourAdjustment2 = 2
    startingX = startingX + digitLength + hourAdjustment
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

function RPTimer:DisplayRun()
  -- Don't show the run timer if the user is not pressing tab
  local tabPressed = false
  for i = 0, 3 do -- There are 4 possible inputs/players from 0 to 3
    if Input.IsActionPressed(ButtonAction.ACTION_MAP, i) then -- 13
      tabPressed = true
      break
    end
  end
  if tabPressed == false then
    return
  end

  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  -- Load the sprites
  if RPTimer.sprites.clock2 == nil then
    RPTimer.sprites.clock2 = Sprite()
    RPTimer.sprites.clock2:Load("gfx/timer/clock.anm2", true)
    RPTimer.sprites.clock2:SetFrame("Default", 0)

    RPTimer.sprites.colon2 = {}
    for i = 1, 2 do
      RPTimer.sprites.colon2[i] = Sprite()
      RPTimer.sprites.colon2[i]:Load("gfx/timer/colon.anm2", true)
      RPTimer.sprites.colon2[i]:SetFrame("Default", 0)
    end

    RPTimer.sprites.digit2 = {}
    for i = 1, 5 do
      RPTimer.sprites.digit2[i] = Sprite()
      RPTimer.sprites.digit2[i]:Load("gfx/timer/timer.anm2", true)
      RPTimer.sprites.digit2[i]:SetFrame("Default", 0)
    end

    RPTimer.sprites.digitMini2 = Sprite()
    RPTimer.sprites.digitMini2:Load("gfx/timer/timerMini.anm2", true)
    RPTimer.sprites.digitMini2:SetFrame("Default", 0)
  end

  -- Find out how much time has passed since the run started
  local elapsedTime
  if RPGlobals.run.startedTime == 0 then
    elapsedTime = 0
  else
    elapsedTime = Isaac.GetTime() - RPGlobals.run.startedTime
    elapsedTime = elapsedTime / 1000 -- This will be in milliseconds, so we divide by 1000
  end

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
  local rawSeconds = elapsedTime % 60 -- 0.000 to 59.999
  local decimals = rawSeconds - math.floor(rawSeconds)
  local tenths = math.floor(decimals * 10)

  -- Local variables
  local digitLength = 7.25
  local hourAdjustment = 2
  local hourAdjustment2 = 0
  local startingX = 52
  local startingY = 41
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) then
    startingX = 87
    startingY = 49
  end

  --
  -- Display the sprites
  --

  local posClock = Vector(startingX + 34, startingY + 45)
  RPTimer.sprites.clock2:RenderLayer(0, posClock)

  if hours > 0 then
    -- The format is "#:##:##" instead of "##:##"
    hourAdjustment2 = 2
    startingX = startingX + digitLength + hourAdjustment
    local posHours = Vector(startingX - digitLength - hourAdjustment, startingY)
    RPTimer.sprites.digit2[5]:SetFrame("Default", tostring(hours))
    RPTimer.sprites.digit2[5]:RenderLayer(0, posHours)

    local posColon2 = Vector(startingX - digitLength + 7, startingY + 19)
    RPTimer.sprites.colon2[2]:RenderLayer(0, posColon2)
  end

  local posMinute1 = Vector(startingX, startingY)
  RPTimer.sprites.digit2[1]:SetFrame("Default", minute1)
  RPTimer.sprites.digit2[1]:RenderLayer(0, posMinute1)

  local posMinute2 = Vector(startingX + digitLength, startingY)
  RPTimer.sprites.digit2[2]:SetFrame("Default", minute2)
  RPTimer.sprites.digit2[2]:RenderLayer(0, posMinute2)

  local posColon1 = Vector(startingX + digitLength + 10, startingY + 19)
  RPTimer.sprites.colon2[1]:RenderLayer(0, posColon1)

  local posSecond1 = Vector(startingX + digitLength + 11, startingY)
  RPTimer.sprites.digit2[3]:SetFrame("Default", second1)
  RPTimer.sprites.digit2[3]:RenderLayer(0, posSecond1)

  local posSecond2 = Vector(startingX + digitLength + 11 + digitLength + 1 - hourAdjustment2, startingY)
  RPTimer.sprites.digit2[4]:SetFrame("Default", second2)
  RPTimer.sprites.digit2[4]:RenderLayer(0, posSecond2)

  local posTenths = Vector(startingX + digitLength + 11 + digitLength + 1 - hourAdjustment2 + digitLength,
                           startingY + 1)
  RPTimer.sprites.digitMini2:SetFrame("Default", tenths)
  RPTimer.sprites.digitMini2:RenderLayer(0, posTenths)
end

function RPTimer:DisplayDebuff()
  if RPGlobals.run.seededDeath.state < 2 then
    return
  end

  -- Load the sprites
  if RPTimer.sprites.clock3 == nil then
    RPTimer.sprites.clock3 = Sprite()
    RPTimer.sprites.clock3:Load("gfx/timer/clock.anm2", true)
    RPTimer.sprites.clock3:SetFrame("Default", 0)

    RPTimer.sprites.colon3 = {}
    for i = 1, 2 do
      RPTimer.sprites.colon3[i] = Sprite()
      RPTimer.sprites.colon3[i]:Load("gfx/timer/colon.anm2", true)
      RPTimer.sprites.colon3[i]:SetFrame("Default", 0)
    end

    RPTimer.sprites.digit3 = {}
    for i = 1, 5 do
      RPTimer.sprites.digit3[i] = Sprite()
      RPTimer.sprites.digit3[i]:Load("gfx/timer/timer.anm2", true)
      RPTimer.sprites.digit3[i]:SetFrame("Default", 0)
    end

    RPTimer.sprites.digitMini3 = Sprite()
    RPTimer.sprites.digitMini3:Load("gfx/timer/timerMini.anm2", true)
    RPTimer.sprites.digitMini3:SetFrame("Default", 0)
  end

  -- Find out how much time is left for the debuff
  local elapsedTime = RPGlobals.run.seededDeath.time - Isaac.GetTime()
  elapsedTime = elapsedTime / 1000 -- This will be in milliseconds, so we divide by 1000
  if elapsedTime <= 0 then
    return
  end

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
  local rawSeconds = elapsedTime % 60 -- 0.000 to 59.999
  local decimals = rawSeconds - math.floor(rawSeconds)
  local tenths = math.floor(decimals * 10)

  -- Local variables
  local digitLength = 7.25
  local hourAdjustment = 2
  local hourAdjustment2 = 0
  local startingX = 65
  local startingY = 79

  --
  -- Display the sprites
  --

  local posClock = Vector(startingX + 34, startingY + 45)
  RPTimer.sprites.clock3:RenderLayer(0, posClock)

  if hours > 0 then
    -- The format is "#:##:##" instead of "##:##"
    hourAdjustment2 = 2
    startingX = startingX + digitLength + hourAdjustment
    local posHours = Vector(startingX - digitLength - hourAdjustment, startingY)
    RPTimer.sprites.digit3[5]:SetFrame("Default", tostring(hours))
    RPTimer.sprites.digit3[5]:RenderLayer(0, posHours)

    local posColon2 = Vector(startingX - digitLength + 7, startingY + 19)
    RPTimer.sprites.colon3[2]:RenderLayer(0, posColon2)
  end

  local posMinute1 = Vector(startingX, startingY)
  RPTimer.sprites.digit3[1]:SetFrame("Default", minute1)
  RPTimer.sprites.digit3[1]:RenderLayer(0, posMinute1)

  local posMinute2 = Vector(startingX + digitLength, startingY)
  RPTimer.sprites.digit3[2]:SetFrame("Default", minute2)
  RPTimer.sprites.digit3[2]:RenderLayer(0, posMinute2)

  local posColon1 = Vector(startingX + digitLength + 10, startingY + 19)
  RPTimer.sprites.colon3[1]:RenderLayer(0, posColon1)

  local posSecond1 = Vector(startingX + digitLength + 11, startingY)
  RPTimer.sprites.digit3[3]:SetFrame("Default", second1)
  RPTimer.sprites.digit3[3]:RenderLayer(0, posSecond1)

  local posSecond2 = Vector(startingX + digitLength + 11 + digitLength + 1 - hourAdjustment2, startingY)
  RPTimer.sprites.digit3[4]:SetFrame("Default", second2)
  RPTimer.sprites.digit3[4]:RenderLayer(0, posSecond2)

  local posTenths = Vector(startingX + digitLength + 11 + digitLength + 1 - hourAdjustment2 + digitLength,
                           startingY + 1)
  RPTimer.sprites.digitMini3:SetFrame("Default", tenths)
  RPTimer.sprites.digitMini3:RenderLayer(0, posTenths)
end

return RPTimer

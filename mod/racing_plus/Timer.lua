local Timer = {}

-- Includes
local g           = require("racing_plus/globals")
local SeededDeath = require("racing_plus/seededdeath")
local Speedrun    = require("racing_plus/speedrun")

-- Variables
Timer.sprites = {}

-- This is the timer that shows how long the race or speedrun has been going on for
function Timer:Display()
  -- Don't show the timer if the user wants it explicitly disabled
  -- (through an additional setting in the "save#.dat" file)
  if g.race.timer ~= nil and
     not g.race.timer then

    return
  end

  -- Always show the timer in a speedrun
  -- Don't show the timer if the race has not started yet or they quit in the middle of the race
  if not Speedrun:InSpeedrun() and
     not g.raceVars.started and
     not g.raceVars.finished then

    return
  end

  -- Load the sprites
  if Timer.sprites.clock == nil then
    Timer.sprites.clock = Sprite()
    Timer.sprites.clock:Load("gfx/timer/clock.anm2", true)
    Timer.sprites.clock:SetFrame("Default", 0)

    Timer.sprites.colon = {}
    for i = 1, 2 do
      Timer.sprites.colon[i] = Sprite()
      Timer.sprites.colon[i]:Load("gfx/timer/colon.anm2", true)
      Timer.sprites.colon[i]:SetFrame("Default", 0)
    end

    Timer.sprites.digit = {}
    for i = 1, 5 do
      Timer.sprites.digit[i] = Sprite()
      Timer.sprites.digit[i]:Load("gfx/timer/timer.anm2", true)
      Timer.sprites.digit[i]:SetFrame("Default", 0)
    end

    Timer.sprites.digitMini = Sprite()
    Timer.sprites.digitMini:Load("gfx/timer/timerMini.anm2", true)
    Timer.sprites.digitMini:SetFrame("Default", 0)
  end

  -- Find out how much time has passed since the race started
  -- (or what the race finish time was)
  local challenge = Isaac.GetChallenge()
  local elapsedTime
  if challenge ~= 0 or
     Speedrun.inSeededSpeedrun then

    if Speedrun.finished then
      elapsedTime = Speedrun.finishedTime
    elseif Speedrun.startedTime == 0 then
      elapsedTime = 0
    else
      elapsedTime = Isaac.GetTime() - Speedrun.startedTime
      -- "Isaac.GetTime()" is analogous to Lua's "os.clock()"
    end
  else
    if g.raceVars.finished then
      elapsedTime = g.raceVars.finishedTime
    else
      elapsedTime = Isaac.GetTime() - g.raceVars.startedTime
      -- "Isaac.GetTime()" is analogous to Lua's "os.clock()"
    end
  end
  elapsedTime = elapsedTime / 1000 -- This will be in milliseconds, so we divide by 1000

  local timeTable = g:ConvertTimeToString(elapsedTime)

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
  Timer.sprites.clock:RenderLayer(0, posClock)

  if timeTable[1] > 0 then
    -- The format is "#:##:##" instead of "##:##"
    hourAdjustment2 = 2
    startingX = startingX + digitLength + hourAdjustment
    local posHours = Vector(startingX - digitLength - hourAdjustment, startingY)
    Timer.sprites.digit[5]:SetFrame("Default", tostring(timeTable[1]))
    Timer.sprites.digit[5]:RenderLayer(0, posHours)

    local posColon2 = Vector(startingX - digitLength + 7, startingY + 19)
    Timer.sprites.colon[2]:RenderLayer(0, posColon2)
  end

  local posMinute1 = Vector(startingX, startingY)
  Timer.sprites.digit[1]:SetFrame("Default", timeTable[2])
  Timer.sprites.digit[1]:RenderLayer(0, posMinute1)

  local posMinute2 = Vector(startingX + digitLength, startingY)
  Timer.sprites.digit[2]:SetFrame("Default", timeTable[3])
  Timer.sprites.digit[2]:RenderLayer(0, posMinute2)

  local posColon1 = Vector(startingX + digitLength + 10, startingY + 19)
  Timer.sprites.colon[1]:RenderLayer(0, posColon1)

  local posSecond1 = Vector(startingX + digitLength + 11, startingY)
  Timer.sprites.digit[3]:SetFrame("Default", timeTable[4])
  Timer.sprites.digit[3]:RenderLayer(0, posSecond1)

  local posSecond2 = Vector(startingX + digitLength + 11 + digitLength + 1 - hourAdjustment2, startingY)
  Timer.sprites.digit[4]:SetFrame("Default", timeTable[5])
  Timer.sprites.digit[4]:RenderLayer(0, posSecond2)

  local posTenths = Vector(startingX + digitLength + 11 + digitLength + 1 - hourAdjustment2 + digitLength,
                           startingY + 1)
  Timer.sprites.digitMini:SetFrame("Default", timeTable[6])
  Timer.sprites.digitMini:RenderLayer(0, posTenths)
end

-- This is the custom timer that emulates the in-game run timer
function Timer:DisplayRun()
  -- Only show the run timer if the player is pressing tab
  local tabPressed = false
  for i = 0, 3 do -- There are 4 possible inputs/players from 0 to 3
    if Input.IsActionPressed(ButtonAction.ACTION_MAP, i) then -- 13
      tabPressed = true
      break
    end
  end
  if not tabPressed then
    return
  end

  if g.seeds:HasSeedEffect(SeedEffect.SEED_NO_HUD) then --- 10
    return
  end

  -- Load the sprites
  if Timer.sprites.clock2 == nil then
    Timer.sprites.clock2 = Sprite()
    Timer.sprites.clock2:Load("gfx/timer/clock.anm2", true)
    Timer.sprites.clock2:SetFrame("Default", 0)

    Timer.sprites.colon2 = {}
    for i = 1, 2 do
      Timer.sprites.colon2[i] = Sprite()
      Timer.sprites.colon2[i]:Load("gfx/timer/colon.anm2", true)
      Timer.sprites.colon2[i]:SetFrame("Default", 0)
    end

    Timer.sprites.digit2 = {}
    for i = 1, 5 do
      Timer.sprites.digit2[i] = Sprite()
      Timer.sprites.digit2[i]:Load("gfx/timer/timer.anm2", true)
      Timer.sprites.digit2[i]:SetFrame("Default", 0)
    end

    Timer.sprites.digitMini2 = Sprite()
    Timer.sprites.digitMini2:Load("gfx/timer/timerMini.anm2", true)
    Timer.sprites.digitMini2:SetFrame("Default", 0)
  end

  -- Find out how much time has passed since the run started
  local elapsedTime
  if g.run.startedTime == 0 then
    elapsedTime = 0
  else
    elapsedTime = Isaac.GetTime() - g.run.startedTime
    elapsedTime = elapsedTime / 1000 -- This will be in milliseconds, so we divide by 1000
  end

  local timeTable = g:ConvertTimeToString(elapsedTime)

  -- Local variables
  local digitLength = 7.25
  local hourAdjustment = 2
  local hourAdjustment2 = 0
  local startingX = 52
  local startingY = 41
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM) then
    startingX = 87
    startingY = 49
  end

  --
  -- Display the sprites
  --

  local posClock = Vector(startingX + 34, startingY + 45)
  Timer.sprites.clock2:RenderLayer(0, posClock)

  if timeTable[1] > 0 then
    -- The format is "#:##:##" instead of "##:##"
    hourAdjustment2 = 2
    startingX = startingX + digitLength + hourAdjustment
    local posHours = Vector(startingX - digitLength - hourAdjustment, startingY)
    Timer.sprites.digit2[5]:SetFrame("Default", tostring(timeTable[1]))
    Timer.sprites.digit2[5]:RenderLayer(0, posHours)

    local posColon2 = Vector(startingX - digitLength + 7, startingY + 19)
    Timer.sprites.colon2[2]:RenderLayer(0, posColon2)
  end

  local posMinute1 = Vector(startingX, startingY)
  Timer.sprites.digit2[1]:SetFrame("Default", timeTable[2])
  Timer.sprites.digit2[1]:RenderLayer(0, posMinute1)

  local posMinute2 = Vector(startingX + digitLength, startingY)
  Timer.sprites.digit2[2]:SetFrame("Default", timeTable[3])
  Timer.sprites.digit2[2]:RenderLayer(0, posMinute2)

  local posColon1 = Vector(startingX + digitLength + 10, startingY + 19)
  Timer.sprites.colon2[1]:RenderLayer(0, posColon1)

  local posSecond1 = Vector(startingX + digitLength + 11, startingY)
  Timer.sprites.digit2[3]:SetFrame("Default", timeTable[4])
  Timer.sprites.digit2[3]:RenderLayer(0, posSecond1)

  local posSecond2 = Vector(startingX + digitLength + 11 + digitLength + 1 - hourAdjustment2, startingY)
  Timer.sprites.digit2[4]:SetFrame("Default", timeTable[5])
  Timer.sprites.digit2[4]:RenderLayer(0, posSecond2)

  local posTenths = Vector(startingX + digitLength + 11 + digitLength + 1 - hourAdjustment2 + digitLength,
                           startingY + 1)
  Timer.sprites.digitMini2:SetFrame("Default", timeTable[6])
  Timer.sprites.digitMini2:RenderLayer(0, posTenths)
end

-- This is the timer that shows up when the player has died in a seeded race
function Timer:DisplaySecond()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  local elapsedTime
  local adjustTimerRight = false
  local moveTimerToBottomRight = false
  if g.run.seededDeath.state >= SeededDeath.state.FETAL_POSITION then
    elapsedTime = g.run.seededDeath.time - Isaac.GetTime()
    if challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") or
       challenge == Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)") then

      -- The timer needs to be moved to the right to account for the "(S#)" icon
      adjustTimerRight = true
    end

  elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") and
         Speedrun.charNum == 1 and
         g.run.roomsEntered == 1 then

    local timeReset = Speedrun.timeItemAssigned + Speedrun.itemLockTime
    elapsedTime = timeReset - Isaac.GetTime()
    moveTimerToBottomRight = true
  end
  if elapsedTime == nil then
    return
  end

  if g.seeds:HasSeedEffect(SeedEffect.SEED_NO_HUD) then --- 10
    return
  end

  -- Load the sprites
  if Timer.sprites.clock3 == nil then
    Timer.sprites.clock3 = Sprite()
    Timer.sprites.clock3:Load("gfx/timer/clock.anm2", true)
    Timer.sprites.clock3:SetFrame("Default", 0)

    Timer.sprites.colon3 = {}
    for i = 1, 2 do
      Timer.sprites.colon3[i] = Sprite()
      Timer.sprites.colon3[i]:Load("gfx/timer/colon.anm2", true)
      Timer.sprites.colon3[i]:SetFrame("Default", 0)
    end

    Timer.sprites.digit3 = {}
    for i = 1, 5 do
      Timer.sprites.digit3[i] = Sprite()
      Timer.sprites.digit3[i]:Load("gfx/timer/timer.anm2", true)
      Timer.sprites.digit3[i]:SetFrame("Default", 0)
    end

    Timer.sprites.digitMini3 = Sprite()
    Timer.sprites.digitMini3:Load("gfx/timer/timerMini.anm2", true)
    Timer.sprites.digitMini3:SetFrame("Default", 0)
  end

  -- Convert milliseconds to seconds
  elapsedTime = elapsedTime / 1000
  if elapsedTime <= 0 then
    return
  end

  local timeTable = g:ConvertTimeToString(elapsedTime)

  -- Local variables
  local digitLength = 7.25
  local hourAdjustment = 2
  local hourAdjustment2 = 0
  local startingX = 65
  local startingY = 79

  if adjustTimerRight then
    startingX = startingX + 18
  end
  if moveTimerToBottomRight then
    local posGame = g:GridToPos(11, 5)
    local pos = Isaac.WorldToRenderPosition(posGame)
    startingX = pos.X - 11
    startingY = pos.Y - 10
  end

  --
  -- Display the sprites
  --

  local posClock = Vector(startingX + 34, startingY + 45)
  Timer.sprites.clock3:RenderLayer(0, posClock)

  if timeTable[1] > 0 then
    -- The format is "#:##:##" instead of "##:##"
    hourAdjustment2 = 2
    startingX = startingX + digitLength + hourAdjustment
    local posHours = Vector(startingX - digitLength - hourAdjustment, startingY)
    Timer.sprites.digit3[5]:SetFrame("Default", tostring(timeTable[1]))
    Timer.sprites.digit3[5]:RenderLayer(0, posHours)

    local posColon2 = Vector(startingX - digitLength + 7, startingY + 19)
    Timer.sprites.colon3[2]:RenderLayer(0, posColon2)
  end

  local posMinute1 = Vector(startingX, startingY)
  Timer.sprites.digit3[1]:SetFrame("Default", timeTable[2])
  Timer.sprites.digit3[1]:RenderLayer(0, posMinute1)

  local posMinute2 = Vector(startingX + digitLength, startingY)
  Timer.sprites.digit3[2]:SetFrame("Default", timeTable[3])
  Timer.sprites.digit3[2]:RenderLayer(0, posMinute2)

  local posColon1 = Vector(startingX + digitLength + 10, startingY + 19)
  Timer.sprites.colon3[1]:RenderLayer(0, posColon1)

  local posSecond1 = Vector(startingX + digitLength + 11, startingY)
  Timer.sprites.digit3[3]:SetFrame("Default", timeTable[4])
  Timer.sprites.digit3[3]:RenderLayer(0, posSecond1)

  local posSecond2 = Vector(startingX + digitLength + 11 + digitLength + 1 - hourAdjustment2, startingY)
  Timer.sprites.digit3[4]:SetFrame("Default", timeTable[5])
  Timer.sprites.digit3[4]:RenderLayer(0, posSecond2)

  local posTenths = Vector(startingX + digitLength + 11 + digitLength + 1 - hourAdjustment2 + digitLength,
                           startingY + 1)
  Timer.sprites.digitMini3:SetFrame("Default", timeTable[6])
  Timer.sprites.digitMini3:RenderLayer(0, posTenths)
end

return Timer

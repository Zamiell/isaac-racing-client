local SpeedrunPostRender = {}

-- Includes
local g        = require("racing_plus/globals")
local Speedrun = require("racing_plus/speedrun")
local Sprites  = require("racing_plus/sprites")

function SpeedrunPostRender:CheckRestart()
  -- Local variables
  local isaacFrameCount = Isaac.GetFrameCount()

  -- We grabbed the checkpoint, so fade out the screen before we reset
  if Speedrun.fadeFrame ~= 0 and isaacFrameCount >= Speedrun.fadeFrame then
    Speedrun.fadeFrame = 0
    g.g:Fadeout(0.0275, g.FadeoutTarget.FADEOUT_RESTART_RUN) -- 3
    Speedrun.resetFrame = isaacFrameCount + 70 -- 72 restarts as the current character, and we want a frame of leeway
    -- (this is necessary because we don't want the player to be able to reset to skip having to watch the fade out)
    return
  end

  -- The screen is now black, so move us to the next character for the speedrun
  if Speedrun.resetFrame ~= 0 and isaacFrameCount >= Speedrun.resetFrame then
    Speedrun.resetFrame = 0
    Speedrun.fastReset = true -- Set this so that we don't go back to the beginning again
    Speedrun.charNum = Speedrun.charNum + 1
    g.run.restart = true
    Isaac.DebugString("Switching to the next character for the speedrun.")
    return
  end
end

-- Called from the "PostRender:Main()" function
function SpeedrunPostRender:DisplayCharProgress()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  -- Don't show the progress if we are not in the custom challenge
  if not Speedrun:InSpeedrun() then
    return
  end

  if g.seeds:HasSeedEffect(SeedEffect.SEED_NO_HUD) then --- 10
    return
  end

  -- Load the sprites for the multi-character speedrun progress
  if Speedrun.sprites.slash == nil then
    Speedrun.sprites.digit = {}
    for i = 1, 4 do
      Speedrun.sprites.digit[i] = Sprite()
      Speedrun.sprites.digit[i]:Load("gfx/timer/timer.anm2", true)
      Speedrun.sprites.digit[i].Scale = Vector(0.9, 0.9)
      -- Make the numbers a bit smaller than the ones used for the timer
      Speedrun.sprites.digit[i]:SetFrame("Default", 0)
    end

    Speedrun.sprites.slash = Sprite()
    Speedrun.sprites.slash:Load("gfx/timer/slash.anm2", true)
    Speedrun.sprites.slash:SetFrame("Default", 0)

    local fileName = "S1"
    if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") or
       challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
      fileName = "S1"
    elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 2)") then
      fileName = "S2"
    elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") then
      fileName = "S3"
    elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") then
      fileName = "S4"
    elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") then
      fileName = "S5"
    elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") then
      fileName = "S6"
    elseif challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") then
      fileName = "S7"
    elseif challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then
      fileName = "V"
    end
    Speedrun.sprites.season = Sprite()
    Speedrun.sprites.season:Load("gfx/speedrun/" .. fileName .. ".anm2", true)
    Speedrun.sprites.season:SetFrame("Default", 0)
  end

  -- Local variables
  local digitLength = 7.25
  local startingX = 23
  if Speedrun.inSeededSpeedrun then
    startingX = startingX + 4 -- We have to shift it to the right because the challenge icon will not appear
  end
  local startingY = 79
  local adjustment1 = 0
  local adjustment2 = 0
  if Speedrun.charNum > 9 then
    adjustment1 = digitLength - 2
    adjustment2 = adjustment1 - 1
  end

  -- Display the sprites
  local digit1 = Speedrun.charNum
  local digit2 = -1
  if Speedrun.charNum > 9 then
    digit1 = 1
    digit2 = Speedrun.charNum - 10
  end
  local digit3 = 7 -- Assume a 7 character speedrun by default
  local digit4 = -1
  if challenge == Isaac.GetChallengeIdByName("R+9 (Season 1)") then
    digit3 = 9
  elseif challenge == Isaac.GetChallengeIdByName("R+14 (Season 1)") then
    digit3 = 1
    digit4 = 4
  elseif challenge == Isaac.GetChallengeIdByName("R+15 (Vanilla)") then
    digit3 = 1
    digit4 = 5
  end

  local posDigit1 = Vector(startingX, startingY)
  Speedrun.sprites.digit[1]:SetFrame("Default", digit1)
  Speedrun.sprites.digit[1]:RenderLayer(0, posDigit1)

  if digit2 ~= -1 then
    local posDigit2 = Vector(startingX + digitLength - 1, startingY)
    Speedrun.sprites.digit[2]:SetFrame("Default", digit2)
    Speedrun.sprites.digit[2]:RenderLayer(0, posDigit2)
  end

  local posSlash = Vector(startingX + digitLength -1 + adjustment1, startingY)
  Speedrun.sprites.slash:RenderLayer(0, posSlash)

  local posDigit3 = Vector(startingX + digitLength + adjustment2 + 5 , startingY)
  Speedrun.sprites.digit[3]:SetFrame("Default", digit3)
  Speedrun.sprites.digit[3]:RenderLayer(0, posDigit3)

  local posDigit4
  if digit4 ~= -1 then
    posDigit4 = Vector(startingX + digitLength + adjustment2 + 3 + digitLength, startingY)
    Speedrun.sprites.digit[3]:SetFrame("Default", digit4)
    Speedrun.sprites.digit[3]:RenderLayer(0, posDigit4)
  end

  local posSeason
  local spacing = 17
  if posDigit4 then
    posSeason = Vector(posDigit4.X + spacing, posDigit4.Y)
  else
    posSeason = Vector(posDigit3.X + spacing, posDigit3.Y)
  end
  Speedrun.sprites.season:SetFrame("Default", 0)
  Speedrun.sprites.season:RenderLayer(0, posSeason)
end

function SpeedrunPostRender:DrawVetoButtonText()
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)") or
     Speedrun.charNum ~= 1 or
     g.run.roomsEntered ~= 1 then

    return
  end

  -- Don't draw the Veto text if there is not a valid order set
  if not Speedrun:CheckValidCharOrder() then
    return
  end

  -- Draw the sprites that correspond to the items that are currently on the veto list
  local x = -45
  for i = 1, #Speedrun.vetoList do
    local itemPosGame = g:GridToPos(11, 7)
    local itemPos = Isaac.WorldToRenderPosition(itemPosGame)
    x = x + 15
    itemPos = Vector(itemPos.X + x, itemPos.Y)
    Speedrun.vetoSprites[i]:Render(itemPos, g.zeroVector, g.zeroVector)
  end

  if Speedrun.vetoTimer == 0 then
    -- Draw the "Veto" text
    local posGame = g:GridToPos(11, 5)
    local pos = Isaac.WorldToRenderPosition(posGame)
    local string = "Veto"
    local length = g.font:GetStringWidthUTF8(string)
    g.font:DrawString(string, pos.X - (length / 2), pos.Y, g.kcolor, 0, true)
  end
end

function SpeedrunPostRender:DrawSeason7Goals()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7)") or
     Speedrun.finished then

    return
  end

  -- Make the baby description persist for at least 2 seconds after the player presses tab
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

  -- Draw the remaining goals on the screen for easy-reference
  local x = 80
  local y = 75
  g.font:DrawString("Remaining Goals:", x + 15, y - 9, g.kcolor, 0, true)

  for i, goal in ipairs(Speedrun.remainingGoals) do
    y = 75 + (20 * i)
    local string = "- " .. tostring(goal)
    g.font:DrawString(string, x + 15, y - 9, g.kcolor, 0, true)
  end
end

function SpeedrunPostRender:RemoveDiversitySprites()
  -- Remove the diversity sprites as soon as we enter another room
  if g.run.roomsEntered > 1 then
    Sprites:ClearPostRaceStartGraphics()
  end
end

return SpeedrunPostRender

local SpeedrunPostRender = {}

-- Includes
local g        = require("racing_plus/globals")
local Speedrun = require("racing_plus/speedrun")
local Season6  = require("racing_plus/season6")
local Season7  = require("racing_plus/season7")
local Season8  = require("racing_plus/season8")

function SpeedrunPostRender:Main()
  if not Speedrun:InSpeedrun() then
    return
  end

  if RacingPlusData == nil then
    return
  end

  SpeedrunPostRender:CheckRestart()
  SpeedrunPostRender:DisplayCharProgress()
  Season6:PostRender()
  Season7:PostRender()
  Season8:PostRender()
end

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

    -- Get the abbreviation for the challenge that we are currently in
    local fileName = Speedrun.challengeTable[challenge][1]

    Speedrun.sprites.season = Sprite()
    Speedrun.sprites.season:Load("gfx/speedrun/" .. fileName .. ".anm2", true)
    Speedrun.sprites.season:SetFrame("Default", 0)
  end

  -- Local variables
  local digitLength = 7.25
  local startingX = 23
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

return SpeedrunPostRender

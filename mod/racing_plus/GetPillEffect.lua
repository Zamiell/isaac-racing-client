local GetPillEffect = {}

-- Includes
local Speedrun = require("racing_plus/speedrun")

-- ModCallbacks.MC_GET_PILL_EFFECT (65)
function GetPillEffect:Main(selectedPillEffect, pillColor)
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 8 Beta)") then
    return Speedrun.S8RunPillEffects[pillColor]
  end
end

return GetPillEffect

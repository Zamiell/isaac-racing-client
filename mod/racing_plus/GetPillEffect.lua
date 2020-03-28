local GetPillEffect = {}

-- Includes
local Season8 = require("racing_plus/season8")

-- ModCallbacks.MC_GET_PILL_EFFECT (65)
function GetPillEffect:Main(selectedPillEffect, pillColor)
  return Season8:GetPillEffect(selectedPillEffect, pillColor)
end

return GetPillEffect

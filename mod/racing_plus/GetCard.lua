local GetCard = {}

-- Includes
local Season8 = require("racing_plus/season8")

-- ModCallbacks.MC_GET_CARD (20)
function GetCard:Main(rng, currentCard, playing, runes, onlyRunes)
  -- Isaac.DebugString("MC_GET_CARD - " .. tostring(currentCard) .. ", " .. tostring(playing) .. ", " ..
  --                   tostring(runes) .. ", " .. tostring(onlyRunes))

  return Season8:GetCard(rng, currentCard, playing, runes, onlyRunes)
end

return GetCard

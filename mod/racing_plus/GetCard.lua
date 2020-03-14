local GetCard = {}

-- Includes
local Season8 = require("racing_plus/season8")

-- ModCallbacks.MC_GETE_CARD (20)
function GetCard:Main(rng, currentCard, playing, runes, onlyRunes)
  Isaac.DebugString("MC_GET_CARD - " .. tostring(currentCard) .. ", " .. tostring(playing) .. ", " ..
                    tostring(runes) .. ", " .. tostring(onlyRunes))

  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 8 Beta)") then
    return Season8:GetCard(rng, currentCard, playing, runes, onlyRunes)
  end
end

return GetCard

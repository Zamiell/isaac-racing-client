local PostEffectUpdate = {}

-- Includes
local g = require("racing_plus/globals")

function PostEffectUpdate:Main(effect)
  -- Changing the color does not work in the PostEffectInit callback
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID) and -- 317
     (effect.Variant == EffectVariant.TEAR_POOF_A or -- 12
      effect.Variant == EffectVariant.TEAR_POOF_B) then -- 13

    effect:SetColor(Color(20, 1, 1, 1, 0, 0, 0), 0, 0, false, false)
  end
end

return PostEffectUpdate

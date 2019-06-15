local PostEffectInit = {}

-- Note: Position, SpawnerType, SpawnerVariant, and MaxDistance are not initialized yet in this callback

-- Includes
local g = require("racing_plus/globals")

-- EffectVariant.FART (34)
function PostEffectInit:Effect34(effect)
  if g.run.changeFartColor == true then
    -- We want special rolls to have a different fart color to distinguish them
    g.run.changeFartColor = false
    local color = Color(5.5, 0.2, 0.2, 1, 0, 0, 0) -- Bright red
    effect:SetColor(color, 0, 0, false, false)
  end
end

-- EffectVariant.HOT_BOMB_FIRE (51)
function PostEffectInit:Effect51(effect)
  -- Turn enemy fires into a different color
  if effect.SubType ~= 0 then -- Enemy fires are never subtype 0
    local color = Color(2, 0.4, 0.4, 1, 1, 1, 1)
    effect:SetColor(color, 10000, 10000, false, false)
    return
  end
end

return PostEffectInit

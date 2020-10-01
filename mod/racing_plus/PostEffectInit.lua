local PostEffectInit = {}

-- Note: Position, SpawnerType, SpawnerVariant, and MaxDistance are not initialized yet in this
-- callback

-- Includes
local g = require("racing_plus/globals")

-- EffectVariant.POOF01 (15)
function PostEffectInit:Poof01(effect)
  -- Fix the bug where Lilith's familiar poofs will be at the bottom of the screen at the beginning
  -- of a run
  if g.g:GetFrameCount() == 0 then
    -- Even though we remove it below, it will still appear for a frame,
    -- so we need to make it invisible
    effect.Visible = false
    effect:Remove()
  end
end

-- EffectVariant.HOT_BOMB_FIRE (51)
function PostEffectInit:HotBombFire(effect)
  -- Turn enemy fires into a different color
  if effect.SubType ~= 0 then -- Enemy fires are never subtype 0
    local color = Color(2, 0.4, 0.4, 1, 1, 1, 1)
    effect:SetColor(color, 10000, 10000, false, false)
    return
  end
end

return PostEffectInit

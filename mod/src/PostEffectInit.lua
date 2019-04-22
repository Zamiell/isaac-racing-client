local PostEffectInit = {}

function PostEffectInit:Main(effect)
  -- Turn enemy fires into a different color
  if effect.Variant == EffectVariant.HOT_BOMB_FIRE and -- 51
     effect.SubType ~= 0 then -- Enemy fires are never subtype 0

    local color = Color(2, 0.4, 0.4, 1, 1, 1, 1)
    effect:SetColor(color, 10000, 10000, false, false)
    return
  end

  -- Turn enemy red creep into green creep (but only on The Womb)
  if effect.Variant == EffectVariant.CREEP_RED then -- 22
    local color = Color(0, 8, 0, 1, 0, 1, 0)
    effect:SetColor(color, 10000, 10000, false, false)
    return
  end
end

return PostEffectInit
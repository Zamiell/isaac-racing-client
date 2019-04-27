local PostEffectUpdate = {}

function PostEffectUpdate:Main(effect)
  -- Turn enemy red creep into green creep (2/2)
  -- We already do this in the PostEffectInit callback,
  -- but we also need to do it here to correctly handle Cage's gray creep, Gurglings red creep, and potentially others
  -- The grayness is applied somewhere after PostEffectInit and before frame 1
  if effect.Variant == EffectVariant.CREEP_RED and -- 22
     effect.FrameCount == 1 then

    local color = Color(0, 8, 0, 1, 0, 1, 0)
    effect:SetColor(color, 10000, 10000, false, false)
    return
  end
end

return PostEffectUpdate
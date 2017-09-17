local RPPostPickupInit = {}

-- ModCallbacks.MC_POST_PICKUP_INIT (34)
-- Implement the functionality of the "Unique Card Backs" mod by piber20
function RPPostPickupInit:Main(pickup)
  -- We only care about cards and runes
  if pickup.Variant ~= PickupVariant.PICKUP_TAROTCARD then -- 300
    return
  end

  local sprite = pickup:GetSprite()
  if pickup.SubType == Card.CARD_CHAOS or -- 42
     pickup.SubType == Card.CARD_HUGE_GROWTH or -- 52
     pickup.SubType == Card.CARD_ANCIENT_RECALL or -- 53
     pickup.SubType == Card.CARD_ERA_WALK then -- 54

    sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/pickup_unique_magic_card.png")
    sprite:LoadGraphics()

  elseif pickup.SubType == Card.CARD_CREDIT then -- 43
    sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/pickup_unique_credit_card.png")
    sprite:LoadGraphics()

  elseif pickup.SubType == Card.CARD_HUMANITY then -- 45
    sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/pickup_unique_cah_card.png")
    sprite:LoadGraphics()

  elseif pickup.SubType == Card.CARD_SUICIDE_KING then -- 46
    sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/pickup_unique_bloodless_card.png")
    sprite:LoadGraphics()

  elseif pickup.SubType == Card.CARD_GET_OUT_OF_JAIL then -- 47
    sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/pickup_unique_aged_card.png")
    sprite:LoadGraphics()

  elseif pickup.SubType == Card.CARD_QUESTIONMARK then -- 48
    sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/pickup_unique_white_card.png")
    sprite:LoadGraphics()

  elseif pickup.SubType == Card.CARD_HOLY then -- 51
    sprite:Load("gfx/items/pick ups/pickup_unique_holy_card_glowing.anm2", true)
    sprite:Play("Appear", false)

  elseif pickup.SubType == Card.RUNE_BLANK or -- 40
         pickup.SubType == Card.RUNE_BLACK then -- 41

    -- Give an alternate rune sprite (one that isn't tilted left or right)
    sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/pickup_unique_generic_rune.png")

    -- The black rune will now glow black; remove this from the blank rune
    sprite:ReplaceSpritesheet(1, "gfx/items/pick ups/pickup_unique_generic_rune.png")

    sprite:LoadGraphics()
  end
end

return RPPostPickupInit

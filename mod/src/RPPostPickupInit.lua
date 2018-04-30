local RPPostPickupInit = {}

-- ModCallbacks.MC_POST_PICKUP_INIT (34)
-- Implement the functionality of the "Unique Card Backs" mod by piber20
function RPPostPickupInit:Main(pickup)
  -- We only care about cards and runes
  if pickup.Variant ~= PickupVariant.PICKUP_TAROTCARD then -- 300
    return
  end

  local sprite = pickup:GetSprite()
  if pickup.SubType == Card.CARD_RULES then -- 44
     sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/pickup_unique_rules_card.png")
     sprite:LoadGraphics()

  elseif pickup.SubType == Card.CARD_SUICIDE_KING then -- 46
    sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/pickup_unique_suicide_king_card.png")
    sprite:LoadGraphics()

  elseif pickup.SubType == Card.CARD_QUESTIONMARK then -- 48
    sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/pickup_unique_question_mark_card.png")
    sprite:LoadGraphics()

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

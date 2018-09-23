local RPPostPickupInit = {}

-- ModCallbacks.MC_POST_PICKUP_INIT (34)
-- Implement the functionality of the "Unique Card Backs" mod by piber20
function RPPostPickupInit:Main(pickup)
  -- We only care about cards and runes
  if pickup.Variant ~= PickupVariant.PICKUP_TAROTCARD then -- 300
    return
  end

  local sprite = pickup:GetSprite()
  if (pickup.SubType >= Card.CARD_FOOL and -- 1
      pickup.SubType <= Card.RUNE_ALGIZ) or -- 39
     -- Blank Rune (40) and Black Rune (41) are handled below
     pickup.SubType == Card.CARD_CHAOS or -- 42
     -- Credit Card (43) has a unique card back in vanilla
     pickup.SubType == Card.CARD_RULES or -- 44
     -- A Card Against Humanity (45) has a unique card back in vanilla
     pickup.SubType == Card.CARD_SUICIDE_KING or -- 46
     pickup.SubType == Card.CARD_GET_OUT_OF_JAIL or -- 47
     -- (Get out of Jail Free Card has a unique card back in vanilla, but this one looks better)
     pickup.SubType == Card.CARD_QUESTIONMARK or -- 48
     -- Dice Shard (49) has a unique card back in vanilla
     -- Emergency Contact (50) has a unique card back in vanilla
     -- Holy Card (51) has a unique card back in vanilla
     (pickup.SubType >= Card.CARD_HUGE_GROWTH and -- 52
      pickup.SubType <= Card.CARD_ERA_WALK) then -- 54

    sprite:ReplaceSpritesheet(0, "gfx/cards/" .. tostring(pickup.SubType) .. ".png")
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

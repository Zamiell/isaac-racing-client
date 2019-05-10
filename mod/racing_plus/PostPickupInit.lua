local PostPickupInit = {}

-- Includes
local g              = require("racing_plus/globals")
local PostItemPickup = require("racing_plus/postitempickup")

-- ModCallbacks.MC_POST_PICKUP_INIT (34)
function PostPickupInit:Main(pickup)
  --[[
  Isaac.DebugString("MC_POST_PICKUP_INIT - " ..
                    tostring(pickup.Type) .. "." .. tostring(pickup.Variant) .. "." .. tostring(pickup.SubType))
  --]]

  --PostPickupInit:CheckOrphanedPickup(pickup)
  -- (commented out for now since it does not work and would involve a ton of extra code to check for
  -- loading zones + teleports + death)
  PostPickupInit:ReplaceCardBacks(pickup)
end

function PostPickupInit:CheckOrphanedPickup(pickup)
  -- Check to see if we entered a loading zone while having an item queued that drops pickups
  local roomFrameCount = g.r:GetFrameCount()
  if not PostPickupInit:InLoadingZone() or
     g.run.pickingUpItem == 0 or
     roomFrameCount == -1 then

    return
  end

  Isaac.DebugString("Entered a loading zone while having an item queued that drops pickups; " ..
                    "inserting the following into our inventory: " ..
                    tostring(pickup.Type) .. "." .. tostring(pickup.Variant) .. "." .. tostring(pickup.SubType))
  if pickup.Variant == PickupVariant.PICKUP_COIN then -- 20
    PostItemPickup:InsertCoin(pickup)

  elseif pickup.Variant == PickupVariant.PICKUP_KEY then -- 30
    PostItemPickup:InsertKey(pickup)

  elseif pickup.Variant == PickupVariant.PICKUP_BOMB then -- 40
    PostItemPickup:InsertBomb(pickup)

  elseif pickup.Variant == PickupVariant.PICKUP_PILL or -- 70
         pickup.Variant == PickupVariant.PICKUP_TAROTCARD then -- 300

    PostItemPickup:InsertPocketItem()

  elseif pickup.Variant == PickupVariant.PICKUP_TRINKET then -- 350
    PostItemPickup:InsertTrinket()
  else
    Isaac.DebugString("Error: Failed to insert the pickup because there is no function defined for this pickup type.")
  end
end

function PostPickupInit:ReplaceCardBacks(pickup)
  -- We only care about cards and runes
  if pickup.Variant ~= PickupVariant.PICKUP_TAROTCARD then -- 300
    return
  end

  if pickup.SubType == Card.RUNE_BLANK or -- 40
     pickup.SubType == Card.RUNE_BLACK then -- 41

   -- Give an alternate rune sprite (one that isn't tilted left or right)
   local sprite = pickup:GetSprite()
   sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/pickup_unique_generic_rune.png")

   -- The black rune will now glow black; remove this from the blank rune
   sprite:ReplaceSpritesheet(1, "gfx/items/pick ups/pickup_unique_generic_rune.png")

   sprite:LoadGraphics()
   return

 elseif pickup.SubType == Card.CARD_CHAOS or -- 42
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

    -- Make some cards face-up
    local sprite = pickup:GetSprite()
    sprite:ReplaceSpritesheet(0, "gfx/cards/" .. tostring(pickup.SubType) .. ".png")
    sprite:LoadGraphics()
   end
end

function PostPickupInit:InLoadingZone()
  -- TODO
end

return PostPickupInit

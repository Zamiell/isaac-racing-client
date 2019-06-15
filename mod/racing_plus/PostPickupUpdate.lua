local PostPickupUpdate = {}

-- Note: This callback only fires on frame 1 and onwards

-- Includes
local g          = require("racing_plus/globals")
local FastTravel = require("racing_plus/fasttravel")
local Samael     = require("racing_plus/samael")
local Pedestals  = require("racing_plus/pedestals")

-- ModCallbacks.MC_POST_PICKUP_UPDATE (35)
function PostPickupUpdate:Main(pickup)
  -- Keep track of pickups that are touched
  -- (used for moving pickups on top of a trapdoor/crawlspace)
  if pickup:GetSprite():IsPlaying("Collect") and
     not pickup.Touched then

    pickup.Touched = true
    Isaac.DebugString("Touched pickup: " ..
                      tostring(pickup.Type) .. "." .. tostring(pickup.Variant) .. "." .. tostring(pickup.SubType))

    if pickup.Variant == PickupVariant.PICKUP_LIL_BATTERY or -- 90
       (pickup.Variant == PickupVariant.PICKUP_KEY and pickup.SubType == 4) then -- Charged Key (30.4)

      -- Recharge the Wraith Skull
      -- (we have to do this manually because the charges on the Wraith Skull are not handled naturally by the game)
      Samael:CheckRechargeWraithSkull()
    end
  end

  -- Make sure that pickups are not overlapping with trapdoors / beams of light / crawlspaces
  if not pickup.Touched then
    -- Pickups will still exist for 15 frames after being picked up since they will be playing the "Collect" animation
    -- So we don't want to move a pickup that is already collected, or it will duplicate it
    -- ("Touched" was manually set to true by the mod above)
    -- Alternatively, we could check for "entity.EntityCollisionClass ~= 0",
    -- but this is bad because the collision is 0 during the long "Appear" animation
    FastTravel:CheckPickupOverHole(pickup)
  end
end

-- PickupVariant.PICKUP_COLLECTIBLE (5.100)
function PostPickupUpdate:Pickup100(pickup)
  -- We manually manage the seed of all collectible items
  if g.g:GetFrameCount() >= g.run.itemReplacementDelay then
    -- We need to delay after using a Void (in case the player has consumed a D6)
    Pedestals:Replace(pickup)
  end
end

return PostPickupUpdate

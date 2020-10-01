local PostPickupUpdate = {}

-- Note: This callback only fires on frame 1 and onwards

-- Includes
local g = require("racing_plus/globals")
local FastTravel = require("racing_plus/fasttravel")
local Samael = require("racing_plus/samael")
local Pedestals = require("racing_plus/pedestals")
local Season8 = require("racing_plus/season8")

-- ModCallbacks.MC_POST_PICKUP_UPDATE (35)
function PostPickupUpdate:Main(pickup)
  -- Keep track of pickups that are touched
  -- (used for moving pickups on top of a trapdoor/crawlspace)
  if (
    (
      pickup:GetSprite():IsPlaying("Collect") -- Most pickups have a "Collect" animation
      or pickup:GetSprite():IsPlaying("Open") -- Chests do not have a "Collect" animation
    )
    and not pickup.Touched
  ) then
    pickup.Touched = true

    -- Some pickups should count as "starting" a Challenge Room or Boss Rush
    if (
      pickup.Variant == PickupVariant.PICKUP_CHEST -- 50
      or pickup.Variant == PickupVariant.PICKUP_BOMBCHEST -- 51
      or pickup.Variant == PickupVariant.PICKUP_SPIKEDCHEST -- 52
      or pickup.Variant == PickupVariant.PICKUP_ETERNALCHEST -- 53
      or pickup.Variant == PickupVariant.PICKUP_MIMICCHEST -- 54
      or pickup.Variant == PickupVariant.PICKUP_LOCKEDCHEST -- 60
      or pickup.Variant == PickupVariant.PICKUP_GRAB_BAG -- 69
      or pickup.Variant == PickupVariant.PICKUP_REDCHEST -- 360
    ) then
      g.run.touchedPickup = true -- This variable is tracked per room
      Isaac.DebugString(
        "Touched pickup: " .. tostring(pickup.Type) .. "." .. tostring(pickup.Variant) .. "."
        .. tostring(pickup.SubType)
      )
    end

    if (
      pickup.Variant == PickupVariant.PICKUP_LIL_BATTERY -- 90
      or (
        pickup.Variant == PickupVariant.PICKUP_KEY -- 30
        and pickup.SubType == KeySubType.KEY_CHARGED -- 4
      )
    ) then
      -- Recharge the Wraith Skull
      -- (we have to do this manually because the charges on the Wraith Skull are not handled
      -- naturally by the game)
      Samael:CheckRechargeWraithSkull()
    end
  end

  -- Make sure that pickups are not overlapping with trapdoors / beams of light / crawlspaces
  if not pickup.Touched then
    -- Pickups will still exist for 15 frames after being picked up since they will be playing the
    -- "Collect" animation
    -- So we don't want to move a pickup that is already collected, or it will duplicate it
    -- ("Touched" was manually set to true by the mod above)
    -- Alternatively, we could check for "entity.EntityCollisionClass ~= 0",
    -- but this is bad because the collision is 0 during the long "Appear" animation
    -- Additionally, we can't use the MC_POST_PICKUP_INIT callback for this because the position
    -- for newly initialized pickups is always equal to (0, 0)
    FastTravel:CheckPickupOverHole(pickup)
  end
end

-- PickupVariant.PICKUP_HEART (10)
function PostPickupUpdate:Heart(pickup)
  -- We only care about freshly spawned black hearts
  if (
    pickup.FrameCount ~= 1
    or pickup.SubType ~= HeartSubType.HEART_BLACK -- 6
  ) then
    return
  end

  -- If this black heart is in the same position as a dead NPC,
  -- assume that it was spawned from a Maw of the Void or Athame
  local parentNPC
  for index, entry in pairs(g.run.blackHeartNPCs) do
    if (
      entry.position.X == pickup.Position.X
      and entry.position.Y == pickup.Position.Y
    ) then
      parentNPC = entry
      break
    end
  end
  if parentNPC == nil then
    -- It must be a black heart from something else, e.g. a room drop
    return
  end

  -- We only allow 1 black heart drop from a particular init seed
  if g.run.blackHeartCount[parentNPC.initSeed] == nil then
    g.run.blackHeartCount[parentNPC.initSeed] = 0
  end
  g.run.blackHeartCount[parentNPC.initSeed] = g.run.blackHeartCount[parentNPC.initSeed] + 1
  if g.run.blackHeartCount[parentNPC.initSeed] >= 2 then
    pickup:Remove()
    Isaac.DebugString("Removed a bugged black heart from a multi-segment enemy.")
  end
end

-- PickupVariant.PICKUP_COIN (20)
function PostPickupUpdate:Coin(pickup)
  -- Local variables
  local sprite = pickup:GetSprite()
  local data = pickup:GetData()

  if pickup.SubType == CoinSubType.COIN_STICKYNICKEL then
    if sprite:IsPlaying("Touched") then
      sprite:Play("TouchedStick", true)
    end
  elseif data.WasStickyNickel then -- Check for our WasStickyNickel data
    data.WasStickyNickel = false
    sprite:Load("gfx/005.022_nickel.anm2", true) -- Revert the nickel sprite to the original sprite
    sprite:Play("Idle", true)
  end
end

-- PickupVariant.PICKUP_COLLECTIBLE (100)
function PostPickupUpdate:Collectible(pickup)
  -- We manually manage the seed of all collectible items
  Pedestals:Replace(pickup)
end

-- PickupVariant.PICKUP_TAROTCARD (300)
function PostPickupUpdate:TarotCard(pickup)
  Season8:PostPickupUpdateTarotCard(pickup)
end

-- PickupVariant.PICKUP_TRINKET (350)
function PostPickupUpdate:Trinket(pickup)
  Season8:PostPickupUpdateTrinket(pickup)
end

return PostPickupUpdate

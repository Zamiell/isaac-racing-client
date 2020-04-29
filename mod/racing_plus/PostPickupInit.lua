local PostPickupInit = {}

-- Note: Position, SpawnerType, SpawnerVariant, and Price are not initialized yet in this callback

-- Includes
local g        = require("racing_plus/globals")
local BigChest = require("racing_plus/bigchest")
local Speedrun = require("racing_plus/speedrun")

-- Variables
PostPickupInit.bigChestAction = false
PostPickupInit.checkpointPos = g.zeroVector

-- PickupVariant.PICKUP_COIN (20)
function PostPickupInit:Pickup20(pickup)
  if pickup.SubType ~= CoinSubType.COIN_STICKYNICKEL then --6
    return
  end

  -- Local variables
  local sprite = pickup:GetSprite()
  local data = pickup:GetData()

  -- Spawn the effect
  local stickyEffect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.STICKY_NICKEL, 0,
                                   pickup.Position, g.zeroVector, pickup)
  local stickySprite = stickyEffect:GetSprite()
  local stickyData = stickyEffect:GetData()

  -- Get what animation to use
  local animation = "Idle"
  if sprite:IsPlaying("Appear") then
    animation = "Appear"
  end
  stickySprite:Play(animation, true)

  -- Set up the data
  data.WasStickyNickel = true
  stickyData.StickyNickel = pickup

  -- Make it render below most things
  stickyEffect.RenderZOffset = -10000
end

-- PickupVariant.PICKUP_TAROTCARD (300)
function PostPickupInit:Pickup300(pickup)
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

-- PickupVariant.PICKUP_BIGCHEST (340)
function PostPickupInit:Pickup340(pickup)
  BigChest:PostPickupInit(pickup)
end

-- PickupVariant.PICKUP_TROPHY (370)
function PostPickupInit:Pickup370(pickup)
  -- Do nothing if we are not on a custom speedrun challenge
  -- (otherwise we would be deleting the trophy in a normal challenge)
  if not Speedrun:InSpeedrun() then
    return
  end

  -- It can be unpredicable whether a big chest or a trophy will spawn;
  -- so funnel all decision making through the Big Chest code
  Isaac.DebugString("Vanilla trophy detected; replacing it with a Big Chest.")
  Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, 0, -- 5.340
              g.r:GetCenterPos(), g.zeroVector, nil)
  pickup:Remove()
end

function PostPickupInit:CheckSpikedChestUnavoidable(pickup)
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomData = g.l:GetCurrentRoomDesc().Data

  -- Check to see if we are in a specific room where a Spiked Chest or Mimic will cause unavoidable damage
  local roomDataVariant = roomData.Variant
  while roomDataVariant >= 10000 do
    -- The 3 flipped versions of room #1 would be #10001, #20001, and #30001
    roomDataVariant = roomDataVariant - 10000
  end

  -- roomData.StageID always returns 0 for some reason, so just use stage and stageType as a workaround
  if ((stage == 1 or stage == 2) and stageType == 0 and roomDataVariant == 716) or -- Basement
     ((stage == 1 or stage == 2) and stageType == 0 and roomDataVariant == 721) or
     ((stage == 1 or stage == 2) and stageType == 1 and roomDataVariant == 716) or -- Cellar
     ((stage == 1 or stage == 2) and stageType == 1 and roomDataVariant == 721) or
     ((stage == 1 or stage == 2) and stageType == 2 and roomDataVariant == 716) or -- Burning Basement
     ((stage == 1 or stage == 2) and stageType == 2 and roomDataVariant == 721) or
     ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 12) or -- Caves
     ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 19) or
     ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 90) or
     ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 119) or
     ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 125) or
     ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 244) or
     ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 518) or
     ((stage == 3 or stage == 4) and stageType == 0 and roomDataVariant == 519) or
     ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 19) or -- Catacombs
     ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 90) or
     ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 119) or
     ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 285) or
     ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 518) or
     ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 12) or -- Flooded Caves
     ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 19) or
     ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 90) or
     ((stage == 3 or stage == 4) and stageType == 1 and roomDataVariant == 119) or
     ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 125) or
     ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 244) or
     ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 518) or
     ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 519) or
     ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 1008) or
     ((stage == 3 or stage == 4) and stageType == 2 and roomDataVariant == 1014) or
     ((stage == 5 or stage == 6) and stageType == 1 and roomDataVariant == 936) or -- Necropolis
     ((stage == 5 or stage == 6) and stageType == 1 and roomDataVariant == 973) or
     ((stage == 7 or stage == 8) and stageType == 0 and roomDataVariant == 458) or -- Womb
     ((stage == 7 or stage == 8) and stageType == 0 and roomDataVariant == 489) or
     ((stage == 7 or stage == 8) and stageType == 1 and roomDataVariant == 458) or -- Utero
     ((stage == 7 or stage == 8) and stageType == 1 and roomDataVariant == 489) or
     ((stage == 7 or stage == 8) and stageType == 2 and roomDataVariant == 458) or -- Scarred Womb
     ((stage == 7 or stage == 8) and stageType == 2 and roomDataVariant == 489) then

    -- Change it to a normal chest
    pickup.Variant = 50
    pickup:GetSprite():Load("gfx/005.050_chest.anm2", true)
    pickup:GetSprite():Play("Appear", false)
    -- (we have to play an animation for the new sprite to actually appear)
    Isaac.DebugString("Replaced a Spiked Chest / Mimic with a normal chest (for an unavoidable damage room).")

    -- Mark it so that other mods are aware of the replacement
    local data = pickup:GetData()
    data.unavoidableReplacement = true
  end
end

return PostPickupInit

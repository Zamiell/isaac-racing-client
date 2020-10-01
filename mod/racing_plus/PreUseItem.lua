local PreUseItem = {}

-- Includes
local g = require("racing_plus/globals")
local UseItem = require("racing_plus/useitem")

-- CollectibleType.COLLECTIBLE_WE_NEED_GO_DEEPER (84)
-- This callback is used naturally by Ehwaz (Passage) runes
function PreUseItem:WeNeedToGoDeeper()
  -- Local variables
  local stage = g.l:GetStage()

  -- Prevent the racers from "cheating" by using the shovel on Womb 2 in the "Everything" race goal
  if g.race.goal == "Everything" and stage == 8 then
    -- Signal that what they did was illegal
    g.p:AnimateSad()

    -- By returning true, it will cancel the original effect
    return true
  end
end

-- CollectibleType.COLLECTIBLE_BOOK_OF_SIN (97)
function PreUseItem:BookOfSin()
  -- The Book of Sin has an equal chance to spawn a heart, coin, bomb, key, battery, pill,
  -- or card/rune
  g.RNGCounter.BookOfSin = g:IncrementRNG(g.RNGCounter.BookOfSin)
  math.randomseed(g.RNGCounter.BookOfSin)
  local bookPickupType = math.random(1, 7)
  g.RNGCounter.BookOfSin = g:IncrementRNG(g.RNGCounter.BookOfSin)

  local position = g.r:FindFreePickupSpawnPosition(g.p.Position, 0, true)
  local velocity = g.zeroVector

  if bookPickupType == 1 then
    -- Random Heart
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_HEART, -- 10
      position,
      velocity,
      g.p,
      0,
      g.RNGCounter.BookOfSin
    )
  elseif bookPickupType == 2 then
    -- Random Coin
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_COIN, -- 20
      position,
      velocity,
      g.p,
      0,
      g.RNGCounter.BookOfSin
    )
  elseif bookPickupType == 3 then
    -- Random Bomb
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_BOMB, -- 40
      position,
      velocity,
      g.p,
      0,
      g.RNGCounter.BookOfSin
    )
  elseif bookPickupType == 4 then
    -- Random Key
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_KEY, -- 30
      position,
      velocity,
      g.p,
      0,
      g.RNGCounter.BookOfSin
    )
  elseif bookPickupType == 5 then
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_LIL_BATTERY, -- 90
      position,
      velocity,
      g.p,
      0,
      g.RNGCounter.BookOfSin
    )
  elseif bookPickupType == 6 then
    -- Random Pill
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_PILL, -- 70
      position,
      velocity,
      g.p,
      0,
      g.RNGCounter.BookOfSin
    )
  elseif bookPickupType == 7 then
    -- Random Card/Rune
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_TAROTCARD, -- 300
      position,
      velocity,
      g.p,
      0,
      g.RNGCounter.BookOfSin
    )
  end

  -- When we return from the function below, no animation will play,
  -- so we have to explitily perform one
  g.p:AnimateCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_SIN, "UseItem", "PlayerPickup") -- 97

  -- Since we cancel the original effect, the UseItem callback will never fire, so do it manually
  UseItem:Main(CollectibleType.COLLECTIBLE_BOOK_OF_SIN) -- 97

  -- By returning true, it will cancel the original effect
  return true
end

-- CollectibleType.COLLECTIBLE_DEAD_SEA_SCROLLS (124)
function PreUseItem:DeadSeaScrolls()
  g.RNGCounter.DeadSeaScrolls = g:IncrementRNG(g.RNGCounter.DeadSeaScrolls)
  math.randomseed(g.RNGCounter.DeadSeaScrolls)
  local effectType = math.random(1, 28)

  local effects = { -- 26 total item effects
    -- https://bindingofisaacrebirth.gamepedia.com/Dead_Sea_Scrolls
    -- Listed in alphabetical order
    CollectibleType.COLLECTIBLE_ANARCHIST_COOKBOOK, -- 65 (#1)
    CollectibleType.COLLECTIBLE_BOBS_ROTTEN_HEAD, -- 42 (#2)
    CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL, -- 34 (#3)
    CollectibleType.COLLECTIBLE_BOOK_REVELATIONS, -- 78 (#4)
    CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS, -- 58 (#5)
    CollectibleType.COLLECTIBLE_BOOK_OF_SIN, -- 97 (#6)
    CollectibleType.COLLECTIBLE_CRACK_THE_SKY, -- 160 (#7)
    CollectibleType.COLLECTIBLE_DECK_OF_CARDS, -- 85 (#8)
    CollectibleType.COLLECTIBLE_GAMEKID, -- 93 (#9)
    CollectibleType.COLLECTIBLE_HOURGLASS, -- 66 (#10)
    CollectibleType.COLLECTIBLE_KAMIKAZE, -- 40 (#11)
    CollectibleType.COLLECTIBLE_LEMON_MISHAP, -- 56 (#12)
    CollectibleType.COLLECTIBLE_MOMS_BOTTLE_PILLS, -- 102 (#13)
    CollectibleType.COLLECTIBLE_MOMS_BRA, -- 39 (#14)
    CollectibleType.COLLECTIBLE_MONSTROS_TOOTH, -- 86 (#15)
    CollectibleType.COLLECTIBLE_MR_BOOM, -- 37 (#16)
    CollectibleType.COLLECTIBLE_MY_LITTLE_UNICORN, -- 77 (#17)
    CollectibleType.COLLECTIBLE_THE_NAIL, -- 83 (#18)
    CollectibleType.COLLECTIBLE_PINKING_SHEARS, -- 107 (#19)
    CollectibleType.COLLECTIBLE_SATANIC_BIBLE, -- 292 (#20)
    CollectibleType.COLLECTIBLE_SHOOP_DA_WHOOP, -- 49 (#21)
    CollectibleType.COLLECTIBLE_TAMMYS_HEAD, -- 38 (#22)
    CollectibleType.COLLECTIBLE_TELEPORT, -- 44 (#23)
    CollectibleType.COLLECTIBLE_WE_NEED_GO_DEEPER, -- 84 (#24)
    CollectibleType.COLLECTIBLE_YUM_HEART, -- 45 (#25)
    CollectibleType.COLLECTIBLE_WOODEN_NICKEL, -- 349 (#26)
  }

  if effectType == 27 then
    g.p:UsePill(PillEffect.PILLEFFECT_EXPLOSIVE_DIARRHEA, PillColor.PILL_NULL) -- 4, 0
    local pillEffect = g.itemConfig:GetPillEffect(PillEffect.PILLEFFECT_EXPLOSIVE_DIARRHEA) -- 4
    g.run.streakText = pillEffect.Name
  elseif effectType == 28 then
    g.p:UsePill(PillEffect.PILLEFFECT_LEMON_PARTY, PillColor.PILL_NULL) -- 26, 0
    local pillEffect = g.itemConfig:GetPillEffect(PillEffect.PILLEFFECT_LEMON_PARTY) -- 26
    g.run.streakText = pillEffect.Name
  else
    g.p:UseActiveItem(effects[effectType], false, false, false, false)
    g.run.streakText = g.itemConfig:GetCollectible(effects[effectType]).Name
  end
  Isaac.DebugString("Used Dead Sea Scrolls effect: " .. tostring(effectType))

  -- Display the streak text so that they know what item they got
  g.run.streakFrame = Isaac.GetFrameCount()

  -- When we return from the function below, no animation will play,
  -- so we have to explitily perform one
  g.p:AnimateCollectible(
    CollectibleType.COLLECTIBLE_DEAD_SEA_SCROLLS, -- 124
    "UseItem",
    "PlayerPickup"
  )

  -- Get rid of the charges
  -- (otherwise, the charges won't be consistently depleted)
  local activeCharge = g.p:GetActiveCharge()
  local batteryCharge = g.p:GetBatteryCharge()
  local totalCharge = activeCharge + batteryCharge
  totalCharge = totalCharge - 2
  g.p:SetActiveCharge(totalCharge)

  -- Since we cancel the original effect, the UseItem callback will never fire, so do it manually
  UseItem:Main(CollectibleType.COLLECTIBLE_DEAD_SEA_SCROLLS) -- 124

  -- Cancel the original effect
  return true
end

-- CollectibleType.COLLECTIBLE_GUPPYS_HEAD (145)
function PreUseItem:GuppysHead()
  g.RNGCounter.GuppysHead = g:IncrementRNG(g.RNGCounter.GuppysHead)
  math.randomseed(g.RNGCounter.GuppysHead)
  local numFlies = math.random(2, 4)
  g.p:AddBlueFlies(numFlies, g.p.Position, nil)

  -- When we return from the function below, no animation will play,
  -- so we have to explitily perform one
  g.p:AnimateCollectible(CollectibleType.COLLECTIBLE_GUPPYS_HEAD, "UseItem", "PlayerPickup") -- 145

  -- Get rid of the charges
  -- (otherwise, the charges won't be consistently depleted)
  local activeCharge = g.p:GetActiveCharge()
  local batteryCharge = g.p:GetBatteryCharge()
  local totalCharge = activeCharge + batteryCharge
  totalCharge = totalCharge - 1
  g.p:SetActiveCharge(totalCharge)

  -- Since we cancel the original effect, the UseItem callback will never fire, so do it manually
  UseItem:Main(CollectibleType.COLLECTIBLE_GUPPYS_HEAD) -- 145

  -- Cancel the original effect
  return true
end

-- CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS (422)
function PreUseItem:GlowingHourGlass()
  -- Mark to reset the active item + the Schoolbag item
  if (
    g.p:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    -- Broken Remote cancels the Glowing Hour Glass effect
    and not g.p:HasTrinket(TrinketType.TRINKET_BROKEN_REMOTE)
  ) then
    g.run.schoolbag.usedGlowingHourGlass = 1
  end
end

-- CollectibleType.COLLECTIBLE_SMELTER (479)
-- This callback is used naturally by Gulp! pills
function PreUseItem:Smelter()
  local trinket1 = g.p:GetTrinket(0) -- This will be 0 if there is no trinket
  local trinket2 = g.p:GetTrinket(1) -- This will be 0 if there is no trinket

  if trinket1 ~= 0 then
    -- Send a message to the item tracker to add this trinket
    Isaac.DebugString("Gulping trinket " .. trinket1)
  end

  if trinket2 ~= 0 then
    -- Send a message to the item tracker to add this trinket
    Isaac.DebugString("Gulping trinket " .. trinket2)
  end

  -- Mark that the trinkets did not break
  g.run.haveWishbone = false
  g.run.haveWalnut = false

  -- By returning nothing, it will go on to do the Smelter effect
end

function PreUseItem:PreventItemPedestalEffects(itemID)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()

  -- Car Battery will mess up the D6 and D100 (and possibly others) because
  -- this function will be entered twice on the same frame
  -- (and there will be no time to replace the pedestal)
  -- The same thing is true for Blank Card + Perthro rune + Tarot Cloth
  if (
    g.p:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) -- 356
    or (
      g.p:HasCollectible(CollectibleType.COLLECTIBLE_BLANK_CARD) -- 451
      and g.p:HasCollectible(CollectibleType.COLLECTIBLE_TAROT_CLOTH) -- 286
    )
  ) then
    return
  end

  -- Similarly, using a ? Card while having Tarot Cloth will cause the same problem
  if gameFrameCount == g.run.questionMarkCard then
    return
  end

  if PreUseItem:UnreplacedItemsExist() then
    Isaac.DebugString(
      "Canceling item " .. tostring(itemID) .. " due to unreplaced items in the room."
    )
    g.run.rechargeItemFrame = gameFrameCount + 1
    return true
  end

  local checkpoints = Isaac.FindByType(
    EntityType.ENTITY_PICKUP, -- 5
    PickupVariant.PICKUP_COLLECTIBLE, -- 100
    CollectibleType.COLLECTIBLE_CHECKPOINT,
    false,
    false
  )
  if #checkpoints > 0 then
    Isaac.DebugString("Canceling item " .. tostring(itemID) .. " due to a Checkpoint in the room.")
    g.run.rechargeItemFrame = gameFrameCount + 1
    return true
  end
end

function PreUseItem:UnreplacedItemsExist()
  -- Local variables
  local roomIndex = g:GetRoomIndex()

  -- Look for pedestals that have not been replaced yet
  local collectibles = Isaac.FindByType(
    EntityType.ENTITY_PICKUP, -- 5
    PickupVariant.PICKUP_COLLECTIBLE, -- 100
    -1,
    false,
    false
  )
  for _, collectible in ipairs(collectibles) do
    local alreadyReplaced = false
    for j = 1, #g.run.replacedPedestals do
      if (
        g.run.replacedPedestals[j].room == roomIndex
        and g.run.replacedPedestals[j].seed == collectible.InitSeed
      ) then
        alreadyReplaced = true
        break
      end
    end

    if not alreadyReplaced and collectible.SubType ~= 0 then
      return true
    end
  end

  return false
end

return PreUseItem

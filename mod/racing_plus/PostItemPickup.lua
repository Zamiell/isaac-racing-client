local PostItemPickup = {}

-- These functions are used to deposit items directly in the player's inventory, if there is room

-- Includes
local g = require("racing_plus/globals")
local Season8 = require("racing_plus/season8")

function PostItemPickup:InsertNearestCoin()
  PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_COIN) -- 20
end

function PostItemPickup:InsertNearestPill()
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_STARTER_DECK) then -- 251
    PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_TAROTCARD) -- 300
  else
    PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_PILL) -- 70
  end
end

function PostItemPickup:InsertNearestCard()
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_LITTLE_BAGGY) then -- 252
    PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_PILL) -- 70
  else
    PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_TAROTCARD) -- 300
  end
end

function PostItemPickup:InsertNearestCardPill()
  -- Prefer to equip cards over pills, since they are almost certainly going to be more useful
  if not PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_TAROTCARD) then -- 300
    PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_PILL) -- 70
  end
end

function PostItemPickup:InsertNearestTrinket()
  PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_TRINKET) -- 350
end

function PostItemPickup:RemoveNearestTrinket()
  PostItemPickup:RemoveNearestPickup(PickupVariant.PICKUP_TRINKET) -- 350
end

function PostItemPickup:InsertNearestPickup(variant)
  local nearestPickup = PostItemPickup:FindNearestPickup(variant)
  if nearestPickup == nil then
    return false
  end

  if variant == PickupVariant.PICKUP_COIN then -- 20
    return PostItemPickup:InsertCoin(nearestPickup)
  elseif variant == PickupVariant.PICKUP_KEY then -- 30
    return PostItemPickup:InsertKey(nearestPickup)
  elseif variant == PickupVariant.PICKUP_BOMB then -- 40
    return PostItemPickup:InsertBomb(nearestPickup)
  elseif variant == PickupVariant.PICKUP_PILL then -- 70
    return PostItemPickup:InsertPill(nearestPickup)
  elseif variant == PickupVariant.PICKUP_TAROTCARD then -- 300
    return PostItemPickup:InsertCard(nearestPickup)
  elseif variant == PickupVariant.PICKUP_TRINKET then -- 350
    return PostItemPickup:InsertTrinket(nearestPickup)
  end

  return false
end

function PostItemPickup:RemoveNearestPickup(variant)
  local nearestPickup = PostItemPickup:FindNearestPickup(variant)
  if nearestPickup == nil then
    return false
  end

  nearestPickup:Remove()
  return true
end

function PostItemPickup:FindNearestPickup(variant)
  local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP, variant, -1, false, false) -- 5
  local nearestPickup = nil
  local nearestPickupDistance = nil
  for _, entity in ipairs(pickups) do
    local pickup = entity:ToPickup()
    if (
      pickup.FrameCount <= 1
      and pickup.SpawnerType == EntityType.ENTITY_PLAYER -- 1
      and pickup.Touched == false
      and pickup.Price == 0
      -- Make an exception for Sticky Nickels
      and (
        variant ~= PickupVariant.PICKUP_COIN -- 20
        or pickup.SubType ~= CoinSubType.COIN_STICKYNICKEL -- 5
      )
      -- Make an exception for Troll Bombs / Mega Troll Bombs
      and (
        variant ~= PickupVariant.PICKUP_BOMB -- 40
        or (
          pickup.SubType ~= BombSubType.BOMB_TROLL -- 3
          and pickup.SubType ~= BombSubType.BOMB_SUPERTROLL -- 5
        )
      )
      -- Make an exception for some detrimental (or potentially detrimental) trinkets
      and (
        variant ~= PickupVariant.PICKUP_TRINKET -- 350
        or (
          pickup.SubType ~= TrinketType.TRINKET_PURPLE_HEART -- 5
          and pickup.SubType ~= TrinketType.TRINKET_MOMS_TOENAIL -- 16
          and pickup.SubType ~= TrinketType.TRINKET_TICK -- 53
          and pickup.SubType ~= TrinketType.TRINKET_FADED_POLAROID -- 69
          and pickup.SubType ~= TrinketType.TRINKET_OUROBOROS_WORM -- 96
        )
      )
    ) then
      local distance = g.p.Position:DistanceSquared(pickup.Position)
      if nearestPickup == nil then
        nearestPickup = pickup
        nearestPickupDistance = distance
      elseif distance < nearestPickupDistance then
        nearestPickup = pickup
        nearestPickupDistance = distance
      end
    end
  end

  return nearestPickup
end

-- PickupVariant.PICKUP_COIN (20)
function PostItemPickup:InsertCoin(coin)
  if coin.SubType == CoinSubType.COIN_PENNY then -- 1
    g.p:AddCoins(1)
  elseif coin.SubType == CoinSubType.COIN_NICKEL then -- 2
    g.p:AddCoins(5)
  elseif coin.SubType == CoinSubType.COIN_DIME then -- 3
    g.p:AddCoins(10)
  elseif coin.SubType == CoinSubType.COIN_DOUBLEPACK then -- 4
    g.p:AddCoins(2)
  elseif coin.SubType == CoinSubType.COIN_LUCKYPENNY then -- 5
    g.p:AddCoins(1) -- (just ignore the luck component for simplicity)
  else
    -- Don't put Sticky Nickels in our inventory automatically
    return
  end

  coin:Remove()

  -- Arbitrarily use the "Touched" property to mark that it is in the process of being deleted
  coin.Touched = true

  return true
end

-- PickupVariant.PICKUP_KEY (30)
function PostItemPickup:InsertKey(key)
  if key.SubType == KeySubType.KEY_NORMAL then -- 1
    g.p:AddKeys(1)
  elseif key.SubType == KeySubType.KEY_GOLDEN then -- 2
    g.p:AddGoldenKey()
  elseif key.SubType == KeySubType.KEY_DOUBLEPACK then -- 3
    g.p:AddKeys(2)
  elseif key.SubType == KeySubType.KEY_CHARGED then -- 4
    g.p:AddKeys(1)
    g.p:FullCharge()
  end

  key:Remove()

  -- Arbitrarily use the "Touched" property to mark that it is in the process of being deleted
  key.Touched = true

  return true
end

-- PickupVariant.PICKUP_BOMB (40)
function PostItemPickup:InsertBomb(bomb)
  if bomb.SubType == BombSubType.BOMB_NORMAL then -- 1
    g.p:AddBombs(1)
  elseif bomb.SubType == BombSubType.BOMB_DOUBLEPACK then -- 2
    g.p:AddBombs(2)
  elseif bomb.SubType == BombSubType.BOMB_GOLDEN then -- 4
    g.p:AddGoldenBomb()
  else
    -- Don't do anything if it is a Troll Bomb or a Mega Troll Bomb
    return
  end

  bomb:Remove()

  -- Arbitrarily use the "Touched" property to mark that it is in the process of being deleted
  bomb.Touched = true

  return true
end

-- PickupVariant.PICKUP_PILL (70)
function PostItemPickup:InsertPill(pill)
  if not PostItemPickup:CheckPocketSlotOpen() then
    return
  end

  g.p:AddPill(pill.SubType)
  pill:Remove()

  -- Arbitrarily use the "Touched" property to mark that it is in the process of being deleted
  pill.Touched = true

  return true
end

-- PickupVariant.PICKUP_TAROTCARD (300)
function PostItemPickup:InsertCard(card)
  if not PostItemPickup:CheckPocketSlotOpen() then
    return
  end

  g.p:AddCard(card.SubType)
  card:Remove()

  -- Arbitrarily use the "Touched" property to mark that it is in the process of being deleted
  card.Touched = true

  return true
end

function PostItemPickup:CheckPocketSlotOpen()
  -- Local variables
  local card1 = g.p:GetCard(0) -- Returns 0 if no card
  local card2 = g.p:GetCard(1) -- Returns 0 if no card
  local pill1 = g.p:GetPill(0) -- Returns 0 if no pill
  local pill2 = g.p:GetPill(1) -- Returns 0 if no pill

  local slots = g.p:GetMaxPoketItems()
  if (
    (slots == 1 and (card1 ~= 0 or pill1 ~= 0))
    or (slots == 2 and (card2 ~= 0 or pill2 ~= 0))
  ) then
    return false
  end
  return true
end

-- PickupVariant.PICKUP_TRINKET (350)
function PostItemPickup:InsertTrinket(trinket)
  if not PostItemPickup:CheckTrinketSlotOpen() then
    return
  end

  g.p:AddTrinket(trinket.SubType)
  trinket:Remove()
  trinket.Touched = true
  -- (arbitrarily use the "Touched" property to mark that it is in the process of being deleted)

  Season8:RemoveTrinket(trinket.SubType)

  return true
end

function PostItemPickup:CheckTrinketSlotOpen()
  -- Local variables
  local trinket1 = g.p:GetTrinket(0) -- Returns 0 if no trinket
  local trinket2 = g.p:GetTrinket(1) -- Returns 0 if no trinket

  local slots = g.p:GetMaxTrinkets()
  if (
    (slots == 1 and trinket1 ~= 0)
    or (slots == 2 and trinket2 ~= 0)
  ) then
    return false
  end
  return true
end

-- CollectibleType.COLLECTIBLE_PAGEANT_BOY (141)
function PostItemPickup.PageantBoy()
  for i = 1, 7 do
    PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_COIN) -- 20
  end
end

-- CollectibleType.COLLECTIBLE_BOX (198)
function PostItemPickup.Box()
  PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_COIN) -- 20
  PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_KEY) -- 30
  PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_BOMB) -- 40
  PostItemPickup:InsertNearestCardPill()
  PostItemPickup:InsertNearestCardPill()
  PostItemPickup:InsertNearestTrinket()
  -- (we ignore the heart)
end

-- CollectibleType.COLLECTIBLE_CAFFEINE_PILL (340)
-- Caffeine Pill is unique in that it will already insert the pill into the player's inventory
-- Change the behavior such that given pill will not replace your current card/pill
function PostItemPickup.CaffeinePill()
  -- Local variables
  local pill1 = g.p:GetPill(0) -- Returns 0 if no pill

  -- Find the first pill or card on the ground that is freshly spawned
  local droppedPickup = PostItemPickup:FindNearestPickup(PickupVariant.PICKUP_PILL) -- 70
  if droppedPickup == nil then
    droppedPickup = PostItemPickup:FindNearestPickup(PickupVariant.PICKUP_TAROTCARD) -- 300
  end
  if droppedPickup == nil then
    return
  end

  -- Directly overwrite the pill from Caffeine Pill (the given pill will always go to slot 1)
  local pickupName
  if droppedPickup.Variant == PickupVariant.PICKUP_PILL then -- 70 then
    g.p:SetPill(0, droppedPickup.SubType)
    pickupName = "pill"
  elseif droppedPickup.Variant == PickupVariant.PICKUP_TAROTCARD then -- 300 then
    g.p:SetCard(0, droppedPickup.SubType)
    pickupName = "card"
  end
  Isaac.DebugString(
    "Returned " .. pickupName .. " " .. tostring(droppedPickup.SubType) .. " and dropped pill "
    .. tostring(pill1) .. "."
  )
  droppedPickup:Remove()

  -- Drop the pill given from Caffeine Pill
  -- (we spawn it instead of using "player:DropPoketItem()" to avoid the complexity of having two
  -- slots)
  local pos = g.r:FindFreePickupSpawnPosition(g.p.Position, 1, true)
  Isaac.Spawn(
    EntityType.ENTITY_PICKUP, -- 5
    PickupVariant.PICKUP_PILL, -- 70
    pill1,
    pos,
    g.zeroVector,
    g.p
  )
end

-- CollectibleType.COLLECTIBLE_LATCH_KEY (343)
function PostItemPickup.LatchKey()
  for i = 1, 2 do
    PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_KEY) -- 30
  end
end

-- CollectibleType.COLLECTIBLE_MATCH_BOOK (344)
function PostItemPickup.MatchBook()
  for i = 1, 3 do
    PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_BOMB) -- 40
  end
end

-- CollectibleType.COLLECTIBLE_RESTOCK (376)
function PostItemPickup.Restock()
  for i = 1, 3 do
    PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_COIN) -- 20
    PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_KEY) -- 30
    PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_BOMB) -- 40
    PostItemPickup:InsertNearestCardPill()
    PostItemPickup:InsertNearestTrinket()
  end
end

-- CollectibleType.COLLECTIBLE_CHAOS (402)
function PostItemPickup.Chaos()
  for i = 1, 6 do
    PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_COIN) -- 20
    PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_KEY) -- 30
    PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_BOMB) -- 40
    PostItemPickup:InsertNearestCardPill()
    PostItemPickup:InsertNearestTrinket()
  end
end

-- CollectibleType.COLLECTIBLE_DADS_LOST_COIN (455)
function PostItemPickup.DadsLostCoin()
  g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_DADS_LOST_COIN) -- 455
  Isaac.DebugString("Removing collectible 455 (Dad's Lost Coin (Vanilla))")
  g.p:AddCollectible(CollectibleType.COLLECTIBLE_DADS_LOST_COIN_CUSTOM, 0, false)
  PostItemPickup:RemoveNearestPickup(PickupVariant.PICKUP_COIN) -- 20
end

-- CollectibleType.COLLECTIBLE_DIVORCE_PAPERS (547)
function PostItemPickup.DivorcePapers()
  g.itemPool:RemoveTrinket(TrinketType.TRINKET_MYSTERIOUS_PAPER) -- 21
  if (
    Isaac.GetChallenge() == Isaac.GetChallengeIdByName("R+7 (Season 8)")
    and g:TableContains(Season8.touchedTrinkets, TrinketType.TRINKET_MYSTERIOUS_PAPER)
  ) then
    PostItemPickup:RemoveNearestTrinket()
    return
  end
  PostItemPickup:InsertNearestTrinket()
end

PostItemPickup.functions = {
  [CollectibleType.COLLECTIBLE_PHD] = PostItemPickup.InsertNearestPill, -- 75
  [CollectibleType.COLLECTIBLE_PAGEANT_BOY] = PostItemPickup.PageantBoy, -- 141
  [CollectibleType.COLLECTIBLE_MAGIC_8_BALL] = PostItemPickup.InsertNearestCard, -- 194
  [CollectibleType.COLLECTIBLE_MOMS_COIN_PURSE] = PostItemPickup.InsertNearestPill, -- 195
  [CollectibleType.COLLECTIBLE_BOX] = PostItemPickup.Box, -- 198
  [CollectibleType.COLLECTIBLE_STARTER_DECK] = PostItemPickup.InsertNearestCard, -- 251
  [CollectibleType.COLLECTIBLE_LITTLE_BAGGY] = PostItemPickup.InsertNearestPill, -- 252
  [CollectibleType.COLLECTIBLE_CAFFEINE_PILL] = PostItemPickup.CaffeinePill, -- 340
  [CollectibleType.COLLECTIBLE_LATCH_KEY] = PostItemPickup.LatchKey, -- 343
  [CollectibleType.COLLECTIBLE_MATCH_BOOK] = PostItemPickup.MatchBook, -- 344
  [CollectibleType.COLLECTIBLE_CRACK_JACKS] = PostItemPickup.InsertNearestTrinket, -- 354
  [CollectibleType.COLLECTIBLE_RESTOCK] = PostItemPickup.Restock, -- 376
  [CollectibleType.COLLECTIBLE_CHAOS] = PostItemPickup.Chaos, -- 402
  [CollectibleType.COLLECTIBLE_TAROT_CLOTH] = PostItemPickup.InsertNearestCard, -- 451
  [CollectibleType.COLLECTIBLE_BELLY_BUTTON] = PostItemPickup.InsertNearestTrinket, -- 458
  [CollectibleType.COLLECTIBLE_DADS_LOST_COIN] = PostItemPickup.DadsLostCoin, -- 455
  [CollectibleType.COLLECTIBLE_POLYDACTYLY] = PostItemPickup.InsertNearestCardPill, -- 454
  [CollectibleType.COLLECTIBLE_LIL_SPEWER] = PostItemPickup.InsertNearestPill, -- 537
  [CollectibleType.COLLECTIBLE_DIVORCE_PAPERS] = PostItemPickup.DivorcePapers, -- 547
}

return PostItemPickup

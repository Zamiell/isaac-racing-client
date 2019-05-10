local PostItemPickup = {}

-- These functions are mostly used to deposit items directly in the player's inventory, if there is room

-- Includes
local g = require("racing_plus/globals")

function PostItemPickup:InsertCoins()
  -- Put all of the freshly spawned coins into our inventory
  local coins = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, -1, false, false) -- 5.20
  for _, coin in ipairs(coins) do
    PostItemPickup:InsertCoin(coin)
  end
end

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
    g.p:AddCoins(1)
    -- (just ignore the luck component for simplicity)
  end -- (don't put Sticky Nickels in our inventory automatically)
  coin:Remove()
end

function PostItemPickup:InsertKeys()
  -- Put all of the freshly spawned keys into our inventory
  local keys = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, -1, false, false) -- 5.30
  for _, key in ipairs(keys) do
    PostItemPickup:InsertKey(key)
  end
end

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
end

function PostItemPickup:InsertBombs()
  -- Put all of the freshly spawned bombs into our inventory
  local bombs = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, -1, false, false) -- 5.40
  for _, bomb in ipairs(bombs) do
    PostItemPickup:InsertBomb(bomb)
  end
end

function PostItemPickup:InsertBomb(bomb)
  if bomb.SubType == BombSubType.BOMB_NORMAL then -- 1
    g.p:AddBombs(1)
  elseif bomb.SubType == BombSubType.BOMB_DOUBLEPACK then -- 2
    g.p:AddBombs(2)
  elseif bomb.SubType == BombSubType.BOMB_GOLDEN then -- 4
    g.p:AddGoldenBomb()
  end -- (don't do anything if it is a Troll Bomb or a Mega Troll Bomb)
  bomb:Remove()
end

function PostItemPickup:InsertPocketItems()
  PostItemPickup:InsertPocketItem()
  PostItemPickup:InsertPocketItem() -- Call it twice in case we have two open pocket item slots
end

-- Put the first pocket item on the ground that is freshly spawned into our inventory
-- (but prefer cards/runes over pills)
function PostItemPickup:InsertPocketItem()
  if not PostItemPickup:CheckPocketSlotOpen() then
    return
  end

  local cards = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, -1, false, false) -- 300
  for _, entity in ipairs(cards) do
    local card = entity:ToPickup()
    if card.FrameCount == 0 and
       not card.Touched then

      g.p:AddCard(card.SubType)
      card:Remove()
      card.Touched = true -- (arbitrarily use the "Touched" property to mark that it is in the process of being deleted)
      return
    end
  end

  local pills = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, -1, false, false) -- 70
  for _, entity in ipairs(pills) do
    local pill = entity:ToPickup()
    if pill.FrameCount == 0 and
       not pill.Touched then

      g.p:AddPill(pill.SubType)
      pill:Remove()
      pill.Touched = true -- (arbitrarily use the "Touched" property to mark that it is in the process of being deleted)
      return
    end
  end
end

function PostItemPickup:CheckPocketSlotOpen()
  -- Local variables
  local card1 = g.p:GetCard(0) -- Returns 0 if no card
  local card2 = g.p:GetCard(1) -- Returns 0 if no card
  local pill1 = g.p:GetPill(0) -- Returns 0 if no pill
  local pill2 = g.p:GetPill(1) -- Returns 0 if no pill

  local slots = g.p:GetMaxPoketItems()
  if (slots == 1 and (card1 ~= 0 or pill1 ~= 0)) or
     (slots == 2 and (card2 ~= 0 or pill2 ~= 0)) then

    return false
  end
  return true
end

function PostItemPickup:InsertTrinkets()
  PostItemPickup:InsertTrinket()
  PostItemPickup:InsertTrinket() -- Call it twice in case we have two open trinket slots
end

function PostItemPickup:InsertTrinket()
  if not PostItemPickup:CheckTrinketSlotOpen() then
    return
  end

  -- Put the first trinket on the ground that is freshly spawned into our inventory
  local trinkets = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, -1, false, false) -- 5.350
  local trinketToInsert = nil
  for _, entity in ipairs(trinkets) do
    local trinket = entity:ToPickup()
    if trinket.FrameCount == 0 and
       not trinket.Touched and
       -- Make an exception for some detrimental (or potentially detrimental) trinkets
       trinket.SubType ~= TrinketType.TRINKET_PURPLE_HEART and -- 5
       trinket.SubType ~= TrinketType.TRINKET_MOMS_TOENAIL and -- 16
       trinket.SubType ~= TrinketType.TRINKET_TICK and -- 53
       trinket.SubType ~= TrinketType.TRINKET_FADED_POLAROID and -- 69
       trinket.SubType ~= TrinketType.TRINKET_OUROBOROS_WORM then -- 96

      trinketToInsert = trinket
      break
    end
  end
  if trinketToInsert == nil then
    return
  end
  g.p:AddTrinket(trinketToInsert.SubType)
  trinketToInsert:Remove()
  trinketToInsert.Touched = true
  -- (arbitrarily use the "Touched" property to mark that it is in the process of being deleted)
end

function PostItemPickup:InsertAll()
  PostItemPickup:InsertCoins()
  PostItemPickup:InsertKeys()
  PostItemPickup:InsertBombs()
  PostItemPickup:InsertPocketItems()
  PostItemPickup:InsertTrinkets()
end

function PostItemPickup:CheckTrinketSlotOpen()
  -- Local variables
  local trinket1 = g.p:GetTrinket(0) -- Returns 0 if no trinket
  local trinket2 = g.p:GetTrinket(1) -- Returns 0 if no trinket

  local slots = g.p:GetMaxTrinkets()
  if (slots == 1 and trinket1 ~= 0) or
     (slots == 2 and trinket2 ~= 0) then

    return false
  end
  return true
end

-- Caffeine Pill is unique in that it will already insert the pill into the player's inventory
-- Change the behavior such that given pill will not replace your current card/pill
function PostItemPickup.CaffeinePill()
  -- Local variables
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"
  local pill1 = g.p:GetPill(0) -- Returns 0 if no pill

  -- Find the first pill or card on the ground that is freshly spawned
  local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP, -1, -1, false, false) -- 5
  local droppedPickup
  for _, pickup in ipairs(pickups) do
    if (pickup.Variant == PickupVariant.PICKUP_PILL or -- 70
        pickup.Variant == PickupVariant.PICKUP_TAROTCARD) and -- 300
       pickup.FrameCount == 0 then

      droppedPickup = pickup
      break
    end
  end
  if droppedPickup == nil then
    return
  end

  -- Directly overwrite the pill from Caffeine Pill (the given pill will always go to slot 1)
  local string = "Returned "
  if droppedPickup.Variant == PickupVariant.PICKUP_PILL then -- 70 then
    g.p:SetPill(0, droppedPickup.SubType)
    string = string .. "pill"
  elseif droppedPickup.Variant == PickupVariant.PICKUP_TAROTCARD then -- 300 then
    g.p:SetCard(0, droppedPickup.SubType)
    string = string .. "card"
  end
  string = string .. " " .. tostring(droppedPickup.SubType) .. " and dropped pill " .. tostring(pill1) .. "."
  Isaac.DebugString(string)
  droppedPickup:Remove()

  -- Drop the pill given from Caffeine Pill
  -- (we spawn it instead of using "player:DropPoketItem()" to avoid the complexity of having two slots)
  local pos = g.r:FindFreePickupSpawnPosition(g.p.Position, 1, true)
  g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, pos, Vector(0, 0), nil, pill1, roomSeed) -- 5.70
end

PostItemPickup.functions = {
  [CollectibleType.COLLECTIBLE_PHD] = PostItemPickup.InsertPocketItems, -- 75
  [CollectibleType.COLLECTIBLE_PAGEANT_BOY] = PostItemPickup.InsertCoins, -- 141
  [CollectibleType.COLLECTIBLE_MAGIC_8_BALL] = PostItemPickup.InsertPocketItems, -- 194
  [CollectibleType.COLLECTIBLE_MOMS_COIN_PURSE] = PostItemPickup.InsertPocketItems, -- 195
  [CollectibleType.COLLECTIBLE_BOX] = PostItemPickup.InsertAll, -- 198
  [CollectibleType.COLLECTIBLE_STARTER_DECK] = PostItemPickup.InsertPocketItems, -- 251
  [CollectibleType.COLLECTIBLE_LITTLE_BAGGY] = PostItemPickup.InsertPocketItems, -- 252
  [CollectibleType.COLLECTIBLE_CAFFEINE_PILL] = PostItemPickup.CaffeinePill, -- 340
  [CollectibleType.COLLECTIBLE_LATCH_KEY] = PostItemPickup.InsertKeys, -- 343
  [CollectibleType.COLLECTIBLE_MATCH_BOOK] = PostItemPickup.InsertBombs, -- 344
  [CollectibleType.COLLECTIBLE_CRACK_JACKS] = PostItemPickup.InsertTrinkets, -- 354
  [CollectibleType.COLLECTIBLE_RESTOCK] = PostItemPickup.InsertAll, -- 376
  [CollectibleType.COLLECTIBLE_CHAOS] = PostItemPickup.InsertAll, -- 402
  [CollectibleType.COLLECTIBLE_TAROT_CLOTH] = PostItemPickup.InsertPocketItems, -- 451
  [CollectibleType.COLLECTIBLE_BELLY_BUTTON] = PostItemPickup.InsertTrinkets, -- 458
  [CollectibleType.COLLECTIBLE_DADS_LOST_COIN] = PostItemPickup.InsertCoins, -- 455
  [CollectibleType.COLLECTIBLE_POLYDACTYLY] = PostItemPickup.InsertPocketItems, -- 454
  [CollectibleType.COLLECTIBLE_LIL_SPEWER] = PostItemPickup.InsertPocketItems, -- 537
  [CollectibleType.COLLECTIBLE_MARBLES] = PostItemPickup.InsertTrinkets, -- 538
  [CollectibleType.COLLECTIBLE_DIVORCE_PAPERS] = PostItemPickup.InsertTrinkets, -- 547
}

return PostItemPickup

local BagFamiliars = {}

-- Includes
local g = require("racing_plus/globals")

-- Variables
BagFamiliars.familiarTable = {}

function BagFamiliars:PostGameStarted()
  -- Local variables
  local stage = g.l:GetStage()
  local stageSeed = g.seeds:GetStageSeed(stage)

  BagFamiliars.familiarTable = {}
  for variant in pairs(BagFamiliars.functions) do
    BagFamiliars.familiarTable[variant] = {
      seed = stageSeed,
      roomsCleared = 0,
      incremented = false,
    }
  end
end

function BagFamiliars:Increment()
  -- Look through all of the player's familiars
  local familiars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, -1, -1, false, false) -- 3
  for _, familiar in ipairs(familiars) do
    -- We only want to increment the rooms cleared variable once,
    -- even we have multiple of the same familiar
    local familiarVars = BagFamiliars.familiarTable[familiar.Variant]
    if (
      familiarVars ~= nil
      and not familiarVars.incremented
    ) then
      familiarVars.incremented = true
      familiarVars.roomsCleared = familiarVars.roomsCleared + 1
    end
  end

  -- Reset the incremented variable
  for _, familiarVars in pairs(BagFamiliars.familiarTable) do
    familiarVars.incremented = false
  end
end

-- Emulate various familiars dropping things
-- (all of these formula were reverse engineered by blcd:
-- https://bindingofisaacrebirth.gamepedia.com/User:Blcd/RandomTidbits#Pickup_Familiars)
function BagFamiliars:CheckSpawn()
  -- Local variables
  local constant1 = 1.1 -- For Little C.H.A.D., Bomb Bag, Acid Baby, Sack of Sacks
  local constant2 = 1.11 -- For The Relic, Mystery Sack, Rune Bag
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then -- 247
    constant1 = 1.2
    constant2 = 1.15
  end

  -- Look through all of the player's familiars
  local entities = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, -1, -1, false, false) -- 3
  for _, entity in ipairs(entities) do
    local familiar = entity:ToFamiliar()
    local familiarFunction = BagFamiliars.functions[familiar.Variant]
    if familiarFunction ~= nil then
      familiarFunction(familiar, constant1, constant2)
    end
  end
end

-- FamiliarVariant.BOMB_BAG (20)
function BagFamiliars.BombBag(familiar, constant1, constant2)
  -- This drops a bomb based on the formula:
  -- floor(cleared / 1.1) > 0 && floor(cleared / 1.1) & 1 == 0
  -- or:
  -- floor(cleared / 1.2) > 0 && floor(cleared / 1.2) & 1 == 0
  local vars = BagFamiliars.familiarTable[familiar.Variant]
  local newRoomsCleared = vars.roomsCleared + 1

  if (
    math.floor(newRoomsCleared / constant1) > 0
    and math.floor(newRoomsCleared / constant1) & 1 == 0
  ) then
    -- Random Bomb
    vars.seed = g:IncrementRNG(vars.seed)
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_BOMB, -- 40
      familiar.Position,
      g.zeroVector,
      familiar,
      0,
      vars.seed
    )
  end
end

-- FamiliarVariant.SACK_OF_PENNIES (21)
function BagFamiliars.SackOfPennies(familiar, constant1, constant2)
  -- This drops a penny/nickel/dime/etc. based on the formula:
  -- cleared > 0 && cleared & 1 == 0
  -- or:
  -- cleared > 0 && (cleared & 1 == 0 || rand() % 3 == 0)
  local vars = BagFamiliars.familiarTable[familiar.Variant]
  local newRoomsCleared = vars.roomsCleared + 1

  vars.seed = g:IncrementRNG(vars.seed)
  math.randomseed(vars.seed)
  local sackBFFChance = math.random(1, 4294967295)
  if (
    newRoomsCleared > 0
    and (
      newRoomsCleared & 1 == 0
      or (g.p:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and sackBFFChance % 3 == 0) -- 247
    )
  ) then
    -- Random Coin
    vars.seed = g:IncrementRNG(vars.seed)
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_COIN, -- 20
      familiar.Position,
      g.zeroVector,
      g.p,
      0,
      vars.seed
    )
  end
end

-- FamiliarVariant.LITTLE_CHAD (22)
function BagFamiliars.LittleChad(familiar, constant1, constant2)
  -- This drops a half a red heart based on the formula:
  -- floor(cleared / 1.1) > 0 && floor(cleared / 1.1) & 1 == 0
  -- or:
  -- floor(cleared / 1.2) > 0 && floor(cleared / 1.2) & 1 == 0
  local vars = BagFamiliars.familiarTable[familiar.Variant]
  local newRoomsCleared = vars.roomsCleared + 1

  if (
    math.floor(newRoomsCleared / constant1) > 0
    and math.floor(newRoomsCleared / constant1) & 1 == 0
  ) then
    vars.seed = g:IncrementRNG(vars.seed)
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_HEART, -- 10
      familiar.Position,
      g.zeroVector,
      familiar,
      HeartSubType.HEART_HALF, -- 2
      vars.seed
    )
  end
end

-- FamiliarVariant.RELIC (23)
function BagFamiliars.Relic(familiar, constant1, constant2)
  -- This drops a soul heart based on the formula:
  -- floor(cleared / 1.11) & 3 == 2
  -- or:
  -- floor(cleared / 1.15) & 3 == 2
  local vars = BagFamiliars.familiarTable[familiar.Variant]
  local newRoomsCleared = vars.roomsCleared + 1

  if math.floor(newRoomsCleared / constant2) & 3 == 2 then
    -- Heart (soul)
    vars.seed = g:IncrementRNG(vars.seed)
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_HEART, -- 10
      familiar.Position,
      g.zeroVector,
      familiar,
      HeartSubType.HEART_SOUL, -- 3
      vars.seed
    )
  end
end

-- FamiliarVariant.JUICY_SACK (52)
function BagFamiliars.JuicySack(familiar, constant1, constant2)
  -- Spawn either 1 or 2 blue spiders (50% chance of each)
  local vars = BagFamiliars.familiarTable[familiar.Variant]
  vars.seed = g:IncrementRNG(vars.seed)
  math.randomseed(vars.seed)
  local spiders = math.random(1, 2)
  g.p:AddBlueSpider(familiar.Position)
  if spiders == 2 then
    g.p:AddBlueSpider(familiar.Position)
  end

  -- The BFFS! synergy gives an additional spider
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then -- 247
    g.p:AddBlueSpider(familiar.Position)
  end
end

-- FamiliarVariant.MYSTERY_SACK (57)
function BagFamiliars.MysterySack(familiar, constant1, constant2)
  -- This drops a heart, coin, bomb, or key based on the formula:
  -- floor(cleared / 1.11) & 3 == 2
  -- or:
  -- floor(cleared / 1.15) & 3 == 2
  -- (also, each pickup sub-type has an equal chance of occuring)
  local vars = BagFamiliars.familiarTable[familiar.Variant]
  local newRoomsCleared = vars.roomsCleared + 1

  if math.floor(newRoomsCleared / constant2) & 3 ~= 2 then
    return
  end

  -- First, decide whether we get a heart, coin, bomb, or key
  vars.seed = g:IncrementRNG(vars.seed)
  math.randomseed(vars.seed)
  local sackPickupType = math.random(1, 4)
  vars.seed = g:IncrementRNG(vars.seed)
  math.randomseed(vars.seed)

  if sackPickupType == 1 then
    local heartType = math.random(1, 11) -- From Heart (5.10.1) to Bone Heart (5.10.11)
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_HEART, -- 10
      familiar.Position,
      g.zeroVector,
      familiar,
      heartType,
      vars.seed
    )
  elseif sackPickupType == 2 then
    local coinType = math.random(1, 6) -- From Penny (5.20.1) to Sticky Nickel (5.20.6)
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_COIN, -- 20
      familiar.Position,
      g.zeroVector,
      familiar,
      coinType,
      vars.seed
    )
  elseif sackPickupType == 3 then
    local keyType = math.random(1, 4) -- From Key (5.30.1) to Charged Key (5.30.4)
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_KEY, -- 30
      familiar.Position,
      g.zeroVector,
      familiar,
      keyType,
      vars.seed
    )
  elseif sackPickupType == 4 then
    local bombType = math.random(1, 4) -- From Bomb (5.40.1) to Golden Bomb (5.40.4)
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_BOMB, -- 40
      familiar.Position,
      g.zeroVector,
      familiar,
      bombType,
      vars.seed
    )
  end
end

-- FamiliarVariant.LIL_CHEST (82)
function BagFamiliars.LilChest(familiar, constant1, constant2)
  -- This drops a heart, coin, bomb, or key based on the formula:
  -- 10% chance for a trinket, if no trinket, 25% chance for a random consumable (based on time)
  -- Or, with BFFS!, 12.5% chance for a trinket, if no trinket,
  -- 31.25% chance for a random consumable
  -- We don't want it based on time in the Racing+ mod
  local vars = BagFamiliars.familiarTable[familiar.Variant]

  -- First, decide whether we get a trinket
  vars.seed = g:IncrementRNG(vars.seed)
  math.randomseed(vars.seed)
  local chestTrinket = math.random(1, 1000)
  if (
    chestTrinket <= 100
    or (g.p:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 125) -- 247
  ) then
    -- Random Trinket
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_TRINKET, -- 350
      familiar.Position,
      g.zeroVector,
      familiar,
      0,
      vars.seed
    )
    return
  end

  -- Second, decide whether it spawns a consumable
  vars.seed = g:IncrementRNG(vars.seed)
  math.randomseed(vars.seed)
  local chestConsumable = math.random(1, 10000)
  if (
    chestConsumable <= 2500
    or (g.p:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 3125) -- 247
   ) then
    -- Third, decide whether we get a heart, coin, bomb, or key
    vars.seed = g:IncrementRNG(vars.seed)
    math.randomseed(vars.seed)
    local chestPickupType = math.random(1, 4)
    vars.seed = g:IncrementRNG(vars.seed)

    if chestPickupType == 1 then
      -- Random Heart
      g.g:Spawn(
        EntityType.ENTITY_PICKUP, -- 5
        PickupVariant.PICKUP_HEART, -- 10
        familiar.Position,
        g.zeroVector,
        familiar,
        0,
        vars.seed
      )
    elseif chestPickupType == 2 then
      -- Random Coin
      g.g:Spawn(
        EntityType.ENTITY_PICKUP, -- 5
        PickupVariant.PICKUP_COIN, -- 20
        familiar.Position,
        g.zeroVector,
        familiar,
        0,
        vars.seed
      )
    elseif chestPickupType == 3 then
      -- Random Key
      g.g:Spawn(
        EntityType.ENTITY_PICKUP, -- 5
        PickupVariant.PICKUP_KEY, -- 30
        familiar.Position,
        g.zeroVector,
        familiar,
        0,
        vars.seed
      )
    elseif chestPickupType == 4 then
      -- Random Bomb
      g.g:Spawn(
        EntityType.ENTITY_PICKUP, -- 5
        PickupVariant.PICKUP_BOMB, -- 40
        familiar.Position,
        g.zeroVector,
        familiar,
        0,
        vars.seed
      )
    end
  end
end

-- FamiliarVariant.BUMBO (88)
function BagFamiliars.Bumbo(familiar, constant1, constant2)
  -- Level 2 Bumbo has a 32% / 40% chance to drop a random pickup
  -- It will be state 0 at level 1, state 1 at level 2, state 2 at level 3, and state 3 at level 4
  if familiar.State + 1 ~= 2 then
    return
  end

  local vars = BagFamiliars.familiarTable[familiar.Variant]

  vars.seed = g:IncrementRNG(vars.seed)
  math.randomseed(vars.seed)
  local chestTrinket = math.random(1, 100)
  if (
    chestTrinket <= 32
    or (g.p:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 40) -- 247
  ) then
    -- Spawn a random pickup
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      0,
      familiar.Position,
      g.zeroVector,
      familiar,
      0,
      vars.seed
    )
  end
end

-- FamiliarVariant.RUNE_BAG (91)
function BagFamiliars.RuneBag(familiar, constant1, constant2)
  -- This drops a random rune based on the formula:
  -- floor(roomsCleared / 1.11) & 3 == 2
  local vars = BagFamiliars.familiarTable[familiar.Variant]
  local newRoomsCleared = vars.roomsCleared + 1

  if math.floor(newRoomsCleared / constant2) & 3 == 2 then
    -- For some reason you cannot spawn the normal "Random Rune" entity (5.301.0)
    -- So, use the GetCard() function
    vars.seed = g:IncrementRNG(vars.seed)
    local subType = g.itemPool:GetCard(vars.seed, false, true, true)
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_TAROTCARD, -- 300
      familiar.Position,
      g.zeroVector,
      familiar,
      subType,
      vars.seed
    )
  end
end

-- FamiliarVariant.SPIDER_MOD (94)
function BagFamiliars.SpiderMod(familiar, constant1, constant2)
  -- Spider Mod has a 10% or 12.5% chance to drop something
  local vars = BagFamiliars.familiarTable[familiar.Variant]

  vars.seed = g:IncrementRNG(vars.seed)
  math.randomseed(vars.seed)
  local chestTrinket = math.random(1, 1000)
  if (
    chestTrinket <= 100
    or (g.p:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and chestTrinket <= 125) -- 247
  ) then
    -- There is a 1/3 chance to spawn a battery and a 2/3 chance to spawn a blue spider
    vars.seed = g:IncrementRNG(vars.seed)
    math.randomseed(vars.seed)
    local spiderModDrop = math.random(1, 3)
    if spiderModDrop == 1 then
      g.g:Spawn(
        EntityType.ENTITY_PICKUP, -- 5
        PickupVariant.PICKUP_LIL_BATTERY, -- 90
        familiar.Position,
        g.zeroVector,
        familiar,
        0,
        vars.seed
      )
    else
      g.p:AddBlueSpider(familiar.Position)
    end
  end
end

-- FamiliarVariant.ACID_BABY (112)
function BagFamiliars.AcidBaby(familiar, constant1, constant2)
  -- This drops a pill based on the formula:
  -- floor(roomsCleared / 1.1) > 0 && floor(roomsCleared / 1.1) & 1 == 0
  local vars = BagFamiliars.familiarTable[familiar.Variant]
  local newRoomsCleared = vars.roomsCleared + 1
  if (
    math.floor(newRoomsCleared / constant1) > 0
    and math.floor(newRoomsCleared / constant1) & 1 == 0
  ) then
    -- Random Pill
    vars.seed = g:IncrementRNG(vars.seed)
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_PILL, -- 70
      familiar.Position,
      g.zeroVector,
      familiar,
      0,
      vars.seed
    )
  end
end

-- FamiliarVariant.SACK_OF_SACKS (114)
function BagFamiliars.SackOfSacks(familiar, constant1, constant2)
  -- This drops a sack based on the formula:
  -- floor(roomsCleared / 1.1) > 0 && floor(roomsCleared / 1.1) & 1 == 0
  local vars = BagFamiliars.familiarTable[familiar.Variant]
  local newRoomsCleared = vars.roomsCleared + 1

  if (
    math.floor(newRoomsCleared / constant1) > 0
    and math.floor(newRoomsCleared / constant1) & 1 == 0
  ) then
    vars.seed = g:IncrementRNG(vars.seed)
    g.g:Spawn(
      EntityType.ENTITY_PICKUP, -- 5
      PickupVariant.PICKUP_GRAB_BAG, -- 69
      familiar.Position,
      g.zeroVector,
      familiar,
      0,
      vars.seed
    )
  end
end

BagFamiliars.functions = {
  [FamiliarVariant.BOMB_BAG] = BagFamiliars.BombBag, -- 20
  [FamiliarVariant.SACK_OF_PENNIES] = BagFamiliars.SackOfPennies, -- 21
  [FamiliarVariant.LITTLE_CHAD] = BagFamiliars.LittleChad, -- 22
  [FamiliarVariant.RELIC] = BagFamiliars.Relic, -- 23
  [FamiliarVariant.JUICY_SACK] = BagFamiliars.JuicySack, -- 52
  [FamiliarVariant.MYSTERY_SACK] = BagFamiliars.MysterySack, -- 57
  [FamiliarVariant.LIL_CHEST] = BagFamiliars.LilChest, -- 82
  [FamiliarVariant.BUMBO] = BagFamiliars.Bumbo, -- 88
  [FamiliarVariant.RUNE_BAG] = BagFamiliars.RuneBag, -- 91
  [FamiliarVariant.SPIDER_MOD] = BagFamiliars.SpiderMod, -- 94
  [FamiliarVariant.ACID_BABY] = BagFamiliars.AcidBaby, -- 112
  [FamiliarVariant.SACK_OF_SACKS] = BagFamiliars.SackOfSacks, -- 114
}

return BagFamiliars

local EvaluateCache = {}

-- Includes
local g = require("racing_plus/globals")

-- ModCallbacks.MC_EVALUATE_CACHE (8)
function EvaluateCache:Main(player, cacheFlag)
  local cacheFunction = EvaluateCache.cacheFunctions[cacheFlag]
  if cacheFunction ~= nil then
    cacheFunction(player, cacheFlag)
  end

  EvaluateCache:DebugStats(player, cacheFlag)
end

-- CacheFlag.CACHE_DAMAGE (1)
function EvaluateCache.Damage(player, cacheFlag)
  EvaluateCache:TechZeroBuild(player, cacheFlag)
end

function EvaluateCache:TechZeroBuild(player, cacheFlag)
  if (
    g:TableContains(g.race.startingItems, CollectibleType.COLLECTIBLE_TECHNOLOGY_ZERO) -- 524
    and g:TableContains(g.race.startingItems, CollectibleType.COLLECTIBLE_POP) -- 529
    and g:TableContains(g.race.startingItems, CollectibleType.COLLECTIBLE_CUPIDS_ARROW) -- 48
    and not g.p:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) -- 114
    and not g.p:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) -- 395
    and not g.p:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) -- 168
    and not g.p:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) -- 149
    and not g.p:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) -- 118
    and not g.p:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) -- 52
  ) then
    player.Damage = player.Damage * 0.5
  end
end

-- CacheFlag.CACHE_SHOTSPEED (4)
function EvaluateCache.ShotSpeed(player, cacheFlag)
  EvaluateCache:CrownOfLight(player, cacheFlag) -- 415
end

-- CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT (415)
function EvaluateCache:CrownOfLight(player, cacheFlag)
  -- Local variables
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()
  local character = player:GetPlayerType()

  -- If Crown of Light is started from a Basement 1 Treasure Room, it should heal for a half heart
  if (
    player:HasCollectible(CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT) -- 415
    and stage == 1
    and roomType == RoomType.ROOM_TREASURE -- 4
    -- (this will still work even if you exit the room with the item held overhead)
    and character == PlayerType.PLAYER_JUDAS -- 7
  ) then
    player:AddHearts(1)
  end
end

-- CacheFlag.CACHE_RANGE (8)
function EvaluateCache.Range(player, cacheFlag)
  EvaluateCache:ManageKeeperHeartContainers(player, cacheFlag)
end

function EvaluateCache:ManageKeeperHeartContainers(player, cacheFlag)
  -- Local variables
  local character = player:GetPlayerType()
  local maxHearts = player:GetMaxHearts()
  local coins = player:GetNumCoins()
  local coinContainers = 0

  if (
    character ~= PlayerType.PLAYER_KEEPER -- 14
    or not player:HasCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET) -- 501
  ) then
    return
  end

  -- Find out how many coin containers we should have
  -- (2 is equal to 1 actual heart container)
  if coins >= 99 then
    coinContainers = 8
  elseif coins >= 75 then
    coinContainers = 6
  elseif coins >= 50 then
    coinContainers = 4
  elseif coins >= 25 then
    coinContainers = 2
  end
  local baseHearts = maxHearts - coinContainers

  -- We have to add the range cache to all health up items in "items.xml"
  for _, itemID in ipairs(g.healthUpItems) do
    if (
      (itemID ~= 1000 and player:GetCollectibleNum(itemID) > g.run.keeper.healthUpItems[itemID])
      or (itemID == 1000 and g.run.keeper.usedHealthUpPill)
    ) then
      g.run.keeper.healthUpItems[itemID] = g.run.keeper.healthUpItems[itemID] + 1
      if itemID == CollectibleType.COLLECTIBLE_DEAD_CAT then -- 81
        -- "player:GetCollectibleNum(81)" will return 9 after a player picks up Dead Cat,
        -- so we need to account for this
        g.run.keeper.healthUpItems[itemID] = g.run.keeper.healthUpItems[itemID] + 8
      end
      if itemID == 1000 then
        g.run.keeper.usedHealthUpPill = false
      end
      Isaac.DebugString("Keeper got a health up item: " .. tostring(itemID))

      if itemID == CollectibleType.COLLECTIBLE_ABADDON then -- 230
        player:AddMaxHearts(-24, true) -- Remove all hearts
        -- Give whatever containers we should have from coins
        player:AddMaxHearts(coinContainers, true)
        player:AddHearts(24) -- This is needed because all the new heart containers will be empty
        -- We have no way of knowing what the current health was before,
        -- because "player:GetHearts()" returns 0 at this point
        -- So, just give them max health
        Isaac.DebugString("Set 0 heart containers to Keeper (Abaddon).")
      elseif itemID == CollectibleType.COLLECTIBLE_DEAD_CAT then -- 81
        player:AddMaxHearts(-24, true) -- Remove all hearts
        player:AddMaxHearts(2 + coinContainers, true)
        -- Give 1 heart container + whatever containers we should have from coins
        player:AddHearts(24) -- This is needed because all the new heart containers will be empty
        -- We have no way of knowing what the current health was before,
        -- because "player:GetHearts()" returns 0 at this point
        -- So, just give them max health
        Isaac.DebugString("Set 1 heart container to Keeper (Dead Cat).")
      elseif (
        baseHearts < 0
        and itemID == CollectibleType.COLLECTIBLE_BODY -- 334
      ) then
        player:AddMaxHearts(6, true) -- Give 3 heart containers
        Isaac.DebugString("Gave 3 heart containers to Keeper.")

        -- Fill in the new containers
        player:AddCoins(1)
        player:AddCoins(1)
        player:AddCoins(1)
      elseif (
        baseHearts < 2
        and (
          itemID == CollectibleType.COLLECTIBLE_RAW_LIVER -- 16
          or itemID == CollectibleType.COLLECTIBLE_BUCKET_LARD -- 129
          or itemID == CollectibleType.COLLECTIBLE_BODY -- 334
        )
      ) then
        player:AddMaxHearts(4, true) -- Give 2 heart containers
        Isaac.DebugString("Gave 2 heart containers to Keeper.")

        -- Fill in the new containers
        player:AddCoins(1)
        player:AddCoins(1)
      elseif baseHearts < 4 then
        player:AddMaxHearts(2, true) -- Give 1 heart container
        Isaac.DebugString("Gave 1 heart container to Keeper.")

        if (
          itemID ~= CollectibleType.COLLECTIBLE_ODD_MUSHROOM_DAMAGE -- 121
          and itemID ~= CollectibleType.COLLECTIBLE_OLD_BANDAGE -- 219
          and itemID ~= 1000 -- Health Up pill
        ) then
          -- Fill in the new container
          -- (Odd Mushroom (Thick) and Old Bandage do not give filled heart containers)
          player:AddCoins(1)
        end
      else
        Isaac.DebugString("Health up detected, but baseHearts are full.")
      end
    end
  end
end

-- CacheFlag.CACHE_SPEED (16)
function EvaluateCache.Speed(player, cacheFlag)
  EvaluateCache:Magdalene(player, cacheFlag)
end

function EvaluateCache:Magdalene(player, cacheFlag)
  -- Local variables
  local character = player:GetPlayerType()

  if character ~= PlayerType.PLAYER_MAGDALENA then -- 1
    return
  end

  -- Emulate having used the starting "Speed Up" pill
  player.MoveSpeed = player.MoveSpeed + 0.15
end

-- CacheFlag.CACHE_LUCK (1024)
function EvaluateCache.Luck(player, cacheFlag)
  EvaluateCache:DadsLostCoin(player, cacheFlag) -- 455
  EvaluateCache:PageantBoyRuleset(player, cacheFlag)
  EvaluateCache:ThirteenLuck(player, cacheFlag)
end

-- CollectibleType.COLLECTIBLE_DADS_LOST_COIN (455)
function EvaluateCache:DadsLostCoin(player, cacheFlag)
  -- We want to put the lucky penny directly into the inventory,
  -- so we make the item itself grant luck
  local numDadsLostCoins = g.p:GetCollectibleNum(CollectibleType.COLLECTIBLE_DADS_LOST_COIN) -- 455
  if numDadsLostCoins > 0 then
    for i = 1, numDadsLostCoins do
      player.Luck = player.Luck + 1
    end
  end
end

function EvaluateCache:PageantBoyRuleset(player, cacheFlag)
  -- The Pageant Boy ruleset starts with 7 luck
  if g.race.rFormat == "pageant" then
    player.Luck = player.Luck + 7
  end
end

-- CollectibleType.CollectibleType.COLLECTIBLE_13_LUCK
function EvaluateCache:ThirteenLuck(player, cacheFlag)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_13_LUCK) then
    player.Luck = 13
  end
end

function EvaluateCache:DebugStats(player, cacheFlag)
  if (
    g.run.debugDamage
    and cacheFlag == CacheFlag.CACHE_DAMAGE -- 1
  ) then
    player.Damage = 1000
  end

  if (
    g.run.debugTears
    and cacheFlag == CacheFlag.CACHE_FIREDELAY -- 2
  ) then
    player.MaxFireDelay = 3
  end

  if (
    g.run.debugSpeed
    and cacheFlag == CacheFlag.CACHE_SPEED -- 16
  ) then
    player.MoveSpeed = 2
  end
end

EvaluateCache.cacheFunctions = {
  [CacheFlag.CACHE_DAMAGE] = EvaluateCache.Damage, -- 1
  [CacheFlag.CACHE_SHOTSPEED] = EvaluateCache.ShotSpeed, -- 4
  [CacheFlag.CACHE_RANGE] = EvaluateCache.Range, -- 8
  [CacheFlag.CACHE_SPEED] = EvaluateCache.Speed, -- 16
  [CacheFlag.CACHE_LUCK] = EvaluateCache.Luck, -- 1024
}

return EvaluateCache

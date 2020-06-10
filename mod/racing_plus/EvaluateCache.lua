local EvaluateCache = {}

-- Includes
local g = require("racing_plus/globals")

-- ModCallbacks.MC_EVALUATE_CACHE (8)
function EvaluateCache:Main(player, cacheFlag)
  -- CacheFlag.CACHE_DAMAGE (1)
  EvaluateCache:TechZeroBuild(player, cacheFlag)

  -- CacheFlag.CACHE_SHOTSPEED (4)
  EvaluateCache:CrownOfLight(player, cacheFlag) -- 415

  -- CacheFlag.CACHE_RANGE (8)
  EvaluateCache:ManageKeeperHeartContainers(player, cacheFlag)

  -- CacheFlag.CACHE_SPEED (16)
  EvaluateCache:Magdalene(player, cacheFlag)

  -- CacheFlag.CACHE_LUCK (1024)
  EvaluateCache:DadsLostCoin(player, cacheFlag) -- 455
  EvaluateCache:PageantBoyRuleset(player, cacheFlag)
  EvaluateCache:ThirteenLuck(player, cacheFlag) -- +13 luck

  -- Multiple
  EvaluateCache:DebugStats(player, cacheFlag)
end

function EvaluateCache:TechZeroBuild(player, cacheFlag)
  if cacheFlag ~= CacheFlag.CACHE_DAMAGE then -- 1
    return
  end

  if g:TableContains(g.race.startingItems, CollectibleType.COLLECTIBLE_TECHNOLOGY_ZERO) and -- 524
     g:TableContains(g.race.startingItems, CollectibleType.COLLECTIBLE_POP) and -- 529
     g:TableContains(g.race.startingItems, CollectibleType.COLLECTIBLE_CUPIDS_ARROW) and -- 48
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) and -- 114
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) and -- 395
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) and -- 168
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) and -- 149
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) and -- 118
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) then -- 52

    player.Damage = player.Damage * 0.5
  end
end

-- CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT (415)
function EvaluateCache:CrownOfLight(player, cacheFlag)
  -- Local variables
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()
  local character = player:GetPlayerType()

  -- If Crown of Light is started from a Basement 1 Treasure Room, it should heal for a half heart
  if cacheFlag == CacheFlag.CACHE_SHOTSPEED and -- 4
     player:HasCollectible(CollectibleType.COLLECTIBLE_CROWN_OF_LIGHT) and -- 415
     stage == 1 and
     roomType == RoomType.ROOM_TREASURE and -- 4
     -- (this will still work even if you exit the room with the item held overhead)
     character == PlayerType.PLAYER_JUDAS then -- 7

    player:AddHearts(1)
  end
end

function EvaluateCache:ManageKeeperHeartContainers(player, cacheFlag)
  -- Local variables
  local character = player:GetPlayerType()
  local maxHearts = player:GetMaxHearts()
  local coins = player:GetNumCoins()
  local coinContainers = 0

  if character ~= PlayerType.PLAYER_KEEPER or -- 14
     not player:HasCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET) or -- 501
     cacheFlag ~= CacheFlag.CACHE_RANGE then -- 8

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
    if (itemID ~= 1000 and player:GetCollectibleNum(itemID) > g.run.keeper.healthUpItems[itemID]) or
        (itemID == 1000 and g.run.keeper.usedHealthUpPill) then

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
        player:AddMaxHearts(coinContainers, true) -- Give whatever containers we should have from coins
        player:AddHearts(24) -- This is needed because all the new heart containers will be empty
        -- We have no way of knowing what the current health was before, because "player:GetHearts()"
        -- returns 0 at this point. So, just give them max health.
        Isaac.DebugString("Set 0 heart containers to Keeper (Abaddon).")

      elseif itemID == CollectibleType.COLLECTIBLE_DEAD_CAT then -- 81
        player:AddMaxHearts(-24, true) -- Remove all hearts
        player:AddMaxHearts(2 + coinContainers, true)
        -- Give 1 heart container + whatever containers we should have from coins
        player:AddHearts(24) -- This is needed because all the new heart containers will be empty
        -- We have no way of knowing what the current health was before, because "player:GetHearts()"
        -- returns 0 at this point. So, just give them max health.
        Isaac.DebugString("Set 1 heart container to Keeper (Dead Cat).")

      elseif baseHearts < 0 and
              itemID == CollectibleType.COLLECTIBLE_BODY then -- 334

        player:AddMaxHearts(6, true) -- Give 3 heart containers
        Isaac.DebugString("Gave 3 heart containers to Keeper.")

        -- Fill in the new containers
        player:AddCoins(1)
        player:AddCoins(1)
        player:AddCoins(1)

      elseif baseHearts < 2 and
              (itemID == CollectibleType.COLLECTIBLE_RAW_LIVER or -- 16
              itemID == CollectibleType.COLLECTIBLE_BUCKET_LARD or -- 129
              itemID == CollectibleType.COLLECTIBLE_BODY) then -- 334

        player:AddMaxHearts(4, true) -- Give 2 heart containers
        Isaac.DebugString("Gave 2 heart containers to Keeper.")

        -- Fill in the new containers
        player:AddCoins(1)
        player:AddCoins(1)

      elseif baseHearts < 4 then
        player:AddMaxHearts(2, true) -- Give 1 heart container
        Isaac.DebugString("Gave 1 heart container to Keeper.")

        if itemID ~= CollectibleType.COLLECTIBLE_ODD_MUSHROOM_DAMAGE and -- 121
            itemID ~= CollectibleType.COLLECTIBLE_OLD_BANDAGE and -- 219
            itemID ~= 1000 then -- Health Up pill

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

function EvaluateCache:Magdalene(player, cacheFlag)
  -- Local variables
  local character = player:GetPlayerType()

  if character ~= PlayerType.PLAYER_MAGDALENA or -- 1
     cacheFlag ~= CacheFlag.CACHE_SPEED then -- 16

    return
  end

  -- Emulate having used the starting "Speed Up" pill
  player.MoveSpeed = player.MoveSpeed + 0.15
end

-- CollectibleType.COLLECTIBLE_DADS_LOST_COIN (455)
function EvaluateCache:DadsLostCoin(player, cacheFlag)
  -- We want to put the lucky penny directly into the inventory
  if cacheFlag == CacheFlag.CACHE_LUCK and -- 1024
     player:HasCollectible(CollectibleType.COLLECTIBLE_DADS_LOST_COIN) then -- 455

    player.Luck = player.Luck + 1
  end
end

function EvaluateCache:PageantBoyRuleset(player, cacheFlag)
  -- The Pageant Boy ruleset starts with 7 luck
  if cacheFlag == CacheFlag.CACHE_LUCK and -- 1024
     g.race.rFormat == "pageant" then

    player.Luck = player.Luck + 7
  end
end

-- CollectibleType.CollectibleType.COLLECTIBLE_13_LUCK
function EvaluateCache:ThirteenLuck(player, cacheFlag)
  -- Look for the custom start item that gives 13 luck
  if cacheFlag == CacheFlag.CACHE_LUCK and -- 1024
     player:HasCollectible(CollectibleType.COLLECTIBLE_13_LUCK) then

    player.Luck = 13
  end
end

function EvaluateCache:DebugStats(player, cacheFlag)
  if g.run.debugDamage and
     cacheFlag == CacheFlag.CACHE_DAMAGE then -- 1

    player.Damage = 1000
  end

  if g.run.debugTears and
     cacheFlag == CacheFlag.CACHE_FIREDELAY then -- 2

    player.MaxFireDelay = 3
  end

  if g.run.debugSpeed and
     cacheFlag == CacheFlag.CACHE_SPEED then -- 16

    player.MoveSpeed = 2
  end
end

return EvaluateCache

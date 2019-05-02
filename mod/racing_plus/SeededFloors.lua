local SeededFloors = {}

-- Includes
local g = require("racing_plus/globals")

-- Different inventory and health conditions can affect special room generation
-- Different special rooms can also sometimes change the actual room selection of non-special rooms
-- This is bad for seeded races; we want to ensure consistent floors
-- Thus, we arbitrarily set inventory and health conditions before going to the next floor, and then swap them back
-- https://bindingofisaacrebirth.gamepedia.com/Level_Generation
function SeededFloors:Before(stage)
  -- Local variables
  local character = g.p:GetPlayerType()
  local goldenHearts = g.p:GetGoldenHearts()
  local coins = g.p:GetNumCoins()
  local keys = g.p:GetNumKeys()
  local seed = g.seeds:GetStageSeed(stage)
  local customRun = g.seeds:IsCustomRun()
  local challenge = Isaac.GetChallenge()

  -- Only swap things if we are playing a specific seed
  if challenge ~= 0 or
     not customRun then

    return
  end

  -- Record the current inventory and health values
  g.run.seededSwap.swapping = true
  g.run.seededSwap.devilVisited = g.g:GetStateFlag(GameStateFlag.STATE_DEVILROOM_VISITED) -- 6
  g.run.seededSwap.bookTouched = g.g:GetStateFlag(GameStateFlag.STATE_BOOK_PICKED_UP) -- 8
  g.run.seededSwap.coins = coins
  g.run.seededSwap.keys = keys
  g.run.seededSwap.heartTable = SeededFloors:SaveHealth()

  -- Modification 1: Devil Room visited
  if stage < 3 then
    g.g:SetStateFlag(GameStateFlag.STATE_DEVILROOM_VISITED, false) -- 6
  else
    g.g:SetStateFlag(GameStateFlag.STATE_DEVILROOM_VISITED, true) -- 6
  end

  -- Modification 2: Book touched
  seed = g:IncrementRNG(seed)
  math.randomseed(seed)
  local bookMod = math.random(1, 2)
  if bookMod == 1 then
    g.g:SetStateFlag(GameStateFlag.STATE_BOOK_PICKED_UP, false) -- 8
  elseif bookMod == 2 then
    g.g:SetStateFlag(GameStateFlag.STATE_BOOK_PICKED_UP, true) -- 8
  end

  -- Modification 3: Coins
  seed = g:IncrementRNG(seed)
  math.randomseed(seed)
  local coinMod = math.random(1, 2)
  g.p:AddCoins(-99)
  if coinMod == 2 then
    -- If coinMod == 1, we don't have to do anything (0 coins)
    -- If coinMod == 2, we give 20 coins
    -- (all we really need is 5 coins but give 20 in case we are on Keeper and have Greed's Gullet
    -- and have empty coin containers)
    g.p:AddCoins(20)
  end

  -- Modification 4: Keys
  seed = g:IncrementRNG(seed)
  math.randomseed(seed)
  local keyMod = math.random(1, 2)
  g.p:AddKeys(-99)
  if keyMod == 2 then
    -- If keyMod == 1, we don't have to do anything (0 keys)
    -- If keyMod == 2, we give 2 keys
    g.p:AddKeys(2)
  end

  -- Remove all health
  g.p:AddGoldenHearts(goldenHearts * -1)
  -- (we have to remove the exact amount of Golden Hearts or else it will bug out)
  -- (we remove Golden Hearts first so that they don't break)
  g.p:AddMaxHearts(-24, false)
  g.p:AddSoulHearts(-24)
  g.p:AddBoneHearts(-12)

  -- Modification 5: Full health
  seed = g:IncrementRNG(seed)
  math.randomseed(seed)
  g.p:AddMaxHearts(2, false)
  g.p:AddHearts(1)
  local fullHealthMod = math.random(1, 100)
  if fullHealthMod <= 66 then
    -- 66% chance to be full health
    g.p:AddHearts(1)
  end

  -- Modification 6: Critical health
  seed = g:IncrementRNG(seed)
  math.randomseed(seed)
  local criticalHealthMod = math.random(1, 100)
  if criticalHealthMod <= 75 then
    -- 75% chance to not be at critical health
    g.p:AddSoulHearts(2)

    -- Keeper will get 3 Blue Flies from this, so manually remove them
    if character == PlayerType.PLAYER_KEEPER then -- 14
      local blueFlies = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY, -1, false, false) -- 3.43
      for i, fly in ipairs(blueFlies) do
        if i > 3 then
          break
        end
        fly:Remove()
      end
    end
  end
end

function SeededFloors:After()
  -- Local variables
  local customRun = g.seeds:IsCustomRun()
  local challenge = Isaac.GetChallenge()
  local devilVisited = g.run.seededSwap.devilVisited
  local bookTouched = g.run.seededSwap.bookTouched
  local coins = g.run.seededSwap.coins
  local keys = g.run.seededSwap.keys

  -- Only swap things if we are playing a specific seed
  if challenge ~= 0 or
     not customRun then

    return
  end

  -- Set everything back to the way it was before
  g.run.seededSwap.swapping = false
  g.g:SetStateFlag(GameStateFlag.STATE_DEVILROOM_VISITED, devilVisited) -- 6
  g.g:SetStateFlag(GameStateFlag.STATE_BOOK_PICKED_UP, bookTouched) -- 8
  g.p:AddCoins(-99)
  g.p:AddCoins(coins)
  g.p:AddKeys(-99)
  g.p:AddKeys(keys)
  SeededFloors:LoadHealth()
end

-- Based on the "REVEL.StoreHealth()" function in the Revelations mod
function SeededFloors:SaveHealth()
  -- Local variables
  local character = g.p:GetPlayerType()
  local soulHeartTypes = {}
  local maxHearts = g.p:GetMaxHearts()
  local hearts = g.p:GetHearts()
  local soulHearts = g.p:GetSoulHearts()
  local boneHearts = g.p:GetBoneHearts()
  local goldenHearts = g.p:GetGoldenHearts()
  local eternalHearts = g.p:GetEternalHearts()

  -- The Forgotten and The Soul has special health, so we need to account for this
  local subPlayer
  if character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
    -- The Forgotten does not have red heart containers, so account for this
    maxHearts = boneHearts * 2
    boneHearts = 0

    -- The Forgotten will always have 0 soul hearts; we need to get the soul heart amount from the sub player
    subPlayer = g.p:GetSubPlayer()
    soulHearts = subPlayer:GetSoulHearts()

  elseif character == PlayerType.PLAYER_THESOUL then -- 17
    -- The Soul will always have 0 bone hearts; we need to get the bone heart amount from the sub player
    subPlayer = g.p:GetSubPlayer()
    maxHearts = subPlayer:GetBoneHearts() * 2 -- We need to store it as "maxHearts" instead of "boneHearts"
    hearts = subPlayer:GetHearts()
  end

  -- Eternal Hearts will be lost since we are about to change floors, so convert it to other types of health
  -- "eternalHearts" will be equal to 1 if we have an Eternal Heart
  if character == PlayerType.PLAYER_XXX or -- 4
     character == PlayerType.PLAYER_THESOUL then -- 17

    soulHearts = soulHearts + eternalHearts * 2

  else
    maxHearts = maxHearts + eternalHearts * 2
    hearts = hearts + eternalHearts * 2
  end

  -- This is the number of individual hearts shown in the HUD, minus heart containers
  local extraHearts = math.ceil(soulHearts / 2) + boneHearts

  -- Since bone hearts can be inserted anywhere between soul hearts,
  -- we need a separate counter to track which soul heart we're currently at
  local currentSoulHeart = 0

  for i = 0, extraHearts - 1 do
    local isBoneHeart = g.p:IsBoneHeart(i)
    if character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
      isBoneHeart = subPlayer:IsBoneHeart(i)
    end
    if isBoneHeart then
      soulHeartTypes[#soulHeartTypes + 1] = HeartSubType.HEART_BONE -- 11
    else
      -- We need to add 1 here because only the second half of a black heart is considered black
      local isBlackHeart = g.p:IsBlackHeart(currentSoulHeart + 1)
      if character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
        isBlackHeart = subPlayer:IsBlackHeart(currentSoulHeart + 1)
      end
      if isBlackHeart then
        soulHeartTypes[#soulHeartTypes + 1] = HeartSubType.HEART_BLACK -- 6
      else
        soulHeartTypes[#soulHeartTypes + 1] = HeartSubType.HEART_SOUL -- 3
      end

      -- Move to the next heart
      currentSoulHeart = currentSoulHeart + 2
    end
  end

  return {
    soulHeartTypes = soulHeartTypes,
    maxHearts      = maxHearts,
    hearts         = hearts,
    soulHearts     = soulHearts,
    boneHearts     = boneHearts,
    goldenHearts   = goldenHearts,
  }
end

function SeededFloors:PrintHealth()
  local hearts = g.run.seededSwap.heartTable
  Isaac.DebugString("DEBUG - Soul heart types:")
  for i, soulHeartType in ipairs(hearts.soulHeartTypes) do
    Isaac.DebugString("DEBUG -   " .. tostring(i) .. ") " .. tostring(soulHeartType))
  end
  Isaac.DebugString("DEBUG - maxHearts: " .. tostring(hearts.maxHearts))
  Isaac.DebugString("DEBUG - hearts: " .. tostring(hearts.hearts))
  Isaac.DebugString("DEBUG - soulHearts: " .. tostring(hearts.soulHearts))
  Isaac.DebugString("DEBUG - boneHearts: " .. tostring(hearts.boneHearts))
  Isaac.DebugString("DEBUG - goldenHearts: " .. tostring(hearts.goldenHearts))
end

-- Based on the "REVEL.LoadHealth()" function in the Revelations mod
function SeededFloors:LoadHealth()
  -- Local variables
  local character = g.p:GetPlayerType()
  local hearts = g.run.seededSwap.heartTable

  SeededFloors:PrintHealth()

  -- Remove all existing health
  g.p:AddMaxHearts(-24, true)
  g.p:AddSoulHearts(-24)
  g.p:AddBoneHearts(-24)

  -- Add the red heart containers
  if character == PlayerType.PLAYER_THESOUL then -- 17
    -- Account for The Soul, as adding health to him is a special case
    local subPlayer = g.p:GetSubPlayer()
    subPlayer:AddMaxHearts(hearts.maxHearts)
  else
    g.p:AddMaxHearts(hearts.maxHearts)
  end

  -- Add the soul / black / bone hearts
  local soulHeartsRemaining = hearts.soulHearts
  for i, heartType in ipairs(hearts.soulHeartTypes) do
    local isHalf = (hearts.soulHearts + hearts.boneHearts * 2) < i * 2
    local addAmount = 2
    if isHalf or
       heartType == HeartSubType.HEART_BONE or -- 11
       soulHeartsRemaining < 2 then
       -- (fix the bug where a half soul heart to the left of a bone heart will be treated as a full soul heart)

      addAmount = 1
    end

    if heartType == HeartSubType.HEART_SOUL then -- 3
      g.p:AddSoulHearts(addAmount)
      soulHeartsRemaining = soulHeartsRemaining - addAmount
    elseif heartType == HeartSubType.HEART_BLACK then -- 6
      g.p:AddBlackHearts(addAmount)
      soulHeartsRemaining = soulHeartsRemaining - addAmount
    elseif heartType == HeartSubType.HEART_BONE then -- 11
      g.p:AddBoneHearts(addAmount)
    end
  end

  -- Fill in the red heart containers
  g.p:AddHearts(hearts.hearts)
  g.p:AddGoldenHearts(hearts.goldenHearts)
  Isaac.DebugString("DEBUG ADDED goldenHearts: " .. tostring(hearts.goldenHearts))
  -- (no matter what kind of heart is added, no sounds effects will play)
end

return SeededFloors

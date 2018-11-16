local RPSeededFloors = {}

-- Includes
local RPGlobals = require("src/rpglobals")

-- Different inventory and health conditions can affect special room generation
-- Different special rooms can also sometimes change the actual room selection of non-special rooms
-- This is bad for seeded races; we want to ensure consistent floors
-- Thus, we arbitrarily set inventory and health conditions before going to the next floor, and then swap them back
-- https://bindingofisaacrebirth.gamepedia.com/Level_Generation
function RPSeededFloors:Before(stage)
  -- Local variables
  local game = Game()
  local seeds = game:GetSeeds()
  local seed = seeds:GetStageSeed(stage)
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()
  local coins = player:GetNumCoins()
  local keys = player:GetNumKeys()
  local challenge = Isaac.GetChallenge()

  -- Only swap things if we are playing a specific seed
  if challenge ~= 0 or
     seeds:IsCustomRun() == false then

    return
  end

  -- Record the current inventory and health values
  RPGlobals.run.seededSwap.swapping = true
  RPGlobals.run.seededSwap.devilVisited = game:GetStateFlag(GameStateFlag.STATE_DEVILROOM_VISITED) -- 6
  RPGlobals.run.seededSwap.bookTouched = game:GetStateFlag(GameStateFlag.STATE_BOOK_PICKED_UP) -- 8
  RPGlobals.run.seededSwap.coins = coins
  RPGlobals.run.seededSwap.keys = keys
  RPGlobals.run.seededSwap.heartTable = RPSeededFloors:SaveHealth()

  -- Modification 1: Devil Room visited
  if stage < 3 then
    game:SetStateFlag(GameStateFlag.STATE_DEVILROOM_VISITED, false) -- 6
  else
    game:SetStateFlag(GameStateFlag.STATE_DEVILROOM_VISITED, true) -- 6
  end

  -- Modification 2: Book touched
  seed = RPGlobals:IncrementRNG(seed)
  math.randomseed(seed)
  local bookMod = math.random(1, 2)
  if bookMod == 1 then
    game:SetStateFlag(GameStateFlag.STATE_BOOK_PICKED_UP, false) -- 8
  elseif bookMod == 2 then
    game:SetStateFlag(GameStateFlag.STATE_BOOK_PICKED_UP, true) -- 8
  end

  -- Modification 3: Coins
  seed = RPGlobals:IncrementRNG(seed)
  math.randomseed(seed)
  local coinMod = math.random(1, 2)
  player:AddCoins(-99)
  if coinMod == 2 then
    -- If coinMod == 1, we don't have to do anything (0 coins)
    -- If coinMod == 2, we give 20 coins
    -- (all we really need is 5 coins but give 20 in case we are on Keeper and have Greed's Gullet
    -- and have empty coin containers)
    player:AddCoins(20)
  end

  -- Modification 4: Keys
  seed = RPGlobals:IncrementRNG(seed)
  math.randomseed(seed)
  local keyMod = math.random(1, 2)
  player:AddKeys(-99)
  if keyMod == 2 then
    -- If keyMod == 1, we don't have to do anything (0 keys)
    -- If keyMod == 2, we give 2 keys
    player:AddKeys(2)
  end

  -- Modification 5: Full health
  seed = RPGlobals:IncrementRNG(seed)
  math.randomseed(seed)
  player:AddMaxHearts(-24, false)
  player:AddSoulHearts(-24)
  player:AddBoneHearts(-24)
  player:AddMaxHearts(2, false)
  player:AddHearts(1)
  local fullHealthMod = math.random(1, 100)
  if fullHealthMod <= 66 then
    -- 66% chance to be full health
    player:AddHearts(1)
  end

  -- Modification 6: Critical health
  seed = RPGlobals:IncrementRNG(seed)
  math.randomseed(seed)
  local criticalHealthMod = math.random(1, 100)
  if criticalHealthMod <= 75 then
    -- 75% chance to not be at critical health
    player:AddSoulHearts(2)

    -- Keeper will get 3 Blue Flies from this, so manually remove them
    if character == PlayerType.PLAYER_KEEPER then -- 14
      local fliesToRemove = 3
      for i, entity in pairs(Isaac.GetRoomEntities()) do
        if entity.Type == EntityType.ENTITY_FAMILIAR and -- 3
           entity.Variant == FamiliarVariant.BLUE_FLY and -- 43
           fliesToRemove > 0 then

          fliesToRemove = fliesToRemove - 1
          entity:Remove()
        end
      end
    end
  end
end

function RPSeededFloors:After()
  -- Local variables
  local game = Game()
  local seeds = game:GetSeeds()
  local player = game:GetPlayer(0)
  local challenge = Isaac.GetChallenge()
  local devilVisited = RPGlobals.run.seededSwap.devilVisited
  local bookTouched = RPGlobals.run.seededSwap.bookTouched
  local coins = RPGlobals.run.seededSwap.coins
  local keys = RPGlobals.run.seededSwap.keys

  -- Only swap things if we are playing a specific seed
  if challenge ~= 0 or
     seeds:IsCustomRun() == false then

    return
  end

  -- Set everything back to the way it was before
  RPGlobals.run.seededSwap.swapping = false
  game:SetStateFlag(GameStateFlag.STATE_DEVILROOM_VISITED, devilVisited) -- 6
  game:SetStateFlag(GameStateFlag.STATE_BOOK_PICKED_UP, bookTouched) -- 8
  player:AddCoins(-99)
  player:AddCoins(coins)
  player:AddKeys(-99)
  player:AddKeys(keys)
  RPSeededFloors:LoadHealth()
end

-- Based on the "REVEL.StoreHealth()" function in the Revelations mod
function RPSeededFloors:SaveHealth()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()
  local heartTypes = {}
  local maxHearts = player:GetMaxHearts()
  local hearts = player:GetHearts()
  local soulHearts = player:GetSoulHearts()
  local boneHearts = player:GetBoneHearts()
  local goldenHearts = player:GetGoldenHearts()

  if character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
    -- The Forgotten does not have red heart containers, so account for this
    maxHearts = boneHearts * 2
    boneHearts = 0

    -- The Forgotten will always have 0 soul hearts; we need to get the soul heart amount from the sub player
    local subPlayer = player:GetSubPlayer()
    soulHearts = subPlayer:GetSoulHearts()

  elseif character == PlayerType.PLAYER_THESOUL then -- 17
    -- The Soul will always have 0 bone hearts; we need to get the bone heart amount from the sub player
    local subPlayer = player:GetSubPlayer()
    hearts = subPlayer:GetHearts()
    boneHearts = subPlayer:GetBoneHearts()
  end

  -- This is the number of individual hearts shown in the HUD, minus heart containers
  local extraHearts = math.ceil(soulHearts / 2) + boneHearts

  -- Since bone hearts can be inserted anywhere between soul hearts,
  -- we need a separate counter to track which soul heart we're currently at
  local currentSoulHeart = 0

  for i = 0, extraHearts - 1 do
    if player:IsBoneHeart(i) then
      heartTypes[#heartTypes + 1] = HeartSubType.HEART_BONE -- 11
    else
      local isBlackHeart = player:IsBlackHeart(currentSoulHeart + 1)
      -- We add 1 because only the second half of a black heart is considered black
      if isBlackHeart then
        heartTypes[#heartTypes + 1] = HeartSubType.HEART_BLACK -- 6
      else
        heartTypes[#heartTypes + 1] = HeartSubType.HEART_SOUL -- 3
      end

      -- Move to the next heart
      currentSoulHeart = currentSoulHeart + 2
    end
  end

  return {
    types = heartTypes,
    maxHearts = maxHearts,
    hearts = hearts,
    soulHearts = soulHearts,
    boneHearts = boneHearts,
    goldenHearts = goldenHearts,
  }
end

-- Based on the "REVEL.LoadHealth()" function in the Revelations mod
function RPSeededFloors:LoadHealth()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local hearts = RPGlobals.run.seededSwap.heartTable

  -- Remove all existing health
  player:AddMaxHearts(-24, true)
  player:AddSoulHearts(-24)
  player:AddBoneHearts(-24)
  player:AddBoneHearts(-24)

  player:AddMaxHearts(hearts.maxHearts)
  local soulHeartsRemaining = hearts.soulHearts
  for i, heartType in ipairs(hearts.types) do
    local isHalf = (hearts.soulHearts + hearts.boneHearts * 2) < i * 2
    local addAmount = 2
    if isHalf or
       heartType == HeartSubType.HEART_BONE or -- 11
       soulHeartsRemaining < 2 then
       -- (fix the bug where a half soul heart to the left of a bone heart will be treated as a full soul heart)

      addAmount = 1
    end

    if heartType == HeartSubType.HEART_SOUL then -- 3
      player:AddSoulHearts(addAmount)
      soulHeartsRemaining = soulHeartsRemaining - addAmount
    elseif heartType == HeartSubType.HEART_BLACK then -- 6
      player:AddBlackHearts(addAmount)
      soulHeartsRemaining = soulHeartsRemaining - addAmount
    elseif heartType == HeartSubType.HEART_BONE then -- 11
      player:AddBoneHearts(addAmount)
    end
  end
  player:AddHearts(hearts.hearts)
  player:AddGoldenHearts(hearts.goldenHearts)
end

return RPSeededFloors

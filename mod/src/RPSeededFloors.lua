local RPSeededFloors = {}

-- Includes
local RPGlobals  = require("src/rpglobals")
local RPSpeedrun = require("src/rpspeedrun")

-- Different inventory and health conditions can affect special room generation
-- Different special rooms can also sometimes change the actual room selection of non-special rooms
-- This is bad for seeded races; we want to ensure consistent floors
-- Thus, we arbitrarily set inventory and health conditions before going to the next floor, and then swap them back
-- https://bindingofisaacrebirth.gamepedia.com/Level_Generation
function RPSeededFloors:Before()
  -- Local variables
  local game = Game()
  local seeds = game:GetSeeds()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()
  local coins = player:GetNumCoins()
  local keys = player:GetNumKeys()
  local hearts = player:GetHearts()
  local maxHearts = player:GetMaxHearts()
  local soulHearts = player:GetSoulHearts()
  local blackHearts = player:GetBlackHearts()
  local boneHearts = player:GetBoneHearts()

  if (RPGlobals.race.rFormat ~= "seeded" or
      RPGlobals.race.status ~= "in progress") and
     RPSpeedrun.inSeededSpeedrun == false then

    return
  end

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

  -- Record the current inventory and health values
  RPGlobals.run.seededSwap.swapping = true
  RPGlobals.run.seededSwap.devilVisited = game:GetStateFlag(GameStateFlag.STATE_DEVILROOM_VISITED) -- 6
  RPGlobals.run.seededSwap.bookTouched = game:GetStateFlag(GameStateFlag.STATE_BOOK_PICKED_UP) -- 8
  RPGlobals.run.seededSwap.coins = coins
  RPGlobals.run.seededSwap.keys = keys
  RPGlobals.run.seededSwap.hearts = hearts
  RPGlobals.run.seededSwap.maxHearts = maxHearts
  RPGlobals.run.seededSwap.soulHearts = soulHearts
  RPGlobals.run.seededSwap.blackHearts = blackHearts
  RPGlobals.run.seededSwap.boneHearts = boneHearts

  -- Get the stage seed for the next level
  local nextStage = stage + 1
  if stage == 8 then
    -- The Womb goes to the Cathedral / Sheol (skipping the Blue Womb)
    nextStage = 10
  end
  local seed = seeds:GetStageSeed(nextStage)

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
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()
  local devilVisited = RPGlobals.run.seededSwap.devilVisited
  local bookTouched = RPGlobals.run.seededSwap.bookTouched
  local coins = RPGlobals.run.seededSwap.coins
  local keys = RPGlobals.run.seededSwap.keys
  local maxHearts = RPGlobals.run.seededSwap.maxHearts
  local hearts = RPGlobals.run.seededSwap.hearts
  local soulHearts = RPGlobals.run.seededSwap.soulHearts
  local blackHearts = RPGlobals.run.seededSwap.blackHearts
  local boneHearts = RPGlobals.run.seededSwap.boneHearts

  if (RPGlobals.race.rFormat ~= "seeded" or
      RPGlobals.race.status ~= "in progress") and
     RPSpeedrun.inSeededSpeedrun == false then

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

  -- Set the health back to the way it was before
  player:AddMaxHearts(-24, true)
  player:AddSoulHearts(-24)
  player:AddBoneHearts(-24)
  player:AddMaxHearts(maxHearts, true)
  -- (on The Forgotten, adding 2 max hearts will give 1 bone heart, so we don't need to do any special handling here)
  player:AddHearts(hearts)
  for i = 1, soulHearts do
    local bitPosition = math.floor((i - 1) / 2)
    local bit = (blackHearts & (1 << bitPosition)) >> bitPosition
    if bit == 0 then -- Soul heart
      player:AddSoulHearts(1)
    else -- Black heart
      player:AddBlackHearts(1)
    end
  end
  player:AddBoneHearts(boneHearts)

  -- If we are The Soul, then we added the hearts above before we had any heart containers
  -- Re-add the hearts again now that we have a container
  if character == PlayerType.PLAYER_THESOUL then -- 17
    player:AddHearts(hearts)
  end
end

return RPSeededFloors

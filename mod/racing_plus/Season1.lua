local Season1 = {}

-- Includes
local g = require("racing_plus/globals")
local Schoolbag = require("racing_plus/schoolbag")

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season1:PostGameStarted9()
  -- Local variables
  local character = g.p:GetPlayerType()

  Isaac.DebugString("In the R+9 (Season 1) challenge.")

  -- Give extra items to some characters
  if character == PlayerType.PLAYER_KEEPER then -- 14
    -- Add the items
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET, 0, false) -- 501
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET) -- 501
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_DUALITY, 0, false) -- 498
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DUALITY) -- 498

    -- Grant an extra coin/heart container
    g.p:AddCoins(24) -- Keeper starts with 1 coin so we only need to give 24
    g.p:AddCoins(1) -- This fills in the new heart container
    g.p:AddCoins(25) -- Add a 2nd container
    g.p:AddCoins(1) -- This fills in the new heart container
  end
end

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season1:PostGameStarted14()
  -- Local variables
  local character = g.p:GetPlayerType()

  Isaac.DebugString("In the R+14 (Season 1) challenge.")

  -- Give extra items to some characters
  if character == PlayerType.PLAYER_ISAAC then -- 0
    -- Add the Battery
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_BATTERY, 0, false) -- 63
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BATTERY) -- 63

    -- Make Isaac start with a double charge instead of a single charge
    g.p:SetActiveCharge(12)
    g.sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170
  elseif character == PlayerType.PLAYER_MAGDALENA then -- 1
    -- Add the Soul Jar
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SOUL_JAR, 0, false)
    -- (the Soul Jar does not appear in any pools)
  elseif character == PlayerType.PLAYER_LILITH then -- 13
    -- Lilith starts with the Schoolbag by default
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    Schoolbag:Put(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS, 4) -- 357
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) -- 357

    -- Reorganize the items on the item tracker
    Isaac.DebugString("Removing collectible 412 (Cambion Conception)")
    Isaac.DebugString("Adding collectible 412 (Cambion Conception)")
  elseif character == PlayerType.PLAYER_KEEPER then -- 14
    -- Add the items
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET, 0, false) -- 501
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET) -- 501
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_DUALITY, 0, false) -- 498
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DUALITY) -- 498

    -- Grant an extra coin/heart container
    g.p:AddCoins(24) -- Keeper starts with 1 coin so we only need to give 24
    g.p:AddCoins(1) -- This fills in the new heart container
    g.p:AddCoins(25) -- Add a 2nd container
    g.p:AddCoins(1) -- This fills in the new heart container
  elseif character == PlayerType.PLAYER_APOLLYON then -- 15
    -- Apollyon starts with the Schoolbag by default
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    Schoolbag:Put(CollectibleType.COLLECTIBLE_VOID, 6) -- 477
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_VOID) -- 477
  end
end

return Season1

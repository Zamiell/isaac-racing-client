local Season2 = {}

-- Includes
local g = require("racing_plus/globals")
local Schoolbag = require("racing_plus/schoolbag")

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season2:PostGameStarted()
  -- Local variables
  local character = g.p:GetPlayerType()

  Isaac.DebugString("In the R+7 (Season 2) challenge.")

  -- Give extra items to some characters
  if character == PlayerType.PLAYER_ISAAC then -- 0
    -- Add the Battery
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_BATTERY, 0, false) -- 63
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_BATTERY) -- 63

    -- Make Isaac start with a double charge instead of a single charge
    g.p:SetActiveCharge(12)
    g.sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170
  elseif character == PlayerType.PLAYER_APOLLYON then -- 15
    -- Apollyon starts with the Schoolbag by default
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM, 0, false)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG_CUSTOM)
    Schoolbag:Put(CollectibleType.COLLECTIBLE_VOID, 6) -- 477
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_VOID) -- 477
  end
end

return Season2

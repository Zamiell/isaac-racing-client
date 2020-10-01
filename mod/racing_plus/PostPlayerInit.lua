local PostPlayerInit = {}

-- Includes
local g = require("racing_plus/globals")
local Season8 = require("racing_plus/season8")

-- ModCallbacks.MC_POST_PLAYER_INIT (9)
-- (this will get called before the "PostGameStarted" callback)
function PostPlayerInit:Main(player)
  -- We don't care if this is a co-op baby
  if player.Variant ~= 0 then
    return
  end

  -- Cache the player object so that we don't have to repeatedly call Game():GetPlayer(0)
  g.p = player

  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local character = player:GetPlayerType()

  Isaac.DebugString("MC_POST_PLAYER_INIT - Character " .. tostring(character))

  -- Do nothing if we are continuing an existing run
  if gameFrameCount ~= 0 then
    return
  end

  -- With Eve, Eden, and Keeper, the beginning of the recharge sound will play, which is annoying
  if (
    character == PlayerType.PLAYER_EVE -- 5
    or character == PlayerType.PLAYER_EDEN -- 9
    or character == PlayerType.PLAYER_KEEPER -- 14
  ) then
    -- Adding the D6 is necessary because these characters have not been given their active item yet
    -- The recharge sounds happens somewhere between this callback and the PostGameStarted callback
    -- (if the active item is already charged,
    -- there won't be a 2nd recharge sound when a new item is added)
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105
    g.sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170
  end

  Season8:PostPlayerInit()
end

return PostPlayerInit

local RPPostPlayerInit = {}

-- ModCallbacks.MC_POST_PLAYER_INIT (9)
-- (this will get called before the "PostGameStarted" callback)
function RPPostPlayerInit:Main(player)
  -- Local variables
  local game = Game()
  local mainPlayer = game:GetPlayer(0)
  local character = mainPlayer:GetPlayerType()
  local sfx = SFXManager()

  Isaac.DebugString("MC_POST_PLAYER_INIT")

  -- We don't care if this is a co-op baby
  if player.Variant ~= 0 then
    return
  end

  -- With Eve, Eden, and Keeper, the beginning of the recharge sound will play, which is annoying
  if character == PlayerType.PLAYER_EVE or -- 5
     character == PlayerType.PLAYER_EDEN or -- 9
     character == PlayerType.PLAYER_KEEPER then -- 14

    -- Adding the D6 is necessary because these characters have not been given their active item yet;
    -- the recharge sounds happens somewhere between this callback and the PostGameStarted callback
    -- (if the active item is already charged, there won't be a 2nd recharge sound when a new item is added)
    player:AddCollectible(CollectibleType.COLLECTIBLE_D6, 6, false) -- 105
    sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE) -- 170
  end
end

return RPPostPlayerInit

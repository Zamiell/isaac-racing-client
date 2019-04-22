local PostBombUpdate = {}

function PostBombUpdate:Main(bomb)
  if bomb.FrameCount ~= 1 then
    return
  end

  -- Find out if this bomb has the homing flag
  local homing = (bomb.Flags & (1 << 2)) >> 2
  if homing == 0 then
    return
  end

  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local challenge = Isaac.GetChallenge()

  -- This mechanic only applies to Season 6
  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6 Beta)") then
    return
  end

  -- Don't do anything if we don't have Sacred Heart
  if player:HasCollectible(CollectibleType.COLLECTIBLE_SACRED_HEART) == false then -- 182
    return
  end

  -- Don't do anything if we have Dr. Fetus or Bobby Bomb (normal homing bombs)
  if player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) or -- 52
     player:HasCollectible(CollectibleType.COLLECTIBLE_BOBBY_BOMB) then -- 125

    return
  end

  -- Remove the homing bombs from Sacred Heart
  bomb.Flags = 0
end

return PostBombUpdate
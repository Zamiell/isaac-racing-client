local PostBombUpdate = {}

-- Includes
local g = require("racing_plus/globals")

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
  local challenge = Isaac.GetChallenge()

  -- This mechanic only applies to Season 6+
  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 6)") and
     challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)") then

    return
  end

  -- Don't do anything if we don't have Sacred Heart
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_SACRED_HEART) then -- 182
    return
  end

  -- Don't do anything if we have Dr. Fetus or Bobby Bomb (normal homing bombs)
  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) or -- 52
     g.p:HasCollectible(CollectibleType.COLLECTIBLE_BOBBY_BOMB) then -- 125

    return
  end

  -- Remove the homing bombs from Sacred Heart
  -- (bombs use tear flags for some reason)
  bomb.Flags = bomb.Flags & ~TearFlags.TEAR_HOMING -- 1 << 2
end

return PostBombUpdate
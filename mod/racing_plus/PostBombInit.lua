local PostBombInit = {}

function PostBombInit:SetTimer(bomb)
  -- Make Troll Bomb and Mega Troll Bomb fuses deterministic (exactly 2 seconds long)
  -- (in vanilla the fuse is: 45 + random(1, 2147483647) % 30)
  -- Note that game physics occur at 30 frames per second instead of 60
  bomb:SetExplosionCountdown(60)
end

return PostBombInit

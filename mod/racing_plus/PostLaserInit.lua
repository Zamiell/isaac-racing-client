local PostLaserInit = {}

-- Includes
local g = require("racing_plus/globals")

-- ModCallbacks.MC_POST_LASER_INIT (47)
function PostLaserInit:Main(laser)
  if laser.Variant ~= 6 then -- "007.006_Giant Red Laser.anm2" in "entities2.xml"
    return
  end

  if g.run.seededDeath.time == 0 then
    return
  end

  local elapsedTime = g.run.seededDeath.time - Isaac.GetTime()
  if elapsedTime <= 0 then
    return
  end

  -- There is no way to stop a Mega Blast while it is currently going with the API
  -- It will keep firing, so we need to delete it on every frame
  laser:Remove()

  -- Even though we delete it, it will still show up for a frame
  -- Thus, the Mega Blast laser will look like it is intermittently shooting, even though it deals no damage
  -- Make it invisible to fix this
  laser.Visible = false
  -- (this also has the side effect of muting the sound effects)

  -- Even though we make it invisible, it still displays effects when it hits a wall
  -- So, reduce the size of it to mitigate this
  laser.SpriteScale = g.zeroVector
  laser.SizeMulti = g.zeroVector
end

return PostLaserInit

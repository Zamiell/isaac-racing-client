local PostLaserInit = {}

-- Note: Position, SpawnerType, SpawnerVariant, and MaxDistance are not initialized yet in this callback

-- Includes
local SeededDeath = require("racing_plus/seededdeath")

function PostLaserInit:Laser6(laser)
  SeededDeath:DeleteMegaBlastLaser(laser)
end

return PostLaserInit

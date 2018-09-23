local RPCards = {}

-- Includes
local RPGlobals = require("src/rpglobals")

function RPCards:Teleport()
  -- Mark that this is not a Cursed Eye teleport
  RPGlobals.run.naturalTeleport = true
end

function RPCards:Strength()
  -- Keep track of whether or not we used a Strength card so that we can fix the bug with Fast-Travel
  RPGlobals.run.usedStrength = true
  Isaac.DebugString("Used a Strength card.")
end

return RPCards

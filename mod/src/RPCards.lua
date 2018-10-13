local RPCards = {}

-- Includes
local RPGlobals = require("src/rpglobals")

function RPCards:Teleport()
  -- Mark that this is not a Cursed Eye teleport
  RPGlobals.run.naturalTeleport = true
end

function RPCards:Strength()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()

  -- Keep track of whether or not we used a Strength card so that we can fix the bug with Fast-Travel
  if character ~= PlayerType.PLAYER_KEEPER then -- 14
    RPGlobals.run.usedStrength = true
    Isaac.DebugString("Used a Strength card.")
  elseif RPGlobals.run.keeper.baseHearts < 4 then
    -- Only give Keeper another heart container if he has less than 2 base containers
    RPGlobals.run.usedStrength = true
    player:AddMaxHearts(2, true) -- Give 1 heart container
    --player:AddCoins(1) -- This fills in the new heart container
    RPGlobals.run.keeper.baseHearts = RPGlobals.run.keeper.baseHearts + 2
    Isaac.DebugString("Gave 1 heart container to Keeper (via a Strength card).")
  end

  -- We don't have to check to see if "hearts == maxHearts" because
  -- the Strength card will naturally heal Keeper for one heart containers
end

return RPCards

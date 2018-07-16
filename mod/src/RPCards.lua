local RPCards = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")

--
-- Card functions
--

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
  RPGlobals.run.usedStrength = true
  Isaac.DebugString("Used a Strength card.")

  -- Only give Keeper another heart container if he has less than 2 base containers
  if character == PlayerType.PLAYER_KEEPER then -- 14
    if RPGlobals.run.keeper.baseHearts < 4 then
      -- Add another heart container (temporarily)
      player:AddMaxHearts(2, true) -- Give 1 heart container
      player:AddCoins(1) -- This fills in the new heart container
      RPGlobals.run.keeper.baseHearts = RPGlobals.run.keeper.baseHearts + 2
      Isaac.DebugString("Gave 1 heart container to Keeper (via a Strength card).")
    else
      RPGlobals.run.usedStrength = false
    end
  end
end

return RPCards

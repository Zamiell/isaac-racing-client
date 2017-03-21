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

  -- Only give Keeper another heart container if he has less than 2 base containers
  if character == PlayerType.PLAYER_KEEPER and -- 14
     RPGlobals.run.keeper.baseHearts < 4 then

    -- Add another heart container (temporarily)
    player:AddMaxHearts(2, true) -- Give 1 heart container
    player:AddCoins(1) -- This fills in the new heart container
    RPGlobals.run.keeper.baseHearts = RPGlobals.run.keeper.baseHearts + 2
    RPGlobals.run.keeper.usedStrength = true
    Isaac.DebugString("Gave 1 heart container to Keeper (via a Strength card).")
  end
end

return RPCards

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

  -- Keep track of whether we used a Strength card to fix the bug with fast-travel
  -- where we permanently keep the size increase
  RPGlobals.run.usedStrength = true
  Isaac.DebugString("Used a \"Strength\" card.")

  -- Only give Keeper another heart container if he has less than 2 base containers
  if character == PlayerType.PLAYER_KEEPER and -- 14
     RPGlobals.run.keeper.baseHearts < 4 then

    -- Add another heart container (temporarily)
    player:AddMaxHearts(2, true) -- Give 1 heart container
    player:AddCoins(1) -- This fills in the new heart container
    RPGlobals.run.keeper.baseHearts = RPGlobals.run.keeper.baseHearts + 2
    Isaac.DebugString("Gave 1 heart container to Keeper (via a Strength card).")
  end
end

function RPCards:HugeGrowth()
  -- Keep track of whether we used a Huge Growth card to fix the bug with fast-travel
  -- where we permanently keep the size increase
  RPGlobals.run.usedHugeGrowth = true
  Isaac.DebugString("Used a \"Huge Growth\" card.")
end

return RPCards

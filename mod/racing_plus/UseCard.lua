local UseCard = {}

-- Includes
local g = require("racing_plus/globals")

function UseCard:Teleport()
  -- Mark that this is not a Cursed Eye teleport
  g.run.naturalTeleport = true
end

function UseCard:Strength()
  -- Local variables
  local character = g.p:GetPlayerType()

  -- Keep track of whether or not we used a Strength card so that we can fix the bug with Fast-Travel
  if character ~= PlayerType.PLAYER_KEEPER then -- 14
    g.run.usedStrength = true
    Isaac.DebugString("Used a Strength card.")
    if character == PlayerType.PLAYER_THEFORGOTTEN then -- 16
      g.run.usedStrengthChar = PlayerType.PLAYER_THEFORGOTTEN -- 16
    elseif character == PlayerType.PLAYER_THESOUL then -- 17
      g.run.usedStrengthChar = PlayerType.PLAYER_THESOUL -- 17
    end
  elseif g.run.keeper.baseHearts < 4 then
    -- Only give Keeper another heart container if he has less than 2 base containers
    g.run.usedStrength = true
    g.p:AddMaxHearts(2, true) -- Give 1 heart container
    g.run.keeper.baseHearts = g.run.keeper.baseHearts + 2
    Isaac.DebugString("Gave 1 heart container to Keeper (via a Strength card).")
  end

  -- We don't have to check to see if "hearts == maxHearts" because
  -- the Strength card will naturally heal Keeper for one heart containers
end

function UseCard:BlackRune()
  local checkpoints = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 5.100
                                       CollectibleType.COLLECTIBLE_CHECKPOINT, false, false)
  for _, checkpoint in ipairs(checkpoints) do
    -- The Checkpoint custom item is about to be deleted, so spawn another one
    g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, checkpoint.Position, checkpoint.Velocity,
              nil, CollectibleType.COLLECTIBLE_CHECKPOINT, checkpoint.InitSeed)
  end
end

return UseCard

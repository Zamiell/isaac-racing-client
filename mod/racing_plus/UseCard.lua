local UseCard = {}

-- Includes
local g              = require("racing_plus/globals")
local PostItemPickup = require("racing_plus/postitempickup")
local Season8        = require("racing_plus/season8")

-- ModCallbacks.MC_USE_CARD (5)
function UseCard:Main(card)
  -- Isaac.DebugString("MC_USE_CARD - " .. tostring(card))

  -- Display the streak text (because Racing+ removes the vanilla streak text)
  if card == Card.RUNE_BLANK then -- 40
    g.run.streakForce = true
  elseif not g.run.streakIgnore then
    -- We ignore blank runes because we want to show the streak text of the actual random effect
    g.run.streakText = g.itemConfig:GetCard(card).Name
    g.run.streakFrame = Isaac.GetFrameCount()
  end
  g.run.streakIgnore = false

  Season8:UseCard(card)
end

-- Card.CARD_JUSTICE (9)
function UseCard:Justice()
  PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_COIN) -- 20
  PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_KEY) -- 30
  PostItemPickup:InsertNearestPickup(PickupVariant.PICKUP_BOMB) -- 40
end

-- Card.CARD_STRENGTH (12)
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

-- Card.RUNE_BLACK (41)
function UseCard:BlackRune()
  -- Local variables
  local stage = g.l:GetStage()

  local checkpoints = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -- 5.100
                                       CollectibleType.COLLECTIBLE_CHECKPOINT, false, false)
  for _, checkpoint in ipairs(checkpoints) do
    -- The Checkpoint custom item is about to be deleted, so spawn another one
    g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, checkpoint.Position, checkpoint.Velocity,
              nil, CollectibleType.COLLECTIBLE_CHECKPOINT, checkpoint.InitSeed)
    Isaac.DebugString("A black rune deleted a Checkpoint - spawning another one.")

    -- Kill the player if they are trying to cheat on the season 7 custom challenge
    if stage == 8 then
      g.p:AnimateSad()
      g.p:Kill()
    end
  end
end

-- Card.CARD_QUESTIONMARK (48)
function UseCard:QuestionMark()
  -- Prevent the bug where using a ? Card while having Tarot Cloth will cause the D6 to get a free charge (1/2)
  g.run.questionMarkCard = g.g:GetFrameCount()
end

function UseCard:Teleport()
  g.run.naturalTeleport = true -- Mark that this is not a Cursed Eye teleport
end

return UseCard

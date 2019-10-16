local PostFireTear = {}

-- Includes
local g = require("racing_plus/globals")

function PostFireTear:Main(tear)
  if g.run.firingExtraTear then
    return
  end

  if g.run.chaosCardTears then
    tear:ChangeVariant(TearVariant.CHAOS_CARD) -- 9
  end

  if g.p:HasCollectible(CollectibleType.COLLECTIBLE_MONSTROS_LUNG) and -- 229
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) and -- 68
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) and -- 114
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) and -- 168
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then -- 395

    local extraTears = 0
    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) then -- 2
      extraTears = 2
    end
    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) then -- 153
      extraTears = 3
    end
    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_20_20) then -- 245
      extraTears = 1
    end
    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) and -- 2
       g.p:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) then -- 153

      extraTears = 6
    end
    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) and -- 2
       g.p:HasCollectible(CollectibleType.COLLECTIBLE_20_20) then -- 245

      extraTears = 4
    end
    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) and -- 153
       g.p:HasCollectible(CollectibleType.COLLECTIBLE_20_20) then -- 245

      extraTears = 5
    end
    if g.p:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) and -- 2
       g.p:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) and -- 153
       g.p:HasCollectible(CollectibleType.COLLECTIBLE_20_20) then -- 245

      extraTears = 8
    end

    if extraTears > 0 then
      for i = 1, extraTears do
        g.run.firingExtraTear = true
        g.p:FireTear(tear.Position, tear.Velocity, true, false, true)
        g.run.firingExtraTear = false
      end
    end
  end
end

return PostFireTear

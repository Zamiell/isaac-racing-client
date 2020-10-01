local Autofire = {}

-- Includes
local g = require("racing_plus/globals")

function Autofire:Toggle()
  -- Local variables
  local isaacFrameCount = Isaac.GetFrameCount()

  -- Only allow the input to be pressed once every 30 frames (1 second)
  if g.run.autofireChangeFrame + 30 >= isaacFrameCount then
    return
  end

  g.run.autofire = not g.run.autofire
  g.run.autofireChangeFrame = isaacFrameCount
  local text = "Enabled"
  if not g.run.autofire then
    text = "Disabled"
  end
  g.run.streakText = text .. " autofire."
  g.run.streakFrame = isaacFrameCount
end

-- We have to return a value from the "IsActionPressed()" and the "GetActionValue()" callbacks in
-- order for Anti-Gravity autofire to work
function Autofire:IsActionPressed()
  if not g.run.autofire then
    return
  end

  -- Local variables
  local player = Game():GetPlayer(0)
  -- (we can't use cached API functions in this callback or else the game will crash)

  if (
    (
      not player:HasCollectible(CollectibleType.COLLECTIBLE_ANTI_GRAVITY) -- 222
      and not player:HasCollectible(CollectibleType.COLLECTIBLE_NUMBER_TWO) -- 378
    )
    or not Autofire:IsTearBuild(player)
  ) then
    return
  end

  if g.g:GetFrameCount() % 2 == 0 then
    return false
  end
end

function Autofire:IsTearBuild(player)
  return (
    not player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) -- 52
    and not player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) -- 68
    and not player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) -- 114
    and not player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) -- 118
    and not player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) -- 168
    and not player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) -- 395
  )
end

-- We have to return a value from the "IsActionPressed()" and the "GetActionValue()" callbacks in
-- order for Anti-Gravity autofire to work
function Autofire:GetActionValue(buttonAction)
  if not g.run.autofire then
    return
  end

  -- Local variables
  local player = Game():GetPlayer(0)
  -- (we can't use cached API functions in this callback or else the game will crash)

  if not player:HasCollectible(CollectibleType.COLLECTIBLE_ANTI_GRAVITY) then -- 222
    return
  end

  if g.g:GetFrameCount() % 2 == 0 then
    return 0
  end
end

return Autofire

local InputAction = {}

-- Includes
local g      = require("racing_plus/globals")
local Samael = require("racing_plus/samael")

-- ModCallbacks.MC_INPUT_ACTION (13)
function InputAction:Main(entity, inputHook, buttonAction)
  -- Local variables
  -- (we can't use cached API functions in this callback or else the game will crash)
  local game = Game()
  local room = game:GetRoom()
  local roomFrameCount = room:GetFrameCount()

  if (buttonAction == ButtonAction.ACTION_SHOOTLEFT or -- 4
      buttonAction == ButtonAction.ACTION_SHOOTRIGHT or -- 5
      buttonAction == ButtonAction.ACTION_SHOOTUP or -- 6
      buttonAction == ButtonAction.ACTION_SHOOTDOWN) and -- 7
     inputHook == InputHook.IS_ACTION_PRESSED then -- 0

    return Samael:IsActionPressed()
  end
  if (buttonAction == ButtonAction.ACTION_SHOOTLEFT or -- 4
      buttonAction == ButtonAction.ACTION_SHOOTRIGHT or -- 5
      buttonAction == ButtonAction.ACTION_SHOOTUP or -- 6
      buttonAction == ButtonAction.ACTION_SHOOTDOWN) and -- 7
     inputHook == InputHook.GET_ACTION_VALUE then -- 2

    local actionValue
    actionValue = InputAction:KnifeDiagonalFix(buttonAction)
    if actionValue ~= nil then
      return actionValue
    end
    actionValue = Samael:GetActionValue(buttonAction)
    if actionValue ~= nil then
      return actionValue
    end
  end

  if buttonAction == ButtonAction.ACTION_PILLCARD and -- 10
     inputHook == InputHook.IS_ACTION_TRIGGERED then -- 1
     -- (the inputHook corresponds to the action, determined through trial and error)

    -- Disable using cards/pills if we are in the trapdoor animation
    -- Disable using cards/pills if we are in the room sliding animation
    if g.run.trapdoor.state > 0 or
       roomFrameCount == 0 then

      return false
    end

  elseif buttonAction == ButtonAction.ACTION_CONSOLE and -- 28
         inputHook == InputHook.IS_ACTION_TRIGGERED then -- 1
         -- (the inputHook corresponds to the action, determined through trial and error)

    -- Prevent opening the console during a race
    if g.race.status == "in progress" and
       not g.debug then

      return false
    end
  end
end

-- Fix the bug where diagonal knife throws have a 1-frame window when playing on keyboard (2/2)
function InputAction:KnifeDiagonalFix(buttonAction)
  -- Local variables
  -- (we can't use cached API functions in this callback or else the game will crash)
  local game = Game()
  local player = game:GetPlayer(0)

  if not player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) or -- 114
     player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) or -- 168
     -- (Epic Fetus is the only thing that overwrites Mom's Knife)
     #g.run.knifeDirection < 1 then

    return
  end

  local storedDirection = g.run.knifeDirection[1]
  if (buttonAction == ButtonAction.ACTION_SHOOTLEFT and -- 4
      storedDirection[1] and
      not storedDirection[2]) or
     (buttonAction == ButtonAction.ACTION_SHOOTRIGHT and -- 5
      storedDirection[2] and
      not storedDirection[1]) or
     (buttonAction == ButtonAction.ACTION_SHOOTUP and -- 6
      storedDirection[3] and
      not storedDirection[4]) or
     (buttonAction == ButtonAction.ACTION_SHOOTDOWN and -- 7
      storedDirection[4] and
      not storedDirection[3]) then

    return 1
  end
end

return InputAction

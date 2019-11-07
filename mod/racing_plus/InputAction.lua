local InputAction = {}

-- Different actions occur on different inputHooks and this is not documented
-- Thus, each action's particular inputHook must be determined through trial and error
-- Also note that we can't use cached API functions in this callback or else the game will crash
-- ButtonAction.ACTION_MENUCONFIRM (14) is bugged and will never fire

-- Includes
local g      = require("racing_plus/globals")
local Samael = require("racing_plus/samael")

-- ModCallbacks.MC_INPUT_ACTION (13)
function InputAction:Main(entity, inputHook, buttonAction)
  return InputAction.InputHookFunction[inputHook](buttonAction)
end

-- InputHook.IS_ACTION_PRESSED (0)
function InputAction.IsActionPressed(buttonAction)
  if InputAction.IsActionPressedFunction[buttonAction] then
    return InputAction.IsActionPressedFunction[buttonAction]()
  end
end

-- InputHook.IS_ACTION_TRIGGERED (1)
function InputAction.IsActionTriggered(buttonAction)
  if InputAction.IsActionTriggeredFunction[buttonAction] then
    return InputAction.IsActionTriggeredFunction[buttonAction]()
  end
end

-- InputHook.GET_ACTION_VALUE (2)
function InputAction.GetActionValue(buttonAction)
  if InputAction.GetActionValueFunction[buttonAction] then
    return InputAction.GetActionValueFunction[buttonAction](buttonAction)
    -- (we pass the buttonAction because the child functions need to know what specific button was pressed)
  end
end

InputAction.InputHookFunction = {
  [InputHook.IS_ACTION_PRESSED] = InputAction.IsActionPressed, -- 0
  [InputHook.IS_ACTION_TRIGGERED] = InputAction.IsActionTriggered, -- 1
  [InputHook.GET_ACTION_VALUE] = InputAction.GetActionValue, -- 2
}

--
-- InputHook.IS_ACTION_PRESSED (0)
--

function InputAction.IsActionPressedShoot()
  return Samael:IsActionPressed()
end

InputAction.IsActionPressedFunction = {
  [ButtonAction.ACTION_SHOOTLEFT] = InputAction.IsActionPressedShoot, -- 4
  [ButtonAction.ACTION_SHOOTRIGHT] = InputAction.IsActionPressedShoot, -- 5
  [ButtonAction.ACTION_SHOOTUP] = InputAction.IsActionPressedShoot, -- 6
  [ButtonAction.ACTION_SHOOTDOWN] = InputAction.IsActionPressedShoot, -- 7
}

--
-- InputHook.IS_ACTION_TRIGGERED (1)
--

function InputAction.IsActionTriggeredPillCard()
  -- Disable using cards/pills if we are in the trapdoor animation
  -- Disable using cards/pills if we are in the room sliding animation
  if g.run.trapdoor.state > 0 or
     Game():GetRoom():GetFrameCount() == 0 then
      -- (we can't use cached API functions in this callback or else the game will crash)

    return false
  end
end

function InputAction.IsActionTriggeredDrop()
  -- Manually switch from The Soul to The Forgotten in specific circumstances
  if g.run.switchForgotten then
    g.run.switchForgotten = false
    return true
  end

  local character = Game():GetPlayer(0):GetPlayerType()
  -- (we can't use cached API functions in this callback or else the game will crash)
  if character == PlayerType.PLAYER_THEFORGOTTEN or -- 16
     character == PlayerType.PLAYER_THESOUL then  -- 17

    -- Prevent character switching while entering a trapdoor
    if g.run.trapdoor.state > 0 then
      return false
    end
  end
end

-- Prevent opening the console during a race
function InputAction.IsActionTriggeredConsole()
  if g.race.status == "in progress" and
     not g.debug then

    return false
  end
end

InputAction.IsActionTriggeredFunction = {
  [ButtonAction.ACTION_PILLCARD] = InputAction.IsActionTriggeredPillCard, -- 10
  [ButtonAction.ACTION_DROP] = InputAction.IsActionTriggeredDrop, -- 11
  [ButtonAction.ACTION_MENUCONFIRM] = InputAction.IsActionTriggeredMenuConfirm, -- 14
  [ButtonAction.ACTION_CONSOLE] = InputAction.IsActionTriggeredConsole, -- 28
}

--
-- InputHook.GET_ACTION_VALUE (2)
--

function InputAction.GetActionValueShoot(buttonAction)
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

-- Fix the bug where diagonal knife throws have a 1-frame window when playing on keyboard (2/2)
function InputAction:KnifeDiagonalFix(buttonAction)
  -- Local variables
  local player = Game():GetPlayer(0)
  -- (we can't use cached API functions in this callback or else the game will crash)

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

InputAction.GetActionValueFunction = {
  [ButtonAction.ACTION_SHOOTLEFT] = InputAction.GetActionValueShoot, -- 4
  [ButtonAction.ACTION_SHOOTRIGHT] = InputAction.GetActionValueShoot, -- 5
  [ButtonAction.ACTION_SHOOTUP] = InputAction.GetActionValueShoot, -- 6
  [ButtonAction.ACTION_SHOOTDOWN] = InputAction.GetActionValueShoot, -- 7
}

return InputAction

local InputAction = {}

-- Different actions occur on different inputHooks and this is not documented
-- Thus, each action's particular inputHook must be determined through trial and error
-- Also note that we can't use cached API functions in this callback or else the game will crash
-- ButtonAction.ACTION_MENUCONFIRM (14) is bugged and will never fire

-- Includes
local g = require("racing_plus/globals")
local Samael = require("racing_plus/samael")
local SeededDeath = require("racing_plus/seededdeath")
local Autofire = require("racing_plus/autofire")

-- ModCallbacks.MC_INPUT_ACTION (13)
function InputAction:Main(entity, inputHook, buttonAction)
  return InputAction.InputHookFunction[inputHook](buttonAction)
end

-- InputHook.IS_ACTION_PRESSED (0)
function InputAction.IsActionPressed(buttonAction)
  local actionPressedFunction = InputAction.IsActionPressedFunction[buttonAction]
  if actionPressedFunction ~= nil then
    return actionPressedFunction()
  end
end

-- InputHook.IS_ACTION_TRIGGERED (1)
function InputAction.IsActionTriggered(buttonAction)
  local actionTriggeredFunction = InputAction.IsActionTriggeredFunction[buttonAction]
  if actionTriggeredFunction ~= nil then
    return actionTriggeredFunction()
  end
end

-- InputHook.GET_ACTION_VALUE (2)
function InputAction.GetActionValue(buttonAction)
  local actionValueFunction = InputAction.GetActionValueFunction[buttonAction]
  if actionValueFunction ~= nil then
    -- We pass the buttonAction because the child functions need to know what specific button was
    -- pressed
    return actionValueFunction(buttonAction)
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
  local actionValue

  actionValue = Samael:IsActionPressed()
  if actionValue ~= nil then
    return actionValue
  end

  actionValue = Autofire:IsActionPressed()
  if actionValue ~= nil then
    return actionValue
  end
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
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  -- (we can't use cached API functions in this callback or else the game will crash)
  local roomFrameCount = room:GetFrameCount()

  -- Disable using cards/pills if we are in the trapdoor animation
  -- Disable using cards/pills if we are in the room sliding animation
  if (
    g.run.trapdoor.state > 0
    or roomFrameCount == 0
  ) then
    return false
  end
end

function InputAction.IsActionTriggeredDrop()
  -- Manually switch from The Soul to The Forgotten in specific circumstances
  if g.run.switchForgotten then
    g.run.switchForgotten = false
    if g.run.seededDeath.state == SeededDeath.state.DEATH_ANIMATION then
      g.p:PlayExtraAnimation("Death")
    end
    return true
  end

  -- Prevent character switching while entering a trapdoor
  if g.run.trapdoor.state == 0 then
    return
  end

  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  -- (we can't use cached API functions in this callback or else the game will crash)
  local character = player:GetPlayerType()

  if (
    character == PlayerType.PLAYER_THEFORGOTTEN -- 16
    or character == PlayerType.PLAYER_THESOUL -- 17
  ) then
    return false
  end
end

-- Prevent opening the console during a race
function InputAction.IsActionTriggeredConsole()
  if g.debug == true then
    return
  end

  -- Allow usage of the console in custom races
  if g.race.status == "in progress" and g.race.rFormat ~= "custom" then
    return false
  end
end

function InputAction.IsActionTriggeredItem()
  if g.run.spamButtons then
    g.sfx:Stop(SoundEffect.SOUND_ISAAC_HURT_GRUNT) -- 55
    return true
  end
end

InputAction.IsActionTriggeredFunction = {
  [ButtonAction.ACTION_ITEM] = InputAction.IsActionTriggeredItem, -- 9
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

  actionValue = Autofire:GetActionValue(buttonAction)
  if actionValue ~= nil then
    return actionValue
  end
end

-- Fix the bug where diagonal knife throws have a 1-frame window when playing on keyboard (2/2)
function InputAction:KnifeDiagonalFix(buttonAction)
  -- Local variables
  local player = Game():GetPlayer(0)
  -- (we can't use cached API functions in this callback or else the game will crash)

  if (
    not player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) -- 114
    or player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) -- 168
    -- (Epic Fetus is the only thing that overwrites Mom's Knife)
    or #g.run.directions < 1
  ) then
    return
  end

  local storedDirection = g.run.directions[1]
  if (
    (
      buttonAction == ButtonAction.ACTION_SHOOTLEFT -- 4
      and storedDirection[1]
      and not storedDirection[2]
    ) or (
      buttonAction == ButtonAction.ACTION_SHOOTRIGHT -- 5
      and storedDirection[2]
      and not storedDirection[1]
    ) or (
      buttonAction == ButtonAction.ACTION_SHOOTUP -- 6
      and storedDirection[3]
      and not storedDirection[4]
    ) or (
      buttonAction == ButtonAction.ACTION_SHOOTDOWN -- 7
      and storedDirection[4]
      and not storedDirection[3]
    )
  ) then
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

local RPInputAction = {}

-- Includes
local RPGlobals = require("src/rpglobals")
local RPSamael  = require("src/rpsamael")

-- ModCallbacks.MC_INPUT_ACTION (13)
function RPInputAction:Main(entity, inputHook, buttonAction)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomFrameCount = room:GetFrameCount()

  if (buttonAction == ButtonAction.ACTION_SHOOTLEFT or -- 4
      buttonAction == ButtonAction.ACTION_SHOOTRIGHT or -- 5
      buttonAction == ButtonAction.ACTION_SHOOTUP or -- 6
      buttonAction == ButtonAction.ACTION_SHOOTDOWN) and -- 7
     inputHook == InputHook.IS_ACTION_PRESSED then -- 0

    return RPSamael:IsActionPressed()
  end
  if (buttonAction == ButtonAction.ACTION_SHOOTLEFT or -- 4
      buttonAction == ButtonAction.ACTION_SHOOTRIGHT or -- 5
      buttonAction == ButtonAction.ACTION_SHOOTUP or -- 6
      buttonAction == ButtonAction.ACTION_SHOOTDOWN) and -- 7
     inputHook == InputHook.GET_ACTION_VALUE then -- 2

    local actionValue
    actionValue = RPInputAction:KnifeDiagonalFix(buttonAction)
    if actionValue ~= nil then
      return actionValue
    end
    actionValue = RPSamael:GetActionValue(buttonAction)
    if actionValue ~= nil then
      return actionValue
    end
  end

  if buttonAction == ButtonAction.ACTION_PILLCARD and -- 10
     inputHook == InputHook.IS_ACTION_TRIGGERED then -- 1
     -- (the inputHook corresponds to the action, determined through trial and error)

    -- Disable using cards/pills if we are in the trapdoor animation
    -- Disable using cards/pills if we are in the room sliding animation
    if RPGlobals.run.trapdoor.state > 0 or
       roomFrameCount == 0 then

      return false
    end

  elseif buttonAction == ButtonAction.ACTION_CONSOLE and -- 28
         inputHook == InputHook.IS_ACTION_TRIGGERED then -- 1
         -- (the inputHook corresponds to the action, determined through trial and error)

    -- Prevent opening the console during a race
    if RPGlobals.race.status == "in progress" and
       RPGlobals.debug == false then

      return false
    end
  end
end

-- Fix the bug where diagonal knife throws have a 1-frame window when playing on keyboard (2/2)
function RPInputAction:KnifeDiagonalFix(buttonAction)
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  if player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) == false or -- 114
     player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) or -- 168
     -- (Epic Fetus is the only thing that overwrites Mom's Knife)
     #RPGlobals.run.knifeDirection < 1 then

    return
  end

  local storedDirection = RPGlobals.run.knifeDirection[1]
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

return RPInputAction

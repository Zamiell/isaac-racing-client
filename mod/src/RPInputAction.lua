local RPInputAction = {}

--
-- Includes
--

local RPGlobals  = require("src/rpglobals")
--local RPSamael   = require("src/rpsamael")

-- ModCallbacks.MC_INPUT_ACTION (13)
function RPInputAction:Main(entity, inputHook, buttonAction)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local roomFrameCount = room:GetFrameCount()

  --[[
  if (buttonAction == ButtonAction.ACTION_SHOOTDOWN or -- 4
      buttonAction == ButtonAction.ACTION_SHOOTRIGHT or -- 5
      buttonAction == ButtonAction.ACTION_SHOOTUP or -- 6
      buttonAction == ButtonAction.ACTION_SHOOTDOWN) and -- 7
     inputHook == InputHook.IS_ACTION_PRESSED then -- 0
     -- (the inputHook corresponds to the action, determined through trial and error)
     -- (this button action also triggers with ButtonAction.GET_ACTION_VALUE / 2)

    --return RPSamael:InputActionShoot(buttonAction)
    if buttonAction == 5 then
      Isaac.DebugString("RETURNING true")
      return true
    end
  --]]

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

return RPInputAction

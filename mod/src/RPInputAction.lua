local RPInputAction = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")

-- ModCallbacks.MC_INPUT_ACTION (13)
function RPInputAction:Main(entity, inputHook, buttonAction)
  -- Disable resetting if the countdown is close to hitting 0
  if RPGlobals.raceVars.resetEnabled == false and
     buttonAction == ButtonAction.ACTION_RESTART then -- 16

    return false
  end

  -- Disable using cards if we are in the trapdoor animation
  if RPGlobals.run.trapdoor.state > 0 and
     buttonAction == ButtonAction.ACTION_PILLCARD then -- 10

    return
  end

  -- Prevent opening the console during a race
  if RPGlobals.race.status == "in progress" and
    buttonAction == ButtonAction.ACTION_CONSOLE then -- 28

    return false
  end
end

return RPInputAction

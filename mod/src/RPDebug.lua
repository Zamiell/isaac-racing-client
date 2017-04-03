local RPDebug = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")
local RPSprites = require("src/rpsprites")

--
-- Variables
--

--local debugVar = 118

--
-- Debug functions
--


function RPDebug:Main()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)
  local sfx = SFXManager()

  -- Print out various debug information to Isaac's log.txt
  Isaac.DebugString("+-------------------------+")
  Isaac.DebugString("| Entering test callback. |")
  Isaac.DebugString("+-------------------------+")

  local globalsToPrint = {
    "run",
    "race",
    "raceVars",
    "spriteTable",
  }

  for i = 1, #globalsToPrint do
    Isaac.DebugString(globalsToPrint[i] .. ":")
    for k, v in pairs(RPGlobals[globalsToPrint[i]]) do
      if type(v) == "table" then
        Isaac.DebugString("  " .. k .. ': ')
        for k2, v2 in pairs(v) do
          if type(v2) == "table" then
            Isaac.DebugString("  " .. k2 .. ': ')
            for k3, v3 in pairs(v2) do
              Isaac.DebugString("      " .. k3 .. ': ' .. tostring(v3))
            end
          else
            Isaac.DebugString("    " .. k2 .. ': ' .. tostring(v2))
          end
        end
      else
        Isaac.DebugString("  " .. k .. ': ' .. tostring(v))
      end
    end
  end

  -- Test stuff
  --RPGlobals.raceVars.finished = true
  --debugVar = debugVar + 1
  --RPSprites:Init("diversity-item5", tostring(debugVar))
  --RPSprites:Init("speedrun-char1", "0")
  RPGlobals.raceVars.startedTime = RPGlobals.raceVars.startedTime - (1000 * 60 * 2)

  Isaac.DebugString("+------------------------+")
  Isaac.DebugString("| Exiting test callback. |")
  Isaac.DebugString("+------------------------+")

  -- Display the "use" animation
  return true
end

return RPDebug

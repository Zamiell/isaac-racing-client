local RPDebug = {}

--
-- Includes
--

local RPGlobals     = require("src/rpglobals")
local RPSprites     = require("src/rpsprites")
local RPSpeedrun    = require("src/rpspeedrun")
--local RPSeededDeath = require("src/rpseededdeath")

--
-- Variables
--

RPDebug.temp = false

--
-- Debug functions
--


function RPDebug:Main()
  -- Enable debug mode
  RPGlobals.debug = true

  -- Print out various debug information to Isaac's log.txt
  Isaac.DebugString("+-------------------------+")
  Isaac.DebugString("| Entering test callback. |")
  Isaac.DebugString("+-------------------------+")

  local globalsToPrint = {
    "run",
    "race",
    "raceVars",
  }

  for i = 1, #globalsToPrint do
    Isaac.DebugString(globalsToPrint[i] .. ":")
    for k, v in pairs(RPGlobals[globalsToPrint[i]]) do
      if type(v) == "table" then
        Isaac.DebugString("  " .. k .. ': ')
        for k2, v2 in pairs(v) do
          if type(v2) == "table" then
            Isaac.DebugString("    " .. k2 .. ': ')
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
  Isaac.DebugString("speedrun: ")
  for k, v in pairs(RPSpeedrun) do
    if type(v) == "string" or
    type(v) == "number" or
    type(v) == "boolean" then

      Isaac.DebugString("  " .. k .. ": " .. tostring(v))
    end
  end
  Isaac.DebugString("sprites: ")
  for k, v in pairs(RPSprites.sprites) do
    for k2, v2 in pairs(v) do
      if k2 == "spriteName" and v2 ~= 0 then
        Isaac.DebugString("  " .. k .. ":")
        Isaac.DebugString("    " .. k2 .. ": " .. tostring(v2))
      end
    end
  end

  --
  -- Test stuff
  --

  --[[
  if RPDebug.temp then
    RPSeededDeath:DebuffOff()
  else
    RPSeededDeath:DebuffOn()
  end
  RPDebug.temp = not RPDebug.temp
  --]]

  --RPGlobals.raceVars.finished = true
  --RPSprites:Init("place", 1)

  -- New Booster Pack item images testing
  --[[
  RPSprites:Init("diversity-item1", 530) -- Collectible
  RPSprites:Init("diversity-item2", 531) -- Collectible
  RPSprites:Init("diversity-item3", 532) -- Collectible
  RPSprites:Init("diversity-item4", 534) -- Collectible
  RPSprites:Init("diversity-item5", 125) -- Trinket
  --]]

  --
  -- End test stuff
  --

  Isaac.DebugString("+------------------------+")
  Isaac.DebugString("| Exiting test callback. |")
  Isaac.DebugString("+------------------------+")

  -- Display the "use" animation
  return true
end

return RPDebug

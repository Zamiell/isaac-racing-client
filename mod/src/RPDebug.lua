local RPDebug = {}

-- Includes
local RPGlobals     = require("src/rpglobals")
local RPSprites     = require("src/rpsprites")
local RPSpeedrun    = require("src/rpspeedrun")

-- Variables
RPDebug.temp = false

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

  --RPGlobals.raceVars.finished = true
  --RPSprites:Init("place", 1)

  -- New Booster Pack item images testing
  --[[
  RPSprites:Init("diversity-item1", 519) -- Active Item
  RPSprites:Init("diversity-item2", 531) -- Passive Item
  RPSprites:Init("diversity-item3", 532) -- Passive Item
  RPSprites:Init("diversity-item4", 534) -- Passive Item
  RPSprites:Init("diversity-item5", 125) -- Trinket
  --]]

  --[[
  local game = Game()
  local cardNum = 1
  for y = 0, 6 do
    for x = 0, 12 do
      if cardNum < 54 then
        local pos = RPGlobals:GridToPos(x, y)
        game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, pos, Vector(0, 0), nil, cardNum, 0)
        cardNum = cardNum + 1
      end
    end
  end
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

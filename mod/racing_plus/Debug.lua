local Debug = {}

-- Includes
local g        = require("racing_plus/globals")
local Sprites  = require("racing_plus/sprites")
local Speedrun = require("racing_plus/speedrun")

-- Variables
Debug.temp = false

function Debug:Main()
  -- Enable debug mode
  g.debug = true

  -- Print out various debug information to Isaac's log.txt
  Isaac.DebugString("+-------------------------+")
  Isaac.DebugString("| Entering test callback. |")
  Isaac.DebugString("+-------------------------+")

  local globalsToPrint = {
    "run",
    "race",
    "raceVars",
  }

  for _, var in ipairs(globalsToPrint) do
    Isaac.DebugString(var .. ":")
    for k, v in pairs(g[var]) do
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
  for k, v in pairs(Speedrun) do
    if type(v) == "string" or
    type(v) == "number" or
    type(v) == "boolean" then

      Isaac.DebugString("  " .. k .. ": " .. tostring(v))
    end
  end
  Isaac.DebugString("sprites: ")
  for k, v in pairs(Sprites.sprites) do
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

  Isaac.DebugString("RP g.run.handsDelay: " .. tostring(g.run.handsDelay))
  --g.raceVars.finished = true
  --Sprites:Init("place", 1)

  -- New Booster Pack item images testing
  --[[
  Sprites:Init("diversity-item1", 519) -- Active Item
  Sprites:Init("diversity-item2", 531) -- Passive Item
  Sprites:Init("diversity-item3", 532) -- Passive Item
  Sprites:Init("diversity-item4", 534) -- Passive Item
  Sprites:Init("diversity-item5", 125) -- Trinket
  --]]

  --[[
  local cardNum = 1
  for y = 0, 6 do
    for x = 0, 12 do
      if cardNum < 54 then
        local pos = g:GridToPos(x, y)
        g.p:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, pos, Vector(0, 0), nil, cardNum, 0)
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

return Debug

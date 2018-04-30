local RPDebug = {}

--
-- Includes
--

local RPGlobals = require("src/rpglobals")
local RPSprites = require("src/rpsprites")
local RPSpeedrun = require("src/rpspeedrun")

--
-- Variables
--

RPDebug.temp = 20

--
-- Debug functions
--


function RPDebug:Main()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local room = game:GetRoom()
  local player = game:GetPlayer(0)
  local sfx = SFXManager()

  -- Enable debug mode
  RPGlobals.debug = true

  RPSpeedrun.charPosition7_3 = { -- The format is character number, X, Y
    {14, 2, 1}, -- Keeper
    {9, 4, 1},  -- Eden
    {10, 6, 1}, -- Lost
    {7, 8, 1},  -- Azazel
    {0, 10, 1}, -- Isaac
    {3, 5, 3},  -- Judas
    {4, 7, 3},  -- Blue Baby
  }

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

  --RPGlobals.raceVars.victoryLaps = RPGlobals.raceVars.victoryLaps + 1
  --RPGlobals.raceVars.finished = true
  --RPSprites:Init("place", 1)

  -- New Booster Pack item images testing
  RPDebug.temp = RPDebug.temp + 1
  Isaac.DebugString("Temp var is now at: " .. tostring(RPDebug.temp))
  --RPSprites:Init("diversity-item1", RPDebug.temp) -- Collectible
  RPSprites:Init("diversity-item5", RPDebug.temp) -- Trinket

  --RPSprites:Init("diversity-item1", 530) -- Collectible
  --RPSprites:Init("diversity-item2", 531) -- Collectible
  --RPSprites:Init("diversity-item3", 532) -- Collectible
  --RPSprites:Init("diversity-item4", 534) -- Collectible
  --RPSprites:Init("diversity-item5", 125) -- Trinket

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

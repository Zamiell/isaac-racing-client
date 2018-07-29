local RPPostNewLevel = {}

--
-- Includes
--

local RPGlobals     = require("src/rpglobals")
local RPPostNewRoom = require("src/rppostnewroom")
local RPFastTravel  = require("src/rpfasttravel")

-- ModCallbacks.MC_POST_NEW_LEVEL (18)
function RPPostNewLevel:Main()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()

  Isaac.DebugString("MC_POST_NEW_LEVEL")

  -- Make sure the callbacks run in the right order
  -- (naturally, PostNewLevel gets called before the PostGameStarted callbacks)
  if gameFrameCount == 0 then
    return
  end

  -- We need to delay if we are doing a "reseed" immediately after a "stage X",
  -- because the "RPPostNewRoom:CheckTrapdoor2()" function will fire before the reseed happens
  if RPFastTravel.delayNewRoomCallback then
    RPFastTravel.delayNewRoomCallback = false
    Isaac.DebugString("Delaying before loading the room due to an imminent reseed.")
    return
  end

  RPPostNewLevel:NewLevel()
end

function RPPostNewLevel:NewLevel()
  -- Local variables
  local game = Game()
  local itemPool = game:GetItemPool()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local player = game:GetPlayer(0)
  local character = player:GetPlayerType()
  local challenge = Isaac.GetChallenge()

  Isaac.DebugString("MC_POST_NEW_LEVEL2")

  -- Find out if we performed a Sacrifice Room teleport
  if (RPGlobals.race.goal == "The Lamb" or
      RPGlobals.race.goal == "Mega Satan" or
      RPGlobals.race.goal == "Everything" or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)")) and
     stage == 11 and stageType == 0 and -- 11.0 is Dark Room
     (RPGlobals.run.currentFloor ~= 10 and
      RPGlobals.run.currentFloor ~= 11) then -- This is necessary because of Forget Me Now

    -- We arrived at the Dark Room without going through Sheol
    Isaac.DebugString("Sacrifice Room teleport detected.")
    RPFastTravel:GotoNextFloor(false, RPGlobals.run.currentFloor)
    -- The first argument is "upwards", the second argument is "redirect"
    return
  end

  -- Set the new floor
  RPGlobals.run.currentFloor = stage
  RPGlobals.run.currentFloorType = stageType
  Isaac.DebugString("New floor: " .. tostring(RPGlobals.run.currentFloor) .. "-" ..
                    tostring(RPGlobals.run.currentFloorType))

  -- Reset some per level flags
  RPGlobals.run.levelDamaged = false
  RPGlobals.run.replacedPedestals = {}
  RPGlobals.run.replacedTrapdoors = {}
  RPGlobals.run.replacedCrawlspaces = {}
  RPGlobals.run.replacedHeavenDoors = {}

  -- Reset the RNG of some items that should be seeded per floor
  local floorSeed = level:GetDungeonPlacementSeed()
  RPGlobals.RNGCounter.Teleport = floorSeed
  RPGlobals.RNGCounter.Undefined = floorSeed
  RPGlobals.RNGCounter.Telepills = floorSeed
  for i = 1, 100 do
    -- Increment the RNG 100 times so that players cannot use knowledge of Teleport! teleports
    -- to determine where the Telepills destination will be
    RPGlobals.RNGCounter.Telepills = RPGlobals:IncrementRNG(RPGlobals.RNGCounter.Telepills)
  end

  -- Start showing the place graphic if we get to Basement 2
  if stage >= 2 then
    RPGlobals.raceVars.showPlaceGraphic = true
  end

  -- Make sure that the diveristy placeholder items are removed
  if stage >= 2 then
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1)
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2)
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3)
  end

  -- Ensure that the "More Options" buff does not persist beyond Basement 1
  -- (it is removed as soon as they enter the first Treasure Room,
  -- but they might have skipped the Basement 1 Treasure Room for some reason)
  if stage >= 2 and RPGlobals.run.removeMoreOptions == true then
    RPGlobals.run.removeMoreOptions = false
    player:RemoveCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) -- 414
  end

  -- Fix the Strength card bug that happens wtih Fast-Travel
  if RPGlobals.run.usedStrength and
     character ~= PlayerType.PLAYER_KEEPER then -- 14

    RPGlobals.run.usedStrength = false
    player:AddMaxHearts(-2) -- Remove a heart container
    Isaac.DebugString("Took away 1 heart container from Keeper (via a Strength card). (RPPost0NewLevel)")
  end

  -- Call PostNewRoom manually (they get naturally called out of order)
  RPPostNewRoom:NewRoom()
end

return RPPostNewLevel

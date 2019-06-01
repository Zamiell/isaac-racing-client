local PostNewLevel = {}

-- Includes
local g            = require("racing_plus/globals")
local PostNewRoom  = require("racing_plus/postnewroom")
local FastTravel   = require("racing_plus/fasttravel")
local SeededFloors = require("racing_plus/seededfloors")
local SoulJar      = require("racing_plus/souljar")

-- ModCallbacks.MC_POST_NEW_LEVEL (18)
function PostNewLevel:Main()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  Isaac.DebugString("MC_POST_NEW_LEVEL - " .. tostring(stage) .. "." .. tostring(stageType))

  -- Make sure the callbacks run in the right order
  -- (naturally, PostNewLevel gets called before the PostGameStarted callbacks)
  if gameFrameCount == 0 and
     not g.run.reseededFloor then

    return
  end
  if g.run.reseededFloor then
    g.run.reseededFloor = false
  end

  -- We need to delay if we are doing a "reseed" immediately after a "stage X",
  -- because the "PostNewRoom:CheckTrapdoor2()" function will fire before the reseed happens
  if FastTravel.delayNewRoomCallback then
    FastTravel.delayNewRoomCallback = false
    Isaac.DebugString("Delaying before loading the room due to an imminent reseed.")
    return
  end

  PostNewLevel:NewLevel()
end

function PostNewLevel:NewLevel()
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local customRun = g.seeds:IsCustomRun()
  local challenge = Isaac.GetChallenge()

  Isaac.DebugString("MC_POST_NEW_LEVEL2 - " .. tostring(stage) .. "." .. tostring(stageType))

  -- Find out if we performed a Sacrifice Room teleport
  if (g.race.goal == "The Lamb" or
      g.race.goal == "Mega Satan" or
      g.race.goal == "Everything" or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 3)") or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") or
      challenge == Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)")) and
     stage == 11 and stageType == 0 and -- 11.0 is Dark Room
     (g.run.currentFloor ~= 10 and
      g.run.currentFloor ~= 11) then -- This is necessary because of Forget Me Now

    -- We arrived at the Dark Room without going through Sheol
    Isaac.DebugString("Sacrifice Room teleport detected.")
    FastTravel:GotoNextFloor(false, g.run.currentFloor)
    -- The first argument is "upwards", the second argument is "redirect"
    return
  end

  -- Reseed the floor if it has a flaw in it
  if challenge ~= 0 or
     not customRun then -- Disable reseeding for set seeds

    if PostNewLevel:CheckDualityNarrowRoom() or -- Check for Duality restrictions
       PostNewLevel:CheckForgottenSoftlock() or -- Forgotten can become softlocked in certain rooms
       PostNewLevel:CheckDupeRooms() then -- Check for duplicate rooms
      -- (checking for duplicate rooms has to be the last check because it will store the rooms as "seen")

      g.run.reseededFloor = true
      g.run.reseedCount = g.run.reseedCount + 1
      g:ExecuteCommand("reseed")
      return
    end
  end

  -- Set the new floor
  g.run.currentFloor = stage
  g.run.currentFloorType = stageType
  Isaac.DebugString("New floor: " .. tostring(g.run.currentFloor) .. "-" ..
                    tostring(g.run.currentFloorType))

  -- Reset some per level flags
  g.run.replacedPedestals = {}
  g.run.replacedTrapdoors = {}
  g.run.replacedCrawlspaces = {}
  g.run.replacedHeavenDoors = {}
  Isaac.DebugString("Reseed count: " .. tostring(g.run.reseedCount))
  g.run.reseedCount = 0
  g.run.tempHolyMantle = false

  -- Reset the RNG of some items that should be seeded per floor
  local stageSeed = g.seeds:GetStageSeed(stage)
  g.RNGCounter.Teleport = stageSeed
  g.RNGCounter.Undefined = stageSeed
  g.RNGCounter.Telepills = stageSeed
  for i = 1, 100 do
    -- Increment the RNG 100 times so that players cannot use knowledge of Teleport! teleports
    -- to determine where the Telepills destination will be
    g.RNGCounter.Telepills = g:IncrementRNG(g.RNGCounter.Telepills)
  end

  -- Make sure that the diveristy placeholder items are removed
  if stage >= 2 then
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_1)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_2)
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_DIVERSITY_PLACEHOLDER_3)
  end

  -- Handle the Soul Jar
  SoulJar:PostNewLevel()

  -- Ensure that the "More Options" buff does not persist beyond Basement 1
  -- (it is removed as soon as they enter the first Treasure Room,
  -- but they might have skipped the Basement 1 Treasure Room for some reason)
  if stage >= 2 and g.run.removeMoreOptions == true then
    g.run.removeMoreOptions = false
    g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_MORE_OPTIONS) -- 414
  end

  FastTravel:FixStrengthCardBug()

  -- Seed floors that are generated when a player uses a Forget Me Now or a 5-pip Dice Room
  if g.run.forgetMeNow then
    g.run.forgetMeNow = false
    SeededFloors:After()
  end

  -- Call PostNewRoom manually (they get naturally called out of order)
  PostNewRoom:NewRoom()
end

-- Reseed the floor if we have Duality and there is a narrow boss room
function PostNewLevel:CheckDualityNarrowRoom()
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_DUALITY) then -- 498
    return false
  end

  -- It is only possible to get a Devil Deal on floors 2 through 8
  -- Furthermore, it is not possible to get a narrow room on floor 8
  local stage = g.l:GetStage()
  if stage <= 1 or
     stage >= 8 then

    return false
  end

  -- Check to see if the boss room is narrow
  local rooms = g.l:GetRooms()
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local roomData = rooms:Get(i).Data
    if roomData.Type == RoomType.ROOM_BOSS then -- 5
      if roomData.Shape == RoomShape.ROOMSHAPE_IH or -- 2
         roomData.Shape == RoomShape.ROOMSHAPE_IV then -- 3

        Isaac.DebugString("Narrow boss room detected with Duality - reseeding.")
        return true
      end
    end
  end

  return false
end

-- If the Forgotten has Chocolate Milk or Brimstone, and then spends all of his soul hearts in a devil deal,
-- then they can become softlocked in certain specific island rooms
function PostNewLevel:CheckForgottenSoftlock()
  local character = g.p:GetPlayerType()
  if character ~= PlayerType.PLAYER_THEFORGOTTEN then -- 17
    return false
  end

  local subPlayer = g.p:GetSubPlayer()
  local soulHearts = subPlayer:GetSoulHearts()
  if soulHearts > 0 then
    return false
  end

  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) and -- 69
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) and -- 118
     not g.p:HasCollectible(CollectibleType.COLLECTIBLE_CURSED_EYE) then -- 316

    return false
  end

  -- Local variables
  local stage = g.l:GetStage()
  if stage <= 2 or
     stage >= 9 then

    return false
  end

  -- Search through the floor for specific rooms
  local rooms = g.l:GetRooms()
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local roomData = rooms:Get(i).Data
    if roomData.Type == RoomType.ROOM_DEFAULT then -- 1
      -- Normalize the room ID (to account for flipped rooms)
      local roomID = roomData.Variant
      while roomID >= 10000 do
        -- The 3 flipped versions of room #1 would be #10001, #20001, and #30001
        roomID = roomID - 10000
      end

      local stageID = roomData.StageID
      if ((stageID == 4 or stageID == 6) and roomID == 226) or -- Caves / Flooded Caves
         ((stageID == 4 or stageID == 6) and roomID == 251) or
         ((stageID == 4 or stageID == 6) and roomID == 303) or
         ((stageID == 4 or stageID == 6) and roomID == 500) or
         ((stageID == 4 or stageID == 5 or stageID == 6) and roomID == 305) or -- Caves / Catacombs / Flooded Caves
         ((stageID == 4 or stageID == 5 or stageID == 6) and roomID == 337) or
         ((stageID == 4 or stageID == 5 or stageID == 6) and roomID == 378) or
         ((stageID == 4 or stageID == 5 or stageID == 6) and roomID == 450) or
         ((stageID == 4 or stageID == 5 or stageID == 6) and roomID == 488) or
         ((stageID == 4 or stageID == 5 or stageID == 6) and roomID == 742) or
         ((stageID == 4 or stageID == 5 or stageID == 6) and roomID == 754) or
         (stageID == 5 and roomID == 224) or -- Catacombs
         ((stageID == 7 and stageID == 8 or stageID == 9) and roomID == 226) or -- Depths / Necropolis / Dank Depths
         ((stageID == 7 and stageID == 8 or stageID == 9) and roomID == 227) or
         ((stageID == 7 and stageID == 8 or stageID == 9) and roomID == 275) or
         ((stageID == 7 and stageID == 8 or stageID == 9) and roomID == 390) or
         ((stageID == 7 and stageID == 8 or stageID == 9) and roomID == 417) or
         ((stageID == 7 and stageID == 8 or stageID == 9) and roomID == 446) or
         ((stageID == 7 and stageID == 8 or stageID == 9) and roomID == 455) or
         ((stageID == 7 and stageID == 8 or stageID == 9) and roomID == 492) or
         ((stageID == 7 and stageID == 8 or stageID == 9) and roomID == 573) or
         ((stageID == 10 and stageID == 11 or stageID == 12) and roomID == 344) or -- Womb / Utero / Scarred Womb
         ((stageID == 10 and stageID == 11 or stageID == 12) and roomID == 417) or
         ((stageID == 10 and stageID == 11 or stageID == 12) and roomID == 458) or
         ((stageID == 10 and stageID == 11 or stageID == 12) and roomID == 459) then

        Isaac.DebugString("Island room detected with low-range Forgotten - reseeding.")
        return true
      end
    end
  end

  return false
end

-- Reseed the floor if there duplicate rooms
function PostNewLevel:CheckDupeRooms()
  -- Local variables
  local stage = g.l:GetStage()
  local rooms = g.l:GetRooms()

  -- Disable this feature if the "Infinite Basements" Easter Egg is enabled,
  -- because the player will run out of rooms after around 40-50 floors
  if g.seeds:HasSeedEffect(SeedEffect.SEED_INFINITE_BASEMENT) then -- 16
    return false
  end

  -- Don't bother checking on Blue Womb, The Chest / Dark Room, or The Void
  if stage == LevelStage.STAGE4_3 or -- 9
     stage == LevelStage.STAGE6 or -- 11
     stage == LevelStage.STAGE7 then -- 12

    return false
  end

  -- Reset the room IDs if we are arriving at a level with a new stage type
  if stage == LevelStage.STAGE2_1 or -- 3
     stage == LevelStage.STAGE3_1 or -- 5
     stage == LevelStage.STAGE4_1 or -- 7
     stage == LevelStage.STAGE5 or -- 10
     stage == LevelStage.STAGE6 then -- 11

    g.run.roomIDs = {}
  end

  local roomIDs = {}
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local roomData = rooms:Get(i).Data
    if roomData.Type == RoomType.ROOM_DEFAULT and -- 1
       roomData.Variant ~= 2 and -- This is the starting room
       roomData.Variant ~= 0 then -- This is the starting room on The Chest / Dark Room

      -- Normalize the room ID (to account for flipped rooms)
      local roomID = roomData.Variant
      while roomID >= 10000 do
        -- The 3 flipped versions of room #1 would be #10001, #20001, and #30001
        roomID = roomID - 10000
      end

      -- Make Basement 1 exempt from duplication checking so that resetting is faster on potato computers
      if stage ~= 1 then
        -- Check to see if this room ID has appeared on previous floors
        for j = 1, #g.run.roomIDs do
          if roomID == g.run.roomIDs[j] then
            Isaac.DebugString("Duplicate room " .. tostring(roomID) .. " found (on previous floor) - reseeding.")
            return true
          end
        end

        -- Also check to see if this room ID appears multiple times on this floor
        for j = 1, #roomIDs do
          if roomID == roomIDs[j] then
            Isaac.DebugString("Duplicate room " .. tostring(roomID) .. " found (on same floor) - reseeding.")
            return true
          end
        end
      end

      -- Keep track of this room ID
      roomIDs[#roomIDs + 1] = roomID
    end
  end

  -- We have gone through all of the rooms and none are duplicated, so permanently store them as rooms already seen
  for _, roomID in ipairs(roomIDs) do
    g.run.roomIDs[#g.run.roomIDs + 1] = roomID
  end

  return false
end

-- Get the grid coordinates on a 13x13 grid
function PostNewLevel:GetXYFromGridIndex(idx)
  -- 0 --> (0, 0)
  -- 1 --> (1, 0)
  -- 13 --> (0, 1)
  -- 14 --> (1, 1)
  -- etc.
  local y = math.floor(idx / 13)
  local x = idx - (y * 13)

  -- Now, we add 1 to each x and y because the game uses a 0-indexed grid and
  -- the pathing library expects a 1-indexed grid
  return x + 1, y + 1
end

return PostNewLevel

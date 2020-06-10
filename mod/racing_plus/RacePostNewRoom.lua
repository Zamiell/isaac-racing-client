local RacePostNewRoom = {}

-- Includes
local g           = require("racing_plus/globals")
local Sprites     = require("racing_plus/sprites")
local SeededDeath = require("racing_plus/seededdeath")
local SeededRooms = require("racing_plus/seededrooms")

RacePostNewRoom.ThreeDollarBillEffects = {
  CollectibleType.COLLECTIBLE_20_20, -- 245
  CollectibleType.COLLECTIBLE_BALL_OF_TAR, -- 231
  CollectibleType.COLLECTIBLE_DARK_MATTER, -- 259
  CollectibleType.COLLECTIBLE_DEATHS_TOUCH, -- 237
  CollectibleType.COLLECTIBLE_FIRE_MIND, -- 257
  CollectibleType.COLLECTIBLE_IRON_BAR, -- 201
  CollectibleType.COLLECTIBLE_MOMS_CONTACTS, -- 110
  CollectibleType.COLLECTIBLE_MY_REFLECTION, -- 5
  CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID, -- 317
  CollectibleType.COLLECTIBLE_NUMBER_ONE, -- 6
  CollectibleType.COLLECTIBLE_OUIJA_BOARD, -- 115
  CollectibleType.COLLECTIBLE_PROPTOSIS, -- 261
  CollectibleType.COLLECTIBLE_SAGITTARIUS, -- 306
  CollectibleType.COLLECTIBLE_SCORPIO, -- 305
  CollectibleType.COLLECTIBLE_SPEED_BALL, -- 143
  CollectibleType.COLLECTIBLE_SPOON_BENDER, -- 3
  CollectibleType.COLLECTIBLE_INNER_EYE, -- 2
  CollectibleType.COLLECTIBLE_TOUGH_LOVE, -- 150
}

function RacePostNewRoom:Main()
  -- Remove some sprites if they are showing
  Sprites:Init("place2", 0)
  Sprites:Init("dps-button", 0)
  Sprites:Init("victory-lap-button", 0)

  RacePostNewRoom:GotoRaceRoom()
  RacePostNewRoom:ThreeDollarBill()
  RacePostNewRoom:CheckEverythingFloorSkip()
  RacePostNewRoom:CheckOpenMegaSatanDoor()
  RacePostNewRoom:CheckVictoryLapBossReplace()

  -- Check for the special death mechanic
  SeededDeath:PostNewRoom()
  SeededDeath:PostNewRoomCheckSacrificeRoom()

  -- Check for rooms that should be manually seeded during seeded races
  SeededRooms:PostNewRoom()
end

-- Go to the custom "Race Room"
function RacePostNewRoom:GotoRaceRoom()
  if (g.race.status == "open" or
      g.race.status == "starting") then

    if g.run.roomsEntered == 1 then
      Isaac.ExecuteCommand("stage 1a") -- The Cellar is the cleanest floor
      g.run.goingToDebugRoom = true
      Isaac.ExecuteCommand("goto d.0") -- We do more things in the next "PostNewRoom" callback
    elseif g.run.roomsEntered == 2 then
      RacePostNewRoom:RaceStartRoom()
    end
    return
  end
end

function RacePostNewRoom:ThreeDollarBill()
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_3_DOLLAR_BILL_SEEDED) then
    return
  end

  -- Local variables
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"

  -- Remove the old item
  if g.run.threeDollarBillItem ~= 0 then
    g.p:RemoveCollectible(g.run.threeDollarBillItem)

    -- Also remove it from the item tracker
    Isaac.DebugString("Removing collectible " .. tostring(g.run.threeDollarBillItem))
  end

  -- Get the new item
  math.randomseed(roomSeed)
  local effectIndex = math.random(1, #RacePostNewRoom.ThreeDollarBillEffects)
  local item = RacePostNewRoom.ThreeDollarBillEffects[effectIndex]
  if not g.p:HasCollectible(item) then
    g.run.threeDollarBillItem = item
    g.p:AddCollectible(item, 0, false, false)
    return
  end

  -- We already have this item,
  -- keep iterating over the effect table until we find an item that we do not have yet
  local originalIndex = effectIndex
  while true do
    effectIndex = effectIndex + 1
    if effectIndex > #RacePostNewRoom.ThreeDollarBillEffects then
      effectIndex = 0
    end

    if effectIndex == originalIndex then
      -- We have every single item in the list, so do nothing
      g.run.threeDollarBillItem = 0
      return
    end

    local newItem = RacePostNewRoom.ThreeDollarBillEffects[effectIndex]
    if not g.p:HasCollectible(newItem) then
      g.run.threeDollarBillItem = newItem
      g.p:AddCollectible(newItem, 0, false, false)
      return
    end
  end
end

function RacePostNewRoom:CheckEverythingFloorSkip()
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local roomType = g.r:GetType()
  local gridSize = g.r:GetGridSize()

  -- Prevent players from skipping a floor on the "Everything" race goal
  if g.race.goal == "Everything" and
     (roomType == RoomType.ROOM_ERROR or -- 3
      roomType == RoomType.ROOM_BLACK_MARKET) then -- 22

    local convertTrapdoorsToBeamsOfLight = false
    local convertBeamsOfLightToTrapdoors = false
    if stage == 8 then
      convertTrapdoorsToBeamsOfLight = true

    elseif stage == 10 and
           stageType == 1 then -- Cathedral

      convertBeamsOfLightToTrapdoors = true

    elseif stage == 10 and
           stageType == 0 then -- Sheol

      convertTrapdoorsToBeamsOfLight = true
    end
    -- (it is impossible to get a I AM ERROR room or a Black Market on The Chest or the Dark Room)

    if convertTrapdoorsToBeamsOfLight then
      -- Replace all trapdoors with beams of light
      for i = 1, gridSize do
        local gridEntity = g.r:GetGridEntity(i)
        if gridEntity ~= nil then
          local saveState = gridEntity:GetSaveState()
          if saveState.Type == GridEntityType.GRID_TRAPDOOR then -- 17
            -- Remove the crawlspace and spawn a Heaven Door (1000.39), which will get replaced on the next frame
            -- in the "FastTravel:ReplaceHeavenDoor()" function
            -- Make the spawner entity the player so that we can distinguish it from the vanilla heaven door
            g.r:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, 0, -- 1000.39
                        gridEntity.Position, g.zeroVector, g.p)
            Isaac.DebugString("Replaced a trapdoor with a heaven door for an Everything race.")
          end
        end
      end
    end

    if convertBeamsOfLightToTrapdoors then
      -- Replace all beams of light with trapdoors
      local heavenDoors = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, -- 1000.39
                                           -1, false, false)
      for _, heavenDoor in ipairs(heavenDoors) do
        heavenDoor:Remove()

        -- Spawn a trapdoor (it will get replaced with the fast-travel version on this frame)
        Isaac.GridSpawn(GridEntityType.GRID_TRAPDOOR, 0, heavenDoor.Position, true) -- 17
        Isaac.DebugString("Replaced a heaven door with a trapdoor for an Everything race.")
      end
    end
  end
end

function RacePostNewRoom:RaceStartRoom()
  -- Remove all enemies
  for _, entity in ipairs(Isaac.GetRoomEntities()) do
    local npc = entity:ToNPC()
    if npc ~= nil then
      entity:Remove()
    end
  end
  g.r:SetClear(true)

  -- We want to trap the player in the room, so delete all 4 doors
  for i = 0, 3 do
    g.r:RemoveDoor(i)
  end

  -- Put the player next to the bottom door
  local pos = Vector(320, 400)
  g.p.Position = pos

  -- Put familiars next to the bottom door, if any
  local familiars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, -1, -1, false, false) -- 3
  for _, familiar in ipairs(familiars) do
    familiar.Position = pos
  end

  -- Spawn two Gaping Maws (235.0)
  Isaac.Spawn(EntityType.ENTITY_GAPING_MAW, 0, 0, g:GridToPos(5, 5), g.zeroVector, nil)
  Isaac.Spawn(EntityType.ENTITY_GAPING_MAW, 0, 0, g:GridToPos(7, 5), g.zeroVector, nil)

  -- Disable the MinimapAPI to emulate what happens with the vanilla map
  if MinimapAPI ~= nil then
    MinimapAPI.Config.Disable = true
  end
end

function RacePostNewRoom:CheckOpenMegaSatanDoor()
  -- Local variables
  local stage = g.l:GetStage()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end

  -- Check to see if we need to open the Mega Satan Door
  if (g.race.goal == "Mega Satan" or
      g.raceVars.finished or
      (g.race.goal == "Everything") and
       g.run.killedLamb) and
     stage == 11 and -- If this is The Chest or Dark Room
     roomIndex == g.l:GetStartingRoomIndex() then

    local door = g.r:GetDoor(1) -- The top door is always 1
    door:TryUnlock(true)
    g.sfx:Stop(SoundEffect.SOUND_UNLOCK00) -- 156
    -- door:IsOpen() is always equal to false here for some reason,
    -- so just open it every time we enter the room and silence the sound effect
    Isaac.DebugString("Opened the Mega Satan door.")
  end
end

function RacePostNewRoom:CheckVictoryLapBossReplace()
  -- Local variables
  local roomDesc = g.l:GetCurrentRoomDesc()
  local roomStageID = roomDesc.Data.StageID
  local roomVariant = roomDesc.Data.Variant
  local roomClear = g.r:IsClear()
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"

  -- Check to see if we need to spawn Victory Lap bosses
  if g.raceVars.finished and
     not roomClear and
     roomStageID == 0 and
     (roomVariant == 3390 or -- Blue Baby
      roomVariant == 3391 or
      roomVariant == 3392 or
      roomVariant == 3393 or
      roomVariant == 5130) then -- The Lamb

    -- Replace Blue Baby / The Lamb with some random bosses (based on the number of Victory Laps)
    local isaacs = Isaac.FindByType(EntityType.ENTITY_ISAAC, -1, -1, false, false) -- 102
    for _, entity in ipairs(isaacs) do
      entity:Remove()
    end
    local lambs = Isaac.FindByType(EntityType.ENTITY_ISAAC, -1, -1, false, false) -- 102
    for _, entity in ipairs(lambs) do
      entity:Remove()
    end

    local randomBossSeed = roomSeed
    local numBosses = g.raceVars.victoryLaps + 1
    for i = 1, numBosses do
      randomBossSeed = g:IncrementRNG(randomBossSeed)
      math.randomseed(randomBossSeed)
      local randomBoss = g.bossArray[math.random(1, #g.bossArray)]
      if randomBoss[1] == EntityType.ENTITY_LARRYJR then -- 19
        -- Larry Jr. and The Hollow require multiple segments
        for j = 1, 6 do
          Isaac.Spawn(randomBoss[1], randomBoss[2], randomBoss[3], g.r:GetCenterPos(), g.zeroVector, nil)
        end
      else
        Isaac.Spawn(randomBoss[1], randomBoss[2], randomBoss[3], g.r:GetCenterPos(), g.zeroVector, nil)
      end
    end
    Isaac.DebugString("Replaced Blue Baby / The Lamb with " .. tostring(numBosses) .. " random bosses.")
  end
end

return RacePostNewRoom

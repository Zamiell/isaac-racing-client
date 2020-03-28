local Season7 = {}

-- Includes
local g                   = require("racing_plus/globals")
local RacePostGameStarted = require("racing_plus/racepostgamestarted")
local Speedrun            = require("racing_plus/speedrun")
local Sprites             = require("racing_plus/sprites")

-- Constants
Season7.goals = {
  "Boss Rush",
  "It Lives!",
  "Hush",
  "Blue Baby",
  "The Lamb",
  "Mega Satan",
  "Ultra Greed",
}

-- Variables
Season7.remainingGoals = {} -- Reset at the beginning of a new run on the first character

-- We have to handle going into the Ultra Greed room with the Door Stop trinket
-- Called from the "SpeedrunPostUpdate:Main()" function
function Season7:CheckUltraGreedSpawned()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    return
  end

  if not g.run.spawnedUltraGreed then
    return
  end
  g.run.spawnedUltraGreed = false

  -- If a door is open (e.g. if a player has Door Stop),
  -- we want to delete the overlapping Ultra Greed Door
  for i = 0, 7 do
    local door = g.r:GetDoor(i)
    if door ~= nil and
       door:IsOpen() then

      -- Find the Ultra Greed Door that overlaps with this open door
      local ultraGreedDoors = Isaac.FindByType(EntityType.ENTITY_ULTRA_DOOR, -1, -1, false, false) -- 294
      for j, ultraGreedDoor in ipairs(ultraGreedDoors) do
        if ultraGreedDoor.Position:Distance(door.Position) < 25 then
          ultraGreedDoor:Remove()
        end
      end
    end
  end
end

-- We need to remove the appropriate goal when the checkpoint is touched
-- Called from the "SpeedrunPostUpdate:CheckCheckpointTouched()" function
function Season7:CheckpointTouched()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    return
  end

  -- Show the remaining goals
  g.run.showGoalsFrame = gameFrameCount + 60

  --
  -- Remove the goal that we just completed
  --

  local roomType = g.r:GetType()
  if roomType == RoomType.ROOM_BOSSRUSH then -- 17
    g:TableRemove(Season7.remainingGoals, "Boss Rush")
    return
  end

  local roomIndexUnsafe = g.l:GetCurrentRoomIndex()
  if roomIndexUnsafe == GridRooms.ROOM_MEGA_SATAN_IDX then -- -7
    g:TableRemove(Season7.remainingGoals, "Mega Satan")
    return
  end

  local stage = g.l:GetStage()
  if stage == 8 then
    g:TableRemove(Season7.remainingGoals, "It Lives!")
    return
  end

  if stage == 9 then
    g:TableRemove(Season7.remainingGoals, "Hush")
    return
  end

  local stageType = g.l:GetStageType()
  if stage == 11 and stageType == 1 then
    g:TableRemove(Season7.remainingGoals, "Blue Baby")
    return
  end

  if stage == 11 and stageType == 0 then
    g:TableRemove(Season7.remainingGoals, "The Lamb")
    return
  end

  if stage == 12 then
    g:TableRemove(Season7.remainingGoals, "Ultra Greed")
    return
  end
end

-- Called from the "PostUpdate:CheckRoomCleared()" function
function Season7:RoomCleared()
  -- Local variables
  local stage = g.l:GetStage()
  local roomIndexUnsafe = g.l:GetCurrentRoomIndex()
  local centerPos = g.r:GetCenterPos()
  local challenge = Isaac.GetChallenge()

  -- Check to see if we just defeated Ultra Greed on a Season 7 speedrun
  if challenge == Isaac.GetChallengeIdByName("R+7 (Season 7)") and
     stage == 12 and
     roomIndexUnsafe == g.run.customBossRoomIndex then

    -- Spawn a big chest (which will get replaced with either a checkpoint or a trophy on the next frame)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BIGCHEST, 0, -- 5.340
                centerPos, g.zeroVector, nil)
  end
end

-- ModCallbacks.MC_POST_RENDER (2)
function Season7:PostRender()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7)") or
     Speedrun.finished then

    return
  end

  -- Make the text persist for at least 2 seconds after the player presses tab
  local tabPressed = false
  for i = 0, 3 do -- There are 4 possible inputs/players from 0 to 3
    if Input.IsActionPressed(ButtonAction.ACTION_MAP, i) then -- 13
      tabPressed = true
      break
    end
  end
  if not tabPressed then
    return
  end

  -- Draw the remaining goals on the screen for easy-reference
  local x = 95
  local baseY = 66
  g.font:DrawString("Remaining Goals:", x, baseY, g.kcolor, 0, true)

  for i, goal in ipairs(Season7.remainingGoals) do
    local y = baseY + (20 * i)
    local string = "- " .. tostring(goal)
    g.font:DrawString(string, x, y, g.kcolor, 0, true)
  end
end

-- ModCallbacks.MC_ENTITY_TAKE_DMG (11)
-- EntityType.ENTITY_ULTRA_GREED (406)
-- EntityType.ENTITY_HUSH (407)
function Season7:EntityTakeDmgRemoveArmor(tookDamage, damageAmount, damageFlag, damageSource, damageCountdownFrames)
  if g.run.dealingExtraDamage then
    return
  end

  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    return
  end

  -- Adjust their HP directly to avoid the damage scaling (armor)
  tookDamage.HitPoints = tookDamage.HitPoints - (damageAmount * 0.5)

  -- Make the NPC flash
  g.run.dealingExtraDamage = true
  tookDamage:TakeDamage(0, 0, damageSource, damageCountdownFrames)
  g.run.dealingExtraDamage = false
end

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season7:PostGameStartedFirstCharacter()
  Season7.remainingGoals = g:TableClone(Season7.goals)
end

-- ModCallbacks.MC_POST_GAME_STARTED (15)
function Season7:PostGameStarted()
  -- Local variables
  local character = g.p:GetPlayerType()

  Isaac.DebugString("In the R+7 (Season 7) challenge.")

  -- Lilith starts with an extra Incubus
  if character == PlayerType.PLAYER_LILITH then -- 13
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_INCUBUS, 0, false) -- 360
    g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_INCUBUS) -- 360

    -- Don't show it on the item tracker
    Isaac.DebugString("Removing collectible 360 (Incubus)")

    -- If we switch characters, we want to remove the extra Incubus
    g.run.extraIncubus = true
  end

  -- Give the 5 random diversity items
  RacePostGameStarted:Diversity()

  -- Remove some powerful items from all pools
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_WE_NEED_GO_DEEPER) -- 84
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_IPECAC) -- 149
  g.itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_MEGA_SATANS_BREATH) -- 441
end

-- ModCallbacks.MC_POST_NEW_LEVEL (18)
function Season7:PostNewLevel()
  -- Local variables
  local stage = g.l:GetStage()
  local rooms = g.l:GetRooms()
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    return
  end

  if stage ~= 12 then
    return
  end

  -- Set the custom boss room to be the first 1x1 boss room
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local roomDesc = rooms:Get(i)
    local roomIndex = roomDesc.SafeGridIndex -- This is always the top-left index
    local roomData = roomDesc.Data
    local roomType = roomData.Type
    local roomShape = roomData.Shape

    if roomType == RoomType.ROOM_BOSS and -- 5
       roomShape == RoomShape.ROOMSHAPE_1x1 then -- 1

      g.run.customBossRoomIndex = roomIndex
      Isaac.DebugString("Set the custom boss room to: " .. tostring(g.run.customBossRoomIndex))
      break
    end
  end
end

-- ModCallbacks.MC_POST_NEW_ROOM (19)
function Season7:PostNewRoom()
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    return
  end

  -- Remove the diversity sprites as soon as we leave the starting room
  if g.run.roomsEntered == 2 then
    Sprites:ClearPostRaceStartGraphics()
  end

  Season7:PostNewRoomStage9()
  Season7:PostNewRoomStage11()
  Season7:PostNewRoomStage12()
end

function Season7:PostNewRoomStage9()
  -- Local variables
  local stage = g.l:GetStage()
  local roomType = g.r:GetType()

  if stage ~= 9 or
     roomType ~= RoomType.ROOM_BOSS then -- 5

    return
  end

  -- Remove The Void door if it is open
  -- (closing it does not work because it will automatically reopen)
  g.r:RemoveGridEntity(20, 0, false) -- gridEntity:Destroy() does not work
  Isaac.DebugString("Manually deleted The Void door.")
end

function Season7:PostNewRoomStage11()
  -- Local variables
  local stage = g.l:GetStage()
  local roomIndexUnsafe = g.l:GetCurrentRoomIndex()
  local startingRoomIndex = g.l:GetStartingRoomIndex()

  if stage ~= 11 or
     roomIndexUnsafe ~= startingRoomIndex then

    return
  end

  -- Spawn a Void Portal if we still need to go to The Void
  if g:TableContains(Season7.remainingGoals, "Ultra Greed") then
    local trapdoor = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.VOID_PORTAL_FAST_TRAVEL, 0, -- 1000
                                 g:GridToPos(1, 1), g.zeroVector, nil)
    trapdoor.DepthOffset = -100 -- This is needed so that the entity will not appear on top of the player
  end

  -- Spawn the Mega Satan trapdoor if we still need to go to Mega Satan
  -- and we are on the second character or beyond
  -- (the normal Mega Satan door does not appear on custom challenges that have a goal set to Blue Baby)
  if g:TableContains(Season7.remainingGoals, "Mega Satan") and
     Speedrun.charNum >= 2 then

    local trapdoor = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.MEGA_SATAN_TRAPDOOR, 0, -- 1000
                                 g:GridToPos(11, 1), g.zeroVector, nil)
    trapdoor.DepthOffset = -100 -- This is needed so that the entity will not appear on top of the player
  end
end

function Season7:PostNewRoomStage12()
  -- Local variables
  local stage = g.l:GetStage()
  local roomIndexUnsafe = g.l:GetCurrentRoomIndex()
  local rooms = g.l:GetRooms()
  local centerPos = g.r:GetCenterPos()
  local roomClear = g.r:IsClear()

  if stage ~= 12 then
    return
  end

  -- Delete the door to a non-Ultra Greed boss room, if any
  -- (we must delete the door before changing the minimap, or else the icon will remain)
  for i = 0, 7 do
    local door = g.r:GetDoor(i)
    if door ~= nil and
       door.TargetRoomType == RoomType.ROOM_BOSS and -- 5
       door.TargetRoomIndex ~= g.run.customBossRoomIndex then

      g.r:RemoveDoor(i)
    end
  end

  -- Show the boss icon for the custom boss room and remove all of the other ones
  for i = 0, rooms.Size - 1 do -- This is 0 indexed
    local roomDesc = rooms:Get(i)
    local roomIndex = roomDesc.SafeGridIndex -- This is always the top-left index
    local roomData = roomDesc.Data
    local roomType = roomData.Type

    if roomType == RoomType.ROOM_BOSS then -- 5
      local room
      if MinimapAPI == nil then
        -- For whatever reason, we can't modify the DisplayFlags on the roomDesc that we already have,
        -- so we have to re-get the room using the following function
        room = g.l:GetRoomByIdx(roomIndex)
      else
        room = MinimapAPI:GetRoomByIdx(roomIndex)
      end
      if roomIndex == g.run.customBossRoomIndex then
        -- Make the Ultra Greed room visible and show the icon
        room.DisplayFlags = 5
      else
        -- Remove the boss room icon (in case we have the Compass or The Mind)
        if MinimapAPI == nil then
          room.DisplayFlags = 0
        elseif room ~= nil then
          room:Remove()
        end
      end
    end
  end
  g.l:UpdateVisibility() -- Setting the display flag will not actually update the map

  -- Spawn the custom boss
  if roomIndexUnsafe == g.run.customBossRoomIndex and
     not roomClear then

    -- Remove all enemies
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
      local npc = entity:ToNPC()
      if npc ~= nil then
        entity:Remove()
      end
    end

    -- Spawn Ultra Greed
    Isaac.Spawn(EntityType.ENTITY_ULTRA_GREED, 0, 0, centerPos, g.zeroVector, nil) -- 406

    -- Mark to potentially delete one of the Ultra Greed Doors on the next frame
    -- (the Ultra Greed Doors take a frame to spawn after Ultra Greed spawns)
    g.run.spawnedUltraGreed = true
  end
end

-- ModCallbacks.MC_POST_NPC_INIT (27)
-- EntityType.ENTITY_ISAAC (102)
function Season7:PostNPCInitIsaac(npc)
  -- Local variables
  local challenge = Isaac.GetChallenge()

  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 7)") then
    return
  end

  -- In season 7 speedruns, we want to go directly into the second phase of Hush
  if npc.Variant == 2 then
    npc:Remove()
    g.g:Spawn(EntityType.ENTITY_HUSH, 0, Vector(580, 260), g.zeroVector, nil, 0, npc.InitSeed) -- 407
    -- (the position is copied from vanilla)
  end
end

return Season7

local FastTravel = {}

-- Includes
local g            = require("racing_plus/globals")
local Sprites      = require("racing_plus/sprites")
local SeededFloors = require("racing_plus/seededfloors")

-- Constants
FastTravel.trapdoorOpenDistance  = 60 -- This feels about right
FastTravel.trapdoorTouchDistance = 16.5 -- This feels about right (it is slightly smaller than vanilla)

-- Enums
FastTravel.state = {
  DISABLED = 0,
  PLAYER_ANIMATION = 1,
  FADING_TO_BLACK = 2,
  SCREEN_IS_BLACK = 3,
  POST_NEW_ROOM_1 = 4,
  POST_NEW_ROOM_2 = 5,
  CONTROLS_ENABLED = 6,
  PLAYER_JUMP = 7,
}

-- Variables
FastTravel.reseed               = false -- Used when we need to reseed the next floor
FastTravel.delayNewRoomCallback = false -- Used when executing a "reseed" immediately after a "stage X"

--
-- Trapdoor / heaven door functions
--

-- "Replace" functions for trapdoor / heaven door
-- (called from the "CheckEntities:Grid()" and "CheckEntities:NonGrid()" functions)
function FastTravel:ReplaceTrapdoor(entity, i)
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()
  local stage = g.l:GetStage()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end

  -- There is no way to manually travel to the "Infiniate Basements" Easter Egg floors,
  -- so just disable the fast-travel feature
  if g.seeds:HasSeedEffect(SeedEffect.SEED_INFINITE_BASEMENT) then -- 16
    return
  end

  -- Don't replace anything in The Void portal room
  if roomIndex == GridRooms.ROOM_THE_VOID_IDX then -- -9
    return
  end

  -- Delete the "natural" trapdoor that spawns one frame after It Lives! (or Hush) is killed
  -- (it spawns after one frame because of fast-clear; on vanilla it spawns after a long delay)
  if gameFrameCount == g.run.itLivesKillFrame + 1 then
    entity.Sprite = Sprite() -- If we don't do this, it will still show for a frame
    g.r:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
    Isaac.DebugString("Deleted the natural trapdoor after It Lives! (or Hush).")
    return
  end

  -- Spawn a custom entity to emulate the original
  local trapdoor
  if roomIndex == GridRooms.ROOM_BLUE_WOOM_IDX then -- -8
    trapdoor = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLUE_WOMB_TRAPDOOR_FAST_TRAVEL, 0, -- 1000
                           entity.Position, g.zeroVector, nil)

  elseif stage == 6 or
         stage == 7 then

    trapdoor = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.WOMB_TRAPDOOR_FAST_TRAVEL, 0, -- 1000
                           entity.Position, g.zeroVector, nil)

  else
    trapdoor = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TRAPDOOR_FAST_TRAVEL, 0, -- 1000
                           entity.Position, g.zeroVector, nil)
  end
  trapdoor.DepthOffset = -100 -- This is needed so that the entity will not appear on top of the player

  -- The custom entity will not respawn if we leave the room,
  -- so we need to keep track of it for the remainder of the floor
  g.run.replacedTrapdoors[#g.run.replacedTrapdoors + 1] = {
    room = roomIndex,
    pos  = entity.Position,
  }

  -- Always spawn the trapdoor closed, unless it is after Satan in Sheol
  -- (or after a boss in the "Everything" race goal)
  if stage ~= 10 and stage ~= 11 then
    trapdoor:ToEffect().State = 1
    trapdoor:GetSprite():Play("Closed", true)
  end

  -- Log it
  --[[
  local debugString = "Replaced a trapdoor in room " .. tostring(roomIndex) .. " at "
  debugString = debugString .. "(" .. tostring(entity.Position.X) .. ", " .. tostring(entity.Position.Y) .. ") "
  debugString = debugString .. "on frame " .. tostring(gameFrameCount)
  Isaac.DebugString(debugString)
  --]]

  -- Remove the original entity
  if i == -1 then
    -- We are replacing a Big Chest
    entity:Remove()
  else
    -- We are replacing a trapdoor grid entity
    entity.Sprite = Sprite() -- If we don't do this, it will still show for a frame
    g.r:RemoveGridEntity(i, 0, false) -- entity:Destroy() does not work
  end
end

function FastTravel:ReplaceHeavenDoor(entity)
  -- Local variables
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"

  -- Delete the "natural" beam of light
  if entity.SpawnerType ~= EntityType.ENTITY_PLAYER then -- 1
    entity:Remove()

    if roomIndex ~= GridRooms.ROOM_ERROR_IDX then -- -2
      -- This is the beam of light that spawns one frame after It Lives! (or Hush) is killed
      -- (it spawns after one frame because of fast-clear; on vanilla it spawns after a long delay)
      Isaac.DebugString("Deleted the natural beam of light after It Lives! (or Hush).")
      return
    end
  end

  -- Spawn a custom entity to emulate the original
  -- (we use an InitSeed of the room seed instead of a random seed to indicate that this is a freshly spawned entity)
  local heaven = g.g:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_DOOR_FAST_TRAVEL, -- 1000
                           entity.Position, g.zeroVector, nil, 0, roomSeed)
  heaven.DepthOffset = 15 -- The default offset of 0 is too low, and 15 is just about perfect

  -- The custom entity will not respawn if we leave the room,
  -- so we need to keep track of it for the remainder of the floor
  g.run.replacedHeavenDoors[#g.run.replacedHeavenDoors + 1] = {
    room = roomIndex,
    pos  = entity.Position,
  }

  --[[
  -- Log it
  local debugString = "Replaced a beam of light in room " .. tostring(roomIndex) .. " "
  debugString = debugString .. " at (" .. tostring(entity.Position.X) .. "," .. tostring(entity.Position.Y) .. ") "
  debugString = debugString .. "on frame " .. tostring(gameFrameCount)
  Isaac.DebugString(debugString)
  --]]

  -- Remove the original entity
  entity:Remove()
end

function FastTravel:CheckPickupOverHole(pickup)
  -- Local variables
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end

  -- We don't need to move Big Chests, Trophies, or Beds
  if pickup.Variant == PickupVariant.PICKUP_BIGCHEST or -- 340
     pickup.Variant == PickupVariant.PICKUP_TROPHY or -- 370
     pickup.Variant == PickupVariant.PICKUP_BED then -- 380

    return
  end

  --[[
  Isaac.DebugString("Checking pickup: " ..
                    tostring(pickup.Type) .. "." .. tostring(pickup.Variant) .. "." .. tostring(pickup.SubType))
  Isaac.DebugString("Position: " .. tostring(pickup.Position.X) .. ", " .. tostring(pickup.Position.Y))
  --]]

  -- Check to see if it is overlapping with a trapdoor / beam of light / crawlspace
  local squareSize = FastTravel.trapdoorTouchDistance + 2
  for _, trapdoor in ipairs(g.run.replacedTrapdoors) do
    if roomIndex == trapdoor.room and
       pickup.Position:Distance(trapdoor.pos) <= squareSize then

      FastTravel:MovePickupFromHole(pickup, trapdoor.pos)
      return
    end
  end
  for _, heavenDoor in ipairs(g.run.replacedHeavenDoors) do
    if roomIndex == heavenDoor.room and
       pickup.Position:Distance(heavenDoor.pos) <= squareSize then

      FastTravel:MovePickupFromHole(pickup, heavenDoor.pos)
      return
    end
  end
  for _, crawlspace in ipairs(g.run.replacedCrawlspaces) do
    if roomIndex == crawlspace.room and
       pickup.Position:Distance(crawlspace.pos) <= squareSize then

      FastTravel:MovePickupFromHole(pickup, crawlspace.pos)
      return
    end
  end
end

function FastTravel:MovePickupFromHole(pickup, posHole)
  -- Local variables
  local squareSize = FastTravel.trapdoorTouchDistance + 2

  -- First, if this is a collectibles that is overlapping with the trapdoor, then move it manually
  -- (this is rare but possible with a Small Rock)
  if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then -- 100
    pickup.Position = g.r:FindFreePickupSpawnPosition(pickup.Position, 1, true)
    return
  end

  -- Make pickups with velocity "bounce" off of the hole
  if (pickup.Velocity.X ~= 0 or pickup.Velocity.Y ~= 0) and
     (pickup.Position.X ~= posHole.X and pickup.Position.Y ~= posHole.Y) then

    -- Invert the velocity
    local reverseVelocity = Vector(pickup.Velocity.X, pickup.Velocity.Y)
    if math.abs(reverseVelocity.X) == math.abs(reverseVelocity.Y) then
      reverseVelocity.X = reverseVelocity.X * -1
      reverseVelocity.Y = reverseVelocity.Y * -1
    elseif math.abs(reverseVelocity.X) > math.abs(reverseVelocity.Y) then
      reverseVelocity.X = reverseVelocity.X * -1
    elseif math.abs(reverseVelocity.X) < math.abs(reverseVelocity.Y) then
      reverseVelocity.Y = reverseVelocity.Y * -1
    end
    pickup.Velocity = reverseVelocity

    -- Use the inverted velocity to slightly move it outside of the trapdoor hitbox
    local newPos = Vector(pickup.Position.X, pickup.Position.Y)
    local pushedOut = false
    for i = 1, 100 do
      -- The velocity of a pickup decreases over time, so we might hit the threshold where
      -- it decreases by just the right amount to not move outside of the hole in 1 iteration,
      -- in which case it will need 2 iterations; but just do 100 iterations to be safe
      newPos.X = newPos.X + reverseVelocity.X
      newPos.Y = newPos.Y + reverseVelocity.Y
      if newPos:Distance(posHole) > squareSize then
        pushedOut = true
        break
      end
    end
    if not pushedOut then
      Isaac.DebugString("Error: Was not able to move the pickup out of the hole after 100 iterations.")
    end
    pickup.Position = newPos

    return
  end

  -- Generate new spawn positions until we find one that doesn't overlap with the hole
  local newPos
  local overlapping = false
  for i = 0, 100 do
    newPos = g.r:FindFreePickupSpawnPosition(pickup.Position, i, true)
    if newPos:Distance(posHole) <= squareSize then
      overlapping = true
    end
    if not overlapping then
      break
    end
  end
  if overlapping then
    -- We were not able to find a free location after 100 attempts, so give up and just delete the pickup
    pickup:Remove()
    Isaac.DebugString("Error: Failed to find a free location after 100 attempts for pickup: " ..
                      tostring(pickup.Type) .. "." .. tostring(pickup.Variant) .. "." .. tostring(pickup.SubType))
  else
    -- Move it
    pickup.Position = newPos
    Isaac.DebugString("Moved a pickup that was overlapping with a hole: " ..
                      tostring(pickup.Type) .. "." .. tostring(pickup.Variant) .. "." .. tostring(pickup.SubType))
  end
end

function FastTravel:CheckTrapdoorEnter(effect, upwards, theVoid)
  -- Local variables
  local stage = g.l:GetStage()
  local isaacFrameCount = Isaac.GetFrameCount()

  -- Check to see if a player is touching the trapdoor
  for i = 1, g.g:GetNumPlayers() do
    local player = Isaac.GetPlayer(i - 1)
    if g.run.trapdoor.state == FastTravel.state.DISABLED and
       ((not upwards and effect.State == 0) or -- The trapdoor is open
        (upwards and stage == 8 and effect.FrameCount >= 40 and effect.InitSeed ~= 0) or
        -- We want the player to be forced to dodge the final wave of tears from It Lives!, so we have to delay
        -- (we initially spawn it with an InitSeed equal to the room seed)
        (upwards and stage == 8 and effect.FrameCount >= 8 and effect.InitSeed == 0) or
        -- The extra delay should not apply if they are re-entering the room
        -- (we respawn beams of light with an InitSeed of 0)
        (upwards and stage ~= 8 and effect.FrameCount >= 8)) and
        -- The beam of light opening animation is 16 frames long,
        -- but we want the player to be taken upwards automatically if they hold "up" or "down" with max (2.0) speed
        -- (and the minimum for this is 8 frames, determined from trial and error)
       player.Position:Distance(effect.Position) <= FastTravel.trapdoorTouchDistance and
       not player:IsHoldingItem() and
       not player:GetSprite():IsPlaying("Happy") and -- Account for lucky pennies
       not player:GetSprite():IsPlaying("Jump") then -- Account for How to Jump

      -- State 1 is activated the moment we touch the trapdoor
      g.run.trapdoor.state = FastTravel.state.PLAYER_ANIMATION
      g.run.trapdoor.upwards = upwards
      g.run.trapdoor.frame = isaacFrameCount + 40 -- Custom animations are 40 frames; see below
      g.run.trapdoor.voidPortal = effect.Variant == EffectVariant.VOID_PORTAL_FAST_TRAVEL
      g.run.trapdoor.megaSatan = effect.Variant == EffectVariant.MEGA_SATAN_TRAPDOOR

      -- If we are The Soul, the Forgotten body will also need to be teleported
      -- However, if we change its position manually, it will just warp back to the same spot on the next frame
      -- Thus, just manually switch to the Forgotten to avoid this bug
      local character = g.p:GetPlayerType()
      if character == PlayerType.PLAYER_THESOUL then -- 17
        g.run.switchForgotten = true

        -- Also warp the body to where The Soul is so that The Forgotton won't jump down through a normal floor
        local forgottenBodies = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, 900, -1, false, false) -- 3
        for _, forgottenBody in ipairs(forgottenBodies) do
          forgottenBody.Position = g.p.Position
        end
      end

      player.ControlsEnabled = false
      player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE -- 0
      -- (this is necessary so that enemy attacks don't move the player while they are doing the jumping animation)
      player.Position = effect.Position -- Teleport the player on top of the trapdoor
      player.Velocity = g.zeroVector -- Remove all of the player's momentum

      if upwards then
        -- The vanilla "LightTravel" animation is 28 frames long,
        -- but we need to delay for longer than that to make it look smooth,
        -- so we modified it to be 40 frames in the ANM2 file
        player:PlayExtraAnimation("LightTravel") -- This is modified to be longer than on vanilla;
      else
        -- The vanilla "Trapdoor" animation is 16 frames long,
        -- but we need to delay for longer than that to make it look smooth,
        -- So we made a custom "TrapDoor2" animation that is 40 frames long)
        player:PlayExtraAnimation("Trapdoor2")
      end
    end
  end
end

-- Called from the PostRender callback
function FastTravel:CheckTrapdoor()
  -- Local varaibles
  local stage = g.l:GetStage()
  local isaacFrameCount = Isaac.GetFrameCount()

  if g.run.trapdoor.state == FastTravel.state.PLAYER_ANIMATION and
     isaacFrameCount >= g.run.trapdoor.frame then

    -- State 2 is activated when the "Trapdoor" animation is completed
    g.p.Visible = false

    -- Make the screen fade to black (we can go to any room for this, so we just use the starting room)
    g.g:StartRoomTransition(g.l:GetStartingRoomIndex(), Direction.NO_DIRECTION, -- -1
                            g.RoomTransition.TRANSITION_NONE) -- 0

    -- Mark to change floors after the screen is black
    g.run.trapdoor.state = FastTravel.state.FADING_TO_BLACK
    g.run.trapdoor.frame = isaacFrameCount + 8
    -- 9 is too many (you can start to see the same room again)

  elseif g.run.trapdoor.state == FastTravel.state.FADING_TO_BLACK and
         isaacFrameCount >= g.run.trapdoor.frame then

    -- Stage 3 is actiated when the screen is black
    g.run.trapdoor.state = FastTravel.state.SCREEN_IS_BLACK
    g.run.trapdoor.floor = stage
    Sprites:Init("black", "black")
    FastTravel:GotoNextFloor(g.run.trapdoor.upwards) -- The argument is "upwards"

  elseif g.run.trapdoor.state == FastTravel.state.POST_NEW_ROOM_2 and
         g.p.ControlsEnabled then

     -- State 6 is activated when the player controls are enabled
     -- (this happens automatically by the game)
     -- (stages 4 and 5 are in the PostNewRoom callback)
     g.run.trapdoor.state = FastTravel.state.CONTROLS_ENABLED
     g.run.trapdoor.frame = isaacFrameCount + 10 -- Wait a while longer
     g.p.ControlsEnabled = false

  elseif g.run.trapdoor.state == FastTravel.state.CONTROLS_ENABLED and
         isaacFrameCount >= g.run.trapdoor.frame then

     -- State 7 is activated when the the hole is spawned and ready
     g.run.trapdoor.state = FastTravel.state.PLAYER_JUMP
     g.run.trapdoor.frame = isaacFrameCount + 25
     -- The "JumpOut" animation is 15 frames long, so give a bit of leeway

     for i = 1, g.g:GetNumPlayers() do
       local player2 = Isaac.GetPlayer(i - 1)

       -- Make the player(s) visable again
       player2.SpriteScale = g.run.trapdoor.scale[i]

       -- Give the player(s) the collision that we removed earlier
       player2.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL -- 4

       -- Play the jumping out of the hole animation
       player2:PlayExtraAnimation("Jump")
     end

     -- Make the hole do the dissapear animation
     local pitfalls = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.PITFALL_CUSTOM, -- 1000
                                       -1, false, false)
     for _, pitfall in ipairs(pitfalls) do
       pitfall:GetSprite():Play("Disappear", true)
     end

  elseif g.run.trapdoor.state == FastTravel.state.PLAYER_JUMP and
         isaacFrameCount >= g.run.trapdoor.frame then

    -- We are finished when the the player has emerged from the hole
    g.run.trapdoor.state = FastTravel.state.DISABLED

    -- Enable the controls for all players
    for i = 1, g.g:GetNumPlayers() do
      local player2 = Isaac.GetPlayer(i - 1)
      player2.ControlsEnabled = true
    end

    -- Kill the hole
    local pitfalls = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.PITFALL_CUSTOM, -- 1000
                                      -1, false, false) -- 3
    for _, pitfall in ipairs(pitfalls) do
      pitfall:Remove()
    end
  end

  -- Fix the bug where Dr. Fetus bombs can be shot while jumping
  if g.run.trapdoor.state > FastTravel.state.DISABLED then
    g.p.FireDelay = 1
  end
end

-- Called from the PostNewRoom callback
function FastTravel:CheckTrapdoor2()
  -- Local variables
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()
  local character = g.p:GetPlayerType()

  -- We are not travelling to a new level if we went through a Mega Satan trapdoor,
  -- so bypass the below PostNewRoom check
  if g.run.trapdoor.state == FastTravel.state.SCREEN_IS_BLACK and
     g.run.trapdoor.megaSatan then

    g.run.trapdoor.state = FastTravel.state.POST_NEW_ROOM_1
  end

  -- We will hit the PostNewRoom callback twice when doing a fast-travel, so do nothing on the first time
  -- (this is just an artifact of the manual reordering)
  if g.run.trapdoor.state == FastTravel.state.SCREEN_IS_BLACK then
    g.run.trapdoor.state = FastTravel.state.POST_NEW_ROOM_1

  elseif g.run.trapdoor.state == FastTravel.state.POST_NEW_ROOM_1 then
    g.run.trapdoor.state = FastTravel.state.POST_NEW_ROOM_2

    -- Remove the black sprite to reveal the new floor
    Sprites:Init("black", 0)

    local pos = g.r:GetCenterPos()
    if g.run.trapdoor.megaSatan then
      -- The center of the Mega Satan room is near the top
      -- Causing Isaac to warp to the top causes the game to bug out,
      -- so adjust the position to be near the bottom entrance
      pos = Vector(320, 650)

      -- Additionally, stop the boss room sound effect
      g.sfx:Stop(SoundEffect.SOUND_CASTLEPORTCULLIS) -- 190

    elseif stage == 9 then -- Blue Womb
      pos = Vector(320, 560)
    end

    for i = 1, g.g:GetNumPlayers() do
      local player = Isaac.GetPlayer(i - 1)

      -- Make the player(s) invisible so that we can jump out of the hole
      -- (this has to be in the PostNewRoom callback so that we don't get bugs with the Glowing Hour Glass)
      -- (we can't use "player.Visible = false" because it won't do anything here)
      g.run.trapdoor.scale[i] = player.SpriteScale
      player.SpriteScale = g.zeroVector

      -- Move the player to the center of the room
      player.Position = pos
    end

    -- Spawn a hole
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PITFALL_CUSTOM, 0, -- 1000
                pos, g.zeroVector, nil)

    -- Show what the new floor is (the game won't show this naturally since we used the console command to get here)
    if not g.raceVars.finished and
       -- (the "Victory Lap" text will overlap with the stage text, so don't bother showing it if the race is finished)
       character ~= Isaac.GetPlayerTypeByName("Random Baby") then
       -- (the baby descriptions will slightly overlap with the stage text,
       -- so don't bother showing it if we are playing as "Random Baby")

       g.run.streakText = g.l:GetName(stage, stageType, 0, false)
       if g.run.streakText == "???" then
        g.run.streakText = "Blue Womb"
       end
       g.run.streakFrame = Isaac.GetFrameCount()
    end

    -- Open the Hush door to speed things up
    if stage == 9 then -- Blue Womb
      local hushDoor = g.r:GetDoor(1)
      if hushDoor ~= nil then
        hushDoor:TryUnlock(true)
      end
      g.sfx:Stop(SoundEffect.SOUND_BOSS_LITE_ROAR) -- 14
    end
  end
end

-- Remove the long fade out / fade in when entering trapdoors
-- (and redirect Sacrifice Room teleports)
function FastTravel:GotoNextFloor(upwards, redirect)
  -- Local game
  local stage = g.l:GetStage()
  local stageType = g.l:GetStageType()

  -- Handle custom Mega Satan trapdoors
  if g.run.trapdoor.megaSatan then
    g.g:StartRoomTransition(GridRooms.ROOM_MEGA_SATAN_IDX, Direction.UP, g.RoomTransition.TRANSITION_NONE) -- -7, 1, 0
    return
  end

  -- By default, we will not need to reseed the new floor
  FastTravel.reseed = false

  -- Get the number and type of the next floor
  local nextStage
  if redirect == nil then
    nextStage = FastTravel:GetNextStage()
  else
    -- We are redirecting a Sacrifice Room teleport, so we are going backwards
    nextStage = redirect
  end
  local nextStageType = FastTravel:GetNextStageType(nextStage, upwards)

  -- Check for completely custom floor paths
  if g.race.goal == "Everything" then
    if stage == 10 and stageType == 1 then -- 10.1 (Cathedral)
      -- Cathedral goes to Sheol
      nextStage = 10
      nextStageType = 0

      -- We need to reseed it because by default, Sheol will have the same layout as Cathedral
      FastTravel.reseed = true

    elseif stage == 10 and stageType == 0 then -- 10.0 (Sheol)
      -- Sheol goes to The Chest
      nextStage = 11
      nextStageType = 1

    elseif stage == 11 and stageType == 1 then -- 11.0 (The Chest)
      -- The Chest goes to the Dark Room
      nextStage = 11
      nextStageType = 0

      -- We need to reseed it because by default, Sheol will have the same layout as Cathedral
      FastTravel.reseed = true
    end
  end

  -- Check to see we need to take extra steps to seed the floor consistently by
  --- performing health and inventory modifications
  SeededFloors:Before(nextStage)

  -- Use the console to manually travel to the floor
  FastTravel:TravelStage(nextStage, nextStageType)

  -- Revert the health and inventory modifications
  SeededFloors:After()
end

function FastTravel:GetNextStage()
  -- Local game
  local stage = g.l:GetStage()
  local roomIndexUnsafe = g.l:GetCurrentRoomIndex()

  local nextStage = stage + 1
  if g.run.trapdoor.voidPortal then
    nextStage = 12

  elseif stage == 8 and
     roomIndexUnsafe ~= GridRooms.ROOM_BLUE_WOOM_IDX then -- -8

    -- If we are not in the Womb special room, then we need to skip a floor
    -- (The Blue Womb is floor 9)
    nextStage = 10

  elseif stage == 11 then
    -- The Chest goes to The Chest
    -- The Dark Room goes to the Dark Room
    nextStage = 11
    FastTravel.reseed = true

  elseif stage == 12 then
    -- The Void goes to The Void
    nextStage = 12
    FastTravel.reseed = true
  end

  return nextStage
end

function FastTravel:GetNextStageType(nextStage, upwards)
  -- Local game
  local stageType = g.l:GetStageType()

  local nextStageType = FastTravel:DetermineStageType(nextStage)
  if nextStage == 9 then
    -- Blue Womb does not have any alternate floors
    nextStageType = 0

  elseif nextStage == 10 then
    if upwards then
      -- Go to Cathedral (10.1)
      nextStageType = 1
    else
      -- Go to Sheol (10.0)
      nextStageType = 0
    end

  elseif nextStage == 11 then
    -- By default, go to The Chest (11.1)
    nextStageType = 1
    if stageType == 0 then
      -- Sheol (10.0) goes to the Dark Room (11.0)
      nextStageType = 0
    end
  end

  return nextStageType
end

-- This is not named GetStageType to differentiate it from "level:GetStageType"
function FastTravel:DetermineStageType(stage)
  -- Local variables
  local stageSeed = g.seeds:GetStageSeed(stage)

  -- The following is the game's internal code to determine the floor type
  -- (this came directly from Spider)
  --[[
    u32 Seed = g_Game->GetSeeds().GetStageSeed(NextStage);
    if (!g_Game->IsGreedMode()) {
      StageType = ((Seed % 2) == 0 && (
        ((NextStage == STAGE1_1 || NextStage == STAGE1_2) && gd.Unlocked(ACHIEVEMENT_CELLAR)) ||
        ((NextStage == STAGE2_1 || NextStage == STAGE2_2) && gd.Unlocked(ACHIEVEMENT_CATACOMBS)) ||
        ((NextStage == STAGE3_1 || NextStage == STAGE3_2) && gd.Unlocked(ACHIEVEMENT_NECROPOLIS)) ||
        ((NextStage == STAGE4_1 || NextStage == STAGE4_2)))
      ) ? STAGETYPE_WOTL : STAGETYPE_ORIGINAL;
    if (Seed % 3 == 0 && NextStage < STAGE5)
      StageType = STAGETYPE_AFTERBIRTH;
  --]]

  -- Emulate what the game's internal code does
  local stageType = StageType.STAGETYPE_ORIGINAL -- 0
  if stageSeed & 1 == 0 then -- This is the same as "stageSeed % 2 == 0", but faster
    stageType = StageType.STAGETYPE_WOTL -- 1
  end
  if stageSeed % 3 == 0 then
    stageType = StageType.STAGETYPE_AFTERBIRTH -- 2
  end

  return stageType
end

function FastTravel:TravelStage(stage, stageType)
  -- Build the command that will take us to the next floor
  local command = "stage " .. stage
  if stageType == 1 then
    command = command .. "a"
  elseif stageType == 2 then
    command = command .. "b"
  end

  g:ExecuteCommand(command)

  if FastTravel.reseed then
    FastTravel.reseed = false

    -- We use the "delayNewRoomCallback" variable to delay firing
    -- the "CheckTrapdoor2()" function before the reseed happens
    FastTravel.delayNewRoomCallback = true

    -- Doing a "reseed" immediately after a "stage" command won't mess anything up
    g:ExecuteCommand("reseed")
  end
end

-- Called from the PostNewLevel callback
function FastTravel:FixStrengthCardBug()
  -- If the player uses a Strength card in a room and jumps into a trapdoor,
  -- then then extra heart container will not get properly removed because
  -- we manually warp the player away from the room/floor
  -- So, detect for this condition and manually remove the heart container
  if not g.run.usedStrength then
    return
  end
  g.run.usedStrength = false

  -- Handle the special case of if we used a Strength card on another form
  local character = g.p:GetPlayerType()
  if (g.run.usedStrengthChar == PlayerType.PLAYER_THEFORGOTTEN and -- 16
      character == PlayerType.PLAYER_THESOUL) or -- 17
     (g.run.usedStrengthChar == PlayerType.PLAYER_THESOUL and -- 17
       character == PlayerType.PLAYER_THEFORGOTTEN) then -- 16

    -- The bug will not occur in this special case
    -- In other words, the game will properly remove the bone heart (if we used the Strength card on The Forgotten)
    -- or the soul heart (if we used the Strength card on The Soul) for us, so we don't have to do anything here
    Isaac.DebugString("Strength card character swap occurred; doing nothing.")
    return
  end

  -- Don't actually remove the heart container if doing so would kill us
  -- (which is the vanilla behavior)
  local maxHearts = g.p:GetMaxHearts()
  local soulHearts = g.p:GetSoulHearts()
  local boneHearts = g.p:GetBoneHearts()
  if (maxHearts == 2 and
      soulHearts == 0 and
      boneHearts == 0) or
     (character == PlayerType.PLAYER_THEFORGOTTEN and
      boneHearts == 1) then

    Isaac.DebugString("Deliberately not removing the heart from a Strength card since it would kill us.")
  else
    g.p:AddMaxHearts(-2, true) -- Remove a heart container
    Isaac.DebugString("Took away 1 heart container to fix the Fast-Travel bug with Strength cards.")
  end
end

--
-- Crawlspace functions
--

-- Called from the "CheckEntities:Grid()" function
function FastTravel:ReplaceCrawlspace(entity, i)
  -- Local variables
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end

  -- Spawn a custom entity to emulate the original
  local crawlspace = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRAWLSPACE_FAST_TRAVEL, 0, -- 1000
                                 entity.Position, g.zeroVector, nil)
  crawlspace.DepthOffset = -100 -- This is needed so that the entity will not appear on top of the player

  -- The custom entity will not respawn if we leave the room,
  -- so we need to keep track of it for the remainder of the floor
  g.run.replacedCrawlspaces[#g.run.replacedCrawlspaces + 1] = {
    room = roomIndex,
    pos  = entity.Position,
  }

  -- Log it
  --[[
  Isaac.DebugString("Replaced crawlspace in room " .. tostring(roomIndex) .. " at (" ..
                    tostring(entity.Position.X) .. "," .. tostring(entity.Position.Y) .. ")")
  --]]

  -- Figure out if it should spawn open or closed, depending if there are one or more players close to it
  local playerClose = false
  for j = 1, g.g:GetNumPlayers() do
    local player = Isaac.GetPlayer(j - 1)
    if player.Position:Distance(entity.Position) <= FastTravel.trapdoorOpenDistance then
      playerClose = true
      break
    end
  end
  if playerClose then
    crawlspace:ToEffect().State = 1
    crawlspace:GetSprite():Play("Closed", true)
    Isaac.DebugString("Spawned crawlspace (closed, state 1).")
  else
    crawlspace:GetSprite():Play("Open Animation", true)
    Isaac.DebugString("Spawned crawlspace (opened, state 0).")
  end

  -- Remove the original entity
  entity.Sprite = Sprite() -- If we don't do this, it will still show for a frame
  g.r:RemoveGridEntity(i, 0, false) -- entity:Destroy() does not work
end

-- Called from the "CheckEntities:NonGrid()" function
function FastTravel:CheckCrawlspaceEnter(effect)
  -- Local variables
  local prevRoomIndex = g.l:GetPreviousRoomIndex()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end

  -- Check to see if a player is touching the crawlspace
  for i = 1, g.g:GetNumPlayers() do
    local player = Isaac.GetPlayer(i - 1)
    if effect.State == 0 and -- The crawlspace is open
       player.Position:Distance(effect.Position) <= FastTravel.trapdoorTouchDistance and
       not player:IsHoldingItem() and
       not player:GetSprite():IsPlaying("Happy") and -- Account for lucky pennies
       not player:GetSprite():IsPlaying("Jump") then -- Account for How to Jump

      -- Save the previous room information in case we return to a room outside the grid (with a negative room index)
      if prevRoomIndex < 0 then
        Isaac.DebugString("Skipped saving the crawlspace previous room since it was negative.")
      else
        g.run.crawlspace.prevRoom = g.l:GetPreviousRoomIndex()
        Isaac.DebugString("Set crawlspace previous room to: " .. tostring(g.run.crawlspace.prevRoom))
      end

      -- If we don't set this, we will return to the center of the room by default
      g.l.DungeonReturnPosition = effect.Position

      -- We need to keep track of which room we came from
      -- (this is needed in case we are in a Boss Rush or other room with a negative room index)
      g.l.DungeonReturnRoomIndex = roomIndex

      -- Go to the crawlspace
      g.g:StartRoomTransition(GridRooms.ROOM_DUNGEON_IDX, Direction.DOWN, -- -4, 3
                              g.RoomTransition.TRANSITION_NONE) -- 0
    end
  end
end

-- Called from the PostUpdate callback
function FastTravel:CheckCrawlspaceExit()
  -- Local variables
  local playerGridIndex = g.r:GetGridIndex(g.p.Position)

  if g.r:GetType() == RoomType.ROOM_DUNGEON and -- 16
     playerGridIndex == 2 then -- If the player is standing on top of the ladder

    -- Do a manual room transition
    g.l.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
    g.g:StartRoomTransition(g.l.DungeonReturnRoomIndex, Direction.UP, -- 1
                            g.RoomTransition.TRANSITION_NONE) -- 0
  end
end

-- Fix the softlock with Boss Rushes and crawlspaces
-- (called from the PostUpdate callback)
function FastTravel:CheckCrawlspaceSoftlock()
  -- Local variables
  local prevRoomIndex = g.l:GetPreviousRoomIndex() -- We need the unsafe version here
  local roomType = g.r:GetType()
  local playerGridIndex = g.r:GetGridIndex(g.p.Position)

  if (roomType == RoomType.ROOM_DEVIL or -- 14
      roomType == RoomType.ROOM_ANGEL) and -- 15
     prevRoomIndex == GridRooms.ROOM_DUNGEON_IDX then -- -4

    if playerGridIndex == 7 then -- Top door
      g.run.crawlspace.direction = Direction.UP -- 1
      g.g:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.UP, -- 1
                              g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Devil/Angel Room, moving up to room: " ..
                        tostring(g.run.crawlspace.prevRoom))

    elseif playerGridIndex == 74 then -- Right door
      g.run.crawlspace.direction = Direction.RIGHT -- 2
      g.g:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.RIGHT, -- 2
                              g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Devil/Angel Room, moving right to room: " ..
                        tostring(g.run.crawlspace.prevRoom))

    elseif playerGridIndex == 127 then -- Bottom door
      g.run.crawlspace.direction = Direction.DOWN -- 3
      g.g:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.DOWN, -- 3
                              g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Devil Devil/Angel Room, moving down to room: " ..
                        tostring(g.run.crawlspace.prevRoom))

    elseif playerGridIndex == 60 then -- Left door
      g.run.crawlspace.direction = Direction.LEFT -- 0
      g.g:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.LEFT, -- 0
                              g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Devil/Angel Room, moving left to room: " ..
                        tostring(g.run.crawlspace.prevRoom))
    end

  elseif roomType == RoomType.ROOM_BOSSRUSH and -- 17
         prevRoomIndex == GridRooms.ROOM_DUNGEON_IDX then -- -4

    if playerGridIndex == 7 then -- Top left door
      g.run.crawlspace.direction = Direction.UP -- 1
      g.g:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.UP, -- 1
                              g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Boss Rush, moving up to room: " ..
                        tostring(g.run.crawlspace.prevRoom))

    elseif playerGridIndex == 139 then -- Right top door
      g.run.crawlspace.direction = Direction.RIGHT -- 2
      g.g:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.RIGHT, -- 2
                              g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Boss Rush, moving right to room: " ..
                        tostring(g.run.crawlspace.prevRoom))

    elseif playerGridIndex == 427 then -- Bottom left door
      g.run.crawlspace.direction = Direction.DOWN -- 3
      g.g:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.DOWN, -- 3
                              g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Boss Rush, moving down to room: " ..
                        tostring(g.run.crawlspace.prevRoom))

    elseif playerGridIndex == 112 then -- Left top door
      g.run.crawlspace.direction = Direction.LEFT -- 0
      g.g:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.LEFT, -- 0
                              g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Boss Rush, moving left to room: " ..
                        tostring(g.run.crawlspace.prevRoom))
    end
  end
end

-- Called in the PostNewRoom callback
function FastTravel:CheckCrawlspaceMiscBugs()
  -- Local variables
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end
  local prevRoomIndex = g.l:GetPreviousRoomIndex() -- We need the unsafe version here

  -- For some reason, we won't go back to location of the crawlspace if we entered from a room outside of the grid,
  -- so we need to move there manually
  -- (in the Boss Rush, this will look glitchy because the game originally sends us next to a Boss Rush door,
  -- but there is no way around this; even if we change player.Position on every frame in the PostRender callback,
  -- the glitchy warp will still occur)
  if roomIndex < 0 and
     roomIndex ~= GridRooms.ROOM_DUNGEON_IDX and -- -4
     -- We don't want to teleport if we are returning to a crawlspace from a Black Market
     roomIndex ~= GridRooms.ROOM_BLACK_MARKET_IDX and -- -6
     -- We don't want to teleport in a Black Market
     prevRoomIndex == GridRooms.ROOM_DUNGEON_IDX then -- -4

    g.p.Position = g.l.DungeonReturnPosition
    Isaac.DebugString("Exited a crawlspace in an off-grid room; crawlspace teleport complete.")
  end

  -- For some reason, if we exit and re-enter a crawlspace from a room outside of the grid,
  -- we won't spawn on the ladder, so move there manually (this causes no visual hiccups like the above code does)
  if roomIndex == GridRooms.ROOM_DUNGEON_IDX and -- -4
     g.l.DungeonReturnRoomIndex < 0 and
     not g.run.crawlspace.blackMarket then

    g.p.Position = Vector(120, 160) -- This is the standard starting location at the top of the ladder
    Isaac.DebugString("Entered crawlspace from a room outside the grid; ladder teleport complete.")
  end

  -- When returning to the boss room from a Boss Rush with a crawlspace in it,
  -- we might not end up in a spot where the player expects, so move to the most logical position manually
  if g.run.crawlspace.direction ~= -1 then
    if g.run.crawlspace.direction == Direction.LEFT then -- 0
      -- Returning from the right door
      g.p.Position = g.r:GetGridPosition(73)
      Isaac.DebugString("Entered the previous room from a nested crawlspace (going left), teleport complete.")
    elseif g.run.crawlspace.direction == Direction.UP then -- 1
      -- Returning from the bottom door
      g.p.Position = g.r:GetGridPosition(112)
      Isaac.DebugString("Entered the previous room from a nested crawlspace (going up), teleport complete.")
    elseif g.run.crawlspace.direction == Direction.RIGHT then -- 2
      -- Returning from the left door
      g.p.Position = g.r:GetGridPosition(61)
      Isaac.DebugString("Entered the previous room from a nested crawlspace (going left), teleport complete.")
    elseif g.run.crawlspace.direction == Direction.DOWN then -- 3
      -- Returning from the top door
      g.p.Position = g.r:GetGridPosition(22)
      Isaac.DebugString("Entered the previous room from a nested crawlspace (going down), teleport complete.")
    end
    g.run.crawlspace.direction = -1
  end

  -- Keep track of whether we are in a Black Market so that we don't teleport the player
  -- if they return to the crawlspace
  if roomIndex == GridRooms.ROOM_BLACK_MARKET_IDX then -- -6
    g.run.crawlspace.blackMarket = true
  else
    g.run.crawlspace.blackMarket = false
  end
end

--
-- Shared functions
--

-- Called from the "CheckEntities:NonGrid()" function
function FastTravel:CheckTrapdoorCrawlspaceOpen(effect)
  -- Local variables
  local roomType = g.r:GetType()

  -- Don't do anything if the trapdoor / crawlspace is already open
  if effect.State == 0 then
    return
  end

  -- Don't do anything if it is freshly spawned in a boss room and one or more players are relatively close
  local playerRelativelyClose = false
  for j = 1, g.g:GetNumPlayers() do
    local player = Isaac.GetPlayer(j - 1)
    if player.Position:Distance(effect.Position) <= FastTravel.trapdoorOpenDistance * 2.5 then
      playerRelativelyClose = true
      break
    end
  end
  if roomType == RoomType.ROOM_BOSS and -- 5
     effect.FrameCount <= 30 and
     effect.DepthOffset ~= -101 and -- We use -101 to signify that it is a respawned trapdoor
     playerRelativelyClose then

    return
  end

  -- Don't do anything if the player is standing too close to the trapdoor / crawlspace
  local playerClose = false
  for j = 1, g.g:GetNumPlayers() do
    local player = Isaac.GetPlayer(j - 1)
    if player.Position:Distance(effect.Position) <= FastTravel.trapdoorOpenDistance then
      playerClose = true
      break
    end
  end
  if playerClose then
    return
  end

  -- Open it
  effect.State = 0
  effect:GetSprite():Play("Open Animation", true)
  --Isaac.DebugString("Opened trap door (player moved away).")
end

-- Called from the PostNewRoom callback
function FastTravel:CheckRoomRespawn()
  -- Local variables
  local stage = g.l:GetStage()
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end

  -- Respawn trapdoors, if necessary
  for _, trapdoor in ipairs(g.run.replacedTrapdoors) do
    if trapdoor.room == roomIndex then
      FastTravel:RemoveOverlappingGridEntity(trapdoor.pos, "trapdoor")

      -- Spawn the new custom entity
      local entity
      if roomIndex == GridRooms.ROOM_BLUE_WOOM_IDX then -- -8
        entity = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLUE_WOMB_TRAPDOOR_FAST_TRAVEL, 0, -- 1000
                             trapdoor.pos, g.zeroVector, nil)

      elseif stage == 6 or
             stage == 7 then

        entity = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.WOMB_TRAPDOOR_FAST_TRAVEL, 0, -- 1000
                             trapdoor.pos, g.zeroVector, nil)

      else
        entity = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TRAPDOOR_FAST_TRAVEL, 0, -- 1000
                             trapdoor.pos, g.zeroVector, nil)
      end
      entity.DepthOffset = -101 -- This is needed so that the entity will not appear on top of the player
      -- We use -101 instead of -100 to signify that it is a respawned trapdoor

      -- Figure out if it should spawn open or closed, depending on if one or more players is close to it
      local playerClose = false
      for j = 1, g.g:GetNumPlayers() do
        local player = Isaac.GetPlayer(j - 1)
        if player.Position:Distance(entity.Position) <= FastTravel.trapdoorOpenDistance then
          playerClose = true
          break
        end
      end
      if playerClose or
         roomIndex == GridRooms.ROOM_BOSSRUSH_IDX then -- -5
         -- (always spawn trapdoors closed in the Boss Rush to prevent specific bugs)

        entity:ToEffect().State = 1
        entity:GetSprite():Play("Closed", true)
        Isaac.DebugString("Respawned trapdoor (closed, state 1).")
      else
        -- The default animation is "Opened", which is what we want
        Isaac.DebugString("Respawned trapdoor (opened, state 0).")
      end
    end
  end

  -- Respawn crawlspaces, if necessary
  for _, crawlspace in ipairs(g.run.replacedCrawlspaces) do
    if crawlspace.room == roomIndex then
      FastTravel:RemoveOverlappingGridEntity(crawlspace.pos, "crawlspace")

      -- Spawn the new custom entity
      local entity = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRAWLSPACE_FAST_TRAVEL, 0, -- 1000
                                 crawlspace.pos, g.zeroVector, nil)
      entity.DepthOffset = -100 -- This is needed so that the entity will not appear on top of the player

      -- Figure out if it should spawn open or closed, depending on if one or more players is close to it
      local playerClose = false
      for j = 1, g.g:GetNumPlayers() do
        local player = Isaac.GetPlayer(j - 1)
        if player.Position:Distance(entity.Position) <= FastTravel.trapdoorOpenDistance then
          playerClose = true
          break
        end
      end
      if playerClose or
         roomIndex < 0 then
         -- (always spawn crawlspaces closed in rooms outside the grid to prevent specific bugs;
         -- e.g. if we need to teleport back to a crawlspace and it is open, the player can softlock)

        entity:ToEffect().State = 1
        entity:GetSprite():Play("Closed", true)
        Isaac.DebugString("Respawned crawlspace (closed, state 1).")
      else
        -- The default animation is "Opened", which is what we want
        Isaac.DebugString("Respawned crawlspace (opened, state 0).")
      end
    end
  end

  -- Respawn beams of light, if necessary
  for _, heavenDoor in ipairs(g.run.replacedHeavenDoors) do
    if heavenDoor.room == roomIndex then
      -- Spawn the new custom entity
      -- (we use an InitSeed of 0 instead of a random seed to signify that it is a respawned entity)
      local entity = g.g:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_DOOR_FAST_TRAVEL, -- 1000
                               heavenDoor.pos, g.zeroVector, nil, 0, 0)
      entity.DepthOffset = 15 -- The default offset of 0 is too low, and 15 is just about perfect
      Isaac.DebugString("Respawned heaven door.")
    end
  end
end

-- Remove any grid entities that will overlap with the custom trapdoor/crawlspace
-- (this is needed because rocks/poop will respawn in the room after reentering)
function FastTravel:RemoveOverlappingGridEntity(pos, type)
  -- Check for the existance of an overlapping grid entity
  local gridIndex = g.r:GetGridIndex(pos)
  local gridEntity = g.r:GetGridEntity(gridIndex)
  if gridEntity == nil then
    return
  end

  -- Remove it
  g.r:RemoveGridEntity(gridIndex, 0, false) -- entity:Destroy() will only work on destroyable entities like TNT
  Isaac.DebugString("Removed a grid entity at index " .. tostring(gridIndex) ..
                    " that would interfere with the " .. tostring(type) .. ".")

  -- If this was a Corny Poop, it will turn the Eternal Fly into an Attack Fly
  local saveState = gridEntity:GetSaveState()
  if saveState.Type == GridEntityType.GRID_POOP and -- 14
     saveState.Variant == 2 then -- Corny Poop

    local flies = Isaac.FindByType(EntityType.ENTITY_ETERNALFLY, -1, -1, false, false) -- 96
    for _, fly in ipairs(flies) do
      fly:Remove()
      Isaac.DebugString("Removed an Eternal Fly associated with the removed Corny Poop.")
    end
  end
end

return FastTravel

local FastTravel = {}

-- Includes
local g            = require("src/globals")
local Sprites      = require("src/sprites")
local SeededFloors = require("src/seededfloors")

-- Constants
FastTravel.trapdoorOpenDistance  = 60 -- This feels about right
FastTravel.trapdoorTouchDistance = 16.5 -- This feels about right (it is slightly smaller than vanilla)
FastTravel.reseed                = false -- Used when we need to reseed the next floor
FastTravel.delayNewRoomCallback  = false -- Used when executing a "reseed" immediately after a "stage X"

--
-- Trapdoor / heaven door functions
--

-- "Replace" functions for trapdoor / heaven door
-- (called from the "CheckEntities:Grid()" and "CheckEntities:NonGrid()" functions)
function FastTravel:ReplaceTrapdoor(entity, i)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local seeds = game:GetSeeds()
  local level = game:GetLevel()
  local room = game:GetRoom()
  local stage = level:GetStage()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end

  -- There is no way to manually travel to the "Infiniate Basements" Easter Egg floors,
  -- so just disable the fast-travel feature
  if seeds:HasSeedEffect(SeedEffect.SEED_INFINITE_BASEMENT) then -- 16
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
    room:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work
    Isaac.DebugString("Deleted the natural trapdoor after It Lives! (or Hush).")
    return
  end

  -- Spawn a custom entity to emulate the original
  local trapdoor
  local type
  if roomIndex == GridRooms.ROOM_BLUE_WOOM_IDX then -- -8
    type = 2
    trapdoor = game:Spawn(Isaac.GetEntityTypeByName("Blue Womb Trapdoor (Fast-Travel)"),
                          Isaac.GetEntityVariantByName("Blue Womb Trapdoor (Fast-Travel)"),
                          entity.Position, Vector(0, 0), nil, 0, 0)

  elseif stage == LevelStage.STAGE3_2 or -- 6
         stage == LevelStage.STAGE4_1 then -- 7

    type = 1
    trapdoor = game:Spawn(Isaac.GetEntityTypeByName("Womb Trapdoor (Fast-Travel)"),
                          Isaac.GetEntityVariantByName("Womb Trapdoor (Fast-Travel)"),
                          entity.Position, Vector(0, 0), nil, 0, 0)

  else
    type = 0
    trapdoor = game:Spawn(Isaac.GetEntityTypeByName("Trapdoor (Fast-Travel)"),
                          Isaac.GetEntityVariantByName("Trapdoor (Fast-Travel)"),
                          entity.Position, Vector(0, 0), nil, 0, 0)
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
  local debugString = "Replaced a "
  if type == 2 then
    debugString = debugString .. "blue womb "
  elseif type == 1 then
    debugString = debugString .. "womb "
  end
  debugString = debugString .. "trapdoor in room " .. tostring(roomIndex) .. " at "
  debugString = debugString .. "(" .. tostring(entity.Position.X) .. ", " .. tostring(entity.Position.Y) .. ") "
  debugString = debugString .. "on frame " .. tostring(gameFrameCount)
  Isaac.DebugString(debugString)

  -- Remove the original entity
  if i == -1 then
    -- We are replacing a Big Chest
    entity:Remove()
  else
    -- We are replacing a trapdoor grid entity
    entity.Sprite = Sprite() -- If we don't do this, it will still show for a frame
    room:RemoveGridEntity(i, 0, false) -- entity:Destroy() does not work
  end
end

function FastTravel:ReplaceHeavenDoor(entity)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local room = game:GetRoom()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"

  -- Delete the "natural" beam of light that spawns one frame after It Lives! (or Hush) is killed
  -- (it spawns after one frame because of fast-clear; on vanilla it spawns after a long delay)
  if gameFrameCount == g.run.itLivesKillFrame + 1 then
    entity:Remove()
    Isaac.DebugString("Deleted the natural beam of light after It Lives! (or Hush).")
    return
  end

  -- Spawn a custom entity to emulate the original
  local heaven = game:Spawn(Isaac.GetEntityTypeByName("Heaven Door (Fast-Travel)"),
                            Isaac.GetEntityVariantByName("Heaven Door (Fast-Travel)"),
                            entity.Position, Vector(0,0), nil, 0, roomSeed)
  heaven.DepthOffset = 15 -- The default offset of 0 is too low, and 15 is just about perfect

  -- The custom entity will not respawn if we leave the room,
  -- so we need to keep track of it for the remainder of the floor
  g.run.replacedHeavenDoors[#g.run.replacedHeavenDoors + 1] = {
    room = roomIndex,
    pos  = entity.Position,
  }

  -- Log it
  local debugString = "Replaced a beam of light in room " .. tostring(roomIndex) .. " "
  debugString = debugString .. " at (" .. tostring(entity.Position.X) .. "," .. tostring(entity.Position.Y) .. ") "
  debugString = debugString .. "on frame " .. tostring(gameFrameCount)
  Isaac.DebugString(debugString)

  -- Remove the original entity
  entity:Remove()
end

-- Called from the "CheckEntities:Entity5()" function
-- (we can't use the MC_POST_PICKUP_INIT callback for this because the position
-- for newly initialized pickups is always equal to 0, 0)
function FastTravel:CheckPickupOverHole(pickup)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
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
  for i = 1, #g.run.replacedTrapdoors do
    if roomIndex == g.run.replacedTrapdoors[i].room and
       g:InsideSquare(pickup.Position, g.run.replacedTrapdoors[i].pos, squareSize) then

      FastTravel:MovePickupFromHole(pickup, g.run.replacedTrapdoors[i].pos)
      return
    end
  end
  for i = 1, #g.run.replacedHeavenDoors do
    if roomIndex == g.run.replacedHeavenDoors[i].room and
       g:InsideSquare(pickup.Position, g.run.replacedHeavenDoors[i].pos, squareSize) then

      FastTravel:MovePickupFromHole(pickup, g.run.replacedHeavenDoors[i].pos)
      return
    end
  end
  for i = 1, #g.run.replacedCrawlspaces do
    if roomIndex == g.run.replacedCrawlspaces[i].room and
       g:InsideSquare(pickup.Position, g.run.replacedCrawlspaces[i].pos, squareSize) then

      FastTravel:MovePickupFromHole(pickup, g.run.replacedCrawlspaces[i].pos)
      return
    end
  end
end

function FastTravel:MovePickupFromHole(pickup, posHole)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()
  local squareSize = FastTravel.trapdoorTouchDistance + 2

  -- First, if this is a collectibles that is overlapping with the trapdoor, then move it manually
  -- (this is rare but possible with a Small Rock)
  if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then -- 100
    pickup.Position = room:FindFreePickupSpawnPosition(pickup.Position, 1, true)
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
      if g:InsideSquare(newPos, posHole, squareSize) == false then
        pushedOut = true
        break
      end
    end
    if pushedOut == false then
      Isaac.DebugString("Error: Was not able to move the pickup out of the hole after 100 iterations.")
    end
    pickup.Position = newPos

    return
  end

  -- Generate new spawn positions until we find one that doesn't overlap with the hole
  local newPos
  local overlapping = false
  for i = 0, 100 do
    newPos = room:FindFreePickupSpawnPosition(pickup.Position, i, true)
    if g:InsideSquare(newPos, posHole, squareSize) then
      overlapping = true
    end
    if overlapping == false then
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

-- Called from the "CheckEntities:NonGrid()" function
function FastTravel:CheckTrapdoorEnter(effect, upwards)
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local isaacFrameCount = Isaac.GetFrameCount()

  -- Check to see if a player is touching the trapdoor
  for i = 1, game:GetNumPlayers() do
    local player = Isaac.GetPlayer(i - 1)
    if g.run.trapdoor.state == 0 and
       ((upwards == false and effect.State == 0) or -- The trapdoor is open
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
       g:InsideSquare(player.Position, effect.Position, FastTravel.trapdoorTouchDistance) and
       player:IsHoldingItem() == false and
       player:GetSprite():IsPlaying("Happy") == false and -- Account for lucky pennies
       player:GetSprite():IsPlaying("Jump") == false then -- Account for How to Jump

      -- State 1 is activated the moment we touch the trapdoor
      g.run.trapdoor.state = 1
      Isaac.DebugString("Trapdoor state: " .. g.run.trapdoor.state .. " (frame " .. gameFrameCount .. ")")
      g.run.trapdoor.upwards = upwards
      g.run.trapdoor.frame = isaacFrameCount + 40 -- Custom animations are 40 frames; see below

      player.ControlsEnabled = false
      player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE -- 0
      -- (this is necessary so that enemy attacks don't move the player while they are doing the jumping animation)
      player.Position = effect.Position -- Teleport the player on top of the trapdoor
      player.Velocity = Vector(0, 0) -- Remove all of the player's momentum

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
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local player = game:GetPlayer(0)
  local isaacFrameCount = Isaac.GetFrameCount()

  if g.run.trapdoor.state == 1 and
     isaacFrameCount >= g.run.trapdoor.frame then

    -- State 2 is activated when the "Trapdoor" animation is completed
    player.Visible = false

    -- Make the screen fade to black (we can go to any room for this, so we just use the starting room)
    game:StartRoomTransition(level:GetStartingRoomIndex(), Direction.NO_DIRECTION, -- -1
                             g.RoomTransition.TRANSITION_NONE) -- 0

    -- Mark to change floors after the screen is black
    g.run.trapdoor.state = 2
    Isaac.DebugString("Trapdoor state: " .. g.run.trapdoor.state .. " (frame " .. gameFrameCount .. ")")
    g.run.trapdoor.frame = isaacFrameCount + 8
    -- 9 is too many (you can start to see the same room again)

  elseif g.run.trapdoor.state == 2 and
         isaacFrameCount >= g.run.trapdoor.frame then

    -- Stage 3 is actiated when the screen is black
    g.run.trapdoor.state = 3
    Isaac.DebugString("Trapdoor state: " .. g.run.trapdoor.state .. " (frame " .. gameFrameCount .. ")")
    g.run.trapdoor.floor = stage
    Sprites:Init("black", "black")
    FastTravel:GotoNextFloor(g.run.trapdoor.upwards) -- The argument is "upwards"

  elseif g.run.trapdoor.state == 5 and
         player.ControlsEnabled then

     -- State 6 is activated when the player controls are enabled
     -- (this happens automatically by the game)
     -- (stages 4 and 5 are in the PostNewRoom callback)
     g.run.trapdoor.state = 6
     Isaac.DebugString("Trapdoor state: " .. g.run.trapdoor.state .. " (frame " .. gameFrameCount .. ")")
     g.run.trapdoor.frame = isaacFrameCount + 10 -- Wait a while longer
     player.ControlsEnabled = false

  elseif g.run.trapdoor.state == 6 and
         isaacFrameCount >= g.run.trapdoor.frame then

     -- State 7 is activated when the the hole is spawned and ready
     g.run.trapdoor.state = 7
     Isaac.DebugString("Trapdoor state: " .. g.run.trapdoor.state .. " (frame " .. gameFrameCount .. ")")
     g.run.trapdoor.frame = isaacFrameCount + 25
     -- The "JumpOut" animation is 15 frames long, so give a bit of leeway

     for i = 1, game:GetNumPlayers() do
       local player2 = Isaac.GetPlayer(i - 1)

       -- Make the player(s) visable again
       player2.SpriteScale = g.run.trapdoor.scale[i]

       -- Give the player(s) the collision that we removed earlier
       player2.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL -- 4

       -- Play the jumping out of the hole animation
       player2:PlayExtraAnimation("Jump")
     end

     -- Make the hole do the dissapear animation
     for i, entity in pairs(Isaac.GetRoomEntities()) do
       if entity.Type == Isaac.GetEntityTypeByName("Pitfall (Custom)") and
          entity.Variant == Isaac.GetEntityVariantByName("Pitfall (Custom)") then

         entity:GetSprite():Play("Disappear", true)
         break
       end
     end

  elseif g.run.trapdoor.state == 7 and
         isaacFrameCount >= g.run.trapdoor.frame then

    -- We are finished when the the player has emerged from the hole
    g.run.trapdoor.state = 0
    Isaac.DebugString("Trapdoor state: " .. g.run.trapdoor.state ..
                      " (finished) (frame " .. gameFrameCount .. ")")

    -- Enable the controls for all players
    for i = 1, game:GetNumPlayers() do
      local player2 = Isaac.GetPlayer(i - 1)
      player2.ControlsEnabled = true
    end

    -- Kill the hole
    for i, entity in pairs(Isaac.GetRoomEntities()) do
      if entity.Type == 1001 then
        entity:Remove()
        break
      end
    end
  end

  -- Fix the bug where Dr. Fetus bombs can be shot while jumping
  if g.run.trapdoor.state > 0 then
    player.FireDelay = 1
  end
end

-- Called from the PostNewRoom callback
function FastTravel:CheckTrapdoor2()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  local room = game:GetRoom()

  -- We will hit the PostNewRoom callback twice when doing a fast-travel, so do nothing on the first time
  -- (this is just an artifact of the manual reordering)
  if g.run.trapdoor.state == 3 then
    g.run.trapdoor.state = 4
    Isaac.DebugString("Trapdoor state: " .. g.run.trapdoor.state .. " (frame " .. gameFrameCount .. ")")

  elseif g.run.trapdoor.state == 4 then
    g.run.trapdoor.state = 5
    Isaac.DebugString("Trapdoor state: " .. g.run.trapdoor.state .. " (frame " .. gameFrameCount .. ")")

    for i = 1, game:GetNumPlayers() do
      local player = Isaac.GetPlayer(i - 1)

      -- Make the player(s) invisible so that we can jump out of the hole
      -- (this has to be in the PostNewRoom callback so that we don't get bugs with the Glowing Hour Glass)
      -- (we can't use "player.Visible = false" because it won't do anything here)
      g.run.trapdoor.scale[i] = player.SpriteScale
      player.SpriteScale = Vector(0, 0)

      -- Move the player to the center of the room
      player.Position = room:GetCenterPos()
    end

    -- Spawn a hole
    game:Spawn(Isaac.GetEntityTypeByName("Pitfall (Custom)"), Isaac.GetEntityVariantByName("Pitfall (Custom)"),
               room:GetCenterPos(), Vector(0,0), nil, 0, 0)

    -- Show what the new floor is (the game won't show this naturally since we used the console command to get here)
    if g.raceVars.finished == false and
       -- (the "Victory Lap" text will overlap with the stage text, so don't bother showing it if the race is finished)
       game:GetPlayer(0):GetPlayerType() ~= Isaac.GetPlayerTypeByName("Random Baby") then
       -- (the baby descriptions will slightly overlap with the stage text,
       -- so don't bother showing it if we are playing as "Random Baby")

       g.run.streakText = level:GetName(stage, stageType, 0, false)
       if g.run.streakText == "???" then
        g.run.streakText = "Blue Womb"
       end
       g.run.streakFrame = Isaac.GetFrameCount()
    end

    -- Remove the black sprite to reveal the new floor
    Sprites:Init("black", 0)
  end
end

-- Remove the long fade out / fade in when entering trapdoors
-- (and redirect Sacrifice Room teleports)
function FastTravel:GotoNextFloor(upwards, redirect)
  -- Local game
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local stageType = level:GetStageType()

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
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local roomIndexUnsafe = level:GetCurrentRoomIndex()

  local nextStage = stage + 1
  if stage == 8 and
     roomIndexUnsafe ~= GridRooms.ROOM_BLUE_WOOM_IDX then -- -8

    -- If we are not in the Womb special room, then we need to skip a floor
    -- (The Blue Womb is floor 9)
    nextStage = 10

  elseif stage == 11 then
    -- The Chest goes to The Chest
    -- The Dark Room goes to the Dark Room
    nextStage = 11
    FastTravel.reseed = true
  end

  return nextStage
end

function FastTravel:GetNextStageType(nextStage, upwards)
  -- Local game
  local game = Game()
  local level = game:GetLevel()
  local stageType = level:GetStageType()

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
  local game = Game()
  local seeds = game:GetSeeds()
  local stageSeed = seeds:GetStageSeed(stage)

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

--
-- Crawlspace functions
--

-- Called from the "CheckEntities:Grid()" function
function FastTravel:ReplaceCrawlspace(entity, i)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local room = game:GetRoom()

  -- Spawn a custom entity to emulate the original
  local crawlspace = game:Spawn(Isaac.GetEntityTypeByName("Crawlspace (Fast-Travel)"),
                                Isaac.GetEntityVariantByName("Crawlspace (Fast-Travel)"),
                                entity.Position, Vector(0,0), nil, 0, 0)
  crawlspace.DepthOffset = -100 -- This is needed so that the entity will not appear on top of the player

  -- The custom entity will not respawn if we leave the room,
  -- so we need to keep track of it for the remainder of the floor
  g.run.replacedCrawlspaces[#g.run.replacedCrawlspaces + 1] = {
    room = roomIndex,
    pos  = entity.Position,
  }

  -- Log it
  Isaac.DebugString("Replaced crawlspace in room " .. tostring(roomIndex) .. " at (" ..
                    tostring(entity.Position.X) .. "," .. tostring(entity.Position.Y) .. ")")

  -- Figure out if it should spawn open or closed, depending if there are one or more players close to it
  local playerClose = false
  for j = 1, game:GetNumPlayers() do
    local player = Isaac.GetPlayer(j - 1)
    if g:InsideSquare(player.Position, entity.Position, FastTravel.trapdoorOpenDistance) then
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
  room:RemoveGridEntity(i, 0, false) -- entity:Destroy() does not work
end

-- Called from the "CheckEntities:NonGrid()" function
function FastTravel:CheckCrawlspaceEnter(effect)
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local prevRoomIndex = level:GetPreviousRoomIndex()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end

  -- Check to see if a player is touching the crawlspace
  for i = 1, game:GetNumPlayers() do
    local player = Isaac.GetPlayer(i - 1)
    if effect.State == 0 and -- The crawlspace is open
       g:InsideSquare(player.Position, effect.Position, FastTravel.trapdoorTouchDistance) and
       player:IsHoldingItem() == false and
       player:GetSprite():IsPlaying("Happy") == false and -- Account for lucky pennies
       player:GetSprite():IsPlaying("Jump") == false then -- Account for How to Jump

      -- Save the previous room information in case we return to a room outside the grid (with a negative room index)
      if prevRoomIndex < 0 then
        Isaac.DebugString("Skipped saving the crawlspace previous room since it was negative.")
      else
        g.run.crawlspace.prevRoom = level:GetPreviousRoomIndex()
        Isaac.DebugString("Set crawlspace previous room to: " .. tostring(g.run.crawlspace.prevRoom))
      end

      -- If we don't set this, we will return to the center of the room by default
      level.DungeonReturnPosition = effect.Position

      -- We need to keep track of which room we came from
      -- (this is needed in case we are in a Boss Rush or other room with a negative room index)
      level.DungeonReturnRoomIndex = roomIndex

      -- Go to the crawlspace
      game:StartRoomTransition(GridRooms.ROOM_DUNGEON_IDX, Direction.DOWN, -- -4, 3
                               g.RoomTransition.TRANSITION_NONE) -- 0
    end
  end
end

-- Called from the PostUpdate callback
function FastTravel:CheckCrawlspaceExit()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local room = game:GetRoom()
  local player = game:GetPlayer(0)
  local playerGridIndex = room:GetGridIndex(player.Position)

  if room:GetType() == RoomType.ROOM_DUNGEON and -- 16
     playerGridIndex == 2 then -- If the player is standing on top of the ladder

    -- Do a manual room transition
    level.LeaveDoor = -1 -- You have to set this before every teleport or else it will send you to the wrong room
    game:StartRoomTransition(level.DungeonReturnRoomIndex, Direction.UP, -- 1
                             g.RoomTransition.TRANSITION_NONE) -- 0
  end
end

-- Fix the softlock with Boss Rushes and crawlspaces
-- (called from the PostUpdate callback)
function FastTravel:CheckCrawlspaceSoftlock()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local room = game:GetRoom()
  local prevRoomIndex = level:GetPreviousRoomIndex() -- We need the unsafe version here
  local roomType = room:GetType()
  local player = game:GetPlayer(0)
  local playerGridIndex = room:GetGridIndex(player.Position)

  if (roomType == RoomType.ROOM_DEVIL or -- 14
      roomType == RoomType.ROOM_ANGEL) and -- 15
     prevRoomIndex == GridRooms.ROOM_DUNGEON_IDX then -- -4

    if playerGridIndex == 7 then -- Top door
      g.run.crawlspace.direction = Direction.UP -- 1
      game:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.UP, -- 1
                               g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Devil/Angel Room, moving up to room: " ..
                        tostring(g.run.crawlspace.prevRoom))

    elseif playerGridIndex == 74 then -- Right door
      g.run.crawlspace.direction = Direction.RIGHT -- 2
      game:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.RIGHT, -- 2
                               g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Devil/Angel Room, moving right to room: " ..
                        tostring(g.run.crawlspace.prevRoom))

    elseif playerGridIndex == 127 then -- Bottom door
      g.run.crawlspace.direction = Direction.DOWN -- 3
      game:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.DOWN, -- 3
                               g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Devil Devil/Angel Room, moving down to room: " ..
                        tostring(g.run.crawlspace.prevRoom))

    elseif playerGridIndex == 60 then -- Left door
      g.run.crawlspace.direction = Direction.LEFT -- 0
      game:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.LEFT, -- 0
                               g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Devil/Angel Room, moving left to room: " ..
                        tostring(g.run.crawlspace.prevRoom))
    end

  elseif roomType == RoomType.ROOM_BOSSRUSH and -- 17
         prevRoomIndex == GridRooms.ROOM_DUNGEON_IDX then -- -4

    if playerGridIndex == 7 then -- Top left door
      g.run.crawlspace.direction = Direction.UP -- 1
      game:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.UP, -- 1
                               g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Boss Rush, moving up to room: " ..
                        tostring(g.run.crawlspace.prevRoom))

    elseif playerGridIndex == 139 then -- Right top door
      g.run.crawlspace.direction = Direction.RIGHT -- 2
      game:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.RIGHT, -- 2
                               g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Boss Rush, moving right to room: " ..
                        tostring(g.run.crawlspace.prevRoom))

    elseif playerGridIndex == 427 then -- Bottom left door
      g.run.crawlspace.direction = Direction.DOWN -- 3
      game:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.DOWN, -- 3
                               g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Boss Rush, moving down to room: " ..
                        tostring(g.run.crawlspace.prevRoom))

    elseif playerGridIndex == 112 then -- Left top door
      g.run.crawlspace.direction = Direction.LEFT -- 0
      game:StartRoomTransition(g.run.crawlspace.prevRoom, Direction.LEFT, -- 0
                               g.RoomTransition.TRANSITION_NONE) -- 0
      Isaac.DebugString("Exited Boss Rush, moving left to room: " ..
                        tostring(g.run.crawlspace.prevRoom))
    end
  end
end

-- Called in the PostNewRoom callback
function FastTravel:CheckCrawlspaceMiscBugs()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local prevRoomIndex = level:GetPreviousRoomIndex() -- We need the unsafe version here
  local room = game:GetRoom()
  local player = game:GetPlayer(0)

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

    player.Position = level.DungeonReturnPosition
    Isaac.DebugString("Exited a crawlspace in an off-grid room; crawlspace teleport complete.")
  end

  -- For some reason, if we exit and re-enter a crawlspace from a room outside of the grid,
  -- we won't spawn on the ladder, so move there manually (this causes no visual hiccups like the above code does)
  if roomIndex == GridRooms.ROOM_DUNGEON_IDX and -- -4
     level.DungeonReturnRoomIndex < 0 and
     g.run.crawlspace.blackMarket == false then

    player.Position = Vector(120, 160) -- This is the standard starting location at the top of the ladder
    Isaac.DebugString("Entered crawlspace from a room outside the grid; ladder teleport complete.")
  end

  -- When returning to the boss room from a Boss Rush with a crawlspace in it,
  -- we might not end up in a spot where the player expects, so move to the most logical position manually
  if g.run.crawlspace.direction ~= -1 then
    if g.run.crawlspace.direction == Direction.LEFT then -- 0
      -- Returning from the right door
      player.Position = room:GetGridPosition(73)
      Isaac.DebugString("Entered the previous room from a nested crawlspace (going left), teleport complete.")
    elseif g.run.crawlspace.direction == Direction.UP then -- 1
      -- Returning from the bottom door
      player.Position = room:GetGridPosition(112)
      Isaac.DebugString("Entered the previous room from a nested crawlspace (going up), teleport complete.")
    elseif g.run.crawlspace.direction == Direction.RIGHT then -- 2
      -- Returning from the left door
      player.Position = room:GetGridPosition(61)
      Isaac.DebugString("Entered the previous room from a nested crawlspace (going left), teleport complete.")
    elseif g.run.crawlspace.direction == Direction.DOWN then -- 3
      -- Returning from the top door
      player.Position = room:GetGridPosition(22)
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
  local game = Game()
  local room = game:GetRoom()
  local roomType = room:GetType()

  -- Don't do anything if the trapdoor / crawlspace is already open
  if effect.State == 0 then
    return
  end

  -- Don't do anything if it is freshly spawned in a boss room and one or more players are relatively close
  local playerRelativelyClose = false
  for j = 1, game:GetNumPlayers() do
    local player = Isaac.GetPlayer(j - 1)
    if g:InsideSquare(player.Position, effect.Position, FastTravel.trapdoorOpenDistance * 2.5) then
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
  for j = 1, game:GetNumPlayers() do
    local player = Isaac.GetPlayer(j - 1)
    if g:InsideSquare(player.Position, effect.Position, FastTravel.trapdoorOpenDistance) then
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
  local game = Game()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end

  -- Respawn trapdoors, if necessary
  for i = 1, #g.run.replacedTrapdoors do
    if g.run.replacedTrapdoors[i].room == roomIndex then
      FastTravel:RemoveOverlappingGridEntity(g.run.replacedTrapdoors[i].pos, "trapdoor")

      -- Spawn the new custom entity
      local entity
      if roomIndex == GridRooms.ROOM_BLUE_WOOM_IDX then -- -8
        entity = game:Spawn(Isaac.GetEntityTypeByName("Blue Womb Trapdoor (Fast-Travel)"),
                            Isaac.GetEntityVariantByName("Blue Womb Trapdoor (Fast-Travel)"),
                            g.run.replacedTrapdoors[i].pos, Vector(0,0), nil, 0, 0)

      elseif stage == LevelStage.STAGE3_2 or -- 6
             stage == LevelStage.STAGE4_1 then -- 7

        entity = game:Spawn(Isaac.GetEntityTypeByName("Womb Trapdoor (Fast-Travel)"),
                            Isaac.GetEntityVariantByName("Womb Trapdoor (Fast-Travel)"),
                            g.run.replacedTrapdoors[i].pos, Vector(0,0), nil, 0, 0)

      else
        entity = game:Spawn(Isaac.GetEntityTypeByName("Trapdoor (Fast-Travel)"),
                            Isaac.GetEntityVariantByName("Trapdoor (Fast-Travel)"),
                            g.run.replacedTrapdoors[i].pos, Vector(0,0), nil, 0, 0)
      end
      entity.DepthOffset = -101 -- This is needed so that the entity will not appear on top of the player
      -- We use -101 instead of -100 to signify that it is a respawned trapdoor

      -- Figure out if it should spawn open or closed, depending on if one or more players is close to it
      local playerClose = false
      for j = 1, game:GetNumPlayers() do
        local player = Isaac.GetPlayer(j - 1)
        if g:InsideSquare(player.Position, entity.Position, FastTravel.trapdoorOpenDistance) then
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
  for i = 1, #g.run.replacedCrawlspaces do
    if g.run.replacedCrawlspaces[i].room == roomIndex then
      FastTravel:RemoveOverlappingGridEntity(g.run.replacedCrawlspaces[i].pos, "crawlspace")

      -- Spawn the new custom entity
      local entity = game:Spawn(Isaac.GetEntityTypeByName("Crawlspace (Fast-Travel)"),
                                Isaac.GetEntityVariantByName("Crawlspace (Fast-Travel)"),
                                g.run.replacedCrawlspaces[i].pos, Vector(0,0), nil, 0, 0)
      entity.DepthOffset = -100 -- This is needed so that the entity will not appear on top of the player

      -- Figure out if it should spawn open or closed, depending on if one or more players is close to it
      local playerClose = false
      for j = 1, game:GetNumPlayers() do
        local player = Isaac.GetPlayer(j - 1)
        if g:InsideSquare(player.Position, entity.Position, FastTravel.trapdoorOpenDistance) then
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
  for i = 1, #g.run.replacedHeavenDoors do
    if g.run.replacedHeavenDoors[i].room == roomIndex then
      -- Spawn the new custom entity
      local entity = game:Spawn(Isaac.GetEntityTypeByName("Heaven Door (Fast-Travel)"),
                                Isaac.GetEntityVariantByName("Heaven Door (Fast-Travel)"),
                                g.run.replacedHeavenDoors[i].pos, Vector(0,0), nil, 0, 0)
                                -- Use an InitSeed of 0 to signify that it is respawned
      entity.DepthOffset = 15 -- The default offset of 0 is too low, and 15 is just about perfect
      Isaac.DebugString("Respawned heaven door.")
    end
  end
end

-- Remove any grid entities that will overlap with the custom trapdoor/crawlspace
-- (this is needed because rocks/poop will respawn in the room after reentering)
function FastTravel:RemoveOverlappingGridEntity(pos, type)
  -- Local variables
  local game = Game()
  local room = game:GetRoom()

  -- Check for the existance of an overlapping grid entity
  local gridIndex = room:GetGridIndex(pos)
  local gridEntity = room:GetGridEntity(gridIndex)
  if gridEntity == nil then
    return
  end

  -- Remove it
  room:RemoveGridEntity(gridIndex, 0, false) -- entity:Destroy() will only work on destroyable entities like TNT
  Isaac.DebugString("Removed a grid entity at index " .. tostring(gridIndex) ..
                    " that would interfere with the " .. tostring(type) .. ".")

  -- If this was a Corny Poop, it turn the Eternal Fly into an Attack Fly
  local saveState = gridEntity:GetSaveState()
  if saveState.Type == GridEntityType.GRID_POOP and -- 14
     saveState.Variant == 2 then -- Corny Poop

    for i, entity in pairs(Isaac.GetRoomEntities()) do
      if entity.Type == EntityType.ENTITY_ETERNALFLY then -- 96
        entity:Remove()
        Isaac.DebugString("Removed an Eternal Fly associated with the removed Corny Poop.")
      end
    end
  end
end

return FastTravel

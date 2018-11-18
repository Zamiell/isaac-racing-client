local RPRace = {}

-- Includes
local RPGlobals  = require("src/rpglobals")
local RPSpeedrun = require("src/rpspeedrun")
local RPSprites  = require("src/rpsprites")

function RPRace:PostUpdate()
  -- We do not want to return if we are not in a race, as there are also speedrun-related checks in the follow functions

  -- Check to see if we need to start the timers
  if RPGlobals.run.startedTime == 0 then
    RPGlobals.run.startedTime = Isaac.GetTime()
  end

  RPRace:PostUpdateCheckFireworks()
  RPRace:PostUpdateCheckVictoryLap()
  RPRace:PostUpdateCheckFinished()
  RPRace:PostUpdateCheckKeeperHolyMantle()
end

-- Make race winners get sparklies and fireworks
function RPRace:PostUpdateCheckFireworks()
  -- Local variables
  local game = Game()
  local gameFrameCount = game:GetFrameCount()
  local player = game:GetPlayer(0)

  if (RPGlobals.raceVars.finished == true and
      RPGlobals.race.status == "none" and
      RPGlobals.race.place == 1 and
      RPGlobals.race.numEntrants >= 3) or
     RPSpeedrun.finished then

    -- Give Isaac sparkly feet (1000.103.0)
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ULTRA_GREED_BLING, 0,
                player.Position + RandomVector():__mul(10), Vector(0, 0), nil)

    -- Spawn 30 fireworks (1000.104.0)
    -- (some can be duds randomly and not spawn any fireworks after the 20 frame countdown)
    if RPGlobals.raceVars.fireworks < 40 and gameFrameCount % 20 == 0 then
      for i = 1, 5 do
        RPGlobals.raceVars.fireworks = RPGlobals.raceVars.fireworks + 1
        local firework = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIREWORKS, 0,
                                     RPGlobals:GridToPos(math.random(1, 11), math.random(2, 8)),
                                     Vector(0, 0), nil) -- 0,12  0,8
        local fireworkEffect = firework:ToEffect()
        fireworkEffect:SetTimeout(20)
      end
    end
  end
end

-- Check to see if the player just picked up the "Victory Lap" custom item
function RPRace:PostUpdateCheckVictoryLap()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local isaacFrameCount = Isaac.GetFrameCount()

  if player:HasCollectible(CollectibleType.COLLECTIBLE_VICTORY_LAP) == false then
    return
  end

  -- Remove it so that we don't trigger this behavior again on the next frame
  player:RemoveCollectible(CollectibleType.COLLECTIBLE_VICTORY_LAP)

  -- Remove the final place graphic if it is showing
  RPSprites:Init("place2", 0)

  -- Make them float upwards
  -- (the code is loosely copied from the "RPFastTravel:CheckTrapdoorEnter()" function)
  RPGlobals.run.trapdoor.state = 1
  Isaac.DebugString("Trapdoor state: " .. RPGlobals.run.trapdoor.state .. " (from Victory Lap)")
  RPGlobals.run.trapdoor.upwards = true
  RPGlobals.run.trapdoor.frame = isaacFrameCount + 40
  player.ControlsEnabled = false
  player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE -- 0
  -- (this is necessary so that enemy attacks don't move the player while they are doing the jumping animation)
  player.Velocity = Vector(0, 0) -- Remove all of the player's momentum
  player:PlayExtraAnimation("LightTravel")
  RPGlobals.run.currentFloor = RPGlobals.run.currentFloor - 1
  -- This is needed or else state 5 will not correctly trigger
  -- (because the PostNewRoom callback will occur 3 times instead of 2)
  RPGlobals.raceVars.victoryLaps = RPGlobals.raceVars.victoryLaps + 1
end

-- Check to see if the player just picked up the "Finished" custom item
function RPRace:PostUpdateCheckFinished()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)

  if player:HasCollectible(CollectibleType.COLLECTIBLE_FINISHED) == false then
    return
  end

  -- Remove the final place graphic if it is showing
  RPSprites:Init("place2", 0)

  -- No animations will advance once the game is fading out,
  -- and the first frame of the item pickup animation looks very strange,
  -- so just make the player invisible to compensate
  player.Visible = false

  -- If we are playing "R+7 Seeded", turn it off
  RPSpeedrun.inSeededSpeedrun = false

  -- Go back to the title screen
  game:Fadeout(0.0275, RPGlobals.FadeoutTarget.FADEOUT_TITLE_SCREEN) -- 2
end

-- Check to see if Keeper took damage with his temporary Holy Mantle
function RPRace:PostUpdateCheckKeeperHolyMantle()
  -- Local variables
  local game = Game()
  local player = game:GetPlayer(0)
  local effects = player:GetEffects()

  if RPGlobals.run.tempHolyMantle and
     effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE) == false then -- 313

    RPGlobals.run.tempHolyMantle = false
  end
end

-- Called from the PostUpdate callback (the "RPCheckEntities:EntityRaceTrophy()" function)
function RPRace:Finish()
  -- Local variables
  local game = Game()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local room = game:GetRoom()
  local roomSeed = room:GetSpawnSeed() -- Gets a reproducible seed based on the room, something like "2496979501"

  -- Finish the race
  RPGlobals.raceVars.finished = true
  RPGlobals.raceVars.finishedTime = Isaac.GetTime() - RPGlobals.raceVars.startedTime
  RPGlobals.raceVars.finishedFrames = Isaac.GetFrameCount() - RPGlobals.raceVars.startedFrame
  RPGlobals.run.endOfRunText = true -- Show the run summary

  -- Tell the client that the goal was achieved (and the race length)
  Isaac.DebugString("Finished race " .. tostring(RPGlobals.race.id) ..
                    " with time: " .. tostring(RPGlobals.raceVars.finishedTime))

  -- Spawn a Victory Lap custom item in the corner of the room (which emulates Forget Me Now)
  local victoryLapPosition = RPGlobals:GridToPos(11, 1)
  if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then
    victoryLapPosition = RPGlobals:GridToPos(11, 6) -- A Y of 1 is out of bounds inside of the Mega Satan room
  end
  game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, victoryLapPosition, Vector(0, 0),
             nil, CollectibleType.COLLECTIBLE_VICTORY_LAP, roomSeed)

  -- Spawn a "Finished" custom item in the corner of the room (which takes you to the main menu)
  local finishedPosition = RPGlobals:GridToPos(1, 1)
  if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then
    finishedPosition = RPGlobals:GridToPos(1, 6) -- A Y of 1 is out of bounds inside of the Mega Satan room
  end
  local item2seed = RPGlobals:IncrementRNG(roomSeed)
  game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, finishedPosition, Vector(0, 0),
             nil, CollectibleType.COLLECTIBLE_FINISHED, item2seed)

  Isaac.DebugString("Spawned a Victory Lap / Finished in the corners of the room.")
end

return RPRace

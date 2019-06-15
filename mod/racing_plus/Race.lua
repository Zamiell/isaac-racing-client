local Race = {}

-- Includes
local g           = require("racing_plus/globals")
local FastTravel  = require("racing_plus/fasttravel")
local Speedrun    = require("racing_plus/speedrun")
local Sprites     = require("racing_plus/sprites")
local SeededDeath = require("racing_plus/seededdeath")

function Race:PostUpdate()
  -- We do not want to return if we are not in a race, as there are also speedrun-related checks in the follow functions
  Race:PostUpdateCheckBossRush()
  Race:PostUpdateCheckFireworks()
  Race:PostUpdateCheckVictoryLap()
  Race:PostUpdateCheckFinished()
  Race:PostUpdateCheckKeeperHolyMantle()
  SeededDeath:PostUpdate()
end

function Race:PostUpdateCheckBossRush()
  if g.run.finishedBossRush or
     g.race.status ~= "in progress" or
     g.race.goal ~= "Boss Rush" or
     not g.g:GetStateFlag(GameStateFlag.STATE_BOSSRUSH_DONE) then

    return
  end

  g.run.finishedBossRush = true
  local pos = g.r:FindFreePickupSpawnPosition(g.r:GetCenterPos(), 1, true)
  g.g:Spawn(EntityType.ENTITY_RACE_TROPHY, 0, pos, g.zeroVector, nil, 0, 0)
  Isaac.DebugString("Spawned the end of Boss Rush trophy.")
end

-- Make race winners get sparklies and fireworks
function Race:PostUpdateCheckFireworks()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()

  -- Make fireworks quieter
  if Isaac.CountEntities(nil, EntityType.ENTITY_EFFECT, EffectVariant.FIREWORKS, -1) > 0 and -- 1000.104
     g.sfx:IsPlaying(SoundEffect.SOUND_BOSS1_EXPLOSIONS) then -- 182

    g.sfx:AdjustVolume(SoundEffect.SOUND_BOSS1_EXPLOSIONS, 0.2)
  end

  -- Do something special for a first place finish (or a speedrun completion)
  if (g.raceVars.finished == true and
      g.race.status == "none" and
      g.race.place == 1 and
      g.race.numEntrants >= 3) or
     Speedrun.finished then

    -- Give Isaac sparkly feet (1000.103.0)
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ULTRA_GREED_BLING, 0,
                g.p.Position + RandomVector():__mul(10), g.zeroVector, nil)

    -- Spawn 30 fireworks (1000.104.0)
    -- (some can be duds randomly and not spawn any fireworks after the 20 frame countdown)
    if g.raceVars.fireworks < 40 and gameFrameCount % 20 == 0 then
      for i = 1, 5 do
        g.raceVars.fireworks = g.raceVars.fireworks + 1
        local firework = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIREWORKS, 0, -- 1000.104
                                     g:GridToPos(math.random(1, 11), math.random(2, 8)),
                                     g.zeroVector, nil)
        local fireworkEffect = firework:ToEffect()
        fireworkEffect:SetTimeout(20)
      end
    end
  end
end

-- Check to see if the player just picked up the "Victory Lap" custom item
function Race:PostUpdateCheckVictoryLap()
  -- Local variables
  local isaacFrameCount = Isaac.GetFrameCount()

  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_VICTORY_LAP) then
    return
  end

  -- Remove it so that we don't trigger this behavior again on the next frame
  g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_VICTORY_LAP)

  -- Remove the final place graphic if it is showing
  Sprites:Init("place2", 0)

  -- Make them float upwards
  -- (the code is loosely copied from the "FastTravel:CheckTrapdoorEnter()" function)
  g.run.trapdoor.state = FastTravel.state.PLAYER_ANIMATION
  g.run.trapdoor.upwards = true
  g.run.trapdoor.frame = isaacFrameCount + 40
  g.p.ControlsEnabled = false
  g.p.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE -- 0
  -- (this is necessary so that enemy attacks don't move the player while they are doing the jumping animation)
  g.p.Velocity = g.zeroVector -- Remove all of the player's momentum
  g.p:PlayExtraAnimation("LightTravel")
  g.run.currentFloor = g.run.currentFloor - 1
  -- This is needed or else state 5 will not correctly trigger
  -- (because the PostNewRoom callback will occur 3 times instead of 2)
  g.raceVars.victoryLaps = g.raceVars.victoryLaps + 1
end

-- Check to see if the player just picked up the "Finished" custom item
function Race:PostUpdateCheckFinished()
  if not g.p:HasCollectible(CollectibleType.COLLECTIBLE_FINISHED) then
    return
  end

  -- Remove the final place graphic if it is showing
  Sprites:Init("place2", 0)

  -- No animations will advance once the game is fading out,
  -- and the first frame of the item pickup animation looks very strange,
  -- so just make the player invisible to compensate
  g.p.Visible = false

  -- If we are playing "R+7 Seeded", turn it off
  Speedrun.inSeededSpeedrun = false

  -- Go back to the title screen
  g.g:Fadeout(0.0275, g.FadeoutTarget.FADEOUT_TITLE_SCREEN) -- 2
end

-- Check to see if Keeper took damage with his temporary Holy Mantle
function Race:PostUpdateCheckKeeperHolyMantle()
  -- Local variables
  local effects = g.p:GetEffects()

  if g.run.tempHolyMantle and
     not effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE) then -- 313

    g.run.tempHolyMantle = false
  end
end

-- Called from the PostUpdate callback (the "CheckEntities:EntityRaceTrophy()" function)
function Race:Finish()
  -- Local variables
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end
  local roomSeed = g.r:GetSpawnSeed() -- Gets a reproducible seed based on the room, e.g. "2496979501"

  -- Finish the race
  g.raceVars.finished = true
  g.raceVars.finishedTime = Isaac.GetTime() - g.raceVars.startedTime
  g.raceVars.finishedFrames = Isaac.GetFrameCount() - g.raceVars.startedFrame
  g.run.endOfRunText = true -- Show the run summary

  -- Tell the client that the goal was achieved (and the race length)
  Isaac.DebugString("Finished race " .. tostring(g.race.id) ..
                    " with time: " .. tostring(g.raceVars.finishedTime))

  -- Spawn a Victory Lap custom item in the corner of the room (which emulates Forget Me Now)
  local victoryLapPosition = g:GridToPos(11, 1)
  if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then
    victoryLapPosition = g:GridToPos(11, 6) -- A Y of 1 is out of bounds inside of the Mega Satan room
  end
  g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, victoryLapPosition, g.zeroVector,
            nil, CollectibleType.COLLECTIBLE_VICTORY_LAP, roomSeed)

  -- Spawn a "Finished" custom item in the corner of the room (which takes you to the main menu)
  local finishedPosition = g:GridToPos(1, 1)
  if roomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then
    finishedPosition = g:GridToPos(1, 6) -- A Y of 1 is out of bounds inside of the Mega Satan room
  end
  local item2seed = g:IncrementRNG(roomSeed)
  g.g:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, finishedPosition, g.zeroVector,
            nil, CollectibleType.COLLECTIBLE_FINISHED, item2seed)

  Isaac.DebugString("Spawned a Victory Lap / Finished in the corners of the room.")
end

function Race:CheckBanB1TreasureRoom()
  -- Local variables
  local stage = g.l:GetStage()
  local challenge = Isaac.GetChallenge()

  return stage == 1 and
         (g.race.rFormat == "seeded" or
          challenge == Isaac.GetChallengeIdByName("R+7 (Season 4)") or
          (challenge == Isaac.GetChallengeIdByName("R+7 (Season 5)") and
           Speedrun.charNum >= 2) or
          challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)") or
          challenge == Isaac.GetChallengeIdByName("R+7 (Season 7 Beta)"))
end

return Race

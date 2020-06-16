local RacePostUpdate = {}

-- Includes
local g               = require("racing_plus/globals")
local Race            = require("racing_plus/race")
local Speedrun        = require("racing_plus/speedrun")
local Sprites         = require("racing_plus/sprites")
local SeededDeath     = require("racing_plus/seededdeath")
local PotatoDummy     = require("racing_plus/potatodummy")
local RacePostNewRoom = require("racing_plus/racepostnewroom")

function RacePostUpdate:Main()
  -- We do not want to return if we are not in a race, as there are also speedrun-related checks in the follow functions
  RacePostUpdate:Check3DollarBill()
  RacePostUpdate:CheckFireworks()
  RacePostUpdate:CheckKeeperHolyMantle()
  RacePostUpdate:CheckFinalRoom()
  SeededDeath:PostUpdate()
end

function RacePostUpdate:Check3DollarBill()
  if g.race.status == "in progress" and
     g.race.rFormat == "seeded" and
     g.p:HasCollectible(CollectibleType.COLLECTIBLE_3_DOLLAR_BILL) then -- 191

    g.p:RemoveCollectible(CollectibleType.COLLECTIBLE_3_DOLLAR_BILL) -- 191
    Isaac.DebugString("Removing collectible " .. tostring(CollectibleType.COLLECTIBLE_3_DOLLAR_BILL)) -- 191
    g.p:AddCollectible(CollectibleType.COLLECTIBLE_3_DOLLAR_BILL_SEEDED, 0, false)
    Isaac.DebugString("Activated the custom 3 Dollar Bill for seeded races.")

    -- Activate a new effect for it (pretending that we just walked into a new room)
    RacePostNewRoom:ThreeDollarBill()
  end
end

-- Make race winners get sparklies and fireworks
function RacePostUpdate:CheckFireworks()
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

-- Check to see if Keeper took damage with his temporary Holy Mantle
function RacePostUpdate:CheckKeeperHolyMantle()
  -- Local variables
  local effects = g.p:GetEffects()

  if g.run.tempHolyMantle and
     not effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE) then -- 313

    g.run.tempHolyMantle = false
  end
end

function RacePostUpdate:CheckFinalRoom()
  if not g.raceVars.finished then
    return
  end

  -- Local variables
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end
  local roomFrameCount = g.r:GetFrameCount()

  if roomFrameCount ~= 1 then
    return
  end

  for _, button in ipairs(g.run.buttons) do
    if button.roomIndex == roomIndex then
      Sprites:Init(button.type .. "-button", button.type .. "-button")

      -- The buttons will cause the door to close, so re-open the door
      -- (thankfully, the door will stay open since the room is already cleared)
      g:OpenDoors()
    end
  end
end

function RacePostUpdate:CheckFinalButtons(gridEntity, i)
  if not g.raceVars.finished then
    return
  end

  -- Local variables
  local roomIndex = g.l:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = g.l:GetCurrentRoomIndex()
  end

  for _, button in ipairs(g.run.buttons) do
    if button.type == "victory-lap" and
       button.roomIndex == roomIndex then

      if gridEntity:GetSaveState().State == 3 and
         gridEntity.Position.X == button.pos.X and
         gridEntity.Position.Y == button.pos.Y then

        Sprites:Init(button.type .. "-button", 0)
        g.r:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work

        Race:VictoryLap()
      end
    end

    if button.type == "dps" and
       button.roomIndex == roomIndex then

      if gridEntity:GetSaveState().State == 3 and
         gridEntity.Position.X == button.pos.X and
         gridEntity.Position.Y == button.pos.Y then

        Sprites:Init(button.type .. "-button", 0)
        g.r:RemoveGridEntity(i, 0, false) -- gridEntity:Destroy() does not work

        -- Disable this button
        button.roomIndex = 999999

        -- Spawn a Potato Dummy
        --Isaac.Spawn(EntityType.ENTITY_NERVE_ENDING, 2, 1, g.r:GetCenterPos(), g.zeroVector, nil) -- 231
        PotatoDummy:Spawn()
      end
    end
  end
end

return RacePostUpdate

local Mahalath = {}

-- Mahalath was originally created by melon goodposter
-- It is heavily modified by Zamiel for Racing+
-- (and to pass the linter)

local game = Game()
local sfx = SFXManager()
local rng = RNG()

local barf = {
  girl = {
    Type = Isaac.GetEntityTypeByName("Mahalath")
  },
  mouth = {
    Type = Isaac.GetEntityTypeByName("Barf Mouth")
  },
  ball = {
    Type = Isaac.GetEntityTypeByName("Barf Ball")
  },
  bomb = {
    Type = Isaac.GetEntityTypeByName("Barf Bomb")
  },
  suction = {
    Variant = Isaac.GetEntityVariantByName("Suction Ring")
  },
  altsprite = "gfx/bosses/mahalath2.png",
  girls = {},
  mouths = {},
  balls = {},
  bombs = {},
  particles = {},
  tears = {}
}

local barfballs = 0
local barfbombs = 0
local delfight = false

-- In Racing+ we modify the level 1 balance values
-- (the original values are noted in a comment next to each value)
local bal = {
  barfcolor = {Color(132 / 255, 188 / 255, 88 / 255, 1, 0, 0, 0), Color(138 / 255, 36 / 255, 49 / 255, 1, 0, 0, 0)},
  bloodcolor = {Color(215 / 255, 10 / 255, 10 / 255, 1, 0, 0, 0), Color(15 / 255, 15 / 255, 15 / 255, 1, 0, 0, 0)},
  creeptype = {23, 22},

  RegBallHitSpeed = {7, 7}, -- 5
  JumpSpeed = {12, 12}, -- 10
  BoredomLimit = 6,
  FirstState = {'queasy', 'queasy'}, -- idle
  T2HealthBuff = 0,
  TransformPercent = {.6, .55},
  IdleRetargetRate = {50, 20}, -- 50 / 20
  -- How many frames she waits when she's idle between attacks to pick a new spot to move to
  ShotgunIdleTime = {18, 7}, -- 18 / 7
  ShotgunIdleVariance = {4, 4}, -- 10
  T2ExtraShotgunRate = 35,
  ShotgunSpreadMax = {105, 105}, -- 65
  SpinBarfTime = {60, 60}, -- 120
  SpinBarfFireRate = {2, 2}, -- 3
  SpinBarfRotation = {274, 274}, -- 125
  BallKnockerHitLimit = {8, 8}, -- 5
  BaseballIdleTime = {20, 5}, -- 20 / 5
  BarfBallsIdleTime = {50, 10}, -- 50 / 10
  ShootBallIdleTime = {25, 5}, -- 25 / 5
  BarfBubbleSize = {1.75, 1.75}, -- 1.5
  SpitTearSpeed = {11, 11}, -- 3
  SpitTearAngle = {22, 22}, -- 30
  ShootBallSpeed = {6, 6}, -- 5
  SuckMaxSuck = {240, 240}, -- 220
  SuckIncreaseRate = {1.3, 1.3}, -- 1
  ShotgunHomingRate = {.18, .18}, -- .09
  T2BallSpeedTarget = 2.2,
  MoveAvoidAccel = {.7, .7}, -- .4
  MoveMouthBlockRange = {140, 140}, -- 220
  MoveAlignXAccel = {.45, .45}, -- .25
  MoveSlowFollowSpeed = {7, 7}, -- 4
  MoveBouncyChaseSpeed = {3, 4}, -- 4 (keep lowered)
  MoveBallKnockerAccel = {1.3, 1.3}, -- 1.2
  MoveBallKnockerSpeed = {5.5, 5.5}, -- 5
  MoveBallKnockerACorrect = {6, 6}, -- 4.2
  BallKnockSpeed = {7, 11}, -- 8; Soccer speed (keep lowered)
  T2ShotgunBallShootSpeed = 4.5,
}

local sound = {
  balloon_inflate = Isaac.GetSoundIdByName("Balloon Inflate"),
  baseball = Isaac.GetSoundIdByName("Baseball"),
  muffled_explosion = Isaac.GetSoundIdByName("Muffled Explosion")
}

local mouthSprite = Sprite()
mouthSprite:Load("gfx/grid/door_11_wombhole.anm2", false)
mouthSprite:ReplaceSpritesheet(0, "gfx/bosses/mahalath_mouth.png")
mouthSprite:LoadGraphics()

local function Lerp(first, second, percent)
  return (first + (second - first) * percent)
end

local function checkpunt(pos, ppos)
  local result = 0
  for i, ball in ipairs(barf.balls) do
    local dist = (pos - ball.Position):Length()
    if dist > 60 and dist < 135 then
      local pdist1 = (ppos - ball.Position):Length()
      local pdist2 = (ppos - pos):Length()
      if pdist2 - 75 > pdist1 then
        result = ball
      end
    end
  end
  return result
end

local function angdif(pos1, pos2, pos3)
  local ang1 = (pos2 - pos1):GetAngleDegrees()
  local ang2 = (pos3 - pos1):GetAngleDegrees()
  return math.abs(((ang2 - ang1) + 180) % 360 - 180)
end

local function getAddress(p)
  return p
  --local addr = tonumber(string.sub(tostring(p), 11), 16)
  --return addr + 8
end

--mahalath aka barf girl
function Mahalath:check_girl(en)
  local player = Isaac.GetPlayer(0)
  local d = en:GetData()
  local s = en:GetSprite()
  local pos = en.Position
  local vel = en.Velocity
  local ppos = player.Position
  local toplr = (ppos - pos):Normalized()
  local toplra = toplr:GetAngleDegrees()

  --INIT
  if d.state == nil then
    --en:SetColor(BaseColor, 1, -1000000, false, false)
    en.GridCollisionClass = GridCollisionClass.COLLISION_SOLID
    d.state = 'intro'
    d.statetime = 0
    d.laststate = 'none'
    d.idletime = 30
    d.move = 'stay'
    d.lastmove = 'none'
    d.dest = pos
    d.checktime = 0

    d.v = 1
    d.fighting = false
    d.ballskilled = 0
    d.puntball = 0
    d.hitball = false

    d.startmass = en.Mass
    d.shotguns = 2 + rng:RandomInt(2)
    d.sgdir = 1

    if en.Variant ~= 0 then
      d.v = 2
    end

    if d.v == 2 then
      for i = 0, 4 do
        s:ReplaceSpritesheet(i, barf.altsprite)
      end
      s:LoadGraphics()
    end
  end

  --State Timer
  if d.state ~= d.laststate then
    d.laststate = d.state
    d.statetime = 0
    d.checktime = 0
  else
    d.statetime = d.statetime + 1
  end
  --BASE BEHAVIOR
  en.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
  --balls
  d.ballhit = nil
  for i, ball in ipairs(barf.balls) do
    if ball:Exists() then
      local size = ball.Size
      if ball:GetData().size then size = ball:GetData().size end
      if (ball.Position - pos):Length() < en.Size + size + 6 and not d.jumping then
        if s:IsPlaying("Spin") or s:IsPlaying("Spin2") then
          ball:GetSprite():Play("Pulse")
          sfx:Play(SoundEffect.SOUND_BOSS2_BUBBLES, .66, 0, false, 1.4)
          d.ballhit = ball
          ball:GetData().hittimer = ball.FrameCount
          if d.state ~= 'ballknocker' then
            ball.Velocity = (ball.Position - pos):Normalized() * bal.RegBallHitSpeed[d.v]
          end
        end
      end
    end
  end
  --move
  Mahalath:move_me(en)
  --jumps
  d.jumping = false
  d.landed = false
  if d.jump == true then
    if d.jumparc == nil then
      d.jumparc = Vector(45, 0)
    end
    d.jumparc = d.jumparc:Rotated(-bal.JumpSpeed[d.v])
    if d.jumparc.Y >= 0 then
      d.jump = false
      d.jumparc = nil
      en.PositionOffset = Vector(0, 0)
      d.landed = true
    else
      en.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
      d.jumping = true
      en.PositionOffset = Vector(0, d.jumparc.Y)
    end
  end
  --mouth check
  if d.mouth and not d.mouth:Exists() then
    d.mouth = nil
  end
  --death check
  if not delfight then
    if not d.mouth and en.HitPoints < 60 then
      d.killed = true
    end
    if en.FrameCount > 30 * 60 * bal.BoredomLimit then
      if not d.mouth then
        d.state = 'transform'
      end
      d.killed = true
    end
    if d.killed then
      if d.state ~= 'transform' and d.state ~= 'baseball' and d.state ~= 'atebomb' then
        if not d.mouth then
          d.state = 'barfdeath'
        else
          d.state = 'escape'
        end
      end
    end
  end
  --INTRO
  if d.state == 'intro' then
    d.move = 'stay'
    if s:IsFinished("Appear") then
      d.state = bal.FirstState[d.v]
      d.idletime = 10
    end
    --IDLE
  elseif d.state == 'idle' then
    --transform check
    if d.mouth == nil and en.HitPoints < en.MaxHitPoints * bal.TransformPercent[d.v] and not delfight then
      d.state = 'transform'
    end
    --base
    if not d.mouth then
      s:Play("Idle")
    elseif d.mouth:GetData().state == 'eat' then
      s:Play("Laugh2")
    else
      s:Play("Idle2")
    end
    d.move = 'avoid'
    if d.statetime % bal.IdleRetargetRate[d.v] == 0 then
      d.retarget = true
    end
    --finish
    if d.statetime >= d.idletime and (d.mouth == nil or d.mouth:GetData().state ~= 'eat') then
      if d.shotguns > 0 then
        d.state = 'shotgun'
      else
        d.shotguns = 2 + rng:RandomInt(2)
        local rand = rng:RandomInt(100)
        if not d.mouth then
          if (barfballs > 1 and rand > 20) or (barfballs == 1 and rand < 20) then
            d.state = 'ballknocker'
          else
            d.state = 'spinbarf'
          end
        else
          if (barfballs > 1 or (barfballs == 1 and rand > 33)) then
            d.state = 'ballknocker'
          else
            d.state = 'spinbarf'
          end
        end
      end
    end
    --TRANSFORM
  elseif d.state == 'transform' then
    --start
    if d.statetime == 0 then
      d.move = 'avoid'
      s:Play("Laugh")
    end
    if d.statetime == 20 then
      s:Play("MouthOff")
    end
    --spawn
    if d.statetime == 28 then
      sfx:Play(SoundEffect.SOUND_SHELLGAME, 1, 0, false, 1)
    end
    if d.statetime == 28 then
      d.mouth = Isaac.Spawn(barf.mouth.Type, 0, 0, pos + Vector(0, 25), Vector(0, 0), en)
      d.mouth:GetData().girl = en
      if d.v == 2 then
        d.mouth:GetSprite():ReplaceSpritesheet(0, barf.altsprite)
        d.mouth:GetSprite():ReplaceSpritesheet(1, barf.altsprite)
        d.mouth:GetSprite():LoadGraphics()
      end
    end
    --finish
    if s:IsFinished("MouthOff") then
      d.state = 'shotgun'
    end
    --BARF DEATH
  elseif d.state == 'barfdeath' then
    Isaac.DebugString("Manually killing Mahalath (barfdeath).")
    en:Kill()

    if d.statetime == 0 then
      d.move = 'alignx'
      s:Play("Queasy")
    end
    if s:IsFinished("Queasy") then
      s:Play("Blood")
    end
    if s:IsPlaying("Blood") then
      d.move = 'nil'
      if en.HitPoints > 1 then
        en:TakeDamage(1, 0, EntityRef(player), 0)
      end
      local frame = s:GetFrame()
      if frame >= 3 and frame <= 67 then
        sfx:Play(SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
        local params = ProjectileParams()
        params.FallingSpeedModifier = -5 - (math.random() * 5)
        params.FallingAccelModifier = 1
        params.Variant = 4
        params.PositionOffset = Vector(0, - 45)
        params.BulletFlags = 8192
        local div = math.min(45, math.max(15, frame)) / 60
        local red = Lerp(bal.barfcolor[d.v].R, bal.bloodcolor[d.v].R, div)
        local green = Lerp(bal.barfcolor[d.v].G, bal.bloodcolor[d.v].G, div)
        local blue = Lerp(bal.barfcolor[d.v].B, bal.bloodcolor[d.v].B, div)
        params.Color = Color(red, green, blue, 1, 0, 0, 0)
        en:FireProjectiles(en.Position + Vector(0, 35),
          Vector(0, 7.5) + (Vector.FromAngle(math.random(360)) * (math.random() * 2)),
        0, getAddress(params))
        en.Velocity = en.Velocity + Vector(0, - .7)
      end
    end
    if s:IsFinished("Blood") then
      sfx:Play(SoundEffect.SOUND_DEATH_BURST_SMALL, 1.3, 0, false, 1)
      en:BloodExplode()
      en:Kill()
    end
    --EAT DEATH
  elseif d.state == 'escape' then
    Isaac.DebugString("Manually killing Mahalath (escape).")
    en:Kill()

    d.move = ''
    local ms = d.mouth:GetSprite()
    local tomouth = d.mouth.Position - pos
    local len = tomouth:Length()
    en.Velocity = Lerp(en.Velocity, tomouth:Normalized() * (math.min(len, 10)), .1)
    if d.statetime == 0 then
      d.mouth:GetData().state = 'eatgirl'
      d.mouth:GetData().move = 'stop'
      ms:Play("Idle")
      s:Play("Idle2")
    end
    if d.statetime >= 30 and (d.mouth.Position - pos):Length() < 12 then
      s:Play("Eaten")
      en.Velocity = Lerp(en.Velocity, tomouth:Normalized() * len, .5)
    end
    if s:IsPlaying("Eaten") and s:GetFrame() == 24 then
      sfx:Play(SoundEffect.SOUND_SHELLGAME, 1, 0, false, 1)
    end
    if s:IsFinished("Eaten") then
      if not d.eaten then
        d.eaten = true
        sfx:Play(SoundEffect.SOUND_MEAT_FEET_SLOW0, 1, 0, false, .8)
        en.Scale = 0
        local angle
        local params = ProjectileParams()
        params.FallingAccelModifier = 1.2
        params.Color = bal.barfcolor[d.v]
        params.Variant = 4
        for i = 1, 360, 360 / 6 do
          params.FallingSpeedModifier = -11 - math.random(3)
          angle = i + math.random(20)
          en:FireProjectiles(en.Position, Vector.FromAngle(angle) * (1.5 + (math.random() * 1)), 0, getAddress(params))
        end
        sfx:Play(SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
        sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 1, 0, false, 1.1)
      end
      ms:Play("Vanish2")
    end
    if ms:IsFinished("Vanish2") then
      sfx:Play(SoundEffect.SOUND_VAMP_GULP, 1, 0, false, 1.1)
      d.mouth:Remove()
      en:Remove()
    end
    --SHOTGUN
  elseif d.state == 'shotgun' then
    d.move = 'avoid'
    --start
    if d.statetime == 0 then
      d.shotguns = d.shotguns - 1
      d.sgdir = d.sgdir * - 1
      if d.sgdir == -1 then
        if not d.mouth then s:Play("ShotgunRight", false)
        else s:Play("ShotgunRight2") end
      else
        if not d.mouth then s:Play("ShotgunLeft", false)
        else s:Play("ShotgunLeft2") end
      end
    end
    --attack
    if s:IsEventTriggered("ShotgunLeft") or s:IsEventTriggered("ShotgunRight") then
      sfx:Play(SoundEffect.SOUND_BLOODSHOOT, .4, 0, false, 1)
      for i = 25 * d.sgdir, bal.ShotgunSpreadMax[d.v] * d.sgdir, 20 * d.sgdir do
        local sgtear = Isaac.Spawn(9, 4, 0, pos, Vector.FromAngle(toplra + i) * 12, en)
        local dir = (ppos - pos):Normalized()
        local dist = (ppos - pos):Length()
        sgtear.Color = bal.barfcolor[d.v]
        sgtear:GetData().behavior = 'homing'
        sgtear:GetData().tgt = pos + (dir * math.max(dist, 60))
        sgtear:GetData().homerate = bal.ShotgunHomingRate[d.v]
        table.insert(barf.tears, sgtear)
      end
      if d.v == 2 and not d.mouth and barfballs > 0 then
        sfx:Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1.5, 0, false, 1)
        for i, ball in ipairs(barf.balls) do
          ball:GetSprite():Play("Pulse")
          ball.Velocity = (ppos - ball.Position):Normalized() * bal.T2ShotgunBallShootSpeed
        end
      end
    end
    --finish
    if s:IsFinished("ShotgunLeft") or
    s:IsFinished("ShotgunRight") or
    s:IsFinished("ShotgunLeft2") or
    s:IsFinished("ShotgunRight2") then

      d.state = 'idle'
      d.idletime = bal.ShotgunIdleTime[d.v] + rng:RandomInt(bal.ShotgunIdleVariance[d.v])
      if d.v == 2 then
        if rng:RandomInt(100) < bal.T2ExtraShotgunRate then
          d.shotguns = d.shotguns + 1
        end
      end
      if d.mouth then
        if d.shotguns == 0 then
          d.idletime = d.idletime + 15
        end
        d.mouth:GetData().state = 'spit'
      end
    end
    --SPIN BARF
  elseif d.state == 'spinbarf' then
    --start
    if d.statetime == 0 then
      d.spinshot = rng:RandomInt(360)
      d.spintime = bal.SpinBarfTime[d.v] + rng:RandomInt(90)
      if not d.mouth then s:Play("PreSpin")
      else s:Play("PreSpin2") end
      if d.mouth then
        d.mouth:GetData().state = 'spinbarf'
      end
    end
    if s:IsFinished("PreSpin") or s:IsFinished("PreSpin2") then
      if not d.mouth then s:Play("Spin")
      else s:Play("Spin2") end
      if not d.mouth then
        d.move = 'blockmiddle'
      else
        d.move = 'bouncychase'
      end
    end
    --attack
    if s:IsPlaying("Spin") or s:IsPlaying("Spin2") then
      if d.statetime % bal.SpinBarfFireRate[d.v] == 0 and not d.mouth then
        sfx:Play(SoundEffect.SOUND_BLOODSHOOT, .4, 0, false, 1)
        local sptear = Isaac.Spawn(9, 4, 0, pos + Vector(0, 15), Vector.FromAngle(d.spinshot) * 7, en)
        sptear.Color = bal.barfcolor[d.v]
        sptear:GetData().behavior = 'spin'
        table.insert(barf.tears, sptear)
        d.spinshot = d.spinshot + bal.SpinBarfRotation[d.v]
      end
    end
    --finish
    if d.statetime == d.spintime then
      if not d.mouth then s:Play("PostSpin")
      else s:Play("PostSpin2") end
    end
    if s:IsFinished("PostSpin") or s:IsFinished("PostSpin2") then
      d.state = 'queasy'
      if d.mouth then
        d.mouth:GetData().state = 'idle'
      end
    end
    --BALL KNOCKER
  elseif d.state == 'ballknocker' then
    if d.mouth then
      if d.mouth:GetData().state == 'eat' then
        d.state = 'idle'
        s:Play("PostSpin2")
      elseif d.mouth:GetData().state == 'baseball' then
        d.state = 'baseball'
        s:Play("PostSpin2")
      elseif d.mouth:GetData().state == 'atebomb' then
        d.state = 'atebomb'
        s:Play("PostSpin2")
      end
    end
    --start
    if d.statetime == 0 then
      d.goodhits = 0
      if d.mouth then
        d.mouth:GetData().state = 'suck'
      end
      if not d.mouth then s:Play("PreSpin")
      else s:Play("PreSpin2") end
    end
    if s:IsFinished("PreSpin") or s:IsFinished("PreSpin2") then
      if not d.mouth then s:Play("Spin")
      else s:Play("Spin2") end
      d.jump = true
    end
    --ball tracking
    if barfballs == 0 and barfbombs == 0 then
      d.checktime = d.checktime + 1
      d.move = 'avoid'
    else
      d.checktime = 0
    end
    if d.mouth and barfballs == 0 and barfbombs > 0 then
      d.move = 'baseball'
    end
    --attack
    if s:IsPlaying("Spin") or s:IsPlaying("Spin2") then
      if d.mouth and d.goodhits >= bal.BallKnockerHitLimit[d.v] then
        d.balltgt = d.mouth.Position + Vector(0, 15)
        d.mouth:GetData().finisheat = true
      else
        d.balltgt = ppos + player.Velocity
      end
      if d.jumping then
        d.move = 'slowdown'
      elseif barfballs > 0 then
        d.move = 'ballknocker'
      end
      if d.ballhit ~= nil then
        en.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        d.jump = true
        en.Velocity = (pos - d.ballhit.Position):Normalized() * 8
      end
      if not d.mouth then
        if barfballs == 0 or d.goodhits > bal.BallKnockerHitLimit[d.v] then
          d.move = 'slowdown'
          s:Play("PostSpin")
        end
      elseif d.checktime > 30 then
        d.move = 'slowdown'
        s:Play("PostSpin2")
      end
      if d.statetime >= 30 * 24 and d.landed then
        if not d.mouth then s:Play("PostSpin")
        else s:Play("PostSpin2") end
      end
    end
    --finish
    if s:IsFinished("PostSpin") or s:IsFinished("PostSpin2") then
      d.state = 'queasy'
    end
    --BASEBALL
  elseif d.state == 'baseball' then
    if d.statetime == 0 then
      d.move = 'baseball'
    end
    local ms = d.mouth:GetSprite()
    if ms:IsEventTriggered("EatBarf") then
      d.move = 'stop'
      sfx:Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1.5, 0, false, 1)
      sfx:Play(SoundEffect.SOUND_LITTLE_SPIT, 1, 0, false, 1.8)
      local bbomb = Isaac.Spawn(barf.bomb.Type, 0, 0, d.mouth.Position + Vector(0, 15), en.Velocity, en):ToNPC()
      bbomb.State = 4
      bbomb:GetData().launch = 1
      bbomb:GetData().girl = en
      bbomb:GetData().nosuck = true
      bbomb:GetSprite():Play("Launch")
      d.checktime = d.statetime
      d.batbomb = bbomb
      bbomb.GridCollisionClass = GridCollisionClass.COLLISION_SOLID
      bbomb.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
      if d.v == 2 then
        bbomb:GetSprite():ReplaceSpritesheet(0, barf.altsprite)
        bbomb:GetSprite():ReplaceSpritesheet(1, barf.altsprite)
        bbomb:GetSprite():LoadGraphics()
      end
    end
    if d.checktime ~= 0 then
      if not d.batbomb or not d.batbomb:Exists() or not d.batbomb:GetData().launch then
        d.state = 'idle'; d.mouth:GetData().state = 'idle'
      end
      local timer = d.statetime - d.checktime
      if timer < 27 then
        local mpos = d.mouth.Position + Vector(0, 15)
        local bpos = Lerp(mpos, pos, timer / 27)
        d.batbomb.Velocity = bpos - d.batbomb.Position
        if timer == 9 then
          s:Play("ShotgunRight2")
        end
      end
      if timer == 27 then
        sfx:Play(sound.baseball, 1, 0, false, 1)
        if d.v == 1 then
          local vel2 = (ppos + player.Velocity - d.batbomb.Position):Normalized() * 13
          local bbomb = Isaac.Spawn(barf.bomb.Type, 0, 0, d.batbomb.Position, vel2, en):ToNPC()
          bbomb:GetData().whacked = true
          bbomb:GetData().girl = en
          bbomb:GetData().nosuck = true
          bbomb.State = 4
          bbomb.GridCollisionClass = GridCollisionClass.COLLISION_SOLID
          bbomb.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
          if d.v == 2 then
            bbomb:GetSprite():ReplaceSpritesheet(0, barf.altsprite)
            bbomb:GetSprite():ReplaceSpritesheet(1, barf.altsprite)
            bbomb:GetSprite():LoadGraphics()
          end
        else
          for i = -15, 15, 15 do
            local vel2 = (ppos + player.Velocity - d.batbomb.Position):Normalized() * 13
            vel2 = vel2:Rotated(i)
            local bbomb = Isaac.Spawn(barf.bomb.Type, 0, 0, d.batbomb.Position, vel2, en):ToNPC()
            bbomb:GetData().girl = en
            bbomb:GetData().nosuck = true
            bbomb.Scale = .7
            bbomb.State = 4
            bbomb.GridCollisionClass = GridCollisionClass.COLLISION_SOLID
            bbomb.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            if d.v == 2 then
              bbomb:GetSprite():ReplaceSpritesheet(0, barf.altsprite)
              bbomb:GetSprite():ReplaceSpritesheet(1, barf.altsprite)
              bbomb:GetSprite():LoadGraphics()
            end
          end
        end
        d.batbomb:Remove()
      end
      if timer == 30 then
        d.state = 'idle'
        d.mouth:GetData().state = 'idle'
        d.idletime = bal.BaseballIdleTime[d.v]
      end
    end
    if s:IsFinished("ShotgunRight2") then
      s:Play("Laugh2")
    end
    --ATE BOMB
  elseif d.state == 'atebomb' then
    if d.statetime == 0 then
      d.move = 'slowdown'
      s:Play("Idle2")
    end
    if d.mouth == nil then
      s:Play("MouthBombed")
    end
    if s:IsEventTriggered('BombDamage') then
      local type = d.atebomb.Type
      local var = d.atebomb.Variant
      if type == barf.bomb.Type or var == 1 or var == 10 then
        en.HitPoints = en.HitPoints - 50
      else
        en.HitPoints = en.HitPoints - 25
      end
      sfx:Play(sound.muffled_explosion, 1, 0, false, 1)
    end
    if s:IsFinished("MouthBombed") then
      d.state = 'spinbarf'
    end
    --QUEASY
  elseif d.state == 'queasy' then
    if d.statetime == 0 then
      if not d.mouth then
        d.rand = rng:RandomInt(100)
        if (barfballs > 1 and d.rand > 20) or (barfballs == 1 and d.rand < 20) then
          d.move = 'slowdown'
        else
          d.move = 'alignx'
        end
      else
        d.move = 'slowdown'
      end
    end
    --start
    if not d.mouth then
      if d.statetime == 0 then
        s:Play("Queasy")
      end
      --finish
      if s:IsFinished("Queasy") then
        if (barfballs > 1 and d.rand > 20) or (barfballs == 1 and d.rand < 20) then
          d.state = 'barfbubble'
        else
          d.state = 'barfballs'
        end
      end
    else
      d.state = 'shootball'
      s:Play("Idle2")
    end
    --BARF BALLS
  elseif d.state == 'barfballs' then
    --start
    if d.statetime == 0 then
      s:Play("BarfBalls")
    end
    --attack
    if s:IsEventTriggered("BarfBalls") then
      d.move = 'slowdown'
      sfx:Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1.5, 0, false, 1)
      sfx:Play(SoundEffect.SOUND_LITTLE_SPIT, 1, 0, false, 1.8)
      en.Velocity = en.Velocity + Vector(0, - 14)
      local bball = Isaac.Spawn(barf.ball.Type, 0, 0, pos + Vector(0, 40), Vector(0, 0), en):ToNPC()
      bball.Velocity = Vector(0, 6)
      bball.State = 4
      bball.PositionOffset = Vector(0, - 45)
      bball.HitPoints = math.min(bball.HitPoints + (d.ballskilled * 5), bball.MaxHitPoints * 2)
      bball:GetData().girl = en
      bball:GetData().lasthit = 0
      if d.v == 2 then
        bball:GetSprite():ReplaceSpritesheet(0, barf.altsprite)
        bball:GetSprite():LoadGraphics()
      end
      d.move = 'avoid'
    end
    --end
    if s:IsFinished("BarfBalls") then
      if d.v == 2 and barfballs < 2 then
        d.state = 'queasy'
      else
        d.state = 'idle'
        d.idletime = bal.BarfBallsIdleTime[d.v]
      end
    end
    --SHOOT BALL
  elseif d.state == 'shootball' then
    if d.statetime == 0 then
      d.mouth:GetData().state = 'shootball'
    end
    if d.mouth:GetData().state == 'idle' then
      d.state = 'idle'
      d.idletime = bal.ShootBallIdleTime[d.v]
    end
    --BARF BUBBLE
  elseif d.state == 'barfbubble' then
    d.move = 'slowfollow'
    --start
    if d.statetime == 0 then
      en.Mass = 15
      s:Play("BubbleStart")
      sfx:Play(sound.balloon_inflate, .5, 0, false, 1)
    end
    --advance
    if s:IsFinished("BubbleStart") then
      s:Play("BubbleHold")
    end
    --attack
    if s:IsPlaying("BubbleHold") then
      if d.statetime == 150 or (d.statetime > 40 and (pos - ppos):Length() < 110) then
        s:Play("BubblePop")
        sfx:Play(SoundEffect.SOUND_PLOP, 1.5, 0, false, 1)
        for i = -90, 150, 120 do
          for j = 30, 330, 15 do
            local tearVel = vel + (Vector.FromAngle(i) * 5 * bal.BarfBubbleSize[d.v]) +
            (Vector.FromAngle(j + i) * 7 * bal.BarfBubbleSize[d.v])
            local tear = Isaac.Spawn(9, 4, 0, pos, tearVel, en)
            tear.Color = bal.barfcolor[d.v]
            tear:GetData().behavior = 'pop'
            table.insert(barf.tears, tear)
          end
        end
      end
    end
    --finish
    if s:IsFinished("BubblePop") then
      en.Mass = d.startmass
      d.puntball = checkpunt(pos, ppos)
      d.state = 'shotgun'
    end
  end

  --EXTRA SOUND
  if s:IsPlaying("Spin") or s:IsPlaying("Spin2") then
    barf.spinloop = true
    sfx:Play(SoundEffect.SOUND_ULTRA_GREED_SPINNING, .3, 0, true, 1.7)
  else
    barf.spinloop = false
    sfx:Stop(SoundEffect.SOUND_ULTRA_GREED_SPINNING)
  end
  if s:IsEventTriggered("ShotgunLeft") or s:IsEventTriggered("ShotgunRight") or
  s:IsEventTriggered("ShotgunLeft2") or s:IsEventTriggered("ShotgunRight2") then
    sfx:Play(SoundEffect.SOUND_SHELLGAME, 1, 0, false, 1)
  end

  -- Adding this because she is too fast!
  local slowModifier = 0.9
  local slowedVelocity = Vector(en.Velocity.X * slowModifier, en.Velocity.Y * slowModifier)
  en.Velocity = slowedVelocity
end

--barf mouth
function Mahalath:check_mouth(en)
  local player = Isaac.GetPlayer(0)
  local d = en:GetData()
  local s = en:GetSprite()
  local pos = en.Position
  local ppos = player.Position
  --DIE
  if d.girl and not d.girl:Exists() then
    en:Kill()
  end
  --INIT
  if not d.init then
    table.insert(barf.mouths, en)
    en.GridCollisionClass = GridCollisionClass.COLLISION_SOLID
    en.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    en.DepthOffset = -100
    d.init = true
    d.dest = pos
    d.checktime = 0
    s:Play("Appear")
    d.v = 1
    if d.girl then d.v = d.girl:GetData().v end
  end
  --routine
  if s:IsFinished("Appear") then
    d.state = 'idle'
  end
  --State Timer
  if d.state ~= d.laststate then
    d.laststate = d.state
    d.statetime = 0
    d.checktime = 0
  else
    d.statetime = d.statetime + 1
  end
  --move
  d.eat = 0
  Mahalath:move_me(en)
  --avoid overlap
  for i, mouth in ipairs(barf.mouths) do
    if mouth:Exists() and not mouth:IsDead() then
      if mouth.InitSeed ~= en.InitSeed then
        local dif = en.Position - mouth.Position
        if dif:Length() < 40 then
          en.Velocity = en.Velocity + (dif:Normalized() * 1.5)
        end
      end
    end
  end
  --IDLE
  if d.state == 'idle' then
    s:Play("Idle")
    d.move = 'mouthblockmiddle'
    if d.statetime % 50 == 0 then
      d.retarget = true
    end
    --EAT
  elseif d.state == 'eat' then
    d.move = 'stop'
    if d.statetime == 0 then
      player:AnimatePitfallIn()
      s:Play("Suck")
    end
    if d.statetime == 8 then
      s:Play("EatClose", true)
    end
    if s:IsPlaying("Chew") then
      player:TakeDamage(1, 0, EntityRef(en), 0)
      if d.statetime % 3 == 0 then
        local gorePos = player.Position + (Vector.FromAngle(math.random(360)) * math.random(10))
        local goreVel = Vector.FromAngle(math.random(360)) * (2 + (math.random() * 6))
        Isaac.Spawn(1000, 5, 0, gorePos, goreVel, nil)
      end
      if d.statetime % 7 == 0 then
        sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 1, 0, false, .7)
      end
      if d.v == 2 then
        sfx:Play(SoundEffect.SOUND_VAMP_GULP, 1, 0, false, 1.1)
        player:Kill()
      end
    end
    if s:IsFinished("EatClose") then
      s:Play("Chew")
      local blood = Isaac.Spawn(1000, 22, 0, player.Position, Vector(0, 0), nil)
      blood.SpriteScale = Vector(2, 2)
      blood.SizeMulti = Vector(2, 2)
    end
    if player:GetSprite():IsPlaying("JumpOut") or d.statetime == 120 then
      s:Play("Barf")
    end
    if s:IsFinished("Barf") then
      s:Play("Idle")
      d.checktime = d.statetime
    end
    if d.checktime > 0 and d.statetime > d.checktime + 20 then
      d.state = 'idle'
    end
    if player:GetSprite():IsPlaying("FallIn") or player:GetSprite():IsPlaying("JumpOut") then
      player.Velocity = (pos - pos)
      player.Position = pos
    end
    --SPIT
  elseif d.state == 'spit' then
    d.move = 'stop'
    if d.statetime == 0 then
      s:Play("QuickBarf")
      d.spitpos = pos + ((ppos - pos):Normalized() * 75)
      d.spitang = (ppos - pos):GetAngleDegrees()
    end
    if s:IsEventTriggered("QuickBarf") then
      sfx:Play(SoundEffect.SOUND_LITTLE_SPIT, 1, 0, false, 1)
      local creep = Isaac.Spawn(1000, bal.creeptype[d.v], 0, en.Position, Vector(0, 0), en)
      creep.SpriteScale = Vector(2, 2)
      creep.SizeMulti = Vector(2, 2)
      d.checktime = d.statetime

      local params = ProjectileParams()
      params.FallingAccelModifier = 1.2
      params.Color = bal.barfcolor[d.v]
      params.Variant = 4
      for i = 1, 7 do
        params.FallingSpeedModifier = (i * - 2)
        local velocity = Vector.FromAngle(d.spitang - bal.SpitTearAngle[d.v] +
        (math.random() * bal.SpitTearAngle[d.v] * 2)) *
        bal.SpitTearSpeed[d.v]
        en:FireProjectiles(pos + Vector(0, 15) + (Vector.FromAngle(math.random(360)) * 8),
          velocity,
        0, getAddress(params))
      end
    end
    if d.checktime ~= 0 then
      if d.statetime - d.checktime <= 10 then
        local creep = Isaac.Spawn(1000, bal.creeptype[d.v], 0,
          (Vector.FromAngle(math.random(360)) * 15) + Lerp(pos + Vector(0, 15),
        d.spitpos, (d.statetime - d.checktime) / 10), Vector(0, 0), en)
        creep.SpriteScale = Vector(1, 1)
        creep.SizeMulti = Vector(1, 1)
      else
        d.state = 'idle'
      end
    end
    --SHOOT BALL
  elseif d.state == 'shootball' then
    if d.statetime == 0 then
      s:Play("QuickBarf")
    end
    if s:IsEventTriggered("QuickBarf") then
      sfx:Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1.5, 0, false, 1)
      sfx:Play(SoundEffect.SOUND_LITTLE_SPIT, 1, 0, false, 1.8)
      local bball = Isaac.Spawn(barf.ball.Type, 0, 0, pos + Vector(0, 5), Vector(0, 0), nil):ToNPC()
      bball.Velocity = (ppos - (pos + Vector(0, 5))):Normalized() * bal.ShootBallSpeed[d.v]
      if d.v == 2 then
        local predict = game:GetRoom():GetClampedPosition(ppos + (player.Velocity * bal.ShootBallSpeed[d.v]), 40)
        bball.Velocity = (predict - (pos + Vector(0, 5))):Normalized() * 9
      end
      en.Velocity = bball.Velocity * - 1.5
      bball.State = 4
      bball.PositionOffset = Vector(0, - 5)
      bball.HitPoints = math.min(bball.HitPoints + (d.girl:GetData().ballskilled * 5), bball.MaxHitPoints * 2)
      bball:GetData().girl = d.girl
      bball:GetData().lasthit = 0
      if d.v == 2 then
        bball:GetSprite():ReplaceSpritesheet(0, barf.altsprite)
        bball:GetSprite():LoadGraphics()
      end
    end
    if s:IsFinished("QuickBarf") then
      local rand = rng:RandomInt(100)
      if barfballs < 2 and (rand > 20 or d.v == 2) then
        s:Play("QuickBarf", true)
      else
        d.state = 'idle'
      end
    end
    --SPIN BARF
  elseif d.state == 'spinbarf' then
    local gs = d.girl:GetSprite()
    if d.statetime == 0 then
      d.move = 'mouthblockmiddle'
      d.spinshot = math.random(360)
      s:Play("CloseSmall")
    end
    if s:IsFinished("CloseSmall") then
      s:Play("Shake")
    end
    if gs:IsFinished("PreSpin2") then
      s:Play("Suck")
      sfx:Play(SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF, 1, 0, false, 1.7)
    end
    if gs:IsPlaying("Spin2") then
      if d.statetime % bal.SpinBarfFireRate[d.v] == 0 and not d.mouth then
        sfx:Play(SoundEffect.SOUND_BLOODSHOOT, .4, 0, false, 1)
        local sptear = Isaac.Spawn(9, 4, 0, pos, Vector.FromAngle(d.spinshot) * 7, en)
        sptear.Color = bal.barfcolor[d.v]
        sptear:GetData().behavior = 'spin'
        table.insert(barf.tears, sptear)
        d.spinshot = d.spinshot + bal.SpinBarfRotation[d.v]
      end
    end
    --SUCK
  elseif d.state == 'suck' then
    local cpos = pos + Vector(0, 15)
    if d.statetime == 0 then
      d.finisheat = false
      s:Play("Idle")
    end
    if d.statetime == 30 then
      s:Play("Suck")
      sfx:Play(SoundEffect.SOUND_LOW_INHALE, 1, 6, false, 1.5)
    end
    if s:IsPlaying("Suck") then
      d.eat = 1
      local dif = cpos - ppos
      local force = math.min(bal.SuckMaxSuck[d.v], d.statetime * bal.SuckIncreaseRate[d.v]) / 450

      if d.statetime % 5 == 0 then
        local ring = Isaac.Spawn(1000, barf.suction.Variant, 0, pos, Vector(0, 0), nil)
        table.insert(barf.particles, ring)
        ring.DepthOffset = -200
        ring:GetSprite().Color = Color(1, 1, 1, .5, 0, 0, 0)
      end

      player.Velocity = player.Velocity + (dif:Normalized() * force)
      if not d.finisheat then
        for i, ball in ipairs(barf.balls) do
          if not ball:GetData().lasthit or (ball.FrameCount - ball:GetData().lasthit) >= 30 then
            ball.Velocity = ball.Velocity + ((cpos - ball.Position):Normalized() * .08)
          end
        end
      end
      local atebomb = 0
      for i, bomb in ipairs(Isaac.GetRoomEntities()) do
        local type = bomb.Type
        if type == 2 then -- player actually
          bomb.Velocity = bomb.Velocity + ((cpos - bomb.Position):Normalized() * 1)
        end
        if (type == barf.bomb.Type and not bomb:GetData().nosuck) or type == 4 then
          local dist = (cpos - bomb.Position):Length()
          if (bomb.FrameCount > 5 or type == 4) and dist < 23 then
            atebomb = bomb
            d.girl:GetData().atebomb = bomb
            break
          else
            local dif2 = cpos - bomb.Position
            local len = dif:Length()
            local force2 = (120 - math.min(120, len)) / 120
            if type == barf.bomb.Type then
              bomb.Velocity = Lerp(bomb.Velocity, dif2:Normalized() * math.min(len, 7), force2 * .08)
            else
              bomb.Velocity = Lerp(bomb.Velocity, dif2:Normalized() * math.min(len, 7), force2 * .05)
            end
          end
        end
      end
      if atebomb ~= 0 then
        if d.girl:GetData().atebomb.Type == 4 then
          atebomb:Remove()
        else
          atebomb:Kill()
        end
        d.state = 'atebomb'
      end
    end
    if d.finisheat then
      d.ateball = nil
      local maxlength = 30
      for i, ball in ipairs(barf.balls) do
        if (cpos - ball.Position):Length() < maxlength then
          maxlength = (cpos - ball.Position):Length()
          d.ateball = ball
        end
      end
      if d.ateball and d.ateball:Exists() then
        d.ateball:GetData().ate = true
        d.ateball:Kill()
        d.state = 'baseball'
      end
    end
    --BASEBALL
  elseif d.state == 'baseball' then
    if d.statetime == 0 then
      s:Play("EatBall")
      sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 1, 0, false, 1)
    end
    if d.statetime == 15 then
      sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 1, 0, false, 1)
    end
    if s:IsEventTriggered("EatBarf") then
      local angle = math.random(360)
      for i = 0, 2 do
        local creepPos = en.Position + (Vector.FromAngle((i * 120) + angle) * 22)
        local creep = Isaac.Spawn(1000, bal.creeptype[d.v], 0, creepPos, Vector(0, 0), en):ToEffect()
        creep.SpriteScale = Vector(2, 2)
        creep.SizeMulti = Vector(2, 2)
      end

      local params = ProjectileParams()
      params.FallingAccelModifier = .8
      params.Color = bal.barfcolor[d.v]
      params.Variant = 4

      for i = 1, 360, 360 / 5 do
        params.FallingSpeedModifier = -11 - math.random(3)
        angle = i + math.random(20)
        en:FireProjectiles(en.Position, Vector.FromAngle(angle) * (1.5 + (math.random() * 1)), 0, getAddress(params))
      end

    end
    if s:IsFinished("EatBarf") then
      s:Play("Laugh")
    end
    --ATE BOMB
  elseif d.state == 'atebomb' then
    if d.statetime == 0 then
      sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 1, 0, false, 1)
      s:Play("EatClose")
    end
    if s:IsFinished("EatClose") then
      s:Play("Vanish")
    end
    if s:IsFinished("Vanish") then
      d.girl:GetData().mouth = nil
      en:Remove()
    end
  end
  --EAT CHECK
  if d.eat == 1 then
    local dif = pos - ppos
    local len = dif:Length()
    if len < 30 then
      d.state = 'eat'
    end
  end
end

--complex movement
function Mahalath:move_me(en)
  local player = Isaac.GetPlayer(0)
  local d = en:GetData()
  local pos = en.Position
  local vel = en.Velocity
  local ppos = player.Position + player.Velocity

  --first frame check
  local newmove = false
  if d.move ~= d.lastmove then
    newmove = true
    d.lastmove = d.move
  end
  --retarget check
  local retarget = false
  if d.retarget then
    retarget = true
    d.retarget = false
  end

  local accel = 0
  local mspeed = 0
  local acorrect = 0
  local mcorrect = 0
  --default
  if d.move == nil then d.move = 'stay' end
  if d.move == 'stop' then
    mcorrect = .2
    --stay
  elseif d.move == 'stay' then
    if newmove then
      d.dest = pos
      accel = .3
      mcorrect = .1
    end
    --avoid
  elseif d.move == 'avoid' then
    accel = bal.MoveAvoidAccel[d.v]
    mspeed = 5
    mcorrect = .1
    if newmove or retarget then
      local rcenter = game:GetRoom():GetCenterPos()
      local avoiddir = (rcenter - ppos):GetAngleDegrees() - 20 + math.random(40)
      local dest = game:GetRoom():GetClampedPosition(ppos + (Vector.FromAngle(avoiddir) * 250), 80)
      d.dest = dest
    end
    --block middle
  elseif d.move == 'blockmiddle' then
    accel = .3
    mspeed = 4
    mcorrect = .15
    local rcenter = game:GetRoom():GetCenterPos()
    d.dest = ppos + ((rcenter - ppos):Normalized() * 170)
    --mouth block middle
  elseif d.move == 'mouthblockmiddle' then
    accel = .5
    mspeed = 1
    mcorrect = .1
    if retarget or newmove then
      local tgt = game:GetRoom():GetCenterPos()
      local dif = tgt - ppos
      local len = dif:Length()
      if len > bal.MoveMouthBlockRange[d.v] then
        tgt = ppos + (dif:Normalized() * bal.MoveMouthBlockRange[d.v])
      end
      tgt = tgt + (Vector.FromAngle(math.random(360)) * 20)
      d.dest = tgt
    end
    --align x
  elseif d.move == 'alignx' then
    accel = bal.MoveAlignXAccel[d.v]
    mspeed = 3
    mcorrect = .08
    local clamp = game:GetRoom():GetClampedPosition(pos, 180)
    d.dest = game:GetRoom():GetClampedPosition(Vector(ppos.X, clamp.Y), 80)
    --slow down
  elseif d.move == 'slowdown' then
    mcorrect = .02
    d.dest = pos
    --slow follow
  elseif d.move == 'slowfollow' then
    accel = math.min(.4, d.statetime / 50)
    mspeed = bal.MoveSlowFollowSpeed[d.v]
    mcorrect = .06
    d.dest = ppos
    --chase
  elseif d.move == 'chase' then
    accel = .45
    mspeed = 6.5
    mcorrect = .1
    acorrect = 4
    d.dest = ppos
    --bouncy chase
  elseif d.move == 'bouncychase' then
    accel = .45
    mspeed = bal.MoveBouncyChaseSpeed[d.v]
    mcorrect = .08
    d.dest = ppos
    --ball knocker (pardon the mess)
  elseif d.move == 'ballknocker' then
    if barfballs ~= 0 then
      accel = bal.MoveBallKnockerAccel[d.v]
      mspeed = bal.MoveBallKnockerSpeed[d.v]
      mcorrect = .09
      acorrect = bal.MoveBallKnockerACorrect[d.v]
      if not d.tgtball or (d.tgtball:IsDead() or not d.tgtball:Exists()) then
        retarget = true
      end
      local maxdist = 10000
      if retarget or newmove then
        for i, ball in ipairs(barf.balls) do
          local dist = (ball.Position - pos):Length()
          if (dist < maxdist and
            (d.tgtball == nil or
          not d.tgtball:Exists())) or
          (ball:GetData().lastscore and
          ball:GetData().lastscore + 60 < ball.FrameCount) then

            d.tgtball = ball
            maxdist = dist
          end
        end
      end
      local room = game:GetRoom()
      local midVel = d.tgtball.Velocity * ((d.tgtball.Position - pos):Length() / vel:Length())
      d.dest = room:GetClampedPosition(d.tgtball.Position + midVel, 20)
      if newmove then
        en.Velocity = en.Velocity * .5
      end
      if d.ballhit then
        local win = false
        d.ballhit:GetData().lasthit = d.ballhit.FrameCount
        if angdif(d.ballhit.Position, pos, d.balltgt) > 150 then
          d.ballhit.Velocity = (d.balltgt - d.ballhit.Position):Normalized() * bal.BallKnockSpeed[d.v]
          win = true
        else
          local angle = (pos - d.ballhit.Position):GetAngleDegrees()
          local bpos = d.tgtball.Position
          local edge1 = game:GetRoom():GetClampedPosition(Vector(-10000, - 10000), d.tgtball:GetData().size)
          local edge2 = game:GetRoom():GetClampedPosition(Vector(10000, 10000), d.tgtball:GetData().size)
          if not win and math.abs(angle - 90) < 60 then
            local ydif1 = math.abs(bpos.Y - edge1.Y)
            local ydif2 = math.abs(d.balltgt.Y - edge1.Y)
            local ratio = ydif1 / (ydif1 + ydif2)
            local xrate = Lerp(0, d.balltgt.X - bpos.X, ratio)
            local balldest = Vector(bpos.X + xrate, edge1.Y)
            if angdif(bpos, pos, balldest) > 110 then
              win = true
              d.ballhit.Velocity = (balldest - d.ballhit.Position ):Normalized() * bal.BallKnockSpeed[d.v]
            end
          end
          if not win and math.abs(angle) + 60 > 180 then
            local xdif1 = math.abs(bpos.X - edge2.X)
            local xdif2 = math.abs(d.balltgt.X - edge2.X)
            local ratio = xdif1 / (xdif1 + xdif2)
            local yrate = Lerp(0, d.balltgt.Y - bpos.Y, ratio)
            local balldest = Vector(edge2.X, bpos.Y + yrate)
            if angdif(bpos, pos, balldest) > 110 then
              win = true
              d.ballhit.Velocity = (balldest - d.ballhit.Position ):Normalized() * bal.BallKnockSpeed[d.v]
            end
          end
          if not win and math.abs(angle + 90) < 60 then
            local ydif1 = math.abs(bpos.Y - edge2.Y)
            local ydif2 = math.abs(d.balltgt.Y - edge2.Y)
            local ratio = ydif1 / (ydif1 + ydif2)
            local xrate = Lerp(0, d.balltgt.X - bpos.X, ratio)
            local balldest = Vector(bpos.X + xrate, edge2.Y)
            if angdif(bpos, pos, balldest) > 110 then
              win = true
              d.ballhit.Velocity = (balldest - d.ballhit.Position ):Normalized() * bal.BallKnockSpeed[d.v]
            end
          end
          if not win and math.abs(angle) < 60 then
            local xdif1 = math.abs(bpos.X - edge1.X)
            local xdif2 = math.abs(d.balltgt.X - edge1.X)
            local ratio = xdif1 / (xdif1 + xdif2)
            local yrate = Lerp(0, d.balltgt.Y - bpos.Y, ratio)
            local balldest = Vector(edge1.X, bpos.Y + yrate)
            if angdif(bpos, pos, balldest) > 110 then
              win = true
              d.ballhit.Velocity = (balldest - d.ballhit.Position ):Normalized() * bal.BallKnockSpeed[d.v]
            end
          end
        end
        if not win then
          d.ballhit.Velocity = (d.ballhit.Position - pos):Normalized() * bal.BallKnockSpeed[d.v]
        else
          d.goodhits = d.goodhits + 1
          d.ballhit:GetData().lastscore = d.ballhit.FrameCount
        end
      end
    end
    --baseball
  elseif d.move == 'baseball' then
    accel = .7
    mspeed = 0
    mcorrect = .05
    local mouth = d.mouth.Position
    local reflect = game:GetRoom():GetClampedPosition(mouth + ((mouth - ppos):Normalized() * 150), 60)
    d.dest = reflect
    --chomp
  elseif d.move == 'chomp' then
    accel = .8
    mspeed = 0
    mcorrect = .02
  end

  d.retarget = false
  --movement
  if mcorrect ~= 0 then
    en.Velocity = en.Velocity:Normalized() * Lerp(en.Velocity:Length(), mspeed, mcorrect)
  end
  if acorrect ~= 0 then
    local ang1 = en.Velocity:GetAngleDegrees()
    local ang2 = (d.dest - pos):GetAngleDegrees()
    if ang1 + 180 < ang2 then ang1 = ang1 + 180 end
    if ang2 + 180 < ang1 then ang2 = ang2 + 180 end
    local ang3 = ang2 - ang1
    if math.abs(ang3) + acorrect < 180 then
      if ang3 > 0 then
        en.Velocity = en.Velocity:Rotated(-math.min(ang3, acorrect))
      elseif ang3 < 0 then
        en.Velocity = en.Velocity:Rotated(-math.max(ang3, - acorrect))
      end
    end
  end
  local moveto = pos - d.dest
  local move = moveto:Normalized() * math.min(accel, moveto:Length())
  en.Velocity = en.Velocity - move

  if d.tgt and d.tgt:Exists() then d.tgt.Position = d.dest end
end

-- Update entity inventories
function Mahalath:PostUpdate()
  local challenge = Isaac.GetChallenge()
  if challenge ~= Isaac.GetChallengeIdByName("R+7 (Season 3)") and
  challenge ~= Isaac.GetChallengeIdByName("Mahalath Practice") then

    return
  end

  barfballs = 0
  for i, en in ipairs(barf.balls) do
    if en:Exists() and not en:IsDead() then
      barfballs = barfballs + 1
    else
      barf.balls.i = nil
      i = i - 1 --luacheck: ignore
    end
  end

  barfbombs = 0
  for i, en in pairs(barf.bombs) do
    if en:Exists() and not en:IsDead() then
      barfbombs = barfbombs + 1
    else
      barf.bombs.i = nil
      i = i - 1 --luacheck: ignore
    end
  end

  for i, en in pairs(barf.mouths) do
    if not en:Exists() or en:IsDead() then
      barf.mouths.i = nil
      i = i - 1 --luacheck: ignore
    end
  end

  for i, en in pairs(barf.tears) do
    if not en:Exists() then
      table.remove(barf.tears, i)
      i = i - 1 --luacheck: ignore
    else
      local d = en:GetData()
      --HOMING
      if d.behavior == 'homing' then
        local hometo = (d.tgt - en.Position):Normalized() * 12
        local myspeed = en.Velocity:Length()
        en.Velocity = Lerp(en.Velocity, hometo, d.homerate):Normalized() * myspeed
        --SPIN
      elseif d.behavior == 'spin' then
        local myang = en.Velocity:GetAngleDegrees()
        en.Velocity = Vector.FromAngle(myang - 4) * en.Velocity:Length() * 1.04
        --BUBBLE POP
      elseif d.behavior == 'pop' then
        en.Velocity = en.Velocity * .88
      end
    end
  end

  for i, en in ipairs(barf.particles) do
    if en:Exists() then
      if en.FrameCount >= 12 then
        en:Remove()
        table.remove(barf.particles, i)
      end
    else
      table.remove(barf.particles, i)
    end
  end
end

--barf balls
function Mahalath:check_balls(en)
  local player = Isaac.GetPlayer(0)
  local d = en:GetData()
  local s = en:GetSprite()
  local pos = en.Position

  --init
  if not d.init then
    table.insert(barf.balls, en)
    en.GridCollisionClass = GridCollisionClass.COLLISION_NONE

    d.init = true
    d.startmass = en.Mass
    d.starthitpoints = en.HitPoints
    d.scaler = 1
    d.size = en.Size
    d.hittimer = 0
    d.lasthit = 0
    d.lastscore = 0
    s:Play("Idle")
    if en.PositionOffset.Y == 0 then
      en.PositionOffset = Vector(0, - 25)
    end

    d.v = 1
    if d.girl then d.v = d.girl:GetData().v end
  end
  --girl check
  if d.girl and (d.girl:IsDead() or not d.girl:Exists()) then
    d.girl = nil
  end
  --scaling
  local max = 1.2 + (((d.starthitpoints - en.MaxHitPoints) / en.MaxHitPoints) * .55)
  d.scaler = Lerp(1, max, en.HitPoints / d.starthitpoints)
  en.Scale = d.scaler
  en.Mass = d.startmass * d.scaler
  d.size = en.Size
  s.Color = Color(1, 1, 1, 1 / ((d.scaler + .5) / 1.5), 0, 0, 0)
  --positioning
  local bounce = .9
  if d.hittimer + 30 < en.FrameCount then
    bounce = .7
    if d.v == 1 then
      if en.Velocity:Length() > .25 then
        en.Velocity = en.Velocity * .985
      end
    else
      en.Velocity = Lerp(en.Velocity, en.Velocity:Normalized() * bal.T2BallSpeedTarget, .04)
    end
  end
  if en.Velocity:Length() > 9 then en.Velocity = en.Velocity:Normalized() * 9 end
  local repos = pos + en.Velocity
  local bounds = game:GetRoom():GetClampedPosition(repos, d.size)
  if bounds.X ~= repos.X then
    en.Velocity = Vector(en.Velocity.X * - bounce, en.Velocity.Y)
  end
  if bounds.Y ~= repos.Y then
    en.Velocity = Vector(en.Velocity.X, en.Velocity.Y * - bounce)
  end
  en.Position = bounds

  if d.hittimer + 120 < en.FrameCount then
    en.Velocity = en.Velocity + ((player.Position - en.Position):Normalized() * .012)
  end

  en.PositionOffset = Lerp(en.PositionOffset, Vector(0, - 25), .05)
  --animation
  if s:IsFinished("Pulse") then s:Play("Idle") end
  --DIE
  if en:IsDead() and not d.ate then
    if d.girl then d.girl:GetData().ballskilled = d.girl:GetData().ballskilled + 1 end
    local bbomb = Isaac.Spawn(barf.bomb.Type, 0, 0, en.Position, en.Velocity * .5, en):ToNPC()
    bbomb.State = 4
    bbomb:GetData().v = d.v
    if d.girl then bbomb:GetData().girl = d.girl end
    if d.v == 2 then
      bbomb:GetSprite():ReplaceSpritesheet(0, barf.altsprite)
      bbomb:GetSprite():ReplaceSpritesheet(1, barf.altsprite)
      bbomb:GetSprite():LoadGraphics()
    end
    local splash = Isaac.Spawn(1000, 12, 0, en.Position, Vector(0, 0), en)
    splash.Color = bal.barfcolor[d.v]
  end
end

--barf bombs
function Mahalath:check_bomb(en)
  local d = en:GetData()
  local s = en:GetSprite()

  --tracking
  if not en:IsDead() then
    barfbombs = barfbombs + 1
  end

  --init
  if not d.init and not d.launch then
    table.insert(barf.bombs, en)
    d.init = true
    s:Play("BubbleSpawn")
    if d.girl then d.v = d.girl:GetData().v end
  end
  if d.girl == nil or (d.girl and (d.girl:IsDead() or not d.girl:Exists())) then
    d.girl = nil
    d.launch = false
  end
  if d.launch and
  (d.girl:HasEntityFlags(EntityFlag.FLAG_FREEZE) or
  d.girl:HasEntityFlags(EntityFlag.FLAG_MIDAS_FREEZE)) then

    d.launch = false
  end
  if not d.launch and en.FrameCount > 1 then
    en.GridCollisionClass = 5
    en.EntityCollisionClass = 4
  end
  if (s:IsFinished("BubbleSpawn") or s:IsFinished("Launch")) and not s:IsPlaying("Launch") then
    if not d.whacked then
      s:Play("Pulse")
    else
      s:Play("ShortPulse")
    end
  end
  --blow up
  if s:IsEventTriggered("Explode") then
    Isaac.Explode(en.Position, en, 50)
    local creep = Isaac.Spawn(1000, bal.creeptype[d.v], 0, en.Position, Vector(0, 0), en):ToEffect()
    creep.SpriteScale = Vector(2, 2)
    creep.SizeMulti = Vector(2, 2)
    if d.v and d.v == 2 then
      creep.Timeout = 150
    end

    local params = ProjectileParams()
    params.FallingAccelModifier = .8
    params.Color = bal.barfcolor[d.v]
    params.Variant = 4
    local angle
    for i = 1, 360, 360 / 5 do
      params.FallingSpeedModifier = -12 - math.random(5)
      angle = i + math.random(20)
      en:FireProjectiles(en.Position, Vector.FromAngle(angle) * (1.5 + (math.random() * .5)), 0, getAddress(params))
    end

    en:Remove()
  end
end

-- EntityType.ENTITY_DELIRIUM (412)
function Mahalath:check_del(entity)
  delfight = true
end

function Mahalath:take_dmg(ent, damage, flags, ref, cooldown)
  local type = ent.Type
  if type == barf.girl.Type and not delfight then
    if ent.HitPoints < damage then
      ent.HitPoints = damage + 1
      ent:GetData().killed = true
      return 0
    end
  end
end

function Mahalath:PostNewRoom()
  -- Local variables
  local gameFrameCount = game:GetFrameCount()
  local room = game:GetRoom()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local challenge = Isaac.GetChallenge()

  -- This sound effect plays in a loop; unless we explicitly stop it,
  -- it can go on forever if the player leaves the boss room mid-fight
  if barf.spinloop then
    sfx:Stop(SoundEffect.SOUND_ULTRA_GREED_SPINNING)
  end

  if gameFrameCount == 0 and
  challenge == Isaac.GetChallengeIdByName("Mahalath Practice") and
  roomIndex == GridRooms.ROOM_DEBUG_IDX then -- -3

    -- Stop the boss room sound effect
    sfx:Stop(SoundEffect.SOUND_CASTLEPORTCULLIS) -- 190

    -- Spawn her
    Isaac.Spawn(barf.girl.Type, 0, 0, room:GetCenterPos(), Vector(0, 0), nil)
    Isaac.DebugString("Spawned Mahalath (for the practice challenge).")
  end
end

return Mahalath

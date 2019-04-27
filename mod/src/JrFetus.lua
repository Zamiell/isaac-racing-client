local JrFetus = {}

-- Jr. Fetus was originally created by DeadInfinity
-- It has some edits by Zamiel

local core = {}
local api = require("src/bossapi")
-- (even though the file is "bossAPI.lua",
-- this must be in lowercase for Linux compatibility purposes)

local drFetusType = Isaac.GetEntityTypeByName("Dr Fetus Jr")

--[[
local function apiStart()
	api = InfinityBossAPI
	api.AddBossToPool("gfx/drfetusboss/portrait_drfetus.png", "gfx/drfetusboss/bossname_drfetus.png", drFetusType, 0, 0, LevelStage.STAGE2_1, nil, 15, nil, nil, nil)
	api.AddBossToPool("gfx/drfetusboss/portrait_drfetus.png", "gfx/drfetusboss/bossname_drfetus.png", drFetusType, 0, 0, LevelStage.STAGE2_2, nil, 15, nil, nil, nil)
	mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.UpdateDrFetus, drFetusType)
end
--]]

local targetVariant = Isaac.GetEntityVariantByName("FetusBossTarget")
local rocketVariant = Isaac.GetEntityVariantByName("FetusBossRocket")

local zeroVector = Vector(0, 0)
local rocketHeightOffset = Vector(0, -300)
local rocketFallSpeed = Vector(0, 30)
local rocketHomeDistance = 50 * 50

local topOfTheJarOffset = Vector(0, -20)

local game = Game()

local directions = {
    {Angle = 0, Anim = "AttackRight"},
    {Angle = 90 * 1, Anim = "AttackDown"},
    {Angle = 90 * 2, Anim = "AttackLeft"},
    {Angle = 90 * 3, Anim = "AttackUp"}
}

local sounds = {
    Slam = {ID = SoundEffect.SOUND_FETUS_LAND},
    Whoosh = {ID = SoundEffect.SOUND_SHELLGAME},
    Splash = {ID = SoundEffect.SOUND_FETUS_JUMP}
}

-- 13 x 7
local patterns = {
    {
        "   X     X   ",
        "             ",
        "     X X     ",
        "             ",
        "     X X     ",
        "             ",
        "   X     X   ",
        Anim = "FlipOff"
    },
    {
        "      X      ",
        "",
        "      X      ",
        " X X X X X X ",
        "      X      ",
        "",
        "      X      ",
        Anim = "FlipOff"
    },
    {
        "X X X X X    ",
        " X X X X X   ",
        "X X X X X    ",
        " X X X X X   ",
        "X X X X X    ",
        " X X X X X   ",
        "X X X X X    ",
        Anim = "AttackLeft"
    },
    {
        "    X X X X X",
        "   X X X X X ",
        "    X X X X X",
        "   X X X X X ",
        "    X X X X X",
        "   X X X X X ",
        "    X X X X X",
        Anim = "AttackRight"
    },
    {
        "",
        "",
        "",
        " X X X X X X ",
        "X X X X X X X",
        " X X X X X X ",
        "X X X X X X X",
        Anim = "AttackDown"
    },
    {
        "X X X X X X X",
        " X X X X X X ",
        "X X X X X X X",
        " X X X X X X ",
        "",
        "",
        "",
        Anim = "AttackUp"
    }
}

local fourShotParams = {
    Cooldown = 50,
    Homing = true,
    HomingWait = 15
}

local fiveShotParams = {
    Cooldown = 40,
    Homing = true,
    HomingWait = 20,
    HomingDistance = rocketHomeDistance
}

local randomShotParams = {
    Cooldown = 50,
    Homing = true,
    HomingDistance = rocketHomeDistance,

}

local followingShotParams = {
    MultipleRockets = true,
    NumRockets = 10,
    Homing = true,
    Cooldown = 60,
    TimeBetweenRockets = 15,
    HomingSpeed = 0.3
}

local patternParams = {
    Cooldown = 80
}

local splashProjectileParams = ProjectileParams()
splashProjectileParams.HeightModifier = 20
splashProjectileParams.VelocityMulti = 0.8
splashProjectileParams.Color = Color(0.980, 0.502, 0.447, 1, 0, 0, 0)
splashProjectileParams.Variant = ProjectileVariant.PROJECTILE_TEAR

local function calcRocketTime(params)
    local ret = params.Cooldown + 10
    if params.MultipleRockets then
        ret = ret + params.NumRockets * ((params.TimeBetweenRockets or 1) + 10)
    end

    return ret
end

local drFetusCreepType = Isaac.GetEntityTypeByName("Creep (Dr Fetus Boss)")
local drFetusCreepVariant = Isaac.GetEntityVariantByName("Creep (Dr Fetus Boss)")
local drFetusCreepSubtype = 689

local drFetusEmbryoType = Isaac.GetEntityTypeByName("Dr Fetus Boss Embryo")
local drFetusEmbryoVariant = Isaac.GetEntityVariantByName("Dr Fetus Boss Embryo")

local AttackCooldowns = {
    --[[ OLD
    Start = 45,
    Post4Shot = 10,
    PostCircleShot = 50,
    PostRandomShot = 50,
    PostSpawnCreep = 50,
    PostFollowingMissile = 50,
    PostAimedShot = 50,
    PostPattern = 20,
    PostSwimAttack = 60]]

    Start = 15,
    Post4Shot = 5,
    PostCircleShot = 5,
    PostRandomShot = 5,
    PostSpawnCreep = 5,
    PostFollowingMissile = 10,
    PostAimedShot = 10,
    PostPattern = 20,
    PostSwimAttack = 15
}

local Weights = {
    CircleShot = 4,
    GoUpTop = 2,
    GoUpTopPlayerNear = 15,
    SpawnCreepPlayerNear = 15,
    Pattern = 6,
    RandomShot = 3,
    AimedShot = 4,
    FourShot = 3,
    FollowingMissile = 2
}

local timeSinceLastPatternAttack = 9999

function JrFetus:UpdateDrFetus(entity)
    local sprite, data, ai, target = api.GetBossVars(entity)

    local hp = entity.HitPoints
    local maxhp = entity.MaxHitPoints

    timeSinceLastPatternAttack = timeSinceLastPatternAttack + 1

    local activeAttack = ai:GetActiveAttack()

    entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
    if entity.FrameCount <= 1 then
        ai:SetAttackCooldown(AttackCooldowns.Start)
    end

    if sprite:IsPlaying("Death") then
        ai:SetActiveAttack("Dying")
        if api.Random(1, 2) == 1 then
            api.SpillCreep(entity.Position, 60, 3, nil, drFetusCreepType, drFetusCreepVariant, drFetusCreepSubtype)
        end

        if sprite:IsEventTriggered("SpawnEmbryo") then
            Isaac.Spawn(drFetusEmbryoType, drFetusEmbryoVariant, 0, entity.Position, api.ZeroVector, nil)
        end
    elseif sprite:IsFinished("Death") then
        entity:Kill()
    end

    local isIdle = not api.IsPlaying(sprite, "FlipOff", "AttackUp", "AttackRight", "AttackDown", "AttackLeft", "Slam", "SwimUp", "IdleTop", "AttackTop", "SwimDown", "Appear", "Death") and not activeAttack
    if isIdle and not sprite:IsPlaying("Idle") then
        sprite:Play("Idle", true)
    end

    if ai:IsCooledDown() and not activeAttack and isIdle then
        ai:ResetPool()

        ai:AddAttackToPool("CircleShot", Weights.CircleShot, "GoUpTop", Weights.GoUpTop)

        if target.Position:DistanceSquared(entity.Position) < rocketHomeDistance * 3.5 then
            ai:AddAttackToPool("GoUpTop", Weights.GoUpTopPlayerNear)
            if hp < maxhp * 0.75 then
                ai:AddAttackToPool("SpawnCreep", Weights.SpawnCreepPlayerNear)
            end
        end

        if timeSinceLastPatternAttack > 70 and not ai:GetBackgroundAttack("FollowingMissile") then
            ai:AddAttackToPool("Pattern", Weights.Pattern + math.floor(timeSinceLastPatternAttack / 100))
        end

        if not ai:GetBackgroundAttack("FollowingMissile") and not ai:GetBackgroundAttack("Pattern") and hp < maxhp * 0.5 then
            ai:AddAttackToPool("FollowingMissile", Weights.FollowingMissile)
        end

        ai:AddAttackToPool("RandomShot", Weights.RandomShot)
        if not ai:GetBackgroundAttack("Pattern") then
            ai:AddAttackToPool("AimedShot", Weights.AimedShot)
            if hp < maxhp * 0.75 then
                ai:AddAttackToPool("4Shot", Weights.FourShot)
            end
        end

        local attack = ai:GetAttackFromPool()

        if attack == "CircleShot" then
            sprite:Play("Slam", true)
            ai:SetActiveAttack("CircleShot")
        elseif attack == "4Shot" then
            ai:SetActiveAttack("4Shot", {
                DirectionOrder = api.Shuffle(directions),
                NumFired = 0
            })
        elseif attack == "RandomShot" then
            sprite:Play("Slam", true)
            ai:SetActiveAttack("RandomShot")
        elseif attack == "GoUpTop" then
            sprite:Play("SwimUp", true)
            ai:SetActiveAttack("GoUpTop")
        elseif attack == "SpawnCreep" then
            sprite:Play("Slam", true)
            ai:SetActiveAttack("SpawnCreep")
        elseif attack == "Pattern" then
            timeSinceLastPatternAttack = 0
            local pattern = patterns[api.Random(1, #patterns)]
            sprite:Play(pattern.Anim, true)
            ai:SetActiveAttack("Pattern", {
                Pattern = pattern
            })
        elseif attack == "FollowingMissile" then
            sprite:Play("FlipOff", true)
            ai:SetActiveAttack("FollowingMissile")
        elseif attack == "AimedShot" then -- triple / quadruple shot aimed at the player
            local direction = target.Position - entity.Position
            local anim = "Slam"
            if math.abs(direction.X) > math.abs(direction.Y) then
                if direction.X < 0 then
                    anim = "AttackLeft"
                else
                    anim = "AttackRight"
                end
            else
                if direction.Y < 0 then
                    anim = "AttackUp"
                else
                    anim = "AttackDown"
                end
            end
            sprite:Play(anim, true)
            ai:SetActiveAttack("AimedShot", {
                Anim = anim,
                Direction = direction
            })
        end
    elseif activeAttack then
        if activeAttack.Name == "4Shot" then
            if not activeAttack.Firing and activeAttack.NumFired < 4 and not api.IsPlaying(sprite, "AttackUp", "AttackDown", "AttackLeft", "AttackRight") then
                activeAttack.NumFired = activeAttack.NumFired + 1
                local direction = activeAttack.DirectionOrder[activeAttack.NumFired]
                sprite:Play(direction.Anim, true)
                activeAttack.Firing = direction
            elseif not activeAttack.Firing and activeAttack.NumFired >= 4 and not api.IsPlaying(sprite, "AttackUp", "AttackDown", "AttackLeft", "AttackRight") then
                ai:SetAttackCooldown(AttackCooldowns.Post4Shot)
                ai:RemoveActiveAttack()
            elseif activeAttack.Firing then
                if sprite:IsEventTriggered(activeAttack.Firing.Anim) then
                    api.PlaySound(sounds.Whoosh)
                    core.launchMissile(entity.Position, Vector.FromAngle(activeAttack.Firing.Angle) * 12, entity, fourShotParams)
                    activeAttack.Firing = nil
                end
            end
        elseif activeAttack.Name == "CircleShot" then
            if sprite:IsEventTriggered("Slam") then
                api.PlaySound(sounds.Slam)
                local numShots = 5
                if hp < maxhp * 0.25 then
                    numShots = 7
                elseif hp < maxhp * 0.5 then
                    numShots = 6
                end

                local offset = api.Random(1, 360)
                for i = 0, numShots - 1 do
                    local direction = Vector.FromAngle(api.GetCircleDegreeOffset(i, numShots) + offset)
                    core.launchMissile(entity.Position, direction * (entity.Position:Distance(target.Position) * 0.05), entity, fiveShotParams)
                end

                ai:RemoveActiveAttack()
                ai:SetAttackCooldown(AttackCooldowns.PostCircleShot)
            end
        elseif activeAttack.Name == "RandomShot" then
            if sprite:IsEventTriggered("Slam") then
                api.PlaySound(sounds.Slam)
                for i = 1, api.Random(3, 6) do
                    local targetPos = Isaac.GetRandomPosition()
                    local direction = targetPos - entity.Position
                    core.launchMissile(entity.Position, direction * 0.05, entity, randomShotParams)
                end

                ai:RemoveActiveAttack()
                ai:SetAttackCooldown(AttackCooldowns.PostRandomShot)
            end
        elseif activeAttack.Name == "Pattern" then
            if sprite:IsEventTriggered(activeAttack.Pattern.Anim) then
                api.PlaySound(sounds.Whoosh)
                ai:AddBackgroundAttack("Pattern", nil, calcRocketTime(patternParams))
                core.launchMissilesFromPattern(activeAttack.Pattern, entity, patternParams)
                ai:RemoveActiveAttack()
                ai:SetAttackCooldown(AttackCooldowns.PostPattern)
            end
        elseif activeAttack.Name == "SpawnCreep" then
            if sprite:IsEventTriggered("Slam") then
                api.PlaySound(sounds.Slam)
                activeAttack.CanSpawnCreep = true
            end

            if activeAttack.CanSpawnCreep then
                if api.Random(1, 2) == 1 then
                    api.SpillCreep(entity.Position, 80, 3, nil, drFetusCreepType, drFetusCreepVariant, drFetusCreepSubtype)
                end
            end

            if not sprite:IsPlaying("Slam") then
                ai:RemoveActiveAttack()
                ai:SetAttackCooldown(AttackCooldowns.PostSpawnCreep)
            end
        elseif activeAttack.Name == "AimedShot" then
            if sprite:IsEventTriggered(activeAttack.Anim) then
                if activeAttack.Anim == "Slam" then
                    api.PlaySound(sounds.Slam)
                else
                    api.PlaySound(sounds.Whoosh)
                end

                local total = 3
                if hp < maxhp * 0.25 then
                    total = 7
                elseif hp < maxhp * 0.5 then
                    total = 5
                end

                local spread = 30
                for i = 1, total do
                    local angle = activeAttack.Direction:GetAngleDegrees()
                    local direction = Vector.FromAngle(angle + api.GetDegreeOffset(i, total, spread))
                    core.launchMissile(entity.Position, direction * 10, entity, randomShotParams)
                end

                ai:RemoveActiveAttack()
                ai:SetAttackCooldown(AttackCooldowns.PostAimedShot)
            end
        elseif activeAttack.Name == "FollowingMissile" then
            if sprite:IsEventTriggered("FlipOff") then
                api.PlaySound(sounds.Whoosh)
                ai:AddBackgroundAttack("FollowingMissile", nil, calcRocketTime(followingShotParams))
                core.launchMissile(entity.Position, zeroVector, entity, followingShotParams)
                ai:RemoveActiveAttack()
                ai:SetAttackCooldown(AttackCooldowns.PostFollowingMissile)
            end
        elseif activeAttack.Name == "GoUpTop" then
            if sprite:IsPlaying("IdleTop") and api.Random(1, 13) == 1 then
                if api.Random(1, 100) > 30 then
                    sprite:Play("AttackTop", true)
                    api.PlaySound(sounds.Whoosh)
                    local direction = target.Position - entity.Position
                    local bomb = Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombVariant.BOMB_TROLL, 0, entity.Position, direction * 0.1, entity)
                    bomb:ToBomb().ExplosionDamage = 1
                    -- This still makes the troll bomb deal a full heart of damage to the player
                    -- but mitigates the damage dealt to NPCs (by default it is 60)
                else
                    sprite:Play("SwimDown", true)
                    ai:RemoveActiveAttack()
                    ai:SetAttackCooldown(AttackCooldowns.PostSwimAttack)
                end
            end

            if sprite:IsEventTriggered("Splash") then
                api.PlaySound(sounds.Splash)
                local offsetEnt = Isaac.Spawn(EntityType.ENTITY_FLY, 0, 0, entity.Position + topOfTheJarOffset, api.ZeroVector, nil):ToNPC()
                offsetEnt:FireBossProjectiles(api.Random(18, 26), zeroVector, 10, splashProjectileParams)
                offsetEnt:Remove()
            end

            if not sprite:IsPlaying("SwimUp") and not sprite:IsPlaying("IdleTop") and not sprite:IsPlaying("AttackTop") and not sprite:IsPlaying("SwimDown") then
                sprite:Play("IdleTop", true)
            end
        end
    end

    ai:Tick()
end

function JrFetus:DrFetusTakeDamage(entity, amount, flags, source, countdown)
    if (entity.HitPoints - amount) < 0 then
        entity.HitPoints = 0
        local sprite = entity:GetSprite()
        if not sprite:IsPlaying("Death") and not sprite:IsFinished("Death") then
            sprite:Play("Death", true)
        end

        return false
    end
end

function JrFetus:DrFetusEmbryoKill(entity)
    if entity.Variant == drFetusEmbryoVariant then
        for i = 1, api.Random(1, 3) do
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, 0, entity.Position, RandomVector() * 3, nil)
        end
    end
end

function core.launchMissilesFromPattern(pattern, boss, params)
    for y, row in ipairs(pattern) do
        local len = string.len(row)
        for x = 1, len do
            local char = string.sub(row, x, x)
            if char == "X" then
                local index = api.VectorToGridIndex(x - 1, y - 1)
                local pos = game:GetRoom():GetGridPosition(index)
                core.launchMissile(pos, zeroVector, boss, params)
            end
        end
    end
end

function core.launchMissile(position, velocity, boss, params)
    local target = Isaac.Spawn(EntityType.ENTITY_EFFECT, targetVariant, 0, position, velocity, nil)
    local data = target:GetData()
    local sprite = target:GetSprite()
    sprite:Play("Blink", true)

    data.Boss = boss
    target.Parent = boss
    data.BossMissile = true
    data.RocketsFired = 0

    data.MissileParams = api.Copy(params)
end

function JrFetus:UpdateMissileTarget(entity)
    local data = entity:GetData()
    if entity.Variant == targetVariant and data.BossMissile then
        local sprite = entity:GetSprite()
        local boss = data.Boss
        local target
        if boss then
            target = data.Boss:GetPlayerTarget()
        end

        if data.MissileParams.Homing and target then
            local shouldHome = true
            if data.MissileParams.HomingWait and data.MissileParams.HomingWait > 0 then
                data.MissileParams.HomingWait = data.MissileParams.HomingWait - 1
                shouldHome = false
            end

            if data.MissileParams.HomingDistance then
                if not (target.Position:DistanceSquared(entity.Position) < data.MissileParams.HomingDistance) then
                    shouldHome = false
                end
            end

            if shouldHome then
                local direction = (target.Position - entity.Position):Normalized()
                entity:AddVelocity(direction * (data.MissileParams.HomingSpeed or 0.6))
            end
        end

        if data.MissileParams.Cooldown and data.MissileParams.Cooldown > 0 then
            data.MissileParams.Cooldown = data.MissileParams.Cooldown - 1
        elseif not data.Rocket then
            local rocket = Isaac.Spawn(EntityType.ENTITY_EFFECT, rocketVariant, 0, entity.Position, zeroVector, data.Boss)
            rocket.SpriteOffset = rocket.SpriteOffset + rocketHeightOffset
            data.Rocket = rocket
        end

        if data.Rocket then
            data.Rocket.Position = entity.Position
            data.Rocket.SpriteOffset = data.Rocket.SpriteOffset + rocketFallSpeed
            if data.Rocket.SpriteOffset.Y >= 0 then
                Isaac.Explode(data.Rocket.Position, data.Boss, 2)
                data.Rocket:Remove()
                data.Rocket = nil
                data.RocketsFired = data.RocketsFired + 1

                if data.MissileParams.MultipleRockets and
                   data.MissileParams.NumRockets and
                   data.RocketsFired < data.MissileParams.NumRockets then

                    data.MissileParams.Cooldown = data.MissileParams.Cooldown + (data.MissileParams.TimeBetweenRockets or 1)
                else
                    entity:Remove()
                end
            end
        end
    end
end

function JrFetus:PostNewRoom()
  -- Local variables
  local gameFrameCount = game:GetFrameCount()
  local room = game:GetRoom()
  local level = game:GetLevel()
  local roomIndex = level:GetCurrentRoomDesc().SafeGridIndex
  if roomIndex < 0 then -- SafeGridIndex is always -1 for rooms outside the grid
    roomIndex = level:GetCurrentRoomIndex()
  end
  local challenge = Isaac.GetChallenge()
  local sfx = SFXManager()

  if gameFrameCount == 0 and
     challenge == Isaac.GetChallengeIdByName("Jr. Fetus Practice") and
     roomIndex == GridRooms.ROOM_DEBUG_IDX then -- -3

    -- Stop the boss room sound effect
    sfx:Stop(SoundEffect.SOUND_CASTLEPORTCULLIS) -- 190

    -- Spawn her
    Isaac.Spawn(drFetusType, 0, 0, room:GetCenterPos(), Vector(0, 0), nil)
    Isaac.DebugString("Spawned Mahalath (for the practice challenge).")
  end
end

return JrFetus

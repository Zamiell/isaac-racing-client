--[[ Here's a blob to use if you want to use this API I guess.
local START_FUNC = apiStart
if InfinityBossAPI then START_FUNC()
else if not __infinityBossInit then
__infinityBossInit={Mod = RegisterMod("InfinityBossAPI", 1.0)}
__infinityBossInit.Mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	if not InfinityBossAPI then
		Isaac.RenderText("A mod requires Simple Boss API to run, go get it on the workshop!", 100, 40, 255, 255, 255, 1)
	end
end) end
__infinityBossInit[#__infinityBossInit+1]=START_FUNC end
]]

local BossAPI = {}
--[[
local mod
if not __infinityBossInit or not __infinityBossInit.Mod then
	mod = RegisterMod("InfinityBossAPI", 1.0)
else
	mod = __infinityBossInit.Mod
end
--]]

BossAPI.Game = Game()
BossAPI.ZeroVector = Vector(0, 0)
BossAPI.OneVector = Vector(1, 1)

local RANDOM_RNG = RNG()
RANDOM_RNG:SetSeed(Random(), 3)

function BossAPI.Random(min, max, rng) -- Re-implements math.random()
    rng = rng or RANDOM_RNG
    if min ~= nil and max ~= nil then -- Min and max passed, integer [min,max]
        return math.floor(rng:RandomFloat() * (max - min + 1) + min)
    elseif min ~= nil then -- Only min passed, integer [0,min]
        return math.floor(rng:RandomFloat() * (min + 1))
    end
    return rng:RandomFloat() -- float [0,1)
end

function BossAPI.WeightedRNG(args, rng)
    local weight_value = 0
    local iterated_weight = 1
    for _, potentialObject in ipairs(args) do
        weight_value = weight_value + potentialObject[2]
    end

    local random_chance = BossAPI.Random(1, weight_value, rng)
    for _, potentialObject in ipairs(args) do
        iterated_weight = iterated_weight + potentialObject[2]
        if iterated_weight > random_chance then
            return potentialObject[1]
        end
    end
end

function BossAPI.GetBossVars(boss)
    local data = boss:GetData()
    if not data.AI then
        data.AI = BossAPI.BossAI()
    end

    if boss.GetPlayerTarget then
        return boss:GetSprite(), data, data.AI, boss:GetPlayerTarget()
    end

    return boss:GetSprite(), boss:GetData(), data.AI
end

function BossAPI.Copy(tbl)
    local ret = {}
    for key, val in pairs(tbl) do
        ret[key] = val
    end

    return ret
end

function BossAPI.Shuffle(tbl)
    for i = 1, #tbl do
        local swapA, swapB = BossAPI.Random(1, #tbl), BossAPI.Random(1, #tbl)
        local A = tbl[swapA]
        tbl[swapA] = tbl[swapB]
        tbl[swapB] = A
    end

    return tbl
end

function BossAPI.VectorToGridIndex(x,y)
    local width = BossAPI.Game:GetRoom():GetGridWidth()
    return width + 1 + (x + width * y)
end

function BossAPI.GetDegreeOffset(number, total, spread)
    local offset
    if total % 2 == 0 then -- even
        offset = (-(total / 2)) * spread
    else
        offset = ((-((total - 1) / 2)) * spread) - spread
    end

    return offset + (spread * number)
end

function BossAPI.GetCircleDegreeOffset(number, total)
    return (360 / total) * number
end

function BossAPI.IsValueWithinRange(value, value2, range)
    local min, max = value2 - range, value2 + range
    return value >= min and value <= max
end

function BossAPI.SpillCreep(position, maxDistance, maxSize, minSize, type, variant, subtype, parent)
    maxDistance = maxDistance or 1
    maxSize = maxSize or 1
    minSize = minSize or 1
    type = type or EntityType.ENTITY_EFFECT
    variant = variant or EffectVariant.CREEP_RED
    subtype = subtype or 0
    local offset = RandomVector() * (BossAPI.Random(0, maxDistance * 100) * 0.01)
    local size = BossAPI.Random(minSize * 100, maxSize * 100) * 0.01
    local creep = Isaac.Spawn(type, variant, subtype, position + offset, BossAPI.ZeroVector, parent)
    creep:ToEffect().Scale = size
end

local sfxManager = SFXManager()
function BossAPI.PlaySound(params)
    local id = params.ID
    if id then
        local volume, framedelay, loop, pitch =
        params.Volume or 1,
        params.FrameDelay or 0,
        params.Loop or false,
        params.Pitch or 1

        if type(id) == "table" then
            id = id[BossAPI.Random(1, #id)]
        end

        sfxManager:Play(id, volume, framedelay, loop, pitch)
    end
end

function BossAPI.ClearRoomLayout()
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if not entity:ToFamiliar() and not entity:ToPlayer() and not entity:ToEffect() then
            entity:Remove()
        end
    end

    local room = BossAPI.Game:GetRoom()
    for index = 1, room:GetGridSize() do
        local grid = room:GetGridEntity(index)
        if grid then
            local type = grid.Desc.Type
            if type ~= GridEntityType.GRID_DOOR and type ~= GridEntityType.GRID_WALL and type ~= GridEntityType.GRID_DECORATION then
                room:RemoveGridEntity(index, 0, false)
            end
        end
    end
end

local bossSpots = {
    [LevelStage.STAGE1_1] = {
        [StageType.STAGETYPE_ORIGINAL] = "01_basement",
        [StageType.STAGETYPE_WOTL] = "02_cellar",
        [StageType.STAGETYPE_AFTERBIRTH] = "13_burning_basement",
        [StageType.STAGETYPE_GREEDMODE] = "01_basement"
    },
    [LevelStage.STAGE1_2] = {
        [StageType.STAGETYPE_ORIGINAL] = "01_basement",
        [StageType.STAGETYPE_WOTL] = "02_cellar",
        [StageType.STAGETYPE_AFTERBIRTH] = "13_burning_basement",
        [StageType.STAGETYPE_GREEDMODE] = "01_basement"
    },
    [LevelStage.STAGE2_1] = {
        [StageType.STAGETYPE_ORIGINAL] = "03_caves",
        [StageType.STAGETYPE_WOTL] = "04_catacombs",
        [StageType.STAGETYPE_AFTERBIRTH] = "14_drowned_caves",
        [StageType.STAGETYPE_GREEDMODE] = "03_caves"
    },
    [LevelStage.STAGE2_2] = {
        [StageType.STAGETYPE_ORIGINAL] = "03_caves",
        [StageType.STAGETYPE_WOTL] = "04_catacombs",
        [StageType.STAGETYPE_AFTERBIRTH] = "14_drowned_caves",
        [StageType.STAGETYPE_GREEDMODE] = "03_caves"
    },
    [LevelStage.STAGE3_1] = {
        [StageType.STAGETYPE_ORIGINAL] = "05_depths",
        [StageType.STAGETYPE_WOTL] = "06_necropolis",
        [StageType.STAGETYPE_AFTERBIRTH] = "15_dank_depths",
        [StageType.STAGETYPE_GREEDMODE] = "05_depths"
    },
    [LevelStage.STAGE3_2] = {
        [StageType.STAGETYPE_ORIGINAL] = "05_depths",
        [StageType.STAGETYPE_WOTL] = "06_necropolis",
        [StageType.STAGETYPE_AFTERBIRTH] = "15_dank_depths",
        [StageType.STAGETYPE_GREEDMODE] = "05_depths"
    },
    [LevelStage.STAGE4_1] = {
        [StageType.STAGETYPE_ORIGINAL] = "07_womb",
        [StageType.STAGETYPE_WOTL] = "07_womb",
        [StageType.STAGETYPE_AFTERBIRTH] = "16_scarred_womb",
        [StageType.STAGETYPE_GREEDMODE] = "07_womb"
    },
    [LevelStage.STAGE4_2] = {
        [StageType.STAGETYPE_ORIGINAL] = "07_womb",
        [StageType.STAGETYPE_WOTL] = "07_womb",
        [StageType.STAGETYPE_AFTERBIRTH] = "16_scarred_womb",
        [StageType.STAGETYPE_GREEDMODE] = "07_womb"
    },
    [LevelStage.STAGE4_3] = {
        [StageType.STAGETYPE_ORIGINAL] = "17_blue_womb",
        [StageType.STAGETYPE_WOTL] = "17_blue_womb",
        [StageType.STAGETYPE_AFTERBIRTH] = "17_blue_womb",
        [StageType.STAGETYPE_GREEDMODE] = "17_blue_womb"
    },
    [LevelStage.STAGE5] = {
        [StageType.STAGETYPE_ORIGINAL] = "09_sheol",
        [StageType.STAGETYPE_WOTL] = "10_cathedral",
        [StageType.STAGETYPE_AFTERBIRTH] = "09_sheol",
        [StageType.STAGETYPE_GREEDMODE] = "09_sheol"
    },
    [LevelStage.STAGE6] = {
        [StageType.STAGETYPE_ORIGINAL] = "11_darkroom",
        [StageType.STAGETYPE_WOTL] = "12_chest",
        [StageType.STAGETYPE_AFTERBIRTH] = "11_darkroom",
        [StageType.STAGETYPE_GREEDMODE] = "18_shop"
    },
    [LevelStage.STAGE7] = {
        [StageType.STAGETYPE_ORIGINAL] = "19_void",
        [StageType.STAGETYPE_WOTL] = "19_void",
        [StageType.STAGETYPE_AFTERBIRTH] = "19_void",
        [StageType.STAGETYPE_GREEDMODE] = "18_shop"
    }
}

--[[
local customVersusScreen = Sprite()
customVersusScreen:Load("bossapi/customversusscreen.anm2", true)

function BossAPI.PlayVersusScreen(portrait, name, spot)
    if not spot then
        local level = BossAPI.Game:GetLevel()
        local type = level:GetStageType()
        local stage = level:GetStage()
        Isaac.DebugString("Getting spot!")
        Isaac.DebugString(stage)
        Isaac.DebugString(type)
        if bossSpots[stage] and bossSpots[stage][type] then
            spot = "gfx/ui/boss/bossspot_" .. bossSpots[stage][type] .. ".png"
        end
    end

    Isaac.DebugString(spot)

    customVersusScreen:ReplaceSpritesheet(2, spot)
    customVersusScreen:ReplaceSpritesheet(4, portrait)
    customVersusScreen:ReplaceSpritesheet(7, name)

    customVersusScreen:LoadGraphics()

    customVersusScreen:Play("Scene", true)
end
--]]

function BossAPI.GetScreenCenterPosition()
    local room = BossAPI.Game:GetRoom()
    local centerOffset = (room:GetCenterPos()) - room:GetTopLeftPos()
    local pos = room:GetCenterPos()
    if centerOffset.X > 260 then
      pos.X = pos.X - 260
    end
    if centerOffset.Y > 140 then
        pos.Y = pos.Y - 140
    end
    return Isaac.WorldToRenderPosition(pos, false)
end

--[[
local tick = false
mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if customVersusScreen:IsPlaying("Scene") then
        tick = not tick
        if tick then
            customVersusScreen:Update()
        end

        local player = Isaac.GetPlayer(0)
        if Input.IsActionTriggered(ButtonAction.ACTION_MENUCONFIRM, player.ControllerIndex) then
            customVersusScreen:Stop()
        end

        customVersusScreen:Render(BossAPI.GetScreenCenterPosition(), BossAPI.ZeroVector, BossAPI.ZeroVector)
    end
end)

local BossPool = {}
--]]

--[[
function BossAPI.AddBossToPool(portrait, name, type, variant, subtype, stage, stageType, weight, validShapes, onSpawn, spot)
    stageType = stageType or "All"
    weight = weight or 10
    portrait = portrait or "gfx/ui/boss/portrait_20.0_monstro.png"
    name = name or "gfx/ui/boss/bossname_20.0_monstro"
    validShapes = validShapes or {RoomShape.ROOMSHAPE_1x1}
    if not BossPool[stage] then
        BossPool[stage] = {}
    end

    if not BossPool[stage][stageType] then
        BossPool[stage][stageType] = {}
    end

    for _, shape in ipairs(validShapes) do
        if not BossPool[stage][stageType][shape] then
            BossPool[stage][stageType][shape] = {}
        end

        BossPool[stage][stageType][shape][#BossPool[stage][stageType][shape] + 1] = {{
            Portrait = portrait,
            Name = name,
            Spot = spot,
            Type = type,
            Variant = variant,
            Subtype = subtype,
            OnSpawn = onSpawn,
            ValidShapes = validShapes
        }, weight}
    end
end
--]]

--[[
local BossRNG = RNG()
function BossAPI.GetBossFromPool(stage, type, shape, seed)
    if BossPool[stage] and ((BossPool[stage]["All"] and BossPool[stage]["All"][shape]) or (BossPool[stage][type] and BossPool[stage][type][shape])) then
        local pool = {}
        pool[#pool + 1] = {"NormalBoss", 100}
        if BossPool[stage]["All"] and BossPool[stage]["All"][shape] then
            for _, bossData in ipairs(BossPool[stage]["All"][shape]) do
                pool[#pool + 1] = bossData
            end
        end

        if BossPool[stage][type] and BossPool[stage][type][shape] then
            for _, bossData in ipairs(BossPool[stage][type][shape]) do
                pool[#pool + 1] = bossData
            end
        end

        BossRNG:SetSeed(seed or Random(), 3)
        return BossAPI.WeightedRNG(pool, BossRNG)
    end
end
--]]

--[[
function BossAPI:PostNewRoom()
    local room = BossAPI.Game:GetRoom()
    local level = BossAPI.Game:GetLevel()
    if room:GetType() == RoomType.ROOM_BOSS and not room:IsClear() then
        local boss = BossAPI.GetBossFromPool(level:GetStage(), level:GetStageType(), room:GetRoomShape(), room:GetSpawnSeed())
        if boss and boss ~= "NormalBoss" then
            BossAPI.ClearRoomLayout()
            BossAPI.PlayVersusScreen(boss.Portrait, boss.Name, boss.Spot)
            local bossSpawned = Isaac.Spawn(boss.Type, boss.Variant or 0, boss.Subtype or 0, room:GetCenterPos(), BossAPI.ZeroVector, nil)
            if boss.OnSpawn then
                boss.OnSpawn(bossSpawned)
            end
        end
    end
end
--]]

function BossAPI.Class()
    local newClass = {}
    setmetatable(newClass, {
        __call = function(tbl, ...)
            local inst = {}
            setmetatable(inst, {
                __index = tbl
            })
            inst:Init(...)
            return inst
        end
    })
    return newClass
end

local Timer = BossAPI.Class()
function Timer:Init(start, increment)
    self.Time = start or 0
    self.Increment = increment
end

function Timer:Tick()
    if self.Increment then
        self.Time = self.Time + 1
    else
        self.Time = self.Time - 1
    end
end

function Timer:Set(amount)
    self.Time = amount
end

function Timer:Get()
    return self.Time
end

function Timer:Is(amount, greater)
    if greater ~= nil then
        if greater then
            return self.Time > amount
        else
            return self.Time < amount
        end
    end

    return self.Time == amount
end

local BossAI = BossAPI.Class()
function BossAI:Init()
    self.OngoingAttacks = {}
    self.AttackPool = {}
    self.Timers = {}
    self:AddTimer("AttackCooldown", 0)
end

function BossAI:AddBackgroundAttack(name, data, timer)
    self.OngoingAttacks[name] = {
        Name = name,
        Data = data
    }

    if timer then
        self.OngoingAttacks[name].Timer = Timer(timer)
    end
end

function BossAI:GetBackgroundAttack(name)
    return self.OngoingAttacks[name]
end

function BossAI:RemoveBackgroundAttack(name)
    self.OngoingAttacks[name] = nil
end

function BossAI:SetActiveAttack(name, data)
    self.ActiveAttack = {
        Name = name
    }

    if data then
        for key, obj in pairs(data) do
            self.ActiveAttack[key] = obj
        end
    end
end

function BossAI:GetActiveAttack()
    return self.ActiveAttack
end

function BossAI:RemoveActiveAttack()
    self.ActiveAttack = nil
end

function BossAI:HasActiveAttack(...)
    if self.ActiveAttack then
        local args = {...}
        if type(args[1]) == "table" then
            args = args[1]
        end

        for _, name in ipairs(args) do
            if self.ActiveAttack.Name == name then
                return true
            end
        end
    end
end

function BossAI:HasBackgroundAttack(...)
    local args = {...}
    if type(args[1]) == "table" then
        args = args[1]
    end

    for _, name in ipairs(args) do
        if self.OngoingAttacks[name] then
            return true
        end
    end
end

function BossAI:AddAttackToPool(...)
    local args = {...}
    local name
    for i, arg in ipairs(args) do
        if i % 2 == 0 then
            self.AttackPool[#self.AttackPool + 1] = {name, arg}
        else
            name = arg
        end
    end
end

function BossAI:ResetPool()
    self.AttackPool = {}
end

function BossAI:GetAttackFromPool()
    return BossAPI.WeightedRNG(self.AttackPool)
end

function BossAI:SetAttackCooldown(amount)
    self:GetTimer("AttackCooldown"):Set(amount)
end

function BossAI:GetAttackCooldown()
    return self:GetTimer("AttackCooldown"):Get()
end

function BossAI:IsCooledDown()
    return self:GetTimer("AttackCooldown"):Get() <= 0
end

function BossAI:AddTimer(name, start, increment)
    self.Timers[name] = Timer(start, increment)
    return self.Timers[name]
end

function BossAI:GetTimer(name)
    return self.Timers[name]
end

function BossAI:Tick()
    for _, timer in pairs(self.Timers) do
        timer:Tick()
    end

    for name, attack in pairs(self.OngoingAttacks) do
        if attack.Timer then
            attack.Timer:Tick()
            if attack.Timer:Get() <= 0 then
                self.OngoingAttacks[name] = nil
            end
        end
    end
end

function BossAPI.IsOverlayPlaying(sprite, ...)
    local args = {...}
    if type(args[1]) == "table" then
        args = args[1]
    end

    for _, anim in ipairs(args) do
        if sprite:IsOverlayPlaying(anim) then
            return true
        end
    end
end

function BossAPI.IsPlaying(sprite, ...)
    local args = {...}
    if type(args[1]) == "table" then
        args = args[1]
    end

    for _, anim in ipairs(args) do
        if sprite:IsPlaying(anim) then
            return true
        end
    end
end

function BossAPI.IsFrame(sprite, ...)
    local args = {...}
    if type(args[1]) == "table" then
        args = args[1]
    end

    for _, frame in ipairs(args) do
        if sprite:GetFrame() == frame then
            return true
        end
    end
end

function BossAPI.IsOverlayFrame(sprite, ...)
    local args = {...}
    if type(args[1]) == "table" then
        args = args[1]
    end

    for _, frame in ipairs(args) do
        if sprite:GetOverlayFrame() == frame then
            return true
        end
    end
end

BossAPI.Timer = Timer
BossAPI.BossAI = BossAI

return BossAPI

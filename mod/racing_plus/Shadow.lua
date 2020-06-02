
-- Includes
local g            = require("racing_plus/globals")
local ShadowClient = require("racing_plus/shadowclient")

local Shadow = {
    beaconInterval = 10 * 60, -- (60 fps per  Isaac::GetFrameCount)
    sprite = nil,
    isActive = false
}

local state = {
    lastUpdated = 0,
    x = nil, y = nil,
    level = nil, room = nil,
    character = nil, -- TODO: this field may probably be redundant if we don't wanna see transformations
    anim_name = "no", anim_frame = nil
}

function Shadow:IsEnabled()
    return g.luadebug and g.raceVars.shadowEnabled
    -- TODO: more race condition checks e.g.:
    -- and g.race.raceID ~= 0 or g.race.status ~= "none" and not g.race.solo
end

function Shadow:Draw()
    -- TODO: define other conditions when shadow is not to be drawn
    if Shadow.isActive then
        Isaac.DebugString("Drawing shadow")
        if Shadow.sprite == nil and state.character ~= nil then
            Shadow.sprite = Sprite {}
            Shadow.sprite:Load("gfx/custom/characters/" .. state.character .. ".anm2", true)
            Shadow.sprite.Color = Color(1, 1, 1, 0.25, 0, 0, 0)
            Isaac.DebugString('Shadow sprite loaded')
            Shadow.sprite:SetFrame("Death", 5)
        end

        local shadowPos = Isaac.WorldToScreen(Vector(state.x, state.y))
        Shadow.sprite:Render(shadowPos, g.zeroVector, g.zeroVector)
    end

    -- Isaac.DebugString("Player pos: x=" .. g.p.Position.X .. ", y=" .. g.p.Position.Y)
    -- Isaac.DebugString("Shadow pos: x=" .. shadow.x .. ", y=" .. shadow.x)
end

function Shadow:IsBeaconFrame()
    local currentFrame = Isaac:GetFrameCount()
    return currentFrame - math.floor(currentFrame/Shadow.beaconInterval)*Shadow.beaconInterval == 0
end

function Shadow:PostUpdate()
    if not Shadow:IsEnabled() then
        return ShadowClient:Disconnect()
    end
    if not ShadowClient.connected then
        ShadowClient:Connect()
        ShadowClient:SendBeacon() -- initial session start
    end

    if Shadow:IsBeaconFrame() then
        ShadowClient:SendBeacon()
    end

    ShadowClient:SendShadow()
    local shadow = ShadowClient:RecvOpponentShadow() -- data may not be yet received
    Shadow.isActive = Shadow.isActive and shadow ~= nil

    if shadow ~= nil then
        local currentFrame = Isaac:GetFrameCount()

        state.x = shadow.x
        state.y = shadow.y
        state.level = shadow.level
        state.room = shadow.room
        if state.character ~= shadow.character then
            Shadow.sprite:Load("gfx/custom/characters/" .. shadow.character .. ".anm2", true)
        end
        state.character = shadow.character

        -- TODO: animation routine
        state.anim_name = shadow.anim_name
        state.anim_frame = shadow.anim_frame

        Shadow.isActive = shadow.level == g.l:GetStage() -- same level
        Shadow.isActive = Shadow.isActive and shadow.room == g.l:GetCurrentRoomIndex() -- same room
        Shadow.isActive = Shadow.isActive and currentFrame - state.lastUpdated < 60
        state.lastUpdated = currentFrame
    end


end

return Shadow
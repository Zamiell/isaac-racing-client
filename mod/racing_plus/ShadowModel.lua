local Shadow = {}

-- Includes
local g           = require("racing_plus/globals")
local struct      = require('racing_plus/struct')

function Shadow.new(self, t)
    --[[ pack/unpack reference:
        "b" a signed char, "B" an unsigned char
        "h" a signed short (2 bytes), "H" an unsigned short (2 bytes)
        "i" a signed int (4 bytes), "I" an unsigned int (4 bytes)
        "l" a signed long (8 bytes), "L" an unsigned long (8 bytes)
        "f" a float (4 bytes), "d" a double (8 bytes)
        "s" a zero-terminated string
        "cn" a sequence of exactly n chars corresponding to a single Lua string]]
    local _t = t or {}
    _t.dataorder = {"race", "player", "x",   "y",   "level", "room",  "character", "anim_name", "anim_frame"}
    _t.dataformat = "I" ..  "I" ..    "f" .. "f" .. "I" ..   "I" ..   "I" ..       "c20" ..            "I"
    --              +4Bytes +4Bytes   +4Bytes+4Bytes+4Bytes  +4Bytes  +4Bytes      +20Bytes            +4Bytes = 52Bytes
    _t.allowedLength = 52
    setmetatable(_t, self)
    self.__index = self
    -- TODO: __newindex function may become handy here in case animation_name is set after constructor call
    return _t
end

function Shadow.fromGame()
    -- TODO: implement custom animation getter
    local s = Shadow:new {
        race = g.race.raceID, player = g.race.userID, -- TODO: replace race/player hardcoded values
        x = g.p.Position.X, y = g.p.Position.Y,
        level = g.l:GetStage(), room = g.l:GetCurrentRoomIndex(),
        character = g.p:GetPlayerType(),
        anim_name = "no",
        anim_frame = g.p:GetSprite():GetFrame(),
    }
    return s
end

function Shadow.marshall(self)
    local ordered = {}
    for _, field in pairs(self.dataorder) do
        table.insert(ordered, self[field])
    end
    return struct.pack(self.dataformat, table.unpack(ordered))
end

function Shadow.unmarshall(self, data)
    local unpacked = {struct.unpack(self.dataformat, data)}
    for num, field in ipairs(self.dataorder) do
        self[field] = unpacked[num]
    end
    self.anim_name = string.gsub(self.anim_name, '%s+', '') -- poormans trailing whitespace trim
end

local function validate(data, allowedLength)
    if type(data) ~= 'string' then
        return nil
    end
    if #data < allowedLength then
        return nil
    end
    return data:sub(1, allowedLength)
end

function Shadow.fromRawData(data)
    local s = Shadow:new()
    data = validate(data, s.allowedLength)
    if data == nil then
        return
    end
    s:unmarshall(data)
    Isaac.DebugString("shadow unmarshalled")
    return s
end

local KeepAlive = { -- prototype
    dataorder = {"race", "player", "message"},
    dataformat = "I" ..  "I" ..    "c5"
}

function KeepAlive:toNetworkBytes()
    local _t = {
        race = 7, player = 1, message = "HELLO" -- TODO: replace race/player hardcoded values
    }

    local ordered = {}
    for _, field in pairs(KeepAlive.dataorder) do
        table.insert(ordered, _t[field])
    end
    return struct.pack(KeepAlive.dataformat, table.unpack(ordered))
end

local ShadowModel = {
    shadow = Shadow,
    keepalive = KeepAlive,
}

return ShadowModel
local Shadow = {}

-- Includes
local g      = require("racing_plus/globals")
local struct = require('racing_plus/struct')

local supportedAnimations = {
  "WalkLeft", "WalkRight", "WalkUp", "WalkDown",
  "Trapdoor2",
  "Death",
  -- "TeleportUp", "TeleportDown", "LightTravel" -- Needs more sophisticated handling by callbacks
}

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
  _t.dataformat = "I" ..  "I" ..  "f" .. "f" .. "I" ..   "I" ..   "I" ..     "c20" ..      "I"
  --        +4Bytes +4Bytes   +4Bytes+4Bytes+4Bytes  +4Bytes  +4Bytes    +20Bytes      +4Bytes = 52Bytes
  _t.allowedLength = 52
  setmetatable(_t, self)
  self.__index = self
  return _t
end

function Shadow.fromGame()
  local s = Shadow:new {
    race = g.race.raceID, player = g.race.userID,
    x = g.p.Position.X, y = g.p.Position.Y,
    level = g.l:GetStage(), room = g.l:GetCurrentRoomIndex(),
    character = g.p:GetPlayerType(),
    anim_name = "",
    anim_frame = g.p:GetSprite():GetFrame(),
  }
  for _, animation in pairs(supportedAnimations) do
    if g.p:GetSprite():IsPlaying(animation) then
      s.anim_name = s.anim_name .. animation
    end
  end
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
  self.anim_name = string.gsub(self.anim_name, '%s+', '') -- Poormans trailing whitespace trim
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
  return s
end

local KeepAlive = { -- Prototype
  dataorder = {"race", "player", "message"},
  dataformat = "I" ..  "I" ..  "c5"
}

function KeepAlive:toNetworkBytes()
  local _t = {
    race = g.race.raceID, player = g.race.userID, message = "HELLO"
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

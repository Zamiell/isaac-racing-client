local Race = {}

-- Includes
local g           = require("racing_plus/globals")
local FastTravel  = require("racing_plus/fasttravel")
local Speedrun    = require("racing_plus/speedrun")
local Sprites     = require("racing_plus/sprites")
local SeededDeath = require("racing_plus/seededdeath")
local struct      = require('racing_plus/struct')

local ModServer = {
  host = "127.0.0.1",  -- Notice: using special domains e.g. localhost may cause socket to be created as IPV6
  port = 9001,
  connected = false, -- represents connection to mod server (mostly for shadow render)
  dataFormat = "ff", -- two floats at this point (x, y)
  socket = g.socket
}

local Shadow = {
  loaded = false,
  entity = nil,
  sprite = Sprite {
    Color = Color(1, 1, 1, 0.9, 0, 0, 0),
  },
}

local ShadowModel = {
  x=nil, y=nil,
  room=nil, level=nil,
  character=nil,
  animation_name=nil, animation_frame=nil
}

function ShadowModel.new(self, t)
  --[[ pack/unpack reference:
        "b" a signed char
        "B" an unsigned char
        "h" a signed short (2 bytes)
        "H" an unsigned short (2 bytes)
        "i" a signed int (4 bytes)
        "I" an unsigned int (4 bytes)
        "l" a signed long (8 bytes)
        "L" an unsigned long (8 bytes)
        "f" a float (4 bytes)
        "d" a double (8 bytes)
        "s" a zero-terminated string
        "cn" a sequence of exactly n chars corresponding to a single Lua string]]
  local _t = t or {}
  _t.dataorder = {"x",   "y",   "level", "room",  "character", "animation_name", "animation_frame"}
  _t.dataformat = "f" .. "f" .. "I" ..   "I" ..   "I" ..       "s" ..            "I"
  setmetatable(_t, self)
  self.__index = self
  return _t
end

function ShadowModel.fromGame()
  -- TODO: implement custom animation getter
  local s = ShadowModel.new {
    x = g.p.Position.X, y = g.p.Position.Y,
    level = g.l.GetStage(), room = g.l:GetCurrentRoomIndex(),
    character = g.p.GetPlayerType(),
    animation_name = "no", animation_frame = g.p:GetSprite().GetFrame()
  }
  return s
end

function ShadowModel.marshall(self)
  local ordered = {}
  for _, field in pairs(self.dataorder) do
    table.insert(ordered, self[field])
  end
  return struct.pack(self.dataformat, table.unpack(ordered))
end

function ShadowModel.unmarshall(self, data)
  local unpacked = {struct.unpack(self.dataformat, data)}
  for num, field in ipairs(self.dataorder) do
    self[field] = unpacked[num]
  end
end

function ShadowModel.fromRawData(data)
  local s = ShadowModel.new()
  s.unmarshall(data)
  return s
end

function Race:PostUpdate()
  -- We do not want to return if we are not in a race, as there are also speedrun-related checks in the follow functions
  Race:PostUpdateCheckFireworks()
  Race:PostUpdateCheckVictoryLap()
  Race:PostUpdateCheckFinished()
  Race:PostUpdateCheckKeeperHolyMantle()
  Race:PostUpdateShadow()
  SeededDeath:PostUpdate()
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
  local gameFrameCount = g.g:GetFrameCount()

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
  g.run.trapdoor.frame = gameFrameCount + 16
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

function ModServer:Connect()
  if not ModServer.socket then return end

  if not ModServer.connected then
    Isaac.DebugString('Connecting to Modserver')

    local udp = ModServer.socket.udp()
    udp:settimeout(0)
    udp:setpeername(ModServer.host, ModServer.port)
    local host, port, af = udp:getpeername()

    if af and host and port then
      Isaac.DebugString("Egress connection (" .. af .. ") is up: " .. host .. ':' .. port)
    else return end

    ModServer.conn = udp
    ModServer.connected = true
    Isaac.DebugString('Connected to Modserver')
  end
end

function ModServer:Disconnect()
  if ModServer.connected then
    ModServer.conn:close()
    ModServer.conn = nil
    ModServer.connected = false
    Isaac.DebugString('Disconnected from Modserver')
  end
end

function Race:SendShadow()
  local co = coroutine.create(function()
    local packed = struct.pack(ModServer.dataFormat, g.p.Position.X, g.p.Position.Y) -- TODO: send anything else
    ModServer.conn:send(packed)
    coroutine.yield()
  end)
  return co
end

function Race:RecvOpponentShadow()
  local co =  coroutine.create(function()
    local data = ModServer.conn:receive(1024)
    if not data then
      ModServer.socket.sleep(0.001) -- in case we were too fast to send data but no data available yet from server
      data = ModServer.conn:receive(1024) -- time to retry receiving
    end
    if not data then coroutine.yield() end
    local x, y = struct.unpack(ModServer.dataFormat, data)
    -- Isaac.DebugString('Received shadow at ' .. tostring(x) .. ':' .. tostring(y))
    coroutine.yield(x, y)
  end)
  return co
end

function Race:IsShadowEnabled()
  return g.luadebug and g.raceVars.shadowEnabled
  -- TODO: more race condition checks e.g.:
  -- and g.race.id ~= 0 or g.race.status ~= "none" and not g.race.solo
end

function Race:PostUpdateShadow()
  if not Race:IsShadowEnabled() then return ModServer:Disconnect() end
  if not ModServer.connected then ModServer:Connect() end

  coroutine.resume(Race:SendShadow())
  local _, x, y = coroutine.resume(Race:RecvOpponentShadow())

  if x and y then
    local shadowPos = Isaac.WorldToScreen(Vector(x, y))
    -- TODO: define case when we should not draw
    if not Shadow.loaded then
      -- TODO: we might consider using dynamic player model (based on data received)
      -- TODO: if we do, Load/Unload must be handled differently
      Shadow.sprite:Load("gfx/custom/characters/" .. PlayerType.PLAYER_AZAZEL .. ".anm2", true)
      Shadow.sprite:SetFrame("Death", 5)
      Shadow.loaded = true
      Isaac.DebugString('Shadow sprite initialized')
    end
    -- Isaac.DebugString('Player at ' .. tostring(g.p.Position.X) .. ':' .. tostring(g.p.Position.Y))
    -- Isaac.DebugString('Drawing shadow')
    Shadow.sprite:Render(shadowPos, g.zeroVector, g.zeroVector)
  end
end

-- Called from the PostUpdate callback (the "CheckEntities:EntityRaceTrophy()" function)
function Race:Finish()
  -- Local variables
  local stage = g.l:GetStage()
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

  if stage == 11 then
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
  end

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
          challenge == Isaac.GetChallengeIdByName("R+7 (Season 6)"))
end

return Race

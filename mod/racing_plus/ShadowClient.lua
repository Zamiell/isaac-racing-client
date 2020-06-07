-- Includes
local g            = require("racing_plus/globals")
local ShadowModel  = require("racing_plus/shadowmodel")

-- Connection
local isaacServerHost = "isaacracing.net"
local isaacServerPort = 9001

-- Client
local ShadowClient = {
  connected = false, -- Represents connection to mod server (mostly for shadow render)
  socket = g.socket,
  maxBufferSize = 1024
}

function ShadowClient:Connect()
  if not ShadowClient.socket then
    return
  end

  if not ShadowClient.connected then
    Isaac.DebugString('Connecting to mod server')

    local udp = ShadowClient.socket.udp4()
    udp:settimeout(0)
    udp:setpeername(isaacServerHost, isaacServerPort)

    local host, port, af = udp:getpeername()
    if af and host and port then
      Isaac.DebugString("Egress raddr: (" .. af .. ") " .. host .. ':' .. port)
    else return end

    host, port, af = udp:getsockname()
    if af and host and port then
      Isaac.DebugString("Egress laddr: (" .. af .. ") " .. host .. ':' .. port)
    else
      return
    end

    ShadowClient.conn = udp
    ShadowClient.connected = true
    Isaac.DebugString('Connected to mod server')
  end
end

function ShadowClient:SendShadow()
  ShadowClient.conn:send(ShadowModel.shadow.fromGame():marshall())
end

function ShadowClient:Disconnect()
  if ShadowClient.connected then
    ShadowClient.conn:close()
    ShadowClient.conn = nil
    ShadowClient.connected = false
    Isaac.DebugString('Disconnected from Modserver')
  end
end

function ShadowClient:RecvOpponentShadow()
  local data = nil
  local limit, attempt = 2, 1
  while attempt <= limit do
    data = ShadowClient.conn:receive(ShadowClient.maxBufferSize)
    if data ~= nil then
      break
    end
    attempt = attempt + 1
  end
  if data == nil then
    return nil
  end
  return ShadowModel.shadow.fromRawData(data)
end

function ShadowClient:SendBeacon()
  ShadowClient.conn:send(ShadowModel.keepalive:toNetworkBytes())
end

return ShadowClient

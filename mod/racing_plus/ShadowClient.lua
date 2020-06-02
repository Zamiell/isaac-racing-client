

-- Includes
local g            = require("racing_plus/globals")
local ShadowModel  = require("racing_plus/shadowmodel")

-- client
local ShadowClient = {
    host = "127.0.0.1",  -- Notice: using special domains e.g. localhost may cause socket to be created as IPV6
    port = 9001,
    connected = false, -- represents connection to mod server (mostly for shadow render)
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
        udp:setpeername(ShadowClient.host, ShadowClient.port)

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
    Isaac.DebugString("-----------Sending shadow---------")
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
    Isaac.DebugString("      Received shadow")
    return ShadowModel.shadow.fromRawData(data)
end

function ShadowClient:SendBeacon()
    Isaac.DebugString("-----------Sending beacon---------")
    ShadowClient.conn:send(ShadowModel.keepalive:toNetworkBytes())
end

return ShadowClient
local Network = {}
Network.__index = Network

Network.host = nil
Network.peer = nil
Network.isServer = false
Network.connected = false
Network.pendingSansDamage = 0
Network.remoteX = 0
Network.remoteY = 0
Network.remoteReceived = false
Network.remoteDir = "d"
Network.remoteFrame = 1
Network.remoteIsMoving = false
Network.remoteHP = 92
Network.remoteZones = {}
Network.remoteCharaAttack = nil
Network.pendingBlaster = nil
Network.remoteBlasterObjects = {}

function Network.initServer(port)
    local enet = require("enet")
    Network.host = enet.host_create("*:" .. (port or 6789))
    Network.isServer = true
    Network.connected = true
    print("Server started")
end

function Network.initClient(address, port)
    local enet = require("enet")
    Network.host = enet.host_create()
    Network.peer = Network.host:connect(address .. ":" .. (port or 6789))
    Network.isServer = false
    Network.connected = false
    print("Connecting...")
end

function Network.update()
    if not Network.host then return end

    while true do
        local event = Network.host:service(0)
        if not event then break end

        if event.type == "connect" then
            Network.peer = event.peer
            Network.connected = true
            print("=== CONNECTED ===")

        elseif event.type == "disconnect" then
            Network.connected = false
            print("=== DISCONNECTED ===")

        elseif event.type == "receive" then
            Network.onReceive(event.data, event.peer)
        end
    end
end

function Network.send(data)
    if Network.peer and Network.connected then
        Network.peer:send(data)
    end
end

function Network.broadcast(data)
    if Network.host then
        Network.host:broadcast(data)
    end
end

function Network.onReceive(data, peer)
    local msgType = data:match("^([^|]+)|")

    if msgType == "pos" then
        local x, y, dir, frame, hp, moving = data:match("pos|([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
        if x and y then
            Network.remoteX = tonumber(x) or 0
            Network.remoteY = tonumber(y) or 0
            Network.remoteDir = dir or "d"
            Network.remoteFrame = tonumber(frame) or 1
            Network.remoteHP = tonumber(hp) or 92
            Network.remoteIsMoving = (moving == "1")
            Network.remoteReceived = true
        end

    elseif msgType == "zone" then
        local x, y = data:match("zone|([^,]+),([^,]+)")
        if x and y then
            table.insert(Network.remoteZones, {
                x = tonumber(x),
                y = tonumber(y),
                timer = 0,
            })
        end

    elseif msgType == "blaster" then
        local x, y = data:match("blaster|([^,]+),([^,]+)")
        if x and y then
            Network.pendingBlaster = {
                targetX = tonumber(x),
                targetY = tonumber(y),
            }
        end

    elseif msgType == "chara_attack" then
        local angle = data:match("chara_attack|([^,]+)")
        if angle then
            Network.remoteCharaAttack = {
                angle = tonumber(angle),
                timer = 0,
                frame = 1,
            }
        end

    elseif msgType == "hit" then
        local target, dmg = data:match("hit|(%a+)|([^,]+)")
        if target == "sans" and dmg then
            Network.pendingSansDamage = (Network.pendingSansDamage or 0) + tonumber(dmg)
        end
    end
end

function Network.updateRemoteZones(dt)
    for i = #Network.remoteZones, 1, -1 do
        local z = Network.remoteZones[i]
        z.timer = z.timer + dt
        if z.timer > 6 then
            table.remove(Network.remoteZones, i)
        end
    end
end

return Network
local Game = require("src.Game")
local Input = require("src.Input")
local Network = require("src.Network")
local Player = require("src.Player")

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    Input.load()
    Game.load()
end

function love.update(dt)
    Network.update()
    Network.updateRemoteZones(dt)
    Game.update(dt)

    if Network.connected then
        local character = Player.getCharacter()
        if character then
            Network.send(
                "pos|" ..
                math.floor(character:getX()) .. "," ..
                math.floor(character:getY()) .. "," ..
                (character.direction or "d") .. "," ..
                (character.frameIndex or 1) .. "," ..
                (character.hp or 92) .. "," ..
                (character.isMoving and "1" or "0")
            )
        end
    end
end

function love.keypressed(key)
    Game.keypressed(key)
end

function love.mousepressed(x, y, button)
    if button == 1 then
        Input.touchpressed(1, x, y)
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        local wasTap = Input.touchreleased(1, x, y)
        if wasTap then
            Game.touchpressed(1, x, y)
        end
    end
end

function love.draw()
    Game.draw()
    Input.drawJoystick()
end

function love.touchpressed(id, x, y)
    Input.touchpressed(id, x, y)
    Game.touchpressed(id, x, y)
end

function love.touchmoved(id, x, y)
    Input.touchmoved(id, x, y)
end

function love.touchreleased(id, x, y)
    local wasTap = Input.touchreleased(id, x, y)
    if wasTap then
        Game.touchpressed(id, x, y)
    end
end
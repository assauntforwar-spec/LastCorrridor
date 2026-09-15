local Sans = require("src.characters.sans.Sans")
local Chara = require("src.characters.chara.Chara")

local Player = {}
local character = nil

function Player.load(role)
    if role == "sans" then
        character = Sans.new()
    elseif role == "chara" then
        character = Chara.new(400, 360)
    end
end

function Player.update(dt, dummy)
    if character and character.update then
        character:update(dt, dummy)
    end
end

function Player.draw()
    if character and character.draw then
        character:draw()
    end
end

function Player.drawZones()
    if character and character.drawZones then
        character:drawZones()
    end
end

function Player.keypressed(key)
    if character and character.keypressed then
        character:keypressed(key)
    end
end

function Player.mousepressed(x, y, button) end

function Player.getX()
    return character and character:getX() or 400
end

function Player.getY()
    return character and character:getY() or 360
end

function Player.getCharacter()
    return character
end

return Player
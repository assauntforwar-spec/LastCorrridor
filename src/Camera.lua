local Camera = {}
Camera.__index = Camera

function Camera.new()
    local self = setmetatable({}, Camera)
    self.x = 0
    self.y = 0
    return self
end

function Camera:follow(target, mapWidth, mapHeight, screenWidth, screenHeight)
    self.x = target.x - screenWidth / 2
    self.y = target.y - screenHeight / 2

    if self.x < 0 then self.x = 0 end
    if self.y < 0 then self.y = 0 end
    if self.x > mapWidth - screenWidth then
        self.x = mapWidth - screenWidth
    end
    if self.y > mapHeight - screenHeight then
        self.y = mapHeight - screenHeight
    end
end

function Camera:apply()
    love.graphics.push()
    love.graphics.translate(-self.x, -self.y)
end

function Camera:unapply()
    love.graphics.pop()
end

return Camera
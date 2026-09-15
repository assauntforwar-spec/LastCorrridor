local SansDummy = {}
SansDummy.__index = SansDummy

function SansDummy.new(x, y)
    local self = setmetatable({}, SansDummy)

    self.x = x or 600
    self.y = y or 350

    self.sprite = love.graphics.newImage(
        "assets/sprites/sans/spr_sans_dt_0.png"
    )

    self.missSprite = love.graphics.newImage(
        "assets/sprites/miss.png"
    )
    self.missScale = 0.1
    self.missTimer = 0
    self.missDuration = 0.5

    self.teleportCooldown = 0

    return self
end

function SansDummy:update(dt)
    if self.missTimer > 0 then
        self.missTimer = self.missTimer - dt
    end
    if self.teleportCooldown > 0 then
        self.teleportCooldown = self.teleportCooldown - dt
    end
end

function SansDummy:checkHit(attackX, attackY)
    local dx = self.x - attackX
    local dy = self.y - attackY
    local dist = math.sqrt(dx * dx + dy * dy)
    return dist < 50
end

function SansDummy:dodge()
    if self.teleportCooldown > 0 then return end

    self.missTimer = self.missDuration
    self.teleportCooldown = 0.3

    local angle = math.random() * math.pi * 2
    local distance = math.random(50, 150)

    local newX = self.x + math.cos(angle) * distance
    local newY = self.y + math.sin(angle) * distance

    if newX < 50 then newX = 50 end
    if newX > 850 then newX = 850 end
    if newY < 50 then newY = 50 end
    if newY > 650 then newY = 650 end

    self.x = newX
    self.y = newY
end

function SansDummy:draw()
    local sprite = self.sprite
    if sprite then
        local sx = sprite:getWidth() / 2
        local sy = sprite:getHeight() / 2
        love.graphics.draw(sprite, self.x, self.y, 0, 2, 2, sx, sy)
    end

    if self.missTimer > 0 then
        local sx = self.missSprite:getWidth() / 2
        local sy = self.missSprite:getHeight() / 2
        love.graphics.draw(self.missSprite, self.x, self.y - 60, 0, 0.9, 0.9, sx, sy)
    end
end

function SansDummy:getX() return self.x end
function SansDummy:getY() return self.y end

return SansDummy